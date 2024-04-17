//
//  GlobalConstants.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/17/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import Foundation

let labels = [
    "background",
    "aeroplane",
    "bicycle",
    "bird",
    "boat",
    "bottle",
    "bus",
    "car",
    "cat",
    "chair",
    "cow",
    "table",
    "dog",
    "horse",
    "motorbike",
    "person",
    "plant",
    "sheep",
    "sofa",
    "train",
    "tv",
]

let objectCategoryIds = [
    "None": [],
    "People": [15],
    "Vehicles": [1, 2, 4, 6, 7, 14, 19],
    "Seating": [9, 18],
    "Animals": [3, 8, 10, 12, 13, 17],
    "Bottles": [5],
    "TVs": [20],
    "Tables": [11],
]
