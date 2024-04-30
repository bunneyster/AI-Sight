//
//  ObjectTracker.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 12/5/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import Foundation

/// Records the object sightings in the most recent frames.
class ObjectFrequencyRecorder {
    // MARK: Lifecycle

    init(minFrequency: Int, frameCount: Int) {
        precondition(minFrequency <= frameCount)
        self.minFrequency = minFrequency
        self.frameCount = frameCount
    }

    // MARK: Public

    public func add(object: MLObject?) {
        objects.append(object?.id)
        frequencies[object?.id, default: 0] += 1
        while objects.count > frameCount {
            frequencies[objects.removeFirst()]! -= 1
        }
    }

    public func isFrequent(object: MLObject?) -> Bool {
        return frequency(object: object) >= minFrequency
    }

    public func frequency(object: MLObject?) -> Int {
        return frequencies[object?.id, default: 0]
    }

    // MARK: Internal

    /// The number of frames to keep in the recorder's history.
    var frameCount: Int
    /// The minimum number of frames in which an object must be present.
    var minFrequency: Int
    /// A map of object ID to the number of times that object appeared in the tracked frames.
    var frequencies = [Int?: Int]()
    /// Chronologically ordered list of objects.
    var objects = [Int?]()
}
