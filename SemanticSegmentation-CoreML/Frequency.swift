//
//  Frequencies.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 2/23/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import Foundation

// MARK: - Frequency

/// Names of the frequencies in a chromatic scale.
enum Frequency {
    case c3
    case cSharp3
    case d3
    case dSharp3
    case e3
    case f3
    case fSharp3
    case g3
    case gSharp3
    case a3
    case aSharp3
    case b3
}

/// C3 heptatonic scale using Pythagorean tuning, based on A3 = 220Hz.
var pythagoreanFrequencies: [Frequency: Double] = [
    .c3: 130.3704,
    .cSharp3: 139.2188,
    .d3: 146.6667,
    .dSharp3: 154.5130,
    .e3: 165.0000,
    .f3: 173.8272,
    .fSharp3: 185.625,
    .g3: 195.5556,
    .gSharp3: 208.8281,
    .a3: 220.0000,
    .aSharp3: 231.7695,
    .b3: 247.5000,
]
