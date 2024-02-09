//
//  Note.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 11/28/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import AVFoundation
import Foundation

/// A wrapper around an `AVAudioPlayerNode` and an `AVAudioFile`.
struct Note {
    // MARK: Lifecycle

    init(file: AVAudioFile, pan: Float = 0.0, volume: Float = 0.0) {
        self.file = file
        self.pan = pan
        self.volume = volume
    }

    // MARK: Internal

    var file: AVAudioFile
    var pan: Float
    var volume: Float
    var node: AVAudioPlayerNode = .init()
}
