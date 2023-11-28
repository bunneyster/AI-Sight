//
//  MLMultiArrayHelperTest.swift
//  SemanticSegmentation-CoreMLTests
//
//  Created by Staphany Park on 11/28/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

@testable import SemanticSegmentation_CoreML
import Vision
import XCTest

final class MLMultiArrayHelperTest: XCTestCase {
    func testGetImageFrameCoordinates() throws {
        let segmentationData = [
            [0, 6, 0],
            [4, 8, 6],
            [0, 4, 0],
        ]
        let segmentationMap = buildSegmentationMap(data: segmentationData)

        let result = MLMultiArrayHelper.getImageFrameCoordinates(
            segmentationmap: segmentationMap,
            row: 3,
            col: 3
        )

        XCTAssertTrue(result.o == [0: 3, 4: 1, 6: 1, 8: 0])
        XCTAssertTrue(result.x == [0: 4, 4: 1, 6: 3, 8: 1])
        XCTAssertTrue(result.y == [0: 4, 4: 3, 6: 1, 8: 1])
    }

    func buildSegmentationMap(data: [[Int]]) -> MLMultiArray {
        let shape = [data.count as NSNumber, data[0].count as NSNumber]
        guard let segmentationMap = try? MLMultiArray(shape: shape, dataType: .int32) else {
            return MLMultiArray()
        }
        for x in 0..<3 {
            for y in 0..<3 {
                let key = [x, y] as [NSNumber]
                segmentationMap[key] = data[x][y] as NSNumber
            }
        }

        return segmentationMap
    }
}
