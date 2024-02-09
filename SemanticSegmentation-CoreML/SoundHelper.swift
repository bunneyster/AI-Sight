//
//  Player.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 11/28/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import AVFoundation
import Foundation
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

    public static func composeLiveMusic(
        segmentationMap: MLMultiArray,
        depthPoints: [Float]
    ) -> [Note] {
        var columnModes = [Int]()
        for column in 0..<numColumns {
            let mode = mode(MLMultiArrayHelper.objectIdsInColumn(
                column,
                segmentationMap: segmentationMap
            )) ?? 0
            columnModes.append(mode)
            print("Mode value \(column + 1) is \(mode)")
        }

        var melody: [Note] = []
        var columnObjectIds: [Int] = []
        var columnVolumes: [Float] = []
        for column in 0..<numColumns {
            let objectId = liveViewModeColumns == 1 ? columnModes[column] :
                Int(truncating: segmentationMap[
                    liveMusicModePixelOffset + column * columnWidth
                ])
            print(objectId)
            columnObjectIds.append(objectId)

            let intensity = DepthHelper
                .intensityForDepth(depth: depthPoints[column])
            columnVolumes
                .append(liveViewModeColumns == 1 ? 1.0 : intensity)

            let fileName = [String(column + 1), objectIdToSound[objectId]]
                .compactMap { $0 }
                .joined()
            let file = try! AVAudioFile(
                forReading: Bundle.main.url(
                    forResource: fileName,
                    withExtension: "wav"
                )!
            )
            melody.append(Note(
                file: file,
                pan: -0.9 + Float(column) * 0.2,
                volume: Float(objectId >= 1 ? columnVolumes[column] : 0.0)
            ))
        }
        return melody
    }

    public static func playMusic(melody: [Note]) {
        let liveEngine = AVAudioEngine()

        for note in melody {
            liveEngine.attach(note.node)
            liveEngine.connect(
                note.node,
                to: liveEngine.mainMixerNode,
                format: note.file.processingFormat
            )
        }

        for (column, note) in melody.enumerated() {
            let delayTime = AVAudioTime(
                sampleTime: AVAudioFramePosition(44100 * Float(column) * 0.007),
                atRate: note.file.processingFormat.sampleRate
            )
            note.node.scheduleFile(note.file, at: delayTime, completionHandler: nil)
            // Must set node volume before starting the engine.
            note.node.volume = note.volume
        }

        liveEngine.prepare()
        try! liveEngine.start()

        for note in melody {
            // Must set node pan after starting the engine; setting it before seems to prevent
            // proper configuration at any point thereafter.
            note.node.pan = note.pan
            note.node.play()
        }
        usleep(500_000)

        try! liveEngine.stop()
    }

    // MARK: Internal

    static func mode(_ array: [Int]) -> (Int)? {
        let countedSet = NSCountedSet(array: array)
        var counts = [(value: Int, count: Int)]()
        var totalCount = 0

        for value in countedSet {
            let count = countedSet.count(for: value)
            if let intValue = value as? Int, intValue != 0 {
                counts.append((intValue, count))
                totalCount += count
            } else if let _ = value as? Int {
                totalCount += count
            }
        }

        counts.sort { $0.count > $1.count }
        var returnValue = 0

        if let mode = counts.first {
            let modeValue = mode.value
            let modeValueInt: Int = modeValue

            let modeCount = Double(mode.count)
            let modePercentage = modeCount / Double(totalCount) * 100
            if modePercentage > 5 {
                returnValue = modeValueInt
            } else {
                returnValue = 0
            }
        }
        return returnValue
    }
}
