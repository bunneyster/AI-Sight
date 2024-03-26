//
//  StreamingProximitySensor.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 3/23/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import OSLog

// MARK: - StreamingProximitySensor

class StreamingProximitySensor {
    // MARK: Lifecycle

    init() {
        mixer.outputVolume = 1
        engine.attach(mixer)
        engine.connect(
            mixer,
            to: engine.mainMixerNode,
            format: engine.mainMixerNode.inputFormat(forBus: 0)
        )
        for player in players {
            player.volume = 1
            engine.attach(player)
            engine.connect(player, to: mixer, format: engine.mainMixerNode.inputFormat(forBus: 0))
        }
    }

    // MARK: Public

    public func start() {
        engine.prepare()
        do {
            try engine.start()
        } catch {
            Logger().error("Could not start engine: \(error)")
        }
        isRunning = true
    }

    public func stop() {
        isRunning = false
    }

    // MARK: Internal

    let objectCategoryIds = [
        "None": [],
        "People": [15],
        "Vehicles": [1, 2, 4, 6, 7, 14, 19],
        "Seating": [9, 18],
        "Animals": [3, 8, 10, 12, 13, 17],
    ]
    let objectCategoryTimbres = [
        "People": "piano",
        "Vehicles": "trumpet",
        "Seating": "breath",
        "Animals": "cat",
    ]
    let depthToFilePitch = [
        1: "1",
        2: "4",
        3: "7",
        4: "10",
    ]
    let depthToBPS = [
        1: 8.0,
        2: 4.0,
        3: 2.0,
        4: 1.0,
    ]
    let engine = AVAudioEngine()
    let mixer = AVAudioMixerNode()
    let players = (0..<8).map { _ in AVAudioPlayerNode() }
    var isRunning = false
    var nextPlayerIndex = 0
    /// The subscription for captured data streamed from the video/depth data publisher.
    var subscription: Subscription?
    /// The original captured data object received from the data publisher.
    var sourceData: CapturedData?
    var lastFileName: String?
    var lastBPS: Double?
    var pan: Float?
    var timer: Timer?

    func processFrame() {
        let copyData = sourceData
        let objects = copyData?.extractObjects() ?? [MLObject]()
        guard let objectCategory = UserDefaults.standard.string(forKey: "objectProximity") else {
            fatalError()
        }
        let closestSelectedObject = objects
            .filter { objectCategoryIds[objectCategory]!.contains($0.id) }
            .min { a, b in a.depth < b.depth }
        Logger().debug("closest object: \(String(describing: closestSelectedObject))")
        if let object = closestSelectedObject,
           let fileName = getFileName(object: object, category: objectCategory),
           let bps = depthToBPS[Int(ceil(object.depth))]
        {
            pan = Float(object.center.x) * 2 / 513 - 1
            if bps != lastBPS || fileName != lastFileName {
                lastBPS = bps
                lastFileName = fileName
                timer?.invalidate()
                DispatchQueue.main.async { [self] in
                    if isRunning {
                        scheduleBeats(bps: bps, fileName: fileName)
                    } else {
                        for player in players {
                            player.stop()
                            player.reset()
                        }
                        engine.stop()
                    }
                }
            }
        } else {
            lastBPS = nil
            lastFileName = nil
            timer?.invalidate()
            for player in players {
                player.stop()
            }
        }
    }

    func getFileName(object: MLObject, category: String) -> String? {
        guard let timbre = objectCategoryTimbres[category] else { return nil }
        guard let pitch = depthToFilePitch[Int(ceil(object.depth))] else { return nil }
        return pitch + timbre
    }

    func scheduleBeats(bps: Double, fileName: String) {
        timer = Timer.scheduledTimer(withTimeInterval: 1 / bps, repeats: true) { [self] _ in
            let file = try! AVAudioFile(forReading: Bundle.main.url(
                forResource: fileName,
                withExtension: "wav"
            )!)
            let player = players[nextPlayerIndex]
            player.scheduleFile(file, at: nil)
            player.pan = pan!
            player.play()
            Logger().debug("\(fileName).wav, bps = \(bps), pan = \(player.pan)")
            nextPlayerIndex = (nextPlayerIndex + 1) % players.count
        }
    }
}

// MARK: Subscriber

extension StreamingProximitySensor: Subscriber {
    typealias Input = CapturedData

    typealias Failure = Never

    func receive(_ input: CapturedData) -> Subscribers.Demand {
        sourceData = input
        processFrame()
        return .unlimited
    }

    func receive(completion _: Subscribers.Completion<Never>) {}

    func receive(subscription: any Subscription) {
        self.subscription = subscription
        subscription.request(.unlimited)
        start()
    }
}

// MARK: Cancellable

extension StreamingProximitySensor: Cancellable {
    public func cancel() {
        subscription?.cancel()
        stop()
    }
}
