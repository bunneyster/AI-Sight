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

    // MARK: Public

    public func extractObjects() -> [MLObject] {
        var objects = [Int: MLObject]()

        guard let segmentationHeight = segmentationMap.shape[0] as? Int,
              let segmentationWidth = segmentationMap.shape[1] as? Int
        else {
            return Array(objects.values)
        }

        let depthBuffer = DepthHelper.getDepthMap(depthData: depthData)
        CVPixelBufferLockBaseAddress(depthBuffer, CVPixelBufferLockFlags(rawValue: 0))

        // Convert the base address to a safe pointer of the appropriate type
        let floatBuffer = unsafeBitCast(
            CVPixelBufferGetBaseAddress(depthBuffer),
            to: UnsafeMutablePointer<Float32>.self
        )
        let videoWidth = videoBufferWidth
        let videoHeight = videoBufferHeight
        let depthWidth = CVPixelBufferGetWidth(depthBuffer)
        let depthHeight = CVPixelBufferGetHeight(depthBuffer)
        let xOffset = (videoWidth - segmentationWidth) / 2
        let yOffset = (videoHeight - segmentationHeight) / 2
        let scaleX = videoWidth / depthWidth
        let scaleY = videoHeight / depthHeight

        for row in 0..<segmentationHeight {
            for col in 0..<segmentationWidth {
                let coords = [row, col] as [NSNumber]
                let id = segmentationMap[coords].intValue
                if id == 0 {
                    continue
                }

                let depthMapX = (col + xOffset) / scaleX
                let depthMapY = (row + yOffset) / scaleY
                let depthIndex = depthMapY * (segmentationWidth / scaleX) + depthMapX
                let depth = floatBuffer[Int(depthIndex)]
                if let object = objects[id] {
                    object.center.x += col
                    object.center.y += row
                    if depth > 0 {
                        object.depth = object.depth == 0 ? depth : min(object.depth, depth)
                    }
                    object.size += 1
                } else {
                    objects[id] = MLObject(
                        id: id,
                        center: IntPoint(x: row, y: col),
                        depth: depth,
                        size: 1
                    )
                }
            }
        }

        CVPixelBufferUnlockBaseAddress(depthBuffer, CVPixelBufferLockFlags(rawValue: 0))

        for (id, object) in objects {
            let size = object.size
            objects[id]?.center.x /= size
            objects[id]?.center.y /= size
        }

        return Array(objects.values)
    }

    // MARK: Internal

    var segmentationMap: MLMultiArray
    var videoBufferHeight: Int
    var videoBufferWidth: Int
    var depthData: AVDepthData
}
