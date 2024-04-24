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

    init(manager: CameraManager) {
        mixer.outputVolume = volume
        engine.attach(mixer)
        engine.connect(
            mixer,
            to: engine.mainMixerNode,
            format: engine.mainMixerNode.inputFormat(forBus: 0)
        )
        for player in players {
            player.volume = volume
            engine.attach(player)
            engine.connect(player, to: mixer, format: engine.mainMixerNode.inputFormat(forBus: 0))
        }

        self.manager = manager
        manager.$captureMode.sink { [self] in
            if $0 == .snapshot {
                self.isRunning = false
            } else {
                self.isRunning = true
            }
        }.store(in: &cancellables)
    }

    // MARK: Public

    public func refreshUserDefaults() {
        depthThreshold1 = UserDefaults.standard.float(forKey: "objectProximityThreshold1")
        depthThreshold2 = UserDefaults.standard.float(forKey: "objectProximityThreshold2")
        depthThreshold3 = UserDefaults.standard.float(forKey: "objectProximityThreshold3")
        depthThreshold4 = UserDefaults.standard.float(forKey: "objectProximityThreshold4")
    }

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

    let objectCategoryTimbres = [
        "People": "piano",
        "Vehicles": "trumpet",
        "Seating": "chair",
        "Animals": "cat",
        "Bottles": "bottle",
        "TVs": "breath",
        "Tables": "chair",
    ]
    var depthThreshold1: Float = UserDefaults.standard.float(forKey: "objectProximityThreshold1")
    var depthThreshold2: Float = UserDefaults.standard.float(forKey: "objectProximityThreshold2")
    var depthThreshold3: Float = UserDefaults.standard.float(forKey: "objectProximityThreshold3")
    var depthThreshold4: Float = UserDefaults.standard.float(forKey: "objectProximityThreshold4")
    let engine = AVAudioEngine()
    let mixer = AVAudioMixerNode()
    let players = (0..<8).map { _ in AVAudioPlayerNode() }
    let volume: Float = 0.5
    var isRunning = false
    var nextPlayerIndex = 0
    /// The subscription for captured data streamed from the video/depth data publisher.
    var subscription: Subscription?
    var manager: CameraManager!
    var cancellables = Set<AnyCancellable>()
    var lastFileName: String?
    var lastBPS: Double?
    var pan: Float?
    var timer: Timer?
    var fileCache = [String: AVAudioFile]()

    func processFrame(_ data: CapturedData) {
        let objects = data.extractObjects(downsampleFactor: 4)
        guard let objectCategory = UserDefaults.standard.string(forKey: "objectProximity") else {
            fatalError()
        }
        let closestSelectedObject = objects
            .filter { objectCategoryIds[objectCategory]!.contains($0.id) }
            .min { a, b in a.depth < b.depth }
        Logger().debug("closest object: \(String(describing: closestSelectedObject))")
        if let object = closestSelectedObject,
           let fileName = getFileName(object: object, category: objectCategory)
        {
            let bps = getBPS(depth: object.depth)
            pan = Float(object.center.x) * 2 / 513 - 1
            if bps != lastBPS || fileName != lastFileName {
                lastBPS = bps
                lastFileName = fileName
                timer?.invalidate()
                DispatchQueue.main.async { [self] in
                    scheduleBeats(bps: bps, fileName: fileName)
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
        guard let pitch = getPitch(depth: object.depth) else { return nil }
        return pitch + timbre
    }

    func getBPS(depth: Float) -> Double {
        if depth < depthThreshold1 {
            return 8
        } else if depth < depthThreshold2 {
            return 4
        } else if depth < depthThreshold3 {
            return 2
        } else if depth < depthThreshold4 {
            return 1
        } else {
            return 0.5
        }
    }

    func getPitch(depth: Float) -> String? {
        if depth < depthThreshold1 {
            return "1"
        } else if depth < depthThreshold2 {
            return "4"
        } else if depth < depthThreshold3 {
            return "7"
        } else {
            return "10"
        }
    }

    func scheduleBeats(bps: Double, fileName: String) {
        timer = Timer.scheduledTimer(withTimeInterval: 1 / bps, repeats: true) { [self] _ in
            if isRunning {
                let file = {
                    if fileCache[fileName] == nil {
                        fileCache[fileName] = try! AVAudioFile(forReading: Bundle.main.url(
                            forResource: fileName,
                            withExtension: "wav"
                        )!)
                    }
                    return fileCache[fileName]
                }()
                let player = players[nextPlayerIndex]
                player.scheduleFile(file!, at: nil)
                player.pan = pan!
                player.play()
                Logger().debug("\(fileName).wav, bps = \(bps), pan = \(player.pan)")
                nextPlayerIndex = (nextPlayerIndex + 1) % players.count
            } else {
                for player in players {
                    player.stop()
                    player.reset()
                }
                engine.stop()
            }
        }
    }
}

// MARK: Subscriber

extension StreamingProximitySensor: Subscriber {
    typealias Input = CapturedData

    typealias Failure = Never

    func receive(_ input: CapturedData) -> Subscribers.Demand {
        processFrame(input)
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
