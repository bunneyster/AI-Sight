//
//  StreamingMainObjectAnnouncer.swift
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

// MARK: - StreamingMainObjectAnnouncer

/// Announces the main object observed in a frame of a video/depth capture stream.
public class StreamingMainObjectAnnouncer {
    // MARK: Lifecycle

    init(manager: CameraManager) {
        self.manager = manager

        manager.$captureMode.sink { [self] in
            if $0 == .snapshot {
                stop()
            }
        }.store(in: &cancellables)
    }

    // MARK: Public

    public func process(_ data: CapturedData) {
        let rawObjects = data.extractObjects(downsampleFactor: 4)
        let filteredObjects = objectFrequencyRecorder
            .filter(objects: rawObjects)
        let minPixels = Double(ModelDimensions.deepLabV3.size) * UserDefaults.standard
            .double(forKey: "minObjectSizePercentage")
        let mainObject = StreamingMainObjectAnnouncer.computeMainObject(
            objects: filteredObjects,
            minSize: Int(round(minPixels)),
            maxDepth: Float(UserDefaults.standard.double(forKey: .announcerMaxDepth)),
            modelDimensions: ModelDimensions.deepLabV3
        )
        Logger().debug("main object: \(String(describing: mainObject))")
        if StreamingMainObjectAnnouncer.mainObjectChanged(
            previous: lastMainObjectChange?.object,
            current: mainObject
        ) {
            if let mainObject = mainObject {
                let spokenName = StreamingMainObjectAnnouncer
                    .shouldAnnounceName(object: mainObject) ? labels[mainObject.id] : nil
                Speaker.shared.speak(
                    objectName: spokenName,
                    depth: mainObject.depth
                        .round(nearest: Float(
                            UserDefaults.standard.double(forKey: .announcerDepthInterval)
                        ))
                )
            }
            lastMainObjectChange = MainObjectChange(object: mainObject, time: Date())
        }
    }

    public func stop() {
        Speaker.shared.stop()
    }

    // MARK: Internal

    /// The amount of time, in seconds, following an announcement, during which subsequent
    /// announcements
    /// for the same object should omit the object's name.
    static let debouncePeriod = 5.0

    /// Configures how consistently an object must appear across multiple frames.
    let objectFrequencyRecorder = ObjectFrequencyRecorder(minFrequency: 4, frameCount: 6)
    /// The subscription for captured data streamed from the video/depth data publisher.
    var subscription: Subscription?
    var manager: CameraManager!
    var cancellables = Set<AnyCancellable>()

    /// Computes which of the given objects qualifies to be announced as the main object.
    ///
    /// - Parameters:
    ///   - objects: All the objects under consideration.
    ///   - minSize: The minimum number of pixels that the main object must have.
    ///   - maxDepth: The maximum depth that the main object may have.
    ///   - modelDimensions: The dimensions of the segmentation map.
    /// - Returns: The main object, if any.
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

    /// Whether the main object needs to be (re-)announced.
    ///
    /// - Parameters:
    ///   - previous: The previous main object.
    ///   - current: The current main object that may need to be announced.
    /// - Returns: Whether the objects have different IDs, or the same object's distance to the user
    /// has significantly changed.
    static func mainObjectChanged(previous: MLObject?, current: MLObject?) -> Bool {
        if let current = current {
            if let previous = previous {
                return current.id != previous.id || !current.depth.isWithinRange(
                    of: previous.depth,
                    nearest: Float(
                        UserDefaults.standard
                            .double(forKey: "announcerDepthInterval")
                    ),
                    tolerance: Float(
                        UserDefaults.standard
                            .double(forKey: "announcerDepthMargin")
                    )
                )
            } else {
                return true
            }
        } else {
            return previous != nil
        }
    }

    /// Whether to include the object's name in its announcement.
    ///
    /// - Parameters:
    ///   - object: The object under consideration.
    /// - Returns: Whether the object is new, or has not been announced in a while.
    static func shouldAnnounceName(object: MLObject) -> Bool {
        return object.id != lastMainObjectChange?.object?.id ||
            abs(lastMainObjectChange?.time.timeIntervalSinceNow ?? 0) > debouncePeriod
    }
}

// MARK: Subscriber

extension StreamingMainObjectAnnouncer: Subscriber {
    public typealias Input = CapturedData

    public typealias Failure = Never

    public func receive(_ input: CapturedData) -> Subscribers.Demand {
        process(input)
        return .unlimited
    }

    public func receive(completion _: Subscribers.Completion<Never>) {}

    public func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.unlimited)
    }
}

// MARK: Cancellable

extension StreamingMainObjectAnnouncer: Cancellable {
    public func cancel() {
        subscription?.cancel()
        Speaker.shared.stop()
    }
}

// MARK: - MainObjectChange

struct MainObjectChange {
    /// The current main object. May be `nil` if no main object is found.
    var object: MLObject?
    /// The time when this change occurred.
    var time: Date
}
