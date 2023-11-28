//
//  MLMultiArrayHelper.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 11/28/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import Foundation
import Vision

class MLMultiArrayHelper {
    public static func objectIdsInColumn(_ column: Int, segmentationMap: MLMultiArray) -> [Int] {
        var objectIds = [Int]()
        let firstPixel = column * 51
        for row in 0..<513 {
            for col in firstPixel..<(firstPixel + 50) {
                let id = segmentationMap[[row, col] as [NSNumber]].intValue
                objectIds.append(id)
            }
        }
        return objectIds
    }

    /// Groups the segmentation data per object ID.
    ///
    /// - Parameters:
    ///   - segmentationMap: The 2D map containing the object-level image.
    ///   - row: The number of rows in the segmentation map.
    ///   - col: The number of columns in the segmentation map.
    /// - Returns: A tuple containing 3 maps: `o`, a map of object ID to the number of corresponding
    /// segmentation map elements, `x`, a map of object ID to the sum of the x-coordinates of its
    /// corresponding segmentation map elements, and `y`, a map of object ID to the sum of the
    /// y-coordinates of its corresponding segmentation map elements.
    public static func getImageFrameCoordinates(
        segmentationmap: MLMultiArray, row: Int, col: Int
    ) -> (o: [Int: Int], x: [Int: Int], y: [Int: Int]) {
        var o = [Int: Int](), x = [Int: Int](), y = [Int: Int]()
        for i in 0...row - 1 {
            for j in 0...col - 1 {
                let key = [i, j] as [NSNumber]
                let k = segmentationmap[key].intValue
                if o.keys.contains(k) {
                    o[k, default: 0] += 1
                    x[k, default: 0] += j
                    y[k, default: 0] += i
                } else {
                    o[k] = 0
                    x[k] = j
                    y[k] = i
                }
            }
        }
        return (o, x, y)
    }
}
