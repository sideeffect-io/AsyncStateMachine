//
//  StateMachineTests.swift
//  TaskTrackerTests
//
//  Created by Thibault Wittemberg on 18/08/2022.
//

import AsyncStateMachine
@testable import TaskTracker
import XCTest

final class StateMachineTests: XCTestCase {

  lazy var mockEntries: [Entry] = {
    (0...15).map { index in
      Entry(
        id: UUID().uuidString,
        startDate: Date(),
        endDate: Date().addingTimeInterval(Double(index) * 2_000),
        description: "Description \(UUID().uuidString)"
      )
    }
  }()

  let mockEntry = Entry(
    id: UUID().uuidString,
    startDate: Date(),
    endDate: Date().addingTimeInterval(2_000),
    description: "Description \(UUID().uuidString)"
  )

  func test_stateMachine_executes_expected_outputs() {
    let sut = stateMachine(initial: .loading)
    XCTStateMachine(sut)
      .assert(when: .loading, execute: .load)
      .assert(when: .adding(entry: mockEntry, into: mockEntries), execute: .add(entry: mockEntry))
      .assert(when: .removing(entries: [mockEntry], from: mockEntries), execute: .remove(entries: [mockEntry]))
      .assertNoOutput(when: .failed)
  }

  func test_stateMachine_executes_expected_transitions_when_loading() async {
    let sut = stateMachine(initial: .loading)
    await XCTStateMachine(sut)
      .assert(when: .loading, on: .loadingHasSucceeded(entries: mockEntries), transitionTo: .loaded(entries: mockEntries))
      .assert(when: .loading, on: .loadingHasFailed, transitionTo: .failed)
      .assertNoTransition(when: .loading, on: .entryShouldBeAdded(entry: mockEntry))
      .assertNoTransition(when: .loading, on: .entriesShouldBeRemoved(mode: .all))
      .assertNoTransition(when: .loading, on: .entriesShouldBeRemoved(mode: .one(index: .init(integer: 0))))
      .assertNoTransition(when: .loading, on: .savingHasSucceeded)
      .assertNoTransition(when: .loading, on: .savingHasFailed)
  }

  func test_stateMachine_executes_expected_transitions_when_loaded() async {
    let sut = stateMachine(initial: .loading)
    await XCTStateMachine(sut)
      .assert(
        when: .loaded(entries: mockEntries),
        on: .entryShouldBeAdded(entry: mockEntry),
        transitionTo: .adding(entry: mockEntry, into: mockEntries)
      )
      .assert(
        when: .loaded(entries: mockEntries),
        on: .entriesShouldBeRemoved(mode: .one(index: .init(integer: 0))),
        transitionTo: .removing(entries: [mockEntries[0]], from: mockEntries)
      )
      .assert(
        when: .loaded(entries: mockEntries),
        on: .entriesShouldBeRemoved(mode: .all),
        transitionTo: .removing(entries: mockEntries, from: mockEntries)
      )
      .assertNoTransition(when: .loaded(entries: mockEntries), on: .loadingHasSucceeded(entries: mockEntries))
      .assertNoTransition(when: .loaded(entries: mockEntries), on: .loadingHasFailed)
      .assertNoTransition(when: .loaded(entries: mockEntries), on: .savingHasSucceeded)
      .assertNoTransition(when: .loaded(entries: mockEntries), on: .savingHasFailed)
  }

  func test_stateMachine_executes_expected_transitions_when_adding() async {
    let sut = stateMachine(initial: .loading)
    await XCTStateMachine(sut)
      .assert(
        when: .adding(entry: mockEntry, into: mockEntries),
        on: .savingHasSucceeded,
        transitionTo: .loading
      )
      .assert(
        when: .adding(entry: mockEntry, into: mockEntries),
        on: .savingHasFailed,
        transitionTo: .failed
      )
      .assertNoTransition(when: .adding(entry: mockEntry, into: mockEntries), on: .loadingHasSucceeded(entries: mockEntries))
      .assertNoTransition(when: .adding(entry: mockEntry, into: mockEntries), on: .loadingHasFailed)
      .assertNoTransition(when: .adding(entry: mockEntry, into: mockEntries), on: .entryShouldBeAdded(entry: mockEntry))
      .assertNoTransition(when: .adding(entry: mockEntry, into: mockEntries), on: .entriesShouldBeRemoved(mode: .all))
      .assertNoTransition(when: .adding(entry: mockEntry, into: mockEntries), on: .entriesShouldBeRemoved(mode: .one(index: .init(integer: 0))))
  }

  func test_stateMachine_executes_expected_transitions_when_removing() async {
    let sut = stateMachine(initial: .loading)
    await XCTStateMachine(sut)
      .assert(
        when: .removing(entries: [mockEntries[0]], from: mockEntries),
        on: .savingHasSucceeded,
        transitionTo: .loading
      )
      .assert(
        when: .removing(entries: [mockEntries[0]], from: mockEntries),
        on: .savingHasFailed,
        transitionTo: .failed
      )
      .assertNoTransition(when: .adding(entry: mockEntry, into: mockEntries), on: .loadingHasSucceeded(entries: mockEntries))
      .assertNoTransition(when: .adding(entry: mockEntry, into: mockEntries), on: .loadingHasFailed)
      .assertNoTransition(when: .adding(entry: mockEntry, into: mockEntries), on: .entryShouldBeAdded(entry: mockEntry))
      .assertNoTransition(when: .adding(entry: mockEntry, into: mockEntries), on: .entriesShouldBeRemoved(mode: .all))
      .assertNoTransition(when: .adding(entry: mockEntry, into: mockEntries), on: .entriesShouldBeRemoved(mode: .one(index: .init(integer: 0))))
  }

  func test_stateMachine_executes_expected_transitions_when_failed() async {
    let sut = stateMachine(initial: .loading)
    await XCTStateMachine(sut)
      .assert(
        when: .failed,
        on: .entryShouldBeAdded(entry: mockEntry),
        transitionTo: .adding(entry: mockEntry, into: [])
      )
      .assertNoTransition(when: .failed, on: .loadingHasSucceeded(entries: mockEntries))
      .assertNoTransition(when: .failed, on: .loadingHasFailed)
      .assertNoTransition(when: .failed, on: .savingHasSucceeded)
      .assertNoTransition(when: .failed, on: .savingHasFailed)
      .assertNoTransition(when: .failed, on: .entriesShouldBeRemoved(mode: .all))
      .assertNoTransition(when: .failed, on: .entriesShouldBeRemoved(mode: .one(index: .init(integer: 0))))
  }
}
