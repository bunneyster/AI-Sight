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
        self.frequencies = [Int: Int]()
        self.frames = [[Int]]()
    }

    // MARK: Public

    /// Adds the given frame objects to the recorder's history and returns a copy that excludes
    /// infrequently seen objects.
    ///
    /// - Parameters:
    ///   - objects: The complete list of objects identified in the latest frame.
    /// - Returns: The subset of objects that appeared at least `minFrequency` times in the last
    /// `frameCount` frames.
    public func filter(objects: [MLObject]) -> [MLObject] {
        while frames.count > frameCount {
            frames.removeFirst().forEach { id in
                frequencies[id]! -= 1
            }
        }
        frames.append(objects.map { $0.id })

        var result = [MLObject]()
        objects.forEach { object in
            frequencies[object.id, default: 0] += 1
            if let frequency = frequencies[object.id], frequency >= minFrequency {
                result.append(object)
            }
        }
        return result
    }

    // MARK: Internal

    /// The number of frames to keep in the recorder's history.
    var frameCount: Int
    /// The minimum number of frames in which an object must be present.
    var minFrequency: Int
    /// The list of frames, from oldest to newest, each containing the IDs of the objects in that
    /// frame.
    var frames: [[Int]]
    /// A map of object ID to the number of times that object appeared in the tracked frames.
    var frequencies: [Int: Int]
}
