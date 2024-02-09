//
//  ObjectData.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 11/21/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import Foundation

// MARK: - MLObject

// An object identified via an image processing ML model.
public class MLObject {
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
    /// The score representing how central this object is within the context of a DeepLabV3
    /// segmentation map.
    lazy var relevanceScore = relevanceScore(modelDimensions: ModelDimensions.deepLabV3)

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
        let curvedSize = exp(-pow(normalizedSize - 0.4, 2) / (2 * pow(0.3, 2)))

        return normalizedDistance * curvedSize
    }
}

// MARK: CustomStringConvertible

extension MLObject: CustomStringConvertible {
    public var description: String {
        return "MLObject(id: \(id), center: \(center), depth: \(depth), size: \(size), relevanceScore: \(relevanceScore)"
    }
}

// MARK: Equatable

extension MLObject: Equatable {
    public static func == (lhs: MLObject, rhs: MLObject) -> Bool {
        return
            lhs.id == rhs.id &&
            lhs.center == rhs.center &&
            lhs.depth == rhs.depth &&
            lhs.size == rhs.size
    }
}
