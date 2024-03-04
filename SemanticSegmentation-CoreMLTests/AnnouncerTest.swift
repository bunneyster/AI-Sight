//
//  AnnouncerTest.swift
//  SemanticSegmentation-CoreMLTests
//
//  Created by Staphany Park on 12/27/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

@testable import SemanticSegmentation_CoreML
import XCTest

final class AnnouncerTest: XCTestCase {
    func testComputeMainObject() throws {
        let objects = [
            MLObject(id: 1, center: IntPoint(x: 1, y: 1), depth: 1, size: 30),
            MLObject(id: 2, center: IntPoint(x: 5, y: 5), depth: 1, size: 30),
            MLObject(id: 3, center: IntPoint(x: 9, y: 9), depth: 1, size: 30),
        ]

        let result = StreamingMainObjectAnnouncer.computeMainObject(
            objects: objects,
            minSize: 20,
            maxDepth: 5,
            modelDimensions: ModelDimensions(height: 10, width: 10)
        )
        XCTAssertEqual(result!.id, 2)
    }

    func testComputeMainObject_underSizeThreshold() throws {
        let objects = [
            MLObject(id: 1, center: IntPoint(x: 1, y: 1), depth: 1, size: 10),
            MLObject(id: 2, center: IntPoint(x: 5, y: 5), depth: 1, size: 10),
            MLObject(id: 3, center: IntPoint(x: 9, y: 9), depth: 1, size: 10),
        ]

        let result = StreamingMainObjectAnnouncer.computeMainObject(
            objects: objects,
            minSize: 20,
            maxDepth: 5,
            modelDimensions: ModelDimensions(height: 10, width: 10)
        )
        XCTAssertNil(result)
    }

    func testComputeMainObject_overDepthThreshold() throws {
        let objects = [
            MLObject(id: 1, center: IntPoint(x: 1, y: 1), depth: 9, size: 30),
            MLObject(id: 2, center: IntPoint(x: 5, y: 5), depth: 9, size: 30),
            MLObject(id: 3, center: IntPoint(x: 9, y: 9), depth: 9, size: 30),
        ]

        let result = StreamingMainObjectAnnouncer.computeMainObject(
            objects: objects,
            minSize: 10,
            maxDepth: 5,
            modelDimensions: ModelDimensions(height: 10, width: 10)
        )
        XCTAssertNil(result)
    }

    func testComputeMainObject_noObjects() throws {
        let result = StreamingMainObjectAnnouncer.computeMainObject(
            objects: [],
            minSize: 20,
            maxDepth: 5,
            modelDimensions: ModelDimensions(height: 10, width: 10)
        )
        XCTAssertNil(result)
    }

    func testMainObjectChanged_noChange() throws {
        let previous = MLObject(id: 1, center: IntPoint(x: 5, y: 5), depth: 0.5, size: 10)
        let current = MLObject(id: 1, center: IntPoint(x: 5, y: 5), depth: 0.5, size: 10)

        let result = StreamingMainObjectAnnouncer.mainObjectChanged(
            previous: previous,
            current: current
        )
        XCTAssertFalse(result)
    }

    func testMainObjectChanged_objectChangesDepthWithinTolerance() throws {
        let previous = MLObject(id: 1, center: IntPoint(x: 5, y: 5), depth: 0.5, size: 10)
        let current = MLObject(id: 1, center: IntPoint(x: 5, y: 5), depth: 0.94, size: 10)

        let result = StreamingMainObjectAnnouncer.mainObjectChanged(
            previous: previous,
            current: current
        )
        XCTAssertFalse(result)
    }

    func testMainObjectChanged_objectChangesDepthOutsideTolerance() throws {
        let previous = MLObject(id: 1, center: IntPoint(x: 5, y: 5), depth: 0.5, size: 10)
        let current = MLObject(id: 1, center: IntPoint(x: 5, y: 5), depth: 0.95, size: 10)

        let result = StreamingMainObjectAnnouncer.mainObjectChanged(
            previous: previous,
            current: current
        )
        XCTAssertTrue(result)
    }

    func testMainObjectChanged_differentObject() throws {
        let previous = MLObject(id: 1, center: IntPoint(x: 5, y: 5), depth: 0.5, size: 10)
        let current = MLObject(id: 2, center: IntPoint(x: 5, y: 5), depth: 0.5, size: 10)

        let result = StreamingMainObjectAnnouncer.mainObjectChanged(
            previous: previous,
            current: current
        )
        XCTAssertTrue(result)
    }

    func testMainObjectChanged_objectAppears() throws {
        let previous: MLObject? = nil
        let current = MLObject(id: 1, center: IntPoint(x: 5, y: 5), depth: 0.5, size: 10)

        let result = StreamingMainObjectAnnouncer.mainObjectChanged(
            previous: previous,
            current: current
        )
        XCTAssertTrue(result)
    }

    func testMainObjectChanged_objectDisappears() throws {
        let previous = MLObject(id: 1, center: IntPoint(x: 5, y: 5), depth: 0.7, size: 10)
        let current: MLObject? = nil

        let result = StreamingMainObjectAnnouncer.mainObjectChanged(
            previous: previous,
            current: current
        )
        XCTAssertTrue(result)
    }
}
