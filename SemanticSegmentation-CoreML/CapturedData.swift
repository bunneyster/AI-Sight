//
//  CapturedData.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 12/26/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import AVFoundation
import Foundation
import Vision

public class CapturedData {
    // MARK: Lifecycle

    init(
        segmentationMap: MLMultiArray,
        videoBufferHeight: Int,
        videoBufferWidth: Int,
        depthData: AVDepthData
    ) {
        self.segmentationMap = segmentationMap
        self.videoBufferHeight = videoBufferHeight
        self.videoBufferWidth = videoBufferWidth
        self.depthData = depthData
    }

    // MARK: Internal

    var segmentationMap: MLMultiArray
    var videoBufferHeight: Int
    var videoBufferWidth: Int
    var depthData: AVDepthData
}
