//
//  On.swift
//
//
//  Created by Thibault WITTEMBERG on 25/06/2022.
//

public struct On<S, E>: Sendable
where S: DSLCompatible, E: DSLCompatible {
  // predicate and transition are 2 separate things because we want
  // to be able to evaluate predicates (which is a sync and fast operation)
  // in isolation to select the good transition (we don't want to execute
  // all the transitions to find out which has a non nil next state)
  let predicate: @Sendable (E) -> Bool
  let transition: @Sendable (E) async -> S?

  public init(
    event: E,
    guard: @escaping @Sendable (E) -> Guard,
    transition: @escaping @Sendable (E) async -> Transition<S>
  ) {
    self.predicate = { inputEvent in
      inputEvent.matches(event) && `guard`(inputEvent).predicate
    }
    self.transition = { inputEvent in await transition(inputEvent).state }
  }

  public init(
    event: E,
    transition: @escaping @Sendable (E) async -> Transition<S>
  ) {
    self.init(
      event: event,
      guard: { _ in Guard(predicate: true) },
      transition: transition
    )
  }

  public init<EventAssociatedValue>(
    event: @escaping (EventAssociatedValue) -> E,
    guard: @escaping @Sendable (EventAssociatedValue) -> Guard,
    transition: @escaping @Sendable (EventAssociatedValue) async -> Transition<S>
  ) {
    self.predicate = { inputEvent in
      if let inputPayload = inputEvent.associatedValue(expecting: EventAssociatedValue.self) {
        return inputEvent.matches(event) &&
        `guard`(inputPayload).predicate
      }
      return false
    }

    self.transition = { inputEvent in
      if let eventPayload = inputEvent.associatedValue(expecting: EventAssociatedValue.self) {
        return await transition(eventPayload).state
      }
      return nil
    }
  }

  public init<EventAssociatedValue>(
    event: @escaping (EventAssociatedValue) -> E,
    transition: @escaping @Sendable (EventAssociatedValue) async -> Transition<S>
  ) {
    self.init(
      event: event,
      guard: { _ in Guard(predicate: true) },
      transition: transition
    )
  }

  public init(
    events: OneOf<E>,
    guard: @escaping @Sendable (E) -> Guard,
    transition: @escaping @Sendable (E) async -> Transition<S>
  ) {
    self.predicate = { event in
      events.predicate(event) && `guard`(event).predicate
    }
    self.transition = { event in await transition(event).state }
  }

  public init(
    events: OneOf<E>,
    transition: @escaping @Sendable (E) async -> Transition<S>
  ) {
    self.init(
      events: events,
      guard: { _ in Guard(predicate: true) },
      transition: transition
    )
  }
}
