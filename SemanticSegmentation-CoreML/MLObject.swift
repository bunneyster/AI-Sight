//
//  ObjectData.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 11/21/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import Foundation

/// An object identified via an image processing ML model.
class MLObject {
    // MARK: Lifecycle

    init(id: Int, center: IntPoint, depth: Float, size: Int) {
        self.id = id
        self.center = center
        self.depth = depth
        self.size = size
    }

    // MARK: Internal

    /// The ID of the object's label.
    var id: Int
    /// The coordinates of the center of the object.
    var center: IntPoint
    /// The distance to the object, in meters.
    var depth: Float
    /// The number of pixels occupied by this object.
    var size: Int

    /// A score representing how central this object is within the context of the image.
    ///
    /// The factors that determine an object's score:
    ///   - proximity to the center of the frame (i.e. closer = higher score)
    ///   - the object's size (i.e. larger = higher score)
    func relevanceScore(modelDimensions: ModelDimensions) -> Float {
        let xDiff = modelDimensions.centerX - center.x
        let yDiff = modelDimensions.centerY - center.y
        let distanceSquared = xDiff * xDiff + yDiff * yDiff

        let normalizedDistance = 1 - Float(distanceSquared) /
            Float(modelDimensions.maxCenterDistanceSquared)
        let normalizedSize = Float(size) / Float(modelDimensions.size)

        return (normalizedDistance * 0.6) + (normalizedSize * 0.4)
    }
}
