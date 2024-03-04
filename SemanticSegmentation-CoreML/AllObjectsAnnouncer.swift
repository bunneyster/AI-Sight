//
//  AllObjectsAnnouncer.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 12/21/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import Vision

/// Announces all the objects observed in a frame, ordered by position.
class AllObjectsAnnouncer {
    let ignoredObjects: Set = ["aeroplane", "sheep", "cow", "horse"]

    /// Announces all the objects enumerated in the given data.
    ///
    /// - Parameters:
    ///   - data: The `CapturedData` collected from a video/depth frame.
    func process(_ data: CapturedData) {
        usleep(1_500_000)

        let objects = data.extractObjects().sorted(by: { $0.center < $1.center })
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
                    depth: object.depth.round(nearest: 0.1),
                    interrupt: false
                )
            }
        }

        usleep(1_000_000)
    }
}
