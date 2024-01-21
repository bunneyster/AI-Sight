//
//  Player.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 11/28/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import AVFoundation
import Foundation
import Vision

class SoundHelper {
    // MARK: Public

    /// Computes the vocalized attributes for a given object.
    ///
    /// - Parameters:
    ///   - k: The object ID.
    ///   - v: The number of segmentation map elements corresponding to the given object ID.
    ///   - x: A map of object ID to the sum of the x-coordinates of the corresponding segmentation
    /// map elements.
    ///   - y: A map of object ID to the sum of the y-coordinates of the corresponding segmentation
    /// map elements.
    ///   - row: The number of rows in the segmentation map.
    ///   - col: The number of columns in the segmentation map.
    /// - Returns: A tuple containing 4 elements: `obj`, the object name, `mult_val`, the pitch
    /// multiplier, `xValue`, the representative x-coordinate, and `sizes`, the size of the object
    /// relative to its containing image.
    public static func getObjectAndPitchMultiplier(
        k: Int,
        v: Int,
        x: [Int: Int],
        y: [Int: Int],
        row: Int,
        col: Int
    ) -> (obj: String, mult_val: Float, xValue: Double, sizes: Double) {
        let b: Int = x[k] ?? 0
        let c: Int = y[k] ?? 0
        let size = Double(v) / (Double(row) * Double(col))
        let multiplier = 0.7 + Float(1 - Double(c) / Double(v) / Double(row))
        let xValue = Double(b) / Double(v) / Double(col)

        return (labels[k], multiplier, xValue, size)
    }
}
