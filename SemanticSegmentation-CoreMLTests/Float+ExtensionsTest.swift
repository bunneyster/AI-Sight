//
//  Float+ExtensionsTest.swift
//  SemanticSegmentation-CoreMLTests
//
//  Created by Staphany Park on 11/21/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

@testable import SemanticSegmentation_CoreML
import XCTest

final class Float_ExtensionsTest: XCTestCase {
    func testRound() throws {
        XCTAssertEqual(Float(0.4).round(nearest: 0.5), 0.5)
        XCTAssertEqual(Float(0.5).round(nearest: 0.5), 0.5)
        XCTAssertEqual(Float(0.6).round(nearest: 0.5), 0.5)

        XCTAssertEqual(Float(0.75).round(nearest: 0.5), 1.0)
        XCTAssertEqual(Float(1.00).round(nearest: 0.5), 1.0)
        XCTAssertEqual(Float(1.24).round(nearest: 0.5), 1.0)
    }

    func testIsWithinRange_zeroTolerance() throws {
        XCTAssertFalse(Float(1.24).isWithinRange(of: 1.5, nearest: 0.5, tolerance: 0))
        XCTAssertTrue(Float(1.25).isWithinRange(of: 1.5, nearest: 0.5, tolerance: 0))
        XCTAssertTrue(Float(1.5).isWithinRange(of: 1.5, nearest: 0.5, tolerance: 0))
        XCTAssertTrue(Float(1.74).isWithinRange(of: 1.5, nearest: 0.5, tolerance: 0))
        XCTAssertFalse(Float(1.75).isWithinRange(of: 1.5, nearest: 0.5, tolerance: 0))
    }

    func testIsWithinRange_nonZeroTolerance() throws {
        XCTAssertFalse(Float(1.23).isWithinRange(of: 1.5, nearest: 0.5, tolerance: 0.01))
        XCTAssertTrue(Float(1.24).isWithinRange(of: 1.5, nearest: 0.5, tolerance: 0.01))
        XCTAssertTrue(Float(1.5).isWithinRange(of: 1.5, nearest: 0.5, tolerance: 0.01))
        XCTAssertTrue(Float(1.75).isWithinRange(of: 1.5, nearest: 0.5, tolerance: 0.01))
        XCTAssertFalse(Float(1.76).isWithinRange(of: 1.5, nearest: 0.5, tolerance: 0.01))
    }

    func testIsWithinRange_roundedUp() throws {
        XCTAssertFalse(Float(1.23).isWithinRange(of: 1.25, nearest: 0.5, tolerance: 0.01))
        XCTAssertTrue(Float(1.24).isWithinRange(of: 1.25, nearest: 0.5, tolerance: 0.01))
        XCTAssertTrue(Float(1.75).isWithinRange(of: 1.25, nearest: 0.5, tolerance: 0.01))
        XCTAssertFalse(Float(1.76).isWithinRange(of: 1.25, nearest: 0.5, tolerance: 0.01))
    }

    func testIsWithinRange_roundedDown() throws {
        XCTAssertFalse(Float(1.23).isWithinRange(of: 1.74, nearest: 0.5, tolerance: 0.01))
        XCTAssertTrue(Float(1.24).isWithinRange(of: 1.74, nearest: 0.5, tolerance: 0.01))
        XCTAssertTrue(Float(1.75).isWithinRange(of: 1.74, nearest: 0.5, tolerance: 0.01))
        XCTAssertFalse(Float(1.76).isWithinRange(of: 1.74, nearest: 0.5, tolerance: 0.01))
    }
}
