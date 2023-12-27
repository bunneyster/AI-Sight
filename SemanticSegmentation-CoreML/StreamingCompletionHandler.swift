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
            let depthBuffer = DepthHelper.getDepthMap(depthData: input.depthData)
            let rawObjects = StreamingCompletionHandler.processObjectData(
                videoBufferWidth: input.videoBufferWidth,
                videoBufferHeight: input.videoBufferHeight,
                segmentationMap: input.segmentationMap,
                depthBuffer: depthBuffer
            )
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

    static func processObjectData(
        videoBufferWidth: Int,
        videoBufferHeight: Int,
        segmentationMap: MLMultiArray,
        depthBuffer: CVPixelBuffer
    ) -> [MLObject] {
        var objects = [Int: MLObject]()

        guard let segmentationHeight = segmentationMap.shape[0] as? Int,
              let segmentationWidth = segmentationMap.shape[1] as? Int
        else {
            return Array(objects.values)
        }

        CVPixelBufferLockBaseAddress(depthBuffer, CVPixelBufferLockFlags(rawValue: 0))

        // Convert the base address to a safe pointer of the appropriate type
        let floatBuffer = unsafeBitCast(
            CVPixelBufferGetBaseAddress(depthBuffer),
            to: UnsafeMutablePointer<Float32>.self
        )
        let videoWidth = videoBufferWidth
        let videoHeight = videoBufferHeight
        let depthWidth = CVPixelBufferGetWidth(depthBuffer)
        let depthHeight = CVPixelBufferGetHeight(depthBuffer)
        let xOffset = (videoWidth - segmentationWidth) / 2
        let yOffset = (videoHeight - segmentationHeight) / 2
        let scaleX = videoWidth / depthWidth
        let scaleY = videoHeight / depthHeight

        for row in 0..<segmentationHeight {
            for col in 0..<segmentationWidth {
                let coords = [row, col] as [NSNumber]
                let id = segmentationMap[coords].intValue
                if id == 0 {
                    continue
                }

                let depthMapX = (col + xOffset) / scaleX
                let depthMapY = (row + yOffset) / scaleY
                let depthIndex = depthMapY * (segmentationWidth / scaleX) + depthMapX
                let depth = floatBuffer[Int(depthIndex)]
                if let object = objects[id] {
                    object.center.x += col
                    object.center.y += row
                    if depth > 0 {
                        object.depth = object.depth == 0 ? depth : min(object.depth, depth)
                    }
                    object.size += 1
                } else {
                    objects[id] = MLObject(
                        id: id,
                        center: IntPoint(x: row, y: col),
                        depth: depth,
                        size: 1
                    )
                }
            }
        }

        CVPixelBufferUnlockBaseAddress(depthBuffer, CVPixelBufferLockFlags(rawValue: 0))

        for (id, object) in objects {
            let size = object.size
            objects[id]?.center.x /= size
            objects[id]?.center.y /= size
        }

        return Array(objects.values)
    }

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
