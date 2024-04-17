//
//  MetalContentView.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/15/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import Metal
import MetalKit
import SwiftUI

// MARK: - MetalRepresentable

/** 
 The `MetalRepresentable` protocol extends `UIViewRepresentable` to allow `MTKView` objects in SwiftUI.
 The `rotationAngle` presents the camera streams upright on device rotations.
 Each new Metal view that conforms to `MetalRepresentable` needs to add its required input properties,
 and to implement the `makeCoordinator` function to return the coordinator that holds the view's drawing logic.
 */
protocol MetalRepresentable: UIViewRepresentable {}

/// An extension of `MetalRepresentable` to share the settings for the conforming views.
extension MetalRepresentable where Self.Coordinator: MTKCoordinator<Self> {
    func makeUIView(context: UIViewRepresentableContext<Self>) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.backgroundColor = context.environment.colorScheme == .dark ? .black : .white
        context.coordinator.setupView(mtkView: mtkView)
        return mtkView
    }

    func updateUIView(_: MTKView, context _: Context) {}
}

// MARK: - MTKCoordinator

/**
  The base coordinator class that conforms to `MTKViewDelegate`. Subclasses can override:
  - `preparePipeline()` - to create a pipeline descriptor with the required vertex and fragment
                                       function to create a `pipelineState`.
 - `draw()` - to perform the drawing operation.
  */
class MTKCoordinator<MTKViewRepresentable: MetalRepresentable>: NSObject, MTKViewDelegate {
    // MARK: Lifecycle

    init(parent: MTKViewRepresentable) {
        self.parent = parent
        self.metalCommandQueue = MetalEnvironment.shared.metalCommandQueue
        super.init()
    }

    // MARK: Internal

    weak var mtkView: MTKView!

    var pipelineState: MTLRenderPipelineState!
    var metalCommandQueue: MTLCommandQueue
    var parent: MTKViewRepresentable

    /// Saves a reference to the `MTKView` in the coordinator and sets up the default settings.
    func setupView(mtkView: MTKView) {
        self.mtkView = mtkView
        self.mtkView.preferredFramesPerSecond = 60
        self.mtkView.isOpaque = true
        self.mtkView.framebufferOnly = false
        self.mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        self.mtkView.drawableSize = mtkView.frame.size
        self.mtkView.enableSetNeedsDisplay = false
        self.mtkView.colorPixelFormat = .bgra8Unorm
        self.mtkView.contentMode = .scaleAspectFit
        self.mtkView.device = MetalEnvironment.shared.metalDevice
        preparePipeline()
    }

    func preparePipeline() {
        // Override in subclass.
    }

    func mtkView(_: MTKView, drawableSizeWillChange _: CGSize) {
        // Override in subclass.
    }

    func draw(in _: MTKView) {
        // Override in subclass.
    }
}
