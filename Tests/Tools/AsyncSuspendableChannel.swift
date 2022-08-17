//
//  AsyncSuspendableChannel.swift
//  
//
//  Created by Thibault WITTEMBERG on 11/08/2022.
//

@testable import AsyncStateMachine

final class AsyncSuspendableChannel<Element>: AsyncSequence, Sendable where Element: Sendable {
  typealias Element = Element
  typealias AsyncIterator = Iterator

  enum State {
    case idle
    case awaitingProducer(UnsafeContinuation<Element?, Never>?)
    case awaitingConsumer(Element?)
    case finished

    var continuation: UnsafeContinuation<Element?, Never>? {
      if case .awaitingProducer(let continuation) = self {
        return continuation
      }
      return nil
    }
  }

  let state = ManagedCriticalState<State>(.awaitingProducer(nil))

  func makeAsyncIterator() -> Iterator {
    Iterator(
      asyncSuspendablechannel: self
    )
  }

  func next() async -> Element? {
    let isCancelled = ManagedCriticalState<Bool>(false)

    return await withTaskCancellationHandler(handler: { [state] in
      let contination = state.withCriticalRegion { state -> UnsafeContinuation<Element?, Never>? in
        isCancelled.apply(criticalState: true)

        switch state {
        case .finished, .idle, .awaitingConsumer:
          return nil
        case .awaitingProducer(let continuation):
          state = .idle
          return continuation
        }
      }

      contination?.resume(returning: nil)
    }, operation: {
      await withUnsafeContinuation { [state] (newContinuation: UnsafeContinuation<Element?, Never>) in
        let decision = state.withCriticalRegion { state -> (Element?, UnsafeContinuation<Element?, Never>?)? in
          if isCancelled.criticalState { return (nil, newContinuation) }

          switch state {
          case .finished:
            return (nil, newContinuation)
          case .idle:
            state = .awaitingProducer(newContinuation)
            return nil
          case .awaitingProducer:
            state = .awaitingProducer(newContinuation)
            return nil
          case .awaitingConsumer(let element):
            state = .idle
            return (element, newContinuation)
          }
        }

        if let decision = decision {
          let element = decision.0
          let continuation = decision.1

          continuation?.resume(returning: element)
        }
      }
    })
  }

  func unsuspend(_ newElement: Element?) {
    let continuation = self.state.withCriticalRegion { state -> UnsafeContinuation<Element?, Never>? in
      switch state {
      case .finished:
        return nil
      case .awaitingProducer(let continuation):
        state = .idle
        return continuation
      case .idle, .awaitingConsumer:
        state = .awaitingConsumer(newElement)
        return nil
      }
    }

    continuation?.resume(returning: newElement)
  }

  func finish() {
    let continuation = self.state.withCriticalRegion { state -> UnsafeContinuation<Element?, Never>? in
      let continuation = state.continuation
      state = .finished
      return continuation
    }

    continuation?.resume(returning: nil)
  }

  struct Iterator: AsyncIteratorProtocol {
    let asyncSuspendablechannel: AsyncSuspendableChannel<Element>

    func next() async -> Element? {
      return await self.asyncSuspendablechannel.next()
    }
  }
}
