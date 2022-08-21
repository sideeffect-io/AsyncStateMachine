//
//  AsyncBufferedChannel.swift
//  
//
//  Created by Thibault WITTEMBERG on 06/08/2022.
//

public final class AsyncBufferedChannel<Element>: AsyncSequence, Sendable
where Element: Sendable {
  public typealias Element = Element
  public typealias AsyncIterator = Iterator

  struct Awaiting: Hashable {
    let id: Int
    let continuation: UnsafeContinuation<Element?, Never>?

    static func placeHolder(id: Int) -> Awaiting {
      Awaiting(id: id, continuation: nil)
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(self.id)
    }

    static func == (lhs: Awaiting, rhs: Awaiting) -> Bool {
      lhs.id == rhs.id
    }
  }

  enum SendDecision {
    case resume(Awaiting, Element)
    case terminate([Awaiting])
    case nothing
  }

  enum AwaitingDecision {
    case resume(Element?)
    case suspend
  }

  enum Value {
    case element(Element)
    case termination
  }

  enum State {
    case active(queue: [Value], awaitings: Set<Awaiting>)
    case finished

    static var initial: State {
      .active(queue: [], awaitings: [])
    }
  }

  let ids: ManagedCriticalState<Int>
  let state: ManagedCriticalState<State>

  init() {
    self.ids = ManagedCriticalState(0)
    self.state = ManagedCriticalState(.initial)
  }

  func generateId() -> Int {
    self.ids.withCriticalRegion { ids in
      ids += 1
      return ids
    }
  }

  func send(_ value: Value) {
    let decision = self.state.withCriticalRegion { state -> SendDecision in
      switch state {
      case var .active(queue, awaitings):
        if !awaitings.isEmpty {
          switch value {
          case .element(let element):
            let awaiting = awaitings.removeFirst()
            state = .active(queue: queue, awaitings: awaitings)
            return .resume(awaiting, element)
          case .termination:
            state = .finished
            return .terminate(Array(awaitings))
          }
        } else {
          switch value {
          case .termination where queue.isEmpty:
            state = .finished
          case .element, .termination:
            queue.append(value)
            state = .active(queue: queue, awaitings: awaitings)
          }
          return .nothing
        }
      case .finished:
        return .nothing
      }
    }

    switch decision {
    case .nothing:
      break
    case .terminate(let awaitings):
      awaitings.forEach { $0.continuation?.resume(returning: nil) }
    case let .resume(awaiting, element):
      awaiting.continuation?.resume(returning: element)
    }
  }

  @Sendable
  func send(_ element: Element) {
    self.send(.element(element))
  }

  @Sendable
  func finish() {
    self.send(.termination)
  }

  func next(onSuspend: (() -> Void)? = nil) async -> Element? {
    let awaitingId = self.generateId()
    let cancellation = ManagedCriticalState<Bool>(false)

    return await withTaskCancellationHandler { [state] in
      let awaiting = state.withCriticalRegion { state -> Awaiting? in
        cancellation.apply(criticalState: true)
        switch state {
        case .active(let queue, var awaitings):
          let awaiting = awaitings.remove(.placeHolder(id: awaitingId))
          state = .active(queue: queue, awaitings: awaitings)
          return awaiting
        case .finished:
          return nil
        }
      }

      awaiting?.continuation?.resume(returning: nil)
    } operation: {
      await withUnsafeContinuation { [state] (continuation: UnsafeContinuation<Element?, Never>) in
        let decision = state.withCriticalRegion { state -> AwaitingDecision in
          guard !cancellation.criticalState else { return .resume(nil) }

          switch state {
          case var .active(queue, awaitings):
            if !queue.isEmpty {
              let value = queue.removeFirst()
              switch value {
              case .termination:
                state = .finished
                return .resume(nil)
              case .element(let element):
                state = .active(queue: queue, awaitings: awaitings)
                return .resume(element)
              }
            } else {
              awaitings.update(with: Awaiting(id: awaitingId, continuation: continuation))
              state = .active(queue: queue, awaitings: awaitings)
              return .suspend
            }
          case .finished:
            return .resume(nil)
          }
        }

        switch decision {
        case .resume(let element): continuation.resume(returning: element)
        case .suspend:
          onSuspend?()
        }
      }
    }
  }

  public func makeAsyncIterator() -> AsyncIterator {
    Iterator(
      channel: self
    )
  }

  public struct Iterator: AsyncIteratorProtocol {
    let channel: AsyncBufferedChannel<Element>

    public func next() async -> Element? {
      await self.channel.next()
    }
  }
}
