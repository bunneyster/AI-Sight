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

    static func processSegmentationMap(segmentationMap: MLMultiArray)
        -> ([String], [Float], [Double], [Double])
    {
        var objs = [String]()
        var mults = [Float]()
        var x_vals = [Double]()
        var objSizes = [Double]()

        guard let row = segmentationMap.shape[0] as? Int,
              let col = segmentationMap.shape[1] as? Int
        else {
            return (objs, mults, x_vals, objSizes)
        }

        let imageFrameCoordinates = MLMultiArrayHelper.getImageFrameCoordinates(
            segmentationmap: segmentationMap,
            row: row,
            col: col
        )

        let o = imageFrameCoordinates.o
        let x = imageFrameCoordinates.x
        let y = imageFrameCoordinates.y

        for (k, v) in o {
            if k == 0 {
                continue
            }

            let objectAndPitchMultiplier = SoundHelper.getObjectAndPitchMultiplier(
                k: k,
                v: v,
                x: x,
                y: y,
                row: row,
                col: col
            )
            let obj = objectAndPitchMultiplier.obj
            let mult_val = objectAndPitchMultiplier.mult_val
            let x_val = objectAndPitchMultiplier.xValue
            let objSize = objectAndPitchMultiplier.sizes

            objs.append(obj)
            mults.append(mult_val)
            x_vals.append(x_val)
            objSizes.append(objSize)
        }

        return (objs, mults, x_vals, objSizes)
    }

    func receive(_ input: CapturedData) -> Subscribers.Demand {
        usleep(1_500_000)

        var objs = [String]()
        var mults = [Float]()
        var x_vals = [Double]()
        var objSizes = [Double]()
        (objs, mults, x_vals, objSizes) = SnapshotSpeechCompletionHandler
            .processSegmentationMap(segmentationMap: input.segmentationMap)

        if objs.isEmpty {
            Speaker.shared.speak(text: "No Objects Identified")
        } else {
            let ignoredObjects: Set = ["aeroplane", "sheep", "cow", "horse"]
            let sorted = x_vals.enumerated().sorted(by: { $0.element < $1.element })
            for (i, _) in sorted {
                let obj = objs[i]
                if ignoredObjects.contains(obj) {
                    continue
                }
                if obj != "bottle", objSizes[i] <= 0.02 {
                    continue
                }
                let mult = mults[i]
                let x_value = x_vals[i]
                Speaker.shared.speak(
                    objectName: obj,
                    multiplier: mult,
                    posValue: x_value
                )
                print("The mult value is \(mult)")
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
