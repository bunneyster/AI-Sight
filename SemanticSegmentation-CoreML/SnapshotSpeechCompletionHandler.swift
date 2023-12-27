//
//  SnapshotSpeechCompletionHandler.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 12/21/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import Vision

class SnapshotSpeechCompletionHandler: Subscriber {
    typealias Input = CapturedData

    typealias Failure = Never

    let ignoredObjects: Set = ["aeroplane", "sheep", "cow", "horse"]

    func receive(_ input: CapturedData) -> Subscribers.Demand {
        usleep(1_500_000)

        let objects = input.extractObjects().sorted(by: { $0.center < $1.center })
            .filter { !ignoredObjects.contains(labels[$0.id]) }
        if objects.isEmpty {
            Speaker.shared.speak(text: "No objects identified")
        } else {
            for object in objects {
                if labels[object.id] != "bottle", object.size <= 5300 {
                    continue
                }
                let vertical = Float(object.center.y) / Float(ModelDimensions.deepLabV3.height)
                let horizontal = Float(object.center.x) / Float(ModelDimensions.deepLabV3.width)
                Speaker.shared.speak(
                    objectName: labels[object.id],
                    verticalPosition: vertical,
                    horizontalPosition: horizontal,
                    depth: object.depth.round(nearest: 0.5),
                    interrupt: false
                )
            }
        }

        usleep(1_000_000)

        return .unlimited
    }

    func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }

    func receive(completion _: Subscribers.Completion<Never>) {}
}
