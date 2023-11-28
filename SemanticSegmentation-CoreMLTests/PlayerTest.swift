//
//  PlayerTest.swift
//  SemanticSegmentation-CoreMLTests
//
//  Created by Staphany Park on 9/27/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

@testable import SemanticSegmentation_CoreML
import Vision
import XCTest

final class PlayerTest: XCTestCase {
    func testGetObjectAndPitchMultiplier_1x1Segment() throws {
        // Cat occupies 1x1 area in center of 3x3 image
        let result = Player.getObjectAndPitchMultiplier(
            k: 8,
            v: 0,
            x: [8: 1],
            y: [8: 1],
            row: 3,
            col: 3
        )

        XCTAssertEqual(result.obj, "cat")
        XCTAssertEqual(result.mult_val, -Float.infinity)
        XCTAssertEqual(result.xValue, Double.infinity)
        XCTAssertEqual(result.sizes, 0)
    }

    func testGetObjectAndPitchMultiplier_objectId() throws {
        let objectId0 = Player.getObjectAndPitchMultiplier(
            k: 0,
            v: 25,
            x: [8: 125],
            y: [8: 125],
            row: 10,
            col: 10
        )
        let objectId8 = Player.getObjectAndPitchMultiplier(
            k: 8,
            v: 25,
            x: [8: 125],
            y: [8: 125],
            row: 10,
            col: 10
        )
        let objectId20 = Player.getObjectAndPitchMultiplier(
            k: 20,
            v: 25,
            x: [8: 125],
            y: [8: 125],
            row: 10,
            col: 10
        )

        XCTAssertEqual(objectId0.obj, "background")
        XCTAssertEqual(objectId8.obj, "cat")
        XCTAssertEqual(objectId20.obj, "tv")
    }

    func testGetObjectAndPitchMultiplier_multiplier() throws {
        // Cat occupies 5x5 area at top of 10x10 image
        let yTop = Player.getObjectAndPitchMultiplier(
            k: 8,
            v: 25,
            x: [8: 125],
            y: [8: 50],
            row: 10,
            col: 10
        )
        // Cat occupies 5x5 area at center of 10x10 image
        let yMid = Player.getObjectAndPitchMultiplier(
            k: 8,
            v: 25,
            x: [8: 125],
            y: [8: 125],
            row: 10,
            col: 10
        )
        // Cat occupies 5x5 area at bottom of 10x10 image
        let yBottom = Player.getObjectAndPitchMultiplier(
            k: 8,
            v: 25,
            x: [8: 125],
            y: [8: 175],
            row: 10,
            col: 10
        )

        XCTAssertEqual(yTop.mult_val, 1.5)
        XCTAssertEqual(yMid.mult_val, 1.2)
        XCTAssertEqual(yBottom.mult_val, 1.0)
    }

    func testGetObjectAndPitchMultiplier_xValue() throws {
        // Cat occupies 5x5 area at left of 10x10 image
        let xLeft = Player.getObjectAndPitchMultiplier(
            k: 8,
            v: 25,
            x: [8: 50],
            y: [8: 125],
            row: 10,
            col: 10
        )
        // Cat occupies 5x5 area at center of 10x10 image
        let xMid = Player.getObjectAndPitchMultiplier(
            k: 8,
            v: 25,
            x: [8: 125],
            y: [8: 125],
            row: 10,
            col: 10
        )
        // Cat occupies 5x5 area at left of 10x10 image
        let xRight = Player.getObjectAndPitchMultiplier(
            k: 8,
            v: 25,
            x: [8: 175],
            y: [8: 125],
            row: 10,
            col: 10
        )

        XCTAssertEqual(xLeft.xValue, 0.2)
        XCTAssertEqual(xMid.xValue, 0.5)
        XCTAssertEqual(xRight.xValue, 0.7)
    }

    func testGetObjectAndPitchMultiplier_size() throws {
        // Cat occupies 2x2 area at center of 10x10 image
        let small = Player.getObjectAndPitchMultiplier(
            k: 8,
            v: 4,
            x: [8: 9],
            y: [8: 9],
            row: 10,
            col: 10
        )
        // Cat occupies 5x5 area at center of 10x10 image
        let medium = Player.getObjectAndPitchMultiplier(
            k: 8,
            v: 25,
            x: [8: 125],
            y: [8: 125],
            row: 10,
            col: 10
        )
        // Cat occupies 8x8 area at center of 10x10 image
        let large = Player.getObjectAndPitchMultiplier(
            k: 8,
            v: 64,
            x: [8: 288],
            y: [8: 288],
            row: 10,
            col: 10
        )

        XCTAssertEqual(small.sizes, 0.04)
        XCTAssertEqual(medium.sizes, 0.25)
        XCTAssertEqual(large.sizes, 0.64)
    }
}
