//
//  MLObjectTest.swift
//  SemanticSegmentation-CoreMLTests
//
//  Created by Staphany Park on 12/5/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

@testable import SemanticSegmentation_CoreML
import XCTest

final class MLObjectTest: XCTestCase {
    let testDimensions = ModelDimensions(height: 10, width: 10)

    func testRelevanceScore_optimalParameters() throws {
        let object = MLObject(id: 1, center: IntPoint(x: 5, y: 5), depth: 3, size: 40)
        XCTAssertEqual(object.relevanceScore(modelDimensions: testDimensions), 1)
    }

    func testRelevanceScore_minSize() throws {
        let object = MLObject(id: 1, center: IntPoint(x: 5, y: 5), depth: 3, size: 1)
        XCTAssertEqual(object.relevanceScore(modelDimensions: testDimensions), 0.91, accuracy: 0.05)
    }

    func testRelevanceScore_maxSize() throws {
        let object = MLObject(id: 1, center: IntPoint(x: 5, y: 5), depth: 3, size: 100)
        XCTAssertEqual(object.relevanceScore(modelDimensions: testDimensions), 0.87, accuracy: 0.05)
    }

    func testRelevanceScore_variousLocations() throws {
        let object1 = MLObject(id: 1, center: IntPoint(x: 0, y: 0), depth: 3, size: 40)
        let object2 = MLObject(id: 1, center: IntPoint(x: 9, y: 9), depth: 3, size: 40)
        let object3 = MLObject(id: 1, center: IntPoint(x: 8, y: 1), depth: 3, size: 40)
        let object4 = MLObject(id: 1, center: IntPoint(x: 2, y: 7), depth: 3, size: 40)
        XCTAssertEqual(object1.relevanceScore(modelDimensions: testDimensions), 0.2, accuracy: 0.05)
        XCTAssertEqual(object2.relevanceScore(modelDimensions: testDimensions), 0.5, accuracy: 0.05)
        XCTAssertEqual(object3.relevanceScore(modelDimensions: testDimensions), 0.6, accuracy: 0.05)
        XCTAssertEqual(object4.relevanceScore(modelDimensions: testDimensions), 0.8, accuracy: 0.05)
    }
}
