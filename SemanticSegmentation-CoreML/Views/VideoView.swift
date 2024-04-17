//
//  PlayerView.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/16/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import Metal
import MetalKit
import OSLog
import SwiftUI
import Vision

// MARK: - VideoView

struct VideoView: UIViewRepresentable, MetalRepresentable {
    var capturedData: CapturedData

    func makeCoordinator() -> MTKVideoTextureCoordinator {
        MTKVideoTextureCoordinator(parent: self)
    }
}

// MARK: - MTKVideoTextureCoordinator

final class MTKVideoTextureCoordinator: MTKCoordinator<VideoView> {
    // MARK: Internal

    override func preparePipeline() {
        guard let metalDevice = mtkView.device else { fatalError("Expected a Metal device.") }
        do {
            let library = MetalEnvironment.shared.metalLibrary
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_render_target")
            pipelineDescriptor.fragmentFunction = library
                .makeFunction(name: "fragment_render_target")
            pipelineState = try metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Unexpected error: \(error).")
        }
    }

    override func draw(in view: MTKView) {
        guard let texture = generateTexture() else { return }
        let size = CGSize(width: texture.texture.width, height: texture.texture.height)
        let renderTargetVertex = sharedMetalRenderingDevice.makeRenderVertexBuffer(size: size)
        let renderTargetUniform = sharedMetalRenderingDevice.makeRenderUniformBuffer(size)

        guard let passDescriptor = view.currentRenderPassDescriptor else { return }
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else { return }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else {
            return
        }

        encoder.setVertexBuffer(renderTargetVertex, offset: 0, index: 0)
        encoder.setVertexBuffer(renderTargetUniform, offset: 0, index: 1)
        encoder.setFragmentTexture(texture.texture, index: 0)
        encoder.setRenderPipelineState(pipelineState)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }

    // MARK: Private

    private var cameraTextureGenerater = CameraTextureGenerater()
    private var multitargetSegmentationTextureGenerater = MultitargetSegmentationTextureGenerater()
    private var overlayingTexturesGenerater = OverlayingTexturesGenerater()

    private func generateTexture() -> Texture? {
        guard let pixelBuffer = parent.capturedData.pixelBuffer,
              let segmentationMap = parent.capturedData.segmentationMap,
              let cameraTexture = cameraTextureGenerater.texture(
                  from: pixelBuffer,
                  pixelFormat: .bgra8Unorm
              ),
              let segmentationTexture = multitargetSegmentationTextureGenerater.texture(
                  segmentationMap,
                  labels.count
              )
        else {
            return nil
        }
        let overlayedTextured = overlayingTexturesGenerater.texture(
            cameraTexture,
            segmentationTexture
        )
        return overlayedTextured
    }
}
