//
//  LiveMetalCameraViewControllerTest.swift
//  SemanticSegmentation-CoreMLTests
//
//  Created by Staphany Park on 10/9/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

@testable import SemanticSegmentation_CoreML
import XCTest

final class LiveMetalCameraViewControllerTest: XCTestCase {
    func testMode_empty() throws {
        let data = [Int]()
        let result = LiveMetalCameraViewController.mode(data)
        XCTAssertEqual(result, 0)
    }

    func testMode_allBackground() throws {
        let data = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let result = LiveMetalCameraViewController.mode(data)
        XCTAssertEqual(result, 0)
    }

    func testMode_below5Percent() throws {
        let data = [Int](1...21)
        let result = LiveMetalCameraViewController.mode(data)
        XCTAssertEqual(result, 0)
    }

    func testMode_noMode() throws {
        let data1 = [7, 2, 8, 5, 9, 3, 1, 4, 0, 6]
        let result1 = LiveMetalCameraViewController.mode(data1)
        XCTAssertEqual(result1, 9)

        // Illustrates that although the result is consistent for a given input, it does
        // not follow a predictable ordering.
        let data2 = [70, 20, 80, 50, 90, 30, 10, 40, 0, 60]
        let result2 = LiveMetalCameraViewController.mode(data2)
        XCTAssertEqual(result2, 70)
    }

    func testMode_singleModeNoBackground() throws {
        let data = [3, 3, 5, 5, 5, 5, 5, 2, 2, 2]
        let result = LiveMetalCameraViewController.mode(data)
        XCTAssertEqual(result, 5)
    }

    func testMode_singleModeWithMoreFrequentBackground() throws {
        let data = [0, 0, 5, 5, 5, 5, 0, 0, 0, 0]
        let result = LiveMetalCameraViewController.mode(data)
        XCTAssertEqual(result, 5)
    }

    func testMode_multipleModes() throws {
        let data1 = [3, 3, 2, 2, 2, 6, 6, 6, 5, 5]
        let result1 = LiveMetalCameraViewController.mode(data1)
        XCTAssertEqual(result1, 6)

        // Illustrates that although the result is consistent for a given input, it does
        // not follow a predictable ordering.
        let data2 = [30, 30, 20, 20, 20, 60, 60, 60, 50, 50]
        let result2 = LiveMetalCameraViewController.mode(data2)
        XCTAssertEqual(result2, 20)
    }
}
