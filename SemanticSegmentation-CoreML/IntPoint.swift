//
//  IntPoint.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 11/21/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import Foundation

// MARK: - IntPoint

/// A pair of coordinates, like `CGPoint`, but using `Int`.
struct IntPoint: Equatable {
    var x: Int
    var y: Int
}

// MARK: Comparable

extension IntPoint: Comparable {
    static func < (lhs: IntPoint, rhs: IntPoint) -> Bool {
        if lhs.x != rhs.x {
            return lhs.x < rhs.x
        } else {
            return lhs.y < rhs.y
        }
    }
}
