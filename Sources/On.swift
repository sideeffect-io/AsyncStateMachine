
public struct On<S, E>: Sendable
where S: DSLCompatible, E: DSLCompatible {
  public let predicate: @Sendable (E) -> Bool
  public let transition: @Sendable (E) async -> S?

  public init(
    event: E,
    transition: @escaping () async -> Transition<S>
  ) {
    self.predicate = { inputEvent in inputEvent.matches(case: event) }
    self.transition = { _ in await transition().state }
  }

  public init(
    event: E,
    guard: @escaping () -> Guard,
    transition: @escaping () async -> Transition<S>
  ) {
    self.predicate = { inputEvent in
      inputEvent.matches(case: event) && `guard`().predicate
    }
    self.transition = { _ in await transition().state }
  }

  public init<EventAssociatedValue>(
    event: @escaping (EventAssociatedValue) -> E,
    transition: @escaping (EventAssociatedValue) async -> Transition<S>
  ) {
    self.predicate = { inputEvent in inputEvent.matches(case: event) }
    self.transition = { inputEvent in
      if let eventPayload: EventAssociatedValue = inputEvent.associatedValue() {
        return await transition(eventPayload).state
      }
      return nil
    }
  }

  public init<EventAssociatedValue>(
    event: @escaping (EventAssociatedValue) -> E,
    guard: @escaping (EventAssociatedValue) -> Guard,
    transition: @escaping (EventAssociatedValue) async -> Transition<S>
  ) {
    self.predicate = { inputEvent in
      if let inputPayload: EventAssociatedValue = inputEvent.associatedValue() {
        return inputEvent.matches(case: event) &&
        `guard`(inputPayload).predicate
      }
      return false
    }

    self.transition = { inputEvent in
      if let eventPayload: EventAssociatedValue = inputEvent.associatedValue() {
        return await transition(eventPayload).state
      }
      return nil
    }
  }

  public init(
    events: OneOf<E>,
    transition: @escaping (E) async -> Transition<S>
  ) {
    self.predicate = events.predicate
    self.transition = { event in await transition(event).state }
  }

  public init(
    events: OneOf<E>,
    guard: @escaping (E) -> Guard,
    transition: @escaping (E) async -> Transition<S>
  ) {
    self.predicate = { event in
      events.predicate(event) && `guard`(event).predicate
    }
    self.transition = { event in await transition(event).state }
  }
}
