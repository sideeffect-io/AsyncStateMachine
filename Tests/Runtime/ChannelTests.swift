//
//  ChannelTests.swift
//
//
//  Created by Thibault WITTEMBERG on 20/06/2022.
//

@testable import AsyncStateMachine
import XCTest

final class ChannelTests: XCTestCase {
  enum Event: DSLCompatible, Equatable {
    case e1
  }

  func test_register_sets_the_receiver() async {
    let expectedEvent = Event.e1
    let receivedEvent = ManagedCriticalState<Event?>(nil)

    let spyReceiver: @Sendable (Event) -> Void = { event in
      receivedEvent.apply(criticalState: event)
    }

    // Given
    let sut = Channel<Event>()
    sut.register(receiver: spyReceiver)

    // When
    sut.receiver.criticalState?(expectedEvent)

    // Then
    XCTAssertEqual(receivedEvent.criticalState, expectedEvent)
  }

  func test_push_calls_the_receiver() async {
    let expectedEvent = Event.e1
    let receivedEvent = ManagedCriticalState<Event?>(nil)

    let spyReceiver: @Sendable (Event) -> Void = { event in
      receivedEvent.apply(criticalState: event)
    }

    // Given
    let sut = Channel<Event>()
    sut.register(receiver: spyReceiver)

    // When
    sut.push(expectedEvent)

    // Then
    XCTAssertEqual(receivedEvent.criticalState, expectedEvent)
  }
}
