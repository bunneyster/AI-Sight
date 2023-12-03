//
//  Float+Extensions.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 11/21/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import Foundation

extension Float {
    func round(nearest: Float) -> Float {
        return (self / nearest).rounded() * nearest
    }

    /// Whether this value is within the range established by a baseline number's rounded value.
    ///
    /// - Parameters:
    ///   - baseline: The number whose rounded value defines the range of acceptable values.
    ///   - nearest: The baseline number is rounded to the nearest multiple of this number.
    ///   - tolerance: The amount that this value may stray from the initially acceptable range of
    /// values.
    func isWithinRange(of baseline: Float, nearest: Float, tolerance: Float) -> Bool {
        let baselineRounded = baseline.round(nearest: nearest)
        let maxOffset = nearest / 2 + tolerance
        return (self >= baselineRounded - maxOffset) && (self < baselineRounded + maxOffset)
    }
}
