//
//  InjectTests.swift
//  
//
//  Created by Thibault WITTEMBERG on 02/07/2022.
//

@testable import AsyncStateMachine
import XCTest

final class InjectTests: XCTestCase {
  func test_inject_returns_function_with_no_parameter_when_inject_1_parameter() async {
    let expectedParam = Int.random(in: 0...100)
    let receivedParam = ManagedCriticalState<Int?>(nil)

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received = inject(
      dep: expectedParam,
      in: { param -> Int in
        receivedParam.apply(criticalState: param)
        return expectedResult
      }
    )

    // When
    let receivedResult = await received()

    // Then
    XCTAssertEqual(receivedParam.criticalState, expectedParam)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_no_parameter_when_inject_2_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let receivedParam1 = ManagedCriticalState<Int?>(nil)
    let receivedParam2 = ManagedCriticalState<Int?>(nil)

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received = inject(
      deps: expectedParam1,
      expectedParam2,
      in: { param1, param2 -> Int in
        receivedParam1.apply(criticalState: param1)
        receivedParam2.apply(criticalState: param2)
        return expectedResult
      }
    )

    // When
    let receivedResult = await received()

    // Then
    XCTAssertEqual(receivedParam1.criticalState, expectedParam1)
    XCTAssertEqual(receivedParam2.criticalState, expectedParam2)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_no_parameter_when_inject_3_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let expectedParam3 = Int.random(in: 0...100)
    let receivedParam1 = ManagedCriticalState<Int?>(nil)
    let receivedParam2 = ManagedCriticalState<Int?>(nil)
    let receivedParam3 = ManagedCriticalState<Int?>(nil)

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received = inject(
      deps: expectedParam1,
      expectedParam2,
      expectedParam3,
      in: { param1, param2, param3 -> Int in
        receivedParam1.apply(criticalState: param1)
        receivedParam2.apply(criticalState: param2)
        receivedParam3.apply(criticalState: param3)
        return expectedResult
      }
    )

    // When
    let receivedResult = await received()

    // Then
    XCTAssertEqual(receivedParam1.criticalState, expectedParam1)
    XCTAssertEqual(receivedParam2.criticalState, expectedParam2)
    XCTAssertEqual(receivedParam3.criticalState, expectedParam3)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_no_parameter_when_inject_4_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let expectedParam3 = Int.random(in: 0...100)
    let expectedParam4 = Int.random(in: 0...100)
    let receivedParam1 = ManagedCriticalState<Int?>(nil)
    let receivedParam2 = ManagedCriticalState<Int?>(nil)
    let receivedParam3 = ManagedCriticalState<Int?>(nil)
    let receivedParam4 = ManagedCriticalState<Int?>(nil)

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received = inject(
      deps: expectedParam1,
      expectedParam2,
      expectedParam3,
      expectedParam4,
      in: { param1, param2, param3, param4 -> Int in
        receivedParam1.apply(criticalState: param1)
        receivedParam2.apply(criticalState: param2)
        receivedParam3.apply(criticalState: param3)
        receivedParam4.apply(criticalState: param4)
        return expectedResult
      })

    // When
    let receivedResult = await received()

    // Then
    XCTAssertEqual(receivedParam1.criticalState, expectedParam1)
    XCTAssertEqual(receivedParam2.criticalState, expectedParam2)
    XCTAssertEqual(receivedParam3.criticalState, expectedParam3)
    XCTAssertEqual(receivedParam4.criticalState, expectedParam4)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_no_parameter_when_inject_5_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let expectedParam3 = Int.random(in: 0...100)
    let expectedParam4 = Int.random(in: 0...100)
    let expectedParam5 = Int.random(in: 0...100)
    let receivedParam1 = ManagedCriticalState<Int?>(nil)
    let receivedParam2 = ManagedCriticalState<Int?>(nil)
    let receivedParam3 = ManagedCriticalState<Int?>(nil)
    let receivedParam4 = ManagedCriticalState<Int?>(nil)
    let receivedParam5 = ManagedCriticalState<Int?>(nil)

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received = inject(
      deps: expectedParam1,
      expectedParam2,
      expectedParam3,
      expectedParam4,
      expectedParam5,
      in: { param1, param2, param3, param4, param5 -> Int in
        receivedParam1.apply(criticalState: param1)
        receivedParam2.apply(criticalState: param2)
        receivedParam3.apply(criticalState: param3)
        receivedParam4.apply(criticalState: param4)
        receivedParam5.apply(criticalState: param5)
        return expectedResult
      })

    // When
    let receivedResult = await received()

    // Then
    XCTAssertEqual(receivedParam1.criticalState, expectedParam1)
    XCTAssertEqual(receivedParam2.criticalState, expectedParam2)
    XCTAssertEqual(receivedParam3.criticalState, expectedParam3)
    XCTAssertEqual(receivedParam4.criticalState, expectedParam4)
    XCTAssertEqual(receivedParam5.criticalState, expectedParam5)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_no_parameter_when_inject_6_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let expectedParam3 = Int.random(in: 0...100)
    let expectedParam4 = Int.random(in: 0...100)
    let expectedParam5 = Int.random(in: 0...100)
    let expectedParam6 = Int.random(in: 0...100)
    let receivedParam1 = ManagedCriticalState<Int?>(nil)
    let receivedParam2 = ManagedCriticalState<Int?>(nil)
    let receivedParam3 = ManagedCriticalState<Int?>(nil)
    let receivedParam4 = ManagedCriticalState<Int?>(nil)
    let receivedParam5 = ManagedCriticalState<Int?>(nil)
    let receivedParam6 = ManagedCriticalState<Int?>(nil)

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received = inject(
      deps: expectedParam1,
      expectedParam2,
      expectedParam3,
      expectedParam4,
      expectedParam5,
      expectedParam6,
      in: { param1, param2, param3, param4, param5, param6 -> Int in
        receivedParam1.apply(criticalState: param1)
        receivedParam2.apply(criticalState: param2)
        receivedParam3.apply(criticalState: param3)
        receivedParam4.apply(criticalState: param4)
        receivedParam5.apply(criticalState: param5)
        receivedParam6.apply(criticalState: param6)
        return expectedResult
      })

    // When
    let receivedResult = await received()

    // Then
    XCTAssertEqual(receivedParam1.criticalState, expectedParam1)
    XCTAssertEqual(receivedParam2.criticalState, expectedParam2)
    XCTAssertEqual(receivedParam3.criticalState, expectedParam3)
    XCTAssertEqual(receivedParam4.criticalState, expectedParam4)
    XCTAssertEqual(receivedParam5.criticalState, expectedParam5)
    XCTAssertEqual(receivedParam6.criticalState, expectedParam6)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_1_parameter_when_inject_2_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let receivedParam1 = ManagedCriticalState<Int?>(nil)
    let receivedParam2 = ManagedCriticalState<Int?>(nil)

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received: (Int) async -> Int = inject(
      dep: expectedParam2,
      in: { param1, param2 -> Int in
        receivedParam1.apply(criticalState: param1)
        receivedParam2.apply(criticalState: param2)
        return expectedResult
      }
    )

    // When
    let receivedResult = await received(expectedParam1)

    // Then
    XCTAssertEqual(receivedParam1.criticalState, expectedParam1)
    XCTAssertEqual(receivedParam2.criticalState, expectedParam2)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_1_parameter_when_inject_3_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let expectedParam3 = Int.random(in: 0...100)
    let receivedParam1 = ManagedCriticalState<Int?>(nil)
    let receivedParam2 = ManagedCriticalState<Int?>(nil)
    let receivedParam3 = ManagedCriticalState<Int?>(nil)

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received: (Int) async -> Int = inject(
      deps: expectedParam2,
      expectedParam3,
      in: { param1, param2, param3 -> Int in
        receivedParam1.apply(criticalState: param1)
        receivedParam2.apply(criticalState: param2)
        receivedParam3.apply(criticalState: param3)
        return expectedResult
      }
    )

    // When
    let receivedResult = await received(expectedParam1)

    // Then
    XCTAssertEqual(receivedParam1.criticalState, expectedParam1)
    XCTAssertEqual(receivedParam2.criticalState, expectedParam2)
    XCTAssertEqual(receivedParam3.criticalState, expectedParam3)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_1_parameter_when_inject_4_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let expectedParam3 = Int.random(in: 0...100)
    let expectedParam4 = Int.random(in: 0...100)
    let receivedParam1 = ManagedCriticalState<Int?>(nil)
    let receivedParam2 = ManagedCriticalState<Int?>(nil)
    let receivedParam3 = ManagedCriticalState<Int?>(nil)
    let receivedParam4 = ManagedCriticalState<Int?>(nil)

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received: (Int) async -> Int = inject(
      deps: expectedParam2,
      expectedParam3,
      expectedParam4,
      in: { param1, param2, param3, param4 -> Int in
        receivedParam1.apply(criticalState: param1)
        receivedParam2.apply(criticalState: param2)
        receivedParam3.apply(criticalState: param3)
        receivedParam4.apply(criticalState: param4)
        return expectedResult
      }
    )

    // When
    let receivedResult = await received(expectedParam1)

    // Then
    XCTAssertEqual(receivedParam1.criticalState, expectedParam1)
    XCTAssertEqual(receivedParam2.criticalState, expectedParam2)
    XCTAssertEqual(receivedParam3.criticalState, expectedParam3)
    XCTAssertEqual(receivedParam4.criticalState, expectedParam4)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_1_parameter_when_inject_5_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let expectedParam3 = Int.random(in: 0...100)
    let expectedParam4 = Int.random(in: 0...100)
    let expectedParam5 = Int.random(in: 0...100)
    let receivedParam1 = ManagedCriticalState<Int?>(nil)
    let receivedParam2 = ManagedCriticalState<Int?>(nil)
    let receivedParam3 = ManagedCriticalState<Int?>(nil)
    let receivedParam4 = ManagedCriticalState<Int?>(nil)
    let receivedParam5 = ManagedCriticalState<Int?>(nil)

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received: (Int) async -> Int = inject(
      deps: expectedParam2,
      expectedParam3,
      expectedParam4,
      expectedParam5,
      in: { param1, param2, param3, param4, param5 -> Int in
        receivedParam1.apply(criticalState: param1)
        receivedParam2.apply(criticalState: param2)
        receivedParam3.apply(criticalState: param3)
        receivedParam4.apply(criticalState: param4)
        receivedParam5.apply(criticalState: param5)
        return expectedResult
      }
    )

    // When
    let receivedResult = await received(expectedParam1)

    // Then
    XCTAssertEqual(receivedParam1.criticalState, expectedParam1)
    XCTAssertEqual(receivedParam2.criticalState, expectedParam2)
    XCTAssertEqual(receivedParam3.criticalState, expectedParam3)
    XCTAssertEqual(receivedParam4.criticalState, expectedParam4)
    XCTAssertEqual(receivedParam5.criticalState, expectedParam5)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_1_parameter_when_inject_6_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let expectedParam3 = Int.random(in: 0...100)
    let expectedParam4 = Int.random(in: 0...100)
    let expectedParam5 = Int.random(in: 0...100)
    let expectedParam6 = Int.random(in: 0...100)
    let receivedParam1 = ManagedCriticalState<Int?>(nil)
    let receivedParam2 = ManagedCriticalState<Int?>(nil)
    let receivedParam3 = ManagedCriticalState<Int?>(nil)
    let receivedParam4 = ManagedCriticalState<Int?>(nil)
    let receivedParam5 = ManagedCriticalState<Int?>(nil)
    let receivedParam6 = ManagedCriticalState<Int?>(nil)

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received: (Int) async -> Int = inject(
      deps: expectedParam2,
      expectedParam3,
      expectedParam4,
      expectedParam5,
      expectedParam6,
      in: { param1, param2, param3, param4, param5, param6 -> Int in
        receivedParam1.apply(criticalState: param1)
        receivedParam2.apply(criticalState: param2)
        receivedParam3.apply(criticalState: param3)
        receivedParam4.apply(criticalState: param4)
        receivedParam5.apply(criticalState: param5)
        receivedParam6.apply(criticalState: param6)
        return expectedResult
      }
    )

    // When
    let receivedResult = await received(expectedParam1)

    // Then
    XCTAssertEqual(receivedParam1.criticalState, expectedParam1)
    XCTAssertEqual(receivedParam2.criticalState, expectedParam2)
    XCTAssertEqual(receivedParam3.criticalState, expectedParam3)
    XCTAssertEqual(receivedParam4.criticalState, expectedParam4)
    XCTAssertEqual(receivedParam5.criticalState, expectedParam5)
    XCTAssertEqual(receivedParam6.criticalState, expectedParam6)
    XCTAssertEqual(receivedResult, expectedResult)
  }
}
