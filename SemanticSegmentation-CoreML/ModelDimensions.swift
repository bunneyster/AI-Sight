//
//  SegmentationResult.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 11/21/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import Foundation

/// The dimensions and related properties of the output of an ML model.
struct ModelDimensions {
    /// The output dimensions of a DeepLabV3 model.
    static let deepLabV3: ModelDimensions = .init(height: 513, width: 513)

    var height: Int
    var width: Int

    /// The x-coordinate of the center point.
    var centerY: Int {
        return height / 2
    }

    /// The y-coordinate of the center point.
    var centerX: Int {
        return width / 2
    }

    /// The square of the maximum distance of any point to the center point.
    var maxCenterDistanceSquared: Int {
        return centerY * centerY + centerX * centerX
    }

    /// The total number of pixels.
    var size: Int {
        return height * width
    }
}
