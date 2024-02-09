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
    public static func horizontalPosition(posValue: Float?) -> String? {
        guard let posValue = posValue else { return nil }

        if posValue <= 0.2 {
            return "far left"
        } else if posValue <= 0.4 {
            return "left"
        } else if posValue <= 0.6 {
            return "center"
        } else if posValue <= 0.8 {
            return "right"
        } else {
            return "far right"
        }
    }

    /// Returns a phrase describing the vertical position represented by the given number.
    ///
    /// - Parameters:
    ///   - multiplier: A number ranging from 0 to 1.
    public static func verticalPosition(multiplier: Float?) -> String? {
        guard let multiplier = multiplier else { return nil }

        if multiplier <= 0.2 {
            return "top"
        } else if multiplier <= 0.4 {
            return "upper"
        } else if multiplier >= 0.8 {
            return "bottom"
        } else if multiplier >= 0.6 {
            return "lower"
        } else {
            return " "
        }
    }

    /// Returns a phrase describing the given number as a distance with 0.1 precision in meters.
    ///
    /// - Parameters:
    ///   - depth: A depth measurement, in meters.
    public static func depthPosition(depth: Float?) -> String? {
        guard let depth = depth else { return nil }

        return String(format: "%.1f meters", depth)
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
        objectName: String? = nil,
        verticalPosition: Float? = nil,
        horizontalPosition: Float? = nil,
        depth: Float? = nil,
        interrupt: Bool = true
    ) {
        let phrase = [
            objectName,
            Speaker.verticalPosition(multiplier: verticalPosition),
            Speaker.horizontalPosition(posValue: horizontalPosition),
            Speaker.depthPosition(depth: depth),
        ].compactMap { $0 }.joined(separator: " ")
        speak(text: phrase, interrupt: interrupt)
    }

    /// Speaks the given text.
    public func speak(text: String, interrupt: Bool = true) {
        if interrupt {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.prefersAssistiveTechnologySettings = true
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
