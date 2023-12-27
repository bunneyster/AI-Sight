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

/// The main object that was last announced.
///
/// The value may be `nil` when no objects were identified (background does not count).
var lastMainObject: MLObject?

// MARK: - StreamingCompletionHandler

public class StreamingCompletionHandler: Subscriber {
    // MARK: Public

    public typealias Input = CapturedData

    public typealias Failure = Never

    public func receive(_ input: CapturedData) -> Subscribers.Demand {
        if liveViewVerbalModeActive == 1 {
            let rawObjects = input.extractObjects()
            Logger()
                .debug("raw:\n\(rawObjects.map { "\($0)" }.joined(separator: "\n"))")
            let filteredObjects = objectFrequencyRecorder
                .filter(objects: rawObjects)
            Logger()
                .debug(
                    "filtered:\n\(filteredObjects.map { "\($0)" }.joined(separator: "\n"))"
                )
            let mainObject = StreamingCompletionHandler.computeMainObject(
                objects: filteredObjects,
                minSize: 13000,
                maxDepth: 5.0, // maximum range of iPhone LiDAR sensor is ~5 meters
                modelDimensions: ModelDimensions.deepLabV3
            )
            Logger().debug("main object: \(String(describing: mainObject))")
            if StreamingCompletionHandler.mainObjectChanged(
                previous: lastMainObject,
                current: mainObject
            ) {
                lastMainObject = mainObject
                if let mainObject = mainObject {
                    Speaker.shared.speak(
                        objectName: labels[mainObject.id],
                        depth: mainObject.depth.round(nearest: 0.5)
                    )
                }
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

    let objectFrequencyRecorder = ObjectFrequencyRecorder(frameCount: 3, minFrequency: 3)

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
}
