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
    var receivedParam: Int?

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received = inject(
      dep: expectedParam,
      in: { param -> Int in
        receivedParam = param
        return expectedResult
      }
    )

    // When
    let receivedResult = await received()

    // Then
    XCTAssertEqual(receivedParam, expectedParam)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_no_parameter_when_inject_2_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    var receivedParam1: Int?
    var receivedParam2: Int?

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received = inject(
      deps: expectedParam1,
      expectedParam2,
      in: { param1, param2 -> Int in
        receivedParam1 = param1
        receivedParam2 = param2
        return expectedResult
      }
    )

    // When
    let receivedResult = await received()

    // Then
    XCTAssertEqual(receivedParam1, expectedParam1)
    XCTAssertEqual(receivedParam2, expectedParam2)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_no_parameter_when_inject_3_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let expectedParam3 = Int.random(in: 0...100)
    var receivedParam1: Int?
    var receivedParam2: Int?
    var receivedParam3: Int?

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received = inject(
      deps: expectedParam1,
      expectedParam2,
      expectedParam3,
      in: { param1, param2, param3 -> Int in
        receivedParam1 = param1
        receivedParam2 = param2
        receivedParam3 = param3
        return expectedResult
      }
    )

    // When
    let receivedResult = await received()

    // Then
    XCTAssertEqual(receivedParam1, expectedParam1)
    XCTAssertEqual(receivedParam2, expectedParam2)
    XCTAssertEqual(receivedParam3, expectedParam3)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_no_parameter_when_inject_4_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let expectedParam3 = Int.random(in: 0...100)
    let expectedParam4 = Int.random(in: 0...100)
    var receivedParam1: Int?
    var receivedParam2: Int?
    var receivedParam3: Int?
    var receivedParam4: Int?

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received = inject(
      deps: expectedParam1,
      expectedParam2,
      expectedParam3,
      expectedParam4,
      in: { param1, param2, param3, param4 -> Int in
        receivedParam1 = param1
        receivedParam2 = param2
        receivedParam3 = param3
        receivedParam4 = param4
        return expectedResult
      })

    // When
    let receivedResult = await received()

    // Then
    XCTAssertEqual(receivedParam1, expectedParam1)
    XCTAssertEqual(receivedParam2, expectedParam2)
    XCTAssertEqual(receivedParam3, expectedParam3)
    XCTAssertEqual(receivedParam4, expectedParam4)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_no_parameter_when_inject_5_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let expectedParam3 = Int.random(in: 0...100)
    let expectedParam4 = Int.random(in: 0...100)
    let expectedParam5 = Int.random(in: 0...100)
    var receivedParam1: Int?
    var receivedParam2: Int?
    var receivedParam3: Int?
    var receivedParam4: Int?
    var receivedParam5: Int?

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received = inject(
      deps: expectedParam1,
      expectedParam2,
      expectedParam3,
      expectedParam4,
      expectedParam5,
      in: { param1, param2, param3, param4, param5 -> Int in
        receivedParam1 = param1
        receivedParam2 = param2
        receivedParam3 = param3
        receivedParam4 = param4
        receivedParam5 = param5
        return expectedResult
      })

    // When
    let receivedResult = await received()

    // Then
    XCTAssertEqual(receivedParam1, expectedParam1)
    XCTAssertEqual(receivedParam2, expectedParam2)
    XCTAssertEqual(receivedParam3, expectedParam3)
    XCTAssertEqual(receivedParam4, expectedParam4)
    XCTAssertEqual(receivedParam5, expectedParam5)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_no_parameter_when_inject_6_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let expectedParam3 = Int.random(in: 0...100)
    let expectedParam4 = Int.random(in: 0...100)
    let expectedParam5 = Int.random(in: 0...100)
    let expectedParam6 = Int.random(in: 0...100)
    var receivedParam1: Int?
    var receivedParam2: Int?
    var receivedParam3: Int?
    var receivedParam4: Int?
    var receivedParam5: Int?
    var receivedParam6: Int?

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
        receivedParam1 = param1
        receivedParam2 = param2
        receivedParam3 = param3
        receivedParam4 = param4
        receivedParam5 = param5
        receivedParam6 = param6
        return expectedResult
      })

    // When
    let receivedResult = await received()

    // Then
    XCTAssertEqual(receivedParam1, expectedParam1)
    XCTAssertEqual(receivedParam2, expectedParam2)
    XCTAssertEqual(receivedParam3, expectedParam3)
    XCTAssertEqual(receivedParam4, expectedParam4)
    XCTAssertEqual(receivedParam5, expectedParam5)
    XCTAssertEqual(receivedParam6, expectedParam6)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_1_parameter_when_inject_2_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    var receivedParam1: Int?
    var receivedParam2: Int?

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received: (Int) async -> Int = inject(
      dep: expectedParam2,
      in: { param1, param2 -> Int in
        receivedParam1 = param1
        receivedParam2 = param2
        return expectedResult
      }
    )

    // When
    let receivedResult = await received(expectedParam1)

    // Then
    XCTAssertEqual(receivedParam1, expectedParam1)
    XCTAssertEqual(receivedParam2, expectedParam2)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_1_parameter_when_inject_3_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let expectedParam3 = Int.random(in: 0...100)
    var receivedParam1: Int?
    var receivedParam2: Int?
    var receivedParam3: Int?

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received: (Int) async -> Int = inject(
      deps: expectedParam2,
      expectedParam3,
      in: { param1, param2, param3 -> Int in
        receivedParam1 = param1
        receivedParam2 = param2
        receivedParam3 = param3
        return expectedResult
      }
    )

    // When
    let receivedResult = await received(expectedParam1)

    // Then
    XCTAssertEqual(receivedParam1, expectedParam1)
    XCTAssertEqual(receivedParam2, expectedParam2)
    XCTAssertEqual(receivedParam3, expectedParam3)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_1_parameter_when_inject_4_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let expectedParam3 = Int.random(in: 0...100)
    let expectedParam4 = Int.random(in: 0...100)
    var receivedParam1: Int?
    var receivedParam2: Int?
    var receivedParam3: Int?
    var receivedParam4: Int?

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received: (Int) async -> Int = inject(
      deps: expectedParam2,
      expectedParam3,
      expectedParam4,
      in: { param1, param2, param3, param4 -> Int in
        receivedParam1 = param1
        receivedParam2 = param2
        receivedParam3 = param3
        receivedParam4 = param4
        return expectedResult
      }
    )

    // When
    let receivedResult = await received(expectedParam1)

    // Then
    XCTAssertEqual(receivedParam1, expectedParam1)
    XCTAssertEqual(receivedParam2, expectedParam2)
    XCTAssertEqual(receivedParam3, expectedParam3)
    XCTAssertEqual(receivedParam4, expectedParam4)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_1_parameter_when_inject_5_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let expectedParam3 = Int.random(in: 0...100)
    let expectedParam4 = Int.random(in: 0...100)
    let expectedParam5 = Int.random(in: 0...100)
    var receivedParam1: Int?
    var receivedParam2: Int?
    var receivedParam3: Int?
    var receivedParam4: Int?
    var receivedParam5: Int?

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received: (Int) async -> Int = inject(
      deps: expectedParam2,
      expectedParam3,
      expectedParam4,
      expectedParam5,
      in: { param1, param2, param3, param4, param5 -> Int in
        receivedParam1 = param1
        receivedParam2 = param2
        receivedParam3 = param3
        receivedParam4 = param4
        receivedParam5 = param5
        return expectedResult
      }
    )

    // When
    let receivedResult = await received(expectedParam1)

    // Then
    XCTAssertEqual(receivedParam1, expectedParam1)
    XCTAssertEqual(receivedParam2, expectedParam2)
    XCTAssertEqual(receivedParam3, expectedParam3)
    XCTAssertEqual(receivedParam4, expectedParam4)
    XCTAssertEqual(receivedParam5, expectedParam5)
    XCTAssertEqual(receivedResult, expectedResult)
  }

  func test_inject_returns_function_with_1_parameter_when_inject_6_parameters() async {
    let expectedParam1 = Int.random(in: 0...100)
    let expectedParam2 = Int.random(in: 0...100)
    let expectedParam3 = Int.random(in: 0...100)
    let expectedParam4 = Int.random(in: 0...100)
    let expectedParam5 = Int.random(in: 0...100)
    let expectedParam6 = Int.random(in: 0...100)
    var receivedParam1: Int?
    var receivedParam2: Int?
    var receivedParam3: Int?
    var receivedParam4: Int?
    var receivedParam5: Int?
    var receivedParam6: Int?

    let expectedResult = Int.random(in: 0...100)

    // Given
    let received: (Int) async -> Int = inject(
      deps: expectedParam2,
      expectedParam3,
      expectedParam4,
      expectedParam5,
      expectedParam6,
      in: { param1, param2, param3, param4, param5, param6 -> Int in
        receivedParam1 = param1
        receivedParam2 = param2
        receivedParam3 = param3
        receivedParam4 = param4
        receivedParam5 = param5
        receivedParam6 = param6
        return expectedResult
      }
    )

    // When
    let receivedResult = await received(expectedParam1)

    // Then
    XCTAssertEqual(receivedParam1, expectedParam1)
    XCTAssertEqual(receivedParam2, expectedParam2)
    XCTAssertEqual(receivedParam3, expectedParam3)
    XCTAssertEqual(receivedParam4, expectedParam4)
    XCTAssertEqual(receivedParam5, expectedParam5)
    XCTAssertEqual(receivedParam6, expectedParam6)
    XCTAssertEqual(receivedResult, expectedResult)
  }
}
