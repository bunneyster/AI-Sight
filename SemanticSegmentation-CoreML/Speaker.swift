//
//  Speaker.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 10/30/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import AVFoundation

class Speaker {
    // MARK: Public

    /// Returns a phrase describing the horizontal position represented by the given number.
    ///
    /// - Parameters:
    ///   - posValue: A number ranging from 0 to 1.
    public static func horizontalPosition(posValue: Double?) -> String? {
        guard let posValue = posValue else { return nil }

        if posValue <= 0.20 {
            return "far left"
        } else if posValue <= 0.40 {
            return "left"
        } else if posValue <= 0.60 {
            return "center"
        } else if posValue <= 0.80 {
            return "right"
        } else {
            return "far right"
        }
    }

    /// Returns a phrase describing the vertical position represented by the given number.
    ///
    /// - Parameters:
    ///   - multiplier: A number ranging from 0.7 to 1.7.
    public static func verticalPosition(multiplier: Float?) -> String? {
        guard let multiplier = multiplier else { return nil }

        if multiplier <= 0.9 {
            return "bottom"
        } else if multiplier <= 1.1 {
            return "lower"
        } else if multiplier >= 1.5 {
            return "top"
        } else if multiplier >= 1.3 {
            return "upper"
        } else {
            return " "
        }
    }

    /// Returns a phrase describing the given number as a distance in meters.
    ///
    /// - Parameters:
    ///   - depth: A non-negative multiple of 0.5.
    public static func depthPosition(depth: Float?) -> String? {
        guard let depth = depth else { return nil }

        return "\(depth) meters"
    }

    /// Speaks the phrase "[object name] + [vertical position] + [horizontal position] +
    /// [distance]".
    ///
    /// - Parameters:
    ///   - objectName: The name of the object.
    ///   - multiplier: The number corresponding to the object's vertical position.
    ///   - posValue: The number corresponding to the object's horizontal position.
    ///   - depth: The distance to the object, in meters.
    public func speak(
        objectName: String,
        multiplier: Float? = nil,
        posValue: Double? = nil,
        depth: Float? = nil,
        interrupt: Bool = true
    ) {
        let phrase = [
            objectName,
            Speaker.verticalPosition(multiplier: multiplier),
            Speaker.horizontalPosition(posValue: posValue),
            Speaker.depthPosition(depth: depth),
        ].compactMap { $0 }.joined(separator: " ")
        speak(text: phrase, interrupt: interrupt)
    }

    /// Speaks the given text.
    public func speak(text: String, interrupt: Bool = true) {
        if interrupt {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: String(text))
        utterance.rate = 0.5 // slows down speaking speed
        utterance.pitchMultiplier = 1.3
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        synthesizer.speak(utterance)
    }

    /// Immediately stop any ongoing utterance.
    public func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: Internal

    static let shared = Speaker()

    let synthesizer = AVSpeechSynthesizer()
}
