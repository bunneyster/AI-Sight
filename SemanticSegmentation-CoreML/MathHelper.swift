//
//  MathHelper.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 2/23/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import Foundation

class MathHelper {
    /// Computes the value at the `i`-th of `by` evenly distributed points in the range from 0 to `end`.
    ///
    /// - Parameters:
    ///   - end: The right bound of the range.
    ///   - by: The number of points to distribute.
    ///   - i: The index to compute.
    /// - Returns: The value of the `i`-th point.
    public static func partition(end: Float, by: Float, i: Float) -> Float {
        precondition(by > 0)
        precondition(i < by)
        return end / (by + 1) * (i + 1)
//        let offset = end / (2 * by)
//        return (end * i) / by + offset
    }
}
