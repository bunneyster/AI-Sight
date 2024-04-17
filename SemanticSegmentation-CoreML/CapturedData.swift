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
        pixelBuffer: CVPixelBuffer? = nil,
        segmentationMap: MLMultiArray? = nil,
        depthData: AVDepthData? = nil
    ) {
        self.pixelBuffer = pixelBuffer
        self.segmentationMap = segmentationMap
        self.depthData = depthData
    }

    // MARK: Public

    public func extractObjects(downsampleFactor: Int = 1) -> [MLObject] {
        var objects = [Int: MLObject]()
        var depths = [Int: [Float]]()

        guard let segmentationMap = segmentationMap,
              let segmentationHeight = segmentationMap.shape[0] as? Int,
              let segmentationWidth = segmentationMap.shape[1] as? Int,
              let pixelBuffer = pixelBuffer,
              let depthData = depthData
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
        CVPixelBufferUnlockBaseAddress(depthBuffer, CVPixelBufferLockFlags(rawValue: 0))

        let videoWidth = CVPixelBufferGetWidth(pixelBuffer)
        let videoHeight = CVPixelBufferGetHeight(pixelBuffer)
        let depthWidth = CVPixelBufferGetWidth(depthBuffer)
        let depthHeight = CVPixelBufferGetHeight(depthBuffer)
        let xOffset = (videoWidth - segmentationWidth) / 2
        let yOffset = (videoHeight - segmentationHeight) / 2
        let scaleX = Float(videoWidth) / Float(depthWidth)
        let scaleY = Float(videoHeight) / Float(depthHeight)

        for r in 0..<segmentationHeight / downsampleFactor {
            for c in 0..<segmentationWidth / downsampleFactor {
                let row = r * downsampleFactor
                let col = c * downsampleFactor
                let coords = [row, col] as [NSNumber]
                let id = segmentationMap[coords].intValue
                if id == 0 {
                    continue
                }

                let depthMapX = Float(col + xOffset) / scaleX
                let depthMapY = Float(row + yOffset) / scaleY
                let depthIndex = depthMapY * Float(depthWidth) + depthMapX
                let depth = floatBuffer[Int(depthIndex)]
                if depth > 0 {
                    depths[id, default: []].append(depth)
                }
                if let object = objects[id] {
                    object.center.x += col
                    object.center.y += row
                    object.size += 1
                } else {
                    objects[id] = MLObject(
                        id: id,
                        center: IntPoint(x: row, y: col),
                        depth: 0,
                        size: 1
                    )
                }
            }
        }

        for (id, values) in depths {
            if let object = objects[id] {
                let sortedValues = values.sorted()
                let percentileValue =
                    sortedValues[Int(
                        Double(values.count - 1) * UserDefaults.standard
                            .double(forKey: "objectDepthPercentile")
                    )]
                object.depth = percentileValue
            }
        }

        for (id, object) in objects {
            let size = object.size
            objects[id]?.center.x /= size
            objects[id]?.center.y /= size
            object.size *= downsampleFactor * downsampleFactor
        }

        return Array(objects.values)
    }

    // MARK: Internal

    var pixelBuffer: CVPixelBuffer?
    var segmentationMap: MLMultiArray?
    var depthData: AVDepthData?
}
