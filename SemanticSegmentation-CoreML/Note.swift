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
        node.pan = pan
        node.volume = volume
    }

    // MARK: Internal

    var node: AVAudioPlayerNode = .init()
    var file: AVAudioFile
}
