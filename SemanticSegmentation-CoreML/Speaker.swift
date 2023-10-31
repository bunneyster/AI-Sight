//
//  Speaker.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 10/30/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import AVFoundation

class Speaker: NSObject {
    // MARK: Lifecycle

    init(synthesizer: AVSpeechSynthesizer) {
        self.synthesizer = synthesizer
    }

    // MARK: Public

    /// Returns a phrase describing the horizontal position represented by the given number.
    ///
    /// - Parameters:
    ///   - posValue: A number ranging from 0 to 1.
    public static func horizontalPosition(posValue: Double) -> String {
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
    public static func verticalPosition(multiplier: Float) -> String {
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

    /// Speaks the phrase "[object name] + [vertical position] + [horizontal position]".
    ///
    /// - Parameters:
    ///   - objectName: The name of the object.
    ///   - multiplier: The number corresponding to the object's vertical position.
    ///   - posValue: The number corresponding to the object's horizontal position.
    public func speak(objectName: String, multiplier: Float, posValue: Double) {
        let phrase = [
            objectName,
            Speaker.verticalPosition(multiplier: multiplier),
            Speaker.horizontalPosition(posValue: posValue),
        ].joined(separator: " ")
        speak(text: phrase)
    }

    /// Speaks the given text.
    public func speak(text: String) {
        let utterance = AVSpeechUtterance(string: String(text))
        utterance.rate = 0.5 // slows down speaking speed
        utterance.pitchMultiplier = 1.3
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        synthesizer.speak(utterance)
    }

    // MARK: Internal

    let synthesizer: AVSpeechSynthesizer
}
