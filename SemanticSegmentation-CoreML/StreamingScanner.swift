//
//  StreamingScanner.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 2/20/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import OSLog

// MARK: - StreamingScanner

/// Horizontally scans a frame and plays a combination of pure tones for each vertical slice.
///
/// Like the vOICe, the scanner continuously moves left and right. When a new frame is received, the
/// scanner picks up where it left off in the previous frame, such that the capture stream always
/// sounds seamless. For each vertical slice, a subset of evenly distributed pixels are selected and
/// a tone is played for each pixel; the depth controls the volume and the vertical position
/// controls the pitch.
public class StreamingScanner {
    // MARK: Lifecycle

    init() {
        let inputFormat = engine.outputNode.inputFormat(forBus: 0)
        self.sampleRate = Float(inputFormat.sampleRate)
        let scale = SoundHelper.buildMajorPentatonicScale(
            fundamental: pythagoreanFrequencies[.g3]!,
            count: Int(numRows)
        )
        for row in 0..<Int(numRows) {
            let node = buildSourceNode(frequency: scale[row])
            node.volume = 0
            sourceNodes.append(node)
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: inputFormat)
        }
        self.leftTapPlayer = buildPlayer(forResource: "beat0")
        self.rightTapPlayer = buildPlayer(forResource: "beat1")
        leftTapPlayer.prepareToPlay()
        rightTapPlayer.prepareToPlay()
    }

    // MARK: Public

    /// Starts scanning the current frame, if available.
    public func start() {
        do {
            try engine.start()
        } catch {
            Logger().error("Could not start engine: \(error)")
        }

        isRunning = true
        var column = -1
        var step = 1
        Timer.scheduledTimer(withTimeInterval: beatDuration, repeats: true) { [self] timer in
            if isRunning {
                if column == Int(numColumns) {
                    tap(player: rightTapPlayer, pan: 1)
                    step = -1
                } else if column < 0 {
                    tap(player: leftTapPlayer, pan: -1)
                    step = 1
                } else {
                    play(column: column)
                }
                column += step
            } else {
                engine.stop()
                timer.invalidate()
            }
        }
    }

    /// Plays the pure tones corresponding to the vertical slice at the given index in the frame.
    public func play(column: Int) {
        let copyData = sourceData
        let xCoord = Int(MathHelper.partition(end: 513, by: numColumns, i: Float(column)))
        let pan = MathHelper.partition(end: 2, by: numColumns, i: Float(column)) - 1

        guard let segmentationHeight = copyData?.segmentationMap.shape[0] as? Int,
              let segmentationWidth = copyData?.segmentationMap.shape[1] as? Int
        else {
            return
        }

        let depthData = (copyData?.depthData)!
        let depthBuffer = DepthHelper.getDepthMap(depthData: depthData)
        CVPixelBufferLockBaseAddress(depthBuffer, .readOnly)
        let floatBuffer = unsafeBitCast(
            CVPixelBufferGetBaseAddress(depthBuffer),
            to: UnsafeMutablePointer<Float32>.self
        )
        CVPixelBufferUnlockBaseAddress(depthBuffer, .readOnly)

        let videoWidth = (copyData?.videoBufferWidth)!
        let videoHeight = (copyData?.videoBufferHeight)!
        let depthWidth = CVPixelBufferGetWidth(depthBuffer)
        let depthHeight = CVPixelBufferGetHeight(depthBuffer)
        let videoXOffset = (videoWidth - segmentationWidth) / 2
        let videoYOffset = (videoHeight - segmentationHeight) / 2
        let scaleX = Float(videoWidth) / Float(depthWidth)
        let scaleY = Float(videoHeight) / Float(depthHeight)

        for (row, node) in sourceNodes.reversed().enumerated() {
            let yCoord = Int(MathHelper.partition(end: 513, by: numRows, i: Float(row)))
            let coords = [yCoord, xCoord] as [NSNumber]
            let id = copyData?.segmentationMap[coords].intValue ?? 0

            let depthMapX = Float(xCoord + videoXOffset) / scaleX
            let depthMapY = Float(yCoord + videoYOffset) / scaleY
            let depthIndex = depthMapY * Float(depthWidth) + depthMapX
            let depth = floatBuffer[Int(depthIndex)]

            if depth > 0 {
                node.volume = computeVolume(id: id, depth: depth)
            }
            node.pan = pan
            Logger()
                .debug(
                    "[\(xCoord), \(yCoord)]: id=\(id), depth=\(depth), volume=\(node.volume), pan=\(pan)"
                )
        }
    }

    public func tap(player: AVAudioPlayer, pan: Float) {
        for node in sourceNodes {
            node.volume = minVolume
        }
        player.pan = pan
        player.volume = tapVolume
        player.play()
    }

    public func stop() {
        isRunning = false
    }

    // MARK: Internal

    /// The number of vertical slices to process.
    let numColumns: Float = 20
    /// The number of data points / pure tones to consider in each vertical slice.
    let numRows: Float = 20
    /// The audio engine running all of the pure tones.
    let engine = AVAudioEngine()
    /// How long to play a single vertical slice, in seconds.
    let beatDuration = 0.075
    /// The volume of the left/right taps.
    let tapVolume: Float = 0.7
    /// The maximum volume of a pure tone.
    let maxVolume: Float = 0.12
    /// The minimum volume of a pure tone.
    let minVolume: Float = 0.0005
    /// The steepness of the distance-volume curve (lower = steeper, higher = flatter).
    let volumeCurve: Float = 0.1

    /// The subscription for captured data streamed from the video/depth data publisher.
    var subscription: Subscription?
    /// The original captured data object received from the data publisher.
    var sourceData: CapturedData?
    /// The sample rate of the pure tones.
    var sampleRate: Float
    /// The pure tone audio nodes, from high pitch (frame top) to low pitch (frame bottom).
    var sourceNodes = [AVAudioSourceNode]()
    /// The audio player that plays the tap sound when the scanner reaches the left of the frame.
    var leftTapPlayer: AVAudioPlayer!
    /// The audio player that plays the tap sound when the scanner reaches the right of the frame.
    var rightTapPlayer: AVAudioPlayer!
    /// Whether the scanner should be running.
    var isRunning = false

    func computeVolume(id: Int, depth: Float) -> Float {
        let volume = (minVolume * depth + maxVolume * volumeCurve) / (depth + volumeCurve)
        return id > 0 ? volume : 0
    }

    /// Builds an audio node that plays a sine wave signal at the given frequency.
    func buildSourceNode(frequency: Double) -> AVAudioSourceNode {
        var phase: Double = 0
        let phaseIncrement = (2 * Double.pi / Double(sampleRate)) * frequency
        return AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let value = sin(phase)
                phase += phaseIncrement
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = Float(value)
                }
            }
            return noErr
        }
    }

    /// Builds an audio player that plays the WAV file with the given name.
    func buildPlayer(forResource: String) -> AVAudioPlayer {
        do {
            let url = Bundle.main.url(forResource: forResource, withExtension: "wav")
            return try AVAudioPlayer(contentsOf: url!)
        } catch {
            Logger().error("Failed to load audio file: \(error)")
            return AVAudioPlayer()
        }
    }
}

// MARK: Subscriber

extension StreamingScanner: Subscriber {
    public typealias Input = CapturedData

    public typealias Failure = Never

    public func receive(_ input: CapturedData) -> Subscribers.Demand {
        sourceData = input
        return .unlimited
    }

    public func receive(completion _: Subscribers.Completion<Never>) {}

    public func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.unlimited)
        start()
    }
}

// MARK: Cancellable

extension StreamingScanner: Cancellable {
    public func cancel() {
        subscription?.cancel()
        stop()
    }
}
