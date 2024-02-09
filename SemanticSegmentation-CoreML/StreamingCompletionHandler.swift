//
//  StreamingCompletionHandler.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 12/21/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import OSLog
import Vision

/// The last change observed in the main object.
var lastMainObjectChange: MainObjectChange?
/// The amount of time, in seconds, following an announcement, during which subsequent announcements
/// for the same object should omit the object's name.
let debouncePeriod = 5.0

// MARK: - StreamingCompletionHandler

public class StreamingCompletionHandler: Subscriber {
    // MARK: Public

    public typealias Input = CapturedData

    public typealias Failure = Never

    public func receive(_ input: CapturedData) -> Subscribers.Demand {
        if liveViewVerbalModeActive == 1 {
            let rawObjects = input.extractObjects()
            let filteredObjects = objectFrequencyRecorder
                .filter(objects: rawObjects)
            let mainObject = StreamingCompletionHandler.computeMainObject(
                objects: filteredObjects,
                minSize: 13000,
                maxDepth: 5.0, // maximum range of iPhone LiDAR sensor is ~5 meters
                modelDimensions: ModelDimensions.deepLabV3
            )
            Logger().debug("main object: \(String(describing: mainObject))")
            if StreamingCompletionHandler.mainObjectChanged(
                previous: lastMainObjectChange?.object,
                current: mainObject
            ) {
                if let mainObject = mainObject {
                    let spokenName = StreamingCompletionHandler
                        .shouldAnnounceName(object: mainObject) ? labels[mainObject.id] : nil
                    Speaker.shared.speak(
                        objectName: spokenName,
                        depth: mainObject.depth.round(nearest: 0.5)
                    )
                }
                lastMainObjectChange = MainObjectChange(object: mainObject, time: Date())
            }
        }

        if liveViewModeActive == true {
            let depthPoints = DepthHelper.computeDepthPoints(depthData: input.depthData)
            let melody = SoundHelper.composeLiveMusic(
                segmentationMap: input.segmentationMap,
                depthPoints: depthPoints
            )

            SoundHelper.playMusic(melody: melody)
        }

        return .unlimited
    }

    public func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }

    public func receive(completion _: Subscribers.Completion<Never>) {}

    // MARK: Internal

    let objectFrequencyRecorder = ObjectFrequencyRecorder(minFrequency: 4, frameCount: 6)

    static func computeMainObject(
        objects: [MLObject],
        minSize: Int,
        maxDepth: Float,
        modelDimensions: ModelDimensions
    )
        -> MLObject?
    {
        if objects.isEmpty {
            return nil
        } else {
            let object = objects
                .max { a, b in
                    a.relevanceScore(modelDimensions: modelDimensions) <
                        b.relevanceScore(modelDimensions: modelDimensions)
                }
            guard let object = object else { return nil }
            if object.size >= minSize, object.depth <= maxDepth {
                return object
            } else {
                return nil
            }
        }
    }

    static func mainObjectChanged(previous: MLObject?, current: MLObject?) -> Bool {
        if let current = current {
            if let previous = previous {
                return current.id != previous.id || !current.depth.isWithinRange(
                    of: previous.depth,
                    nearest: 0.5,
                    tolerance: 0.2
                )
            } else {
                return true
            }
        } else {
            return previous != nil
        }
    }

    static func shouldAnnounceName(object: MLObject) -> Bool {
        return object.id != lastMainObjectChange?.object?.id ||
            abs(lastMainObjectChange?.time.timeIntervalSinceNow ?? 0) > debouncePeriod
    }
}

// MARK: - MainObjectChange

struct MainObjectChange {
    /// The current main object. May be `nil` if no main object is found.
    var object: MLObject?
    /// The time when this change occurred.
    var time: Date
}
