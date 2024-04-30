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

// MARK: - StreamingMainObjectAnnouncer

/// Announces the main object observed in a frame of a video/depth capture stream.
public class StreamingMainObjectAnnouncer {
    // MARK: Lifecycle

    init(manager: CameraManager) {
        self.manager = manager

        manager.$captureMode.sink { [self] in
            if $0 != .streaming {
                stop()
            }
        }.store(in: &cancellables)
    }

    // MARK: Public

    public func process(_ data: CapturedData) {
        let rawObjects = data.extractObjects(downsampleFactor: 4)
        Logger()
            .debug(
                "raw objects: \n\(rawObjects.map { String(describing: $0) }.joined(separator: ",\n"))"
            )
        let minPixels = Double(ModelDimensions.deepLabV3.size) * UserDefaults.standard
            .double(forKey: "minObjectSizePercentage")
        let filteredObjects = rawObjects
            .filter {
                ($0.size > Int(round(minPixels))) &&
                    ($0.depth < Float(UserDefaults.standard.double(forKey: .announcerMaxDepth)))
            }
        let mainObject = StreamingMainObjectAnnouncer.computeMainObject(objects: filteredObjects)
        objectFrequencyRecorder.add(object: mainObject)
        if StreamingMainObjectAnnouncer.mainObjectChanged(
            previous: lastMainObjectChange?.object,
            current: mainObject
        ), objectFrequencyRecorder.isFrequent(object: mainObject) {
            if let mainObject = mainObject {
                let spokenName = shouldAnnounceName(object: mainObject) ? labels[mainObject.id] :
                    nil
                Speaker.shared.speak(
                    objectName: spokenName,
                    depth: mainObject.depth
                        .round(nearest: Float(
                            UserDefaults.standard.double(forKey: .announcerDepthInterval)
                        ))
                )
                Logger().debug("main object: \(String(describing: mainObject)) <- Announced")
            }
            lastMainObjectChange = MainObjectChange(object: mainObject, time: Date())
        } else {
            let frequency = objectFrequencyRecorder.frequency(object: mainObject)
            Logger()
                .debug(
                    "main object: \(String(describing: mainObject)), freq=\(frequency)"
                )
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
    /// The last stable main object change to be recorded.
    var lastMainObjectChange: MainObjectChange?
    /// The subscription for captured data streamed from the video/depth data publisher.
    var subscription: Subscription?
    var manager: CameraManager!
    var cancellables = Set<AnyCancellable>()

    /// Computes which of the given objects qualifies to be announced as the main object.
    ///
    /// - Parameters:
    ///   - objects: All the objects under consideration.
    /// - Returns: The main object, if any.
    static func computeMainObject(objects: [MLObject]) -> MLObject? {
        if objects.isEmpty {
            return nil
        } else {
            let modelDimensions = ModelDimensions.deepLabV3
            let object = objects
                .max { a, b in
                    a.relevanceScore(modelDimensions: modelDimensions) <
                        b.relevanceScore(modelDimensions: modelDimensions)
                }
            guard let object = object else { return nil }
            return object
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
    func shouldAnnounceName(object: MLObject) -> Bool {
        return object.id != lastMainObjectChange?.object?.id ||
            abs(lastMainObjectChange?.time.timeIntervalSinceNow ?? 0) > StreamingMainObjectAnnouncer
            .debouncePeriod
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
        lastMainObjectChange = MainObjectChange(object: nil, time: Date())
    }
}

// MARK: - MainObjectChange

struct MainObjectChange {
    /// The current main object. May be `nil` if no main object is found.
    var object: MLObject?
    /// The time when this change occurred.
    var time: Date
}
