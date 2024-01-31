//
//  Scanner.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 1/23/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import OSLog

public class Scanner: Subscriber {
    // MARK: Lifecycle

    init(modelDimensions: ModelDimensions = .deepLabV3) {
        self.height = modelDimensions.height
        self.width = modelDimensions.width
        
        let format = engine.mainMixerNode.inputFormat(forBus: 0)
        self.sampleRate = Float(format.sampleRate)
        self.frameCount = AVAudioFrameCount(duration * sampleRate)
        for i in 0...1 {
            buffers.append(AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: frameCount
            ))
            buffers[i]?.frameLength = frameCount
        }

        engine.attach(player)
        engine.connect(
            player,
            to: engine.mainMixerNode,
            format: engine.mainMixerNode.inputFormat(forBus: 0)
        )
    }

    // MARK: Public

    public typealias Input = CapturedData

    public typealias Failure = Never

    public func receive(_ input: CapturedData) -> Subscribers.Demand {
        data = input
        return .unlimited
    }

    public func receive(completion _: Subscribers.Completion<Never>) {}

    public func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }

    public func start() {
        do {
            try engine.start()
            direction = .right
            scheduleBuffer(bufferIndex: 0, columnIndex: 0)
            player.play()
        } catch {
            print("Could not start engine: \(error)")
        }
    }

    public func stop() {
        player.stop()
        player.reset()
        engine.stop()
    }

    // MARK: Internal

    let twoPi = 2 * Float.pi

    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()

    /// Frequency range 20 ~ 10240 (20 * 512)
    let frequency: Float = 20
    let amplitude: Float = 0.5
    let duration: Float = 0.002

    var buffers = [AVAudioPCMBuffer?]()
    var sampleRate: Float
    var frameCount: AVAudioFrameCount
    var height: Int
    var width: Int
    var direction: Direction = .right

    var data: CapturedData?

    func scheduleBuffer(bufferIndex: Int, columnIndex: Int) {
//        Logger().debug("schedule buffer for column \(columnIndex)")
        let buffer = buffers[bufferIndex]
        let phaseStep = twoPi * frequency / sampleRate
        var bufferPtr = buffer?.floatChannelData?[0]
        for frame in 0..<frameCount {
            let phase = fmodf(Float(frame) * phaseStep, twoPi)
            let value = signal(phase: phase, columnIndex: columnIndex)
            bufferPtr?.pointee = value
            bufferPtr = bufferPtr?.successor()
        }
        player.scheduleBuffer(buffer!) { [self] in
            var nextColumnIndex: Int
            if direction == .left {
                if columnIndex == 0 {
                    usleep(250_000)
                    nextColumnIndex = columnIndex
                    direction = .right
                } else {
                    nextColumnIndex = columnIndex - 1
                }
            } else {
                if columnIndex == width - 1 {
                    usleep(250_000)
                    nextColumnIndex = columnIndex
                    direction = .left
                } else {
                    nextColumnIndex = columnIndex + 1
                }
            }
            scheduleBuffer(bufferIndex: abs(bufferIndex - 1), columnIndex: nextColumnIndex)
        }
    }

    func signal(phase: Float, columnIndex: Int) -> Float {
        var sum: Float = 0
//        sum += sin(Float(columnIndex) * phase)
        for row in 0..<height {
            let coords = [row, columnIndex] as [NSNumber]
            if let id = data?.segmentationMap[coords].intValue, id > 0 {
                sum += sin(Float(row + 1) * phase)
//                Logger().debug("(\(row), \(columnIndex)), sum: \(sum)")
            }
        }
        return sum * amplitude
    }
    
    enum Direction {
        case right
        case left
    }

//    func buildAudioSourceNode() {
//        let mainMixer = engine.mainMixerNode
//        let output = engine.outputNode
//        let outputFormat = output.inputFormat(forBus: 0)
//        let sampleRate = Float(outputFormat.sampleRate)
//        let inputFormat = AVAudioFormat(
//            commonFormat: outputFormat.commonFormat,
//            sampleRate: outputFormat.sampleRate,
//            channels: 1,
//            interleaved: outputFormat.isInterleaved
//        )
//
//        let phaseIncrement = (twoPi / sampleRate) * frequency
//        let srcNode = AVAudioSourceNode { [self] _, _, frameCount, audioBufferList -> OSStatus in
//            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
//            for frame in 0..<Int(frameCount) {
//                let v1 = sine(currentPhase)
//                let v2 = sine(2 * currentPhase)
//                let v3 = sine(3 * currentPhase)
//                let v4 = sine(4 * currentPhase)
//                let v5 = sine(5 * currentPhase)
//                let value = (v1 + v2 + v3 + v4 + v5) * amplitude
//                currentPhase += phaseIncrement
//                if currentPhase >= twoPi {
//                    currentPhase -= twoPi
//                }
//                if currentPhase < 0.0 {
//                    currentPhase += twoPi
//                }
//                for buffer in ablPointer {
//                    let buf: UnsafeMutableBufferPointer<Float> =
//                    UnsafeMutableBufferPointer(buffer)
//                    buf[frame] = value
//                }
//            }
//            return noErr
//        }
//
//        engine.attach(srcNode)
//        engine.connect(srcNode, to: mainMixer, format: inputFormat)
//        engine.connect(mainMixer, to: output, format: outputFormat)
//        mainMixer.outputVolume = 0.5
//    }
}
