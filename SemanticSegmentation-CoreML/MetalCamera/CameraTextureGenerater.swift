//
//  MetalCamera.swift → CameraTextureGenerater.swift
//  MetalCamera → SemanticSegmentation-CoreML
//
//  Created by Eric on 2020/06/06.
//  Updated by Doyoung Gwak on 2020/11/16.
//

import CoreMedia
import OSLog

class CameraTextureGenerater: NSObject {
    
    public let sourceKey: String
    var videoTextureCache: CVMetalTextureCache?
    
    public init(sourceKey: String = "camera") {
        self.sourceKey = sourceKey
        super.init()

        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, sharedMetalRenderingDevice.device, nil, &videoTextureCache)
    }
    
    func texture(from cameraFrame: CVPixelBuffer) -> Texture? {
        guard let videoTextureCache = videoTextureCache else { return nil }

        let bufferWidth = CVPixelBufferGetWidth(cameraFrame)
        let bufferHeight = CVPixelBufferGetHeight(cameraFrame)

        var textureRef: CVMetalTexture? = nil
        let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          videoTextureCache,
                                                          cameraFrame,
                                                          nil,
                                                          .bgra8Unorm,
                                                          bufferWidth,
                                                          bufferHeight,
                                                          0,
                                                          &textureRef)
        switch result {
        case kCVReturnAllocationFailed:
            Logger().debug("aa create texture status: allocation failed")
        case kCVReturnError:
            Logger().debug("aa create texture status: error")
        case kCVReturnInvalidArgument:
            Logger().debug("aa create texture status: invalid argument")
        case kCVReturnSuccess:
            Logger().debug("aa create texture status: success")
        case kCVReturnUnsupported:
            Logger().debug("aa create texture status: unsupported")
        default:
            Logger().debug("aa create texture status: unknown - \(result)")
        }
        if let concreteTexture = textureRef,
            let cameraTexture = CVMetalTextureGetTexture(concreteTexture) {
            return Texture(texture: cameraTexture, textureKey: self.sourceKey)
        } else {
            return nil
        }
    }
    
    func texture(from sampleBuffer: CMSampleBuffer) -> Texture? {
        guard let cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        return texture(from: cameraFrame)
    }
}
