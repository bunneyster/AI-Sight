//
//  UserDefaults+Extensions.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/25/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import Foundation

let initialUserDefaults: [String: Any] = [
    UserDefaults.Key.announcer.rawValue: true,
    UserDefaults.Key.announcerDepthInterval.rawValue: 0.5,
    UserDefaults.Key.announcerDepthMargin.rawValue: 0.2,
    UserDefaults.Key.announcerMaxDepth.rawValue: 5.0,
    UserDefaults.Key.minObjectSizePercentage.rawValue: 0.01,
    UserDefaults.Key.proximeter.rawValue: "None",
    UserDefaults.Key.proximityThreshold1.rawValue: Float(0.75),
    UserDefaults.Key.proximityThreshold2.rawValue: Float(1.25),
    UserDefaults.Key.proximityThreshold3.rawValue: Float(1.75),
    UserDefaults.Key.proximityThreshold4.rawValue: Float(2.5),
    UserDefaults.Key.scanner.rawValue: "None",
    UserDefaults.Key.scannerNumColumns.rawValue: 20,
    UserDefaults.Key.scannerNumRows.rawValue: 20,
    UserDefaults.Key.useVoiceOverSettings.rawValue: false,
]

public extension UserDefaults {
    enum Key: String {
        case announcer
        case announcerDepthInterval
        case announcerDepthMargin
        case announcerMaxDepth
        case minObjectSizePercentage
        case objectDepthPercentile
        case proximeter
        case proximityThreshold1
        case proximityThreshold2
        case proximityThreshold3
        case proximityThreshold4
        case scanner
        case scannerNumColumns
        case scannerNumRows
        case useVoiceOverSettings
    }

    func double(forKey: Key) -> Double {
        return double(forKey: forKey.rawValue)
    }

    func float(forKey: Key) -> Float {
        return float(forKey: forKey.rawValue)
    }

    func integer(forKey: Key) -> Int {
        return integer(forKey: forKey.rawValue)
    }

    func string(forKey: Key) -> String? {
        return string(forKey: forKey.rawValue)
    }
}
