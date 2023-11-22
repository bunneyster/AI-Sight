//
//  Float+Extensions.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 11/21/23.
//  Copyright © 2023 Doyoung Gwak. All rights reserved.
//

import Foundation

extension Float {
    func round(nearest: Float) -> Float {
        return (self / nearest).rounded() * nearest
    }
}
