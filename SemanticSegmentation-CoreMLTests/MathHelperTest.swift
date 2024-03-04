//
//  MathHelperTest.swift
//  SemanticSegmentation-CoreMLTests
//
//  Created by Staphany Park on 3/4/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

@testable import SemanticSegmentation_CoreML
import XCTest

final class MathHelperTest: XCTestCase {
    func testPartition() throws {
        XCTAssertEqual(MathHelper.partition(end: 3, by: 1, i: 0), 1.5)

        XCTAssertEqual(MathHelper.partition(end: 3, by: 2, i: 0), 1.0)
        XCTAssertEqual(MathHelper.partition(end: 3, by: 2, i: 1), 2.0)

        XCTAssertEqual(MathHelper.partition(end: 3, by: 3, i: 0), 0.75)
        XCTAssertEqual(MathHelper.partition(end: 3, by: 3, i: 1), 1.5)
        XCTAssertEqual(MathHelper.partition(end: 3, by: 3, i: 2), 2.25)

        XCTAssertEqual(MathHelper.partition(end: 3, by: 4, i: 0), 0.6)
        XCTAssertEqual(MathHelper.partition(end: 3, by: 5, i: 0), 0.5)
        XCTAssertEqual(MathHelper.partition(end: 3, by: 7, i: 0), 0.375)
    }
}
