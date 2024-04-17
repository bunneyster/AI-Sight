//
//  MetalEnvironment.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/15/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import Foundation
import Metal

class MetalEnvironment {
    // MARK: Lifecycle

    private init() {
        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Unable to create the metal device.")
        }
        guard let metalCommandQueue = metalDevice.makeCommandQueue() else {
            fatalError("Unable to create the command queue.")
        }
        let url = Bundle.main.url(forResource: "default", withExtension: "metallib")!
        let metalLibrary = try! metalDevice.makeLibrary(URL: url)
        self.metalDevice = metalDevice
        self.metalCommandQueue = metalCommandQueue
        self.metalLibrary = metalLibrary
    }

    // MARK: Internal

    static let shared: MetalEnvironment = .init()

    let metalDevice: MTLDevice
    let metalCommandQueue: MTLCommandQueue
    let metalLibrary: MTLLibrary
}
