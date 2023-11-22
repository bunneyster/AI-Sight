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
}
