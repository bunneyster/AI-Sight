//
//  Player.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 11/28/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import AVFoundation
import Foundation
import OSLog
import Vision

class SoundHelper {
    // MARK: Public

    /// Computes the vocalized attributes for a given object.
    ///
    /// - Parameters:
    ///   - k: The object ID.
    ///   - v: The number of segmentation map elements corresponding to the given object ID.
    ///   - x: A map of object ID to the sum of the x-coordinates of the corresponding segmentation
    /// map elements.
    ///   - y: A map of object ID to the sum of the y-coordinates of the corresponding segmentation
    /// map elements.
    ///   - row: The number of rows in the segmentation map.
    ///   - col: The number of columns in the segmentation map.
    /// - Returns: A tuple containing 4 elements: `obj`, the object name, `mult_val`, the pitch
    /// multiplier, `xValue`, the representative x-coordinate, and `sizes`, the size of the object
    /// relative to its containing image.
    public static func getObjectAndPitchMultiplier(
        k: Int,
        v: Int,
        x: [Int: Int],
        y: [Int: Int],
        row: Int,
        col: Int
    ) -> (obj: String, mult_val: Float, xValue: Double, sizes: Double) {
        let b: Int = x[k] ?? 0
        let c: Int = y[k] ?? 0
        let size = Double(v) / (Double(row) * Double(col))
        let multiplier = 0.7 + Float(1 - Double(c) / Double(v) / Double(row))
        let xValue = Double(b) / Double(v) / Double(col)

        return (labels[k], multiplier, xValue, size)
    }

    /// Generates the frequencies comprising a major pentatonic scale starting from the given pitch.
    ///
    /// - Parameters:
    ///   - fundamental: The base pitch that determines the key of the scale.
    ///   - count: The number of tones to generate.
    /// - Returns: The list of frequencies corresponding to the requested pentatonic scale, in
    /// increasing order.
    public static func buildMajorPentatonicScale(fundamental: Double, count: Int) -> [Double] {
        var result: [Double] = []
        for i in 0..<count {
            let multiple = pow(2, Double(i / 5)) * pentatonicRatios[i % 5]
            result.append(fundamental * multiple)
        }
        return result
    }

    /// Builds an audio node that plays a sine wave signal at the given frequency and sample rate..
    public static func buildSourceNode(frequency: Double, sampleRate: Double) -> AVAudioSourceNode {
        var phase: Double = 0
        let phaseIncrement = (2 * Double.pi / sampleRate) * frequency
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
    public static func buildPlayer(forResource: String) -> AVAudioPlayer {
        do {
            let url = Bundle.main.url(forResource: forResource, withExtension: "wav")
            return try AVAudioPlayer(contentsOf: url!)
        } catch {
            Logger().error("Failed to load audio file: \(error)")
            return AVAudioPlayer()
        }
    }

    // MARK: Internal

    /// The ratios between consecutive notes in a major pentatonic scale.
    static let pentatonicRatios: [Double] = [1, 1.125, 1.265625, 1.5, 1.6875]
}
