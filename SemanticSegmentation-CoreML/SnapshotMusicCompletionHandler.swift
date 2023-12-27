//
//  SnapshotMusicCompletionHandler.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 12/21/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import Vision

class SnapshotMusicCompletionHandler: Subscriber {
    typealias Input = CapturedData

    typealias Failure = Never

    func receive(_ input: CapturedData) -> Subscribers.Demand {
        var melody: [Note] = []

        for column in 0..<10 {
            let pan = -0.9 + Float(column) * 0.2 // [-0.9, 0.9] in increments of 0.2
            let fileDrums = try! AVAudioFile(
                forReading: Bundle.main.url(forResource: "drum", withExtension: "wav")!
            )
            melody.append(Note(file: fileDrums, pan: pan, volume: 0.5))

            for row in 0..<10 {
                let pixelIndex = snapshotMusicModePixelOffsets[row] + column * columnWidth
                let objectId = Int(truncating: input.segmentationMap[pixelIndex])
                let fileName = [String(row + 1), objectIdToSound[objectId]]
                    .compactMap { $0 }
                    .joined()
                let file = try! AVAudioFile(
                    forReading: Bundle.main.url(
                        forResource: fileName,
                        withExtension: "wav"
                    )!
                )
                melody.append(Note(
                    file: file,
                    pan: pan,
                    volume: Float(objectId >= 1 ? 1.0 : 0.0)
                ))
            }

            let engine = AVAudioEngine()
            for note in melody {
                engine.attach(note.node)
                engine.connect(
                    note.node,
                    to: engine.mainMixerNode,
                    format: note.file.processingFormat
                )
                note.node.scheduleFile(note.file, at: nil, completionHandler: nil)
            }

            engine.prepare()
            try! engine.start()

            for note in melody {
                note.node.play()
                usleep(1000)
            }

            melody = []
            usleep(500_000)
        }

        return .unlimited
    }

    func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }

    func receive(completion _: Subscribers.Completion<Never>) {}
}
