//
//  MetalVideoView.swift
//  MetalCamera
//
//  Created by Eric on 2020/06/04.
//

import Foundation
import MetalKit
import AVFoundation

public class MetalVideoView: MTKView {
    public var currentTexture: Texture? {
        willSet (newValue) {
            guard let texture = newValue else { return }
            drawableSize = CGSize(width: texture.texture.width, height: texture.texture.height)
        }
    }

    private var pipelineState: MTLRenderPipelineState!
    private var render_target_vertex: MTLBuffer!
    private var render_target_uniform: MTLBuffer!

    public required init(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }

    private func setup() {
        self.device = sharedMetalRenderingDevice.device

        isOpaque = false
        setupTargetUniforms()

        do {
            try setupPiplineState()
        } catch {
            fatalError("Metal initialize failed: \(error.localizedDescription)")
        }
    }

    func setupTargetUniforms() {
        let size = drawableSize
        render_target_vertex = sharedMetalRenderingDevice.makeRenderVertexBuffer(size: size)
        render_target_uniform = sharedMetalRenderingDevice.makeRenderUniformBuffer(size)
    }

    private func setupPiplineState() throws {
        let rpd = try sharedMetalRenderingDevice.generateRenderPipelineDescriptor("vertex_render_target",
                                                                                  "fragment_render_target",
                                                                                  colorPixelFormat)
        pipelineState = try sharedMetalRenderingDevice.device.makeRenderPipelineState(descriptor: rpd)
    }

    public override func draw(_ rect:CGRect) {
        if let currentDrawable = self.currentDrawable, let imageTexture = currentTexture {
            let renderPassDescriptor = MTLRenderPassDescriptor()
            let attachment = renderPassDescriptor.colorAttachments[0]
            attachment?.clearColor = clearColor
            attachment?.texture = currentDrawable.texture
            attachment?.loadAction = .clear
            attachment?.storeAction = .store

            let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer()
            let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)

            commandEncoder?.setRenderPipelineState(pipelineState)

            commandEncoder?.setVertexBuffer(render_target_vertex, offset: 0, index: 0)
            commandEncoder?.setVertexBuffer(render_target_uniform, offset: 0, index: 1)
            commandEncoder?.setFragmentTexture(imageTexture.texture, index: 0)
            commandEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

            commandEncoder?.endEncoding()
            commandBuffer?.present(currentDrawable)
            commandBuffer?.commit()
        }
    }

    public enum Rotation: Int {
        case rotate0Degrees
        case rotate90Degrees
        case rotate180Degrees
        case rotate270Degrees

        init?(videoOrientation: AVCaptureVideoOrientation) {
            switch videoOrientation {
            case .portrait:
                self = .rotate0Degrees
            case .portraitUpsideDown:
                self = .rotate180Degrees
            case .landscapeRight:
                self = .rotate90Degrees
            case .landscapeLeft:
                self = .rotate270Degrees
            @unknown default:
                fatalError("Unknown orientation.")
            }
        }

        init?(photoOrientation: CGImagePropertyOrientation) {
            switch photoOrientation {
            case .up:
                self = .rotate0Degrees
            case .down:
                self = .rotate180Degrees
            case .right:
                self = .rotate90Degrees
            case .left:
                self = .rotate270Degrees
            @unknown default:
                fatalError("Unknown orientation.")
            }
        }
    }
}
