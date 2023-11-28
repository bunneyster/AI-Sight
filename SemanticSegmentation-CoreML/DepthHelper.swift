//
//  DepthHelper.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 11/28/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import AVFoundation
import Foundation

class DepthHelper {
    public static func getDepthMap(depthData: AVDepthData) -> CVPixelBuffer {
        var convertedDepth: AVDepthData
        let depthDataType = kCVPixelFormatType_DepthFloat32
        if depthData.depthDataType != depthDataType {
            convertedDepth = depthData.converting(toDepthDataType: depthDataType)
        } else {
            convertedDepth = depthData
        }

        return convertedDepth.depthDataMap
    }

    public static func computeDepthPoints(depthData: AVDepthData) -> [Float] {
        let depthDataMap = getDepthMap(depthData: depthData)
        CVPixelBufferLockBaseAddress(depthDataMap, CVPixelBufferLockFlags(rawValue: 0))

        // Convert the base address to a safe pointer of the appropriate type
        let floatBuffer = unsafeBitCast(
            CVPixelBufferGetBaseAddress(depthDataMap),
            to: UnsafeMutablePointer<Float32>.self
        )

        CVPixelBufferUnlockBaseAddress(depthDataMap, CVPixelBufferLockFlags(rawValue: 0))

        var depthPoints = Array(repeating: Float(0), count: 10)
        for i in 0..<10 {
            depthPoints[i] = floatBuffer[28804 + i * 19]
        }
        return depthPoints
    }

    public static func intensityForDepth(depth: Float) -> Float {
        if depth <= 1.2 {
            return 1
        } else if depth <= 2.2 {
            return 0.2
        } else {
            return 0.05
        }
    }
}
