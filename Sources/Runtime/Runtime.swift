//
//  RuntimeStrategy.swift
//
//
//  Created by Thibault WITTEMBERG on 25/06/2022.
//

public struct Runtime<S, E, O>: Sendable
where S: DSLCompatible, E: DSLCompatible & Sendable, O: DSLCompatible {
  var sideEffects = [SideEffect<S, E, O>]()
  var stateMiddlewares = [Middleware<S>]()
  var eventMiddlewares = [Middleware<E>]()

  let eventChannel = AsyncChannel<E>()

  public init() {}

  @discardableResult
  public func map(
    output: O,
    to sideEffect: @escaping () -> AnyAsyncSequence<E>,
    priority: TaskPriority? = nil,
    strategy: ExecutionStrategy<S> = .continueWhenAnyState
  ) -> Self {
    var mutableSelf = self

    let predicate: @Sendable (O) -> Bool = { currentOutput in
      currentOutput.matches(output)
    }

    let sideEffect: @Sendable (O) -> AnyAsyncSequence<E> = { _ in
      sideEffect()
    }

    mutableSelf.sideEffects.append(
      SideEffect(
        predicate: predicate,
        execute: sideEffect,
        priority: priority,
        strategy: strategy
      )
    )

    return mutableSelf
  }

  @discardableResult
  public func map(
    output: O,
    to sideEffect: @escaping () async -> E?,
    priority: TaskPriority? = nil,
    strategy: ExecutionStrategy<S> = .continueWhenAnyState
  ) -> Self {
    let sideEffect: () -> AnyAsyncSequence<E> = {
      AsyncJustSequence(sideEffect)
        .eraseToAnyAsyncSequence()
    }

    return self.map(
      output: output,
      to: sideEffect,
      priority: priority,
      strategy: strategy
    )
  }

  @discardableResult
  public func map<OutputAssociatedValue>(
    output: @escaping (OutputAssociatedValue) -> O,
    to sideEffect: @escaping (OutputAssociatedValue) -> AnyAsyncSequence<E>,
    priority: TaskPriority? = nil,
    strategy: ExecutionStrategy<S> = .continueWhenAnyState
  ) -> Self {
    var mutableSelf = self

    let predicate: @Sendable (O) -> Bool = { currentOutput in
      currentOutput.matches(output)
    }
    
    let sideEffect: @Sendable (O) -> AnyAsyncSequence<E>? = { currentOutput in
      if let outputAssociatedValue = currentOutput.associatedValue(expecting: OutputAssociatedValue.self) {
        return sideEffect(outputAssociatedValue)
      }

      return nil
    }

    mutableSelf.sideEffects.append(
      SideEffect(
        predicate: predicate,
        execute: sideEffect,
        priority: priority,
        strategy: strategy
      )
    )

    return mutableSelf
  }

  @discardableResult
  public func map<OutputAssociatedValue>(
    output: @escaping (OutputAssociatedValue) -> O,
    to sideEffect: @escaping (OutputAssociatedValue) async -> E?,
    priority: TaskPriority? = nil,
    strategy: ExecutionStrategy<S> = .continueWhenAnyState
  ) -> Self {
    let sideEffect: (OutputAssociatedValue) -> AnyAsyncSequence<E> = { outputAssociatedValue in
      return AsyncJustSequence({ await sideEffect(outputAssociatedValue) })
        .eraseToAnyAsyncSequence()
    }

    return self.map(
      output: output,
      to: sideEffect,
      priority: priority,
      strategy: strategy
    )
  }

  @discardableResult
  public func register(
    middleware: @Sendable @escaping (S) async -> Void,
    priority: TaskPriority? = nil
  ) -> Self {
    var mutableSelf = self

    mutableSelf.stateMiddlewares.append(
      Middleware<S>(
        execute: { state in
          await middleware(state)
          return false
        },
        priority: priority
      )
    )

    return mutableSelf
  }

  @discardableResult
  public func register(
    middleware: @Sendable @escaping (E) async -> Void,
    priority: TaskPriority? = nil
  ) -> Self {
    var mutableSelf = self

    mutableSelf.eventMiddlewares.append(
      Middleware<E>(
        execute: { event in
          await middleware(event)
          return false
        },
        priority: priority
      )
    )

    return mutableSelf
  }

  @discardableResult
  public func connectAsReceiver(
    to pipe: Pipe<E>
  ) -> Self {
    pipe.register { [eventChannel] event in
      await eventChannel.send(event)
    }
    return self
  }

  @discardableResult
  public func connectAsSender<OtherE>(
    to pipe: Pipe<OtherE>,
    when state: S,
    send event: OtherE
  ) -> Self {
    return self.register(middleware: { (inputState: S) in
      guard inputState.matches(state) else { return }
      await pipe.push(event)
    })
  }

  @discardableResult
  public func connectAsSender<StateAssociatedValue, OtherE>(
    to pipe: Pipe<OtherE>,
    when state: @escaping (StateAssociatedValue) -> S,
    send event: @escaping (StateAssociatedValue) -> OtherE
  ) -> Self {
    return self.register(middleware: { (inputState: S) in
      guard let value = inputState.associatedValue(matching: state)
      else { return }
      await pipe.push(event(value))
    })
  }

  @Sendable func sideEffects(for output: O) -> SideEffect<S, E, O>? {
    self
      .sideEffects
      .first(where: { sideEffect in sideEffect.predicate(output) })
  }
}

