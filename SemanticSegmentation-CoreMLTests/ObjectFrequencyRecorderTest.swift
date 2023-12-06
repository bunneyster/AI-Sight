//
//  ObjectFrequencyRecorderTest.swift
//  SemanticSegmentation-CoreMLTests
//
//  Created by Staphany Park on 12/6/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

@testable import SemanticSegmentation_CoreML
import XCTest

final class ObjectFrequencyRecorderTest: XCTestCase {
    func testFilter() throws {
        let recorder = ObjectFrequencyRecorder(frameCount: 3, minFrequency: 3)

        let frame1 = [
            MLObject(id: 1, center: IntPoint(x: 1, y: 1), depth: 1, size: 10),
            MLObject(id: 2, center: IntPoint(x: 1, y: 1), depth: 1, size: 10),
        ]
        XCTAssertEqual(recorder.filter(objects: frame1), [])

        let frame2 = [MLObject(id: 1, center: IntPoint(x: 1, y: 1), depth: 1, size: 10)]
        XCTAssertEqual(recorder.filter(objects: frame2), [])

        let frame3 = [
            MLObject(id: 1, center: IntPoint(x: 5, y: 5), depth: 1, size: 10),
            MLObject(id: 2, center: IntPoint(x: 1, y: 1), depth: 1, size: 10),
        ]
        XCTAssertEqual(recorder.filter(objects: frame3), [
            MLObject(id: 1, center: IntPoint(x: 5, y: 5), depth: 1, size: 10),
        ])
    }
}
