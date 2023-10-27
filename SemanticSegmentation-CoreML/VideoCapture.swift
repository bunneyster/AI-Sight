//
//  VideoCapture.swift
//  Awesome ML
//
//  Created by Eugene Bokhan on 3/13/18.
//  Updated by Doyoung Gwak on 03/07/2018.
//  Copyright © 2018 Eugene Bokhan. All rights reserved.
//

import AVFoundation
import CoreVideo
import OSLog
import UIKit

// MARK: - VideoCaptureDelegate

public protocol VideoCaptureDelegate: AnyObject {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoSampleBuffer: CMSampleBuffer)
    func processData(depthData: AVDepthData?, videoData: CVPixelBuffer?)
    func processData(depthData: AVDepthData?, videoData: CMSampleBuffer?)
}

// MARK: - VideoCapture

public class VideoCapture: NSObject {
    // MARK: Public

    public var previewLayer: AVCaptureVideoPreviewLayer?
    public weak var delegate: VideoCaptureDelegate?
//    public weak var depthDelegate: AVCaptureDepthDataOutputDelegate?

    /// Giles - change frames per second FPS with the below command? Was 15
    public var fps = 50

    /// Gileszzz could selection of this be what overly zooms in the image? .vga640x480
    public func setUp(
        sessionPreset: AVCaptureSession.Preset = .vga640x480,
        completion: @escaping (Bool) -> Void
    ) {
        setUpCamera(sessionPreset: sessionPreset, completion: { success in
            completion(success)
        })
    }

    public func start() {
        if !captureSession.isRunning {
            // Offload `.startRunning()` to serial background thread since it's a blocking call.
            sessionQueue.async {
                self.captureSession.startRunning()
            }
        }
    }

    public func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    public func makePreview() -> AVCaptureVideoPreviewLayer? {
        guard self.previewLayer == nil else { return self.previewLayer }
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        previewLayer.connection?.videoOrientation = .portrait
        self.previewLayer = previewLayer
        return previewLayer
    }

    // MARK: Internal

    let captureSession = AVCaptureSession()
    let videoDataOutput = AVCaptureVideoDataOutput()
    let depthDataOutput = AVCaptureDepthDataOutput()

//    let queue = DispatchQueue(label: "com.tucan9389.camera-queue")
    let sessionQueue = DispatchQueue(label: "SessionQueue", attributes: [], autoreleaseFrequency: .workItem, target: .global())
    let dataOutputQueue = DispatchQueue(label: "DataOutputQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    let videoDataQueue = DispatchQueue(label: "VideoDataQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    let depthDataQueue = DispatchQueue(label: "DepthDataQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

//    let sessionQueue = DispatchQueue(
//        label: "data queue",
//        qos: .userInitiated,
//        attributes: [],
//        autoreleaseFrequency: .workItem
//    )
    var outputSynchronizer: AVCaptureDataOutputSynchronizer?
    var videoTextureCache: CVMetalTextureCache?

    /// Giles change .front (selfie) to .back for the back camera
    /// Giles5 - what other cameras and FoV options are available?
    func setUpCamera(
        sessionPreset: AVCaptureSession.Preset,
        position _: AVCaptureDevice.Position? = .back,
        completion: @escaping (_ success: Bool) -> Void
    ) {
        sessionQueue.async { [self] in
            captureSession.beginConfiguration()
            captureSession.sessionPreset = sessionPreset

            let device: AVCaptureDevice?
            if #available(iOS 15.4, *) {
                device = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.builtInLiDARDepthCamera],
                    mediaType: .video,
                    position: .back
                ).devices.first
                print("LiDAR available")
            } else {
                device = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.builtInWideAngleCamera],
                    mediaType: .video,
                    position: .back
                ).devices.first
                print("LiDAR not available, using wide angle cam")
                // Fallback on earlier versions
            }

            guard let captureDevice = device else {
                print("Error: no video devices available")
                return
            }
            
//            if let frameDuration = captureDevice.activeDepthDataFormat?.videoSupportedFrameRateRanges.first?.maxFrameDuration {
//                do {
//                    try captureDevice.lockForConfiguration()
//                    captureDevice.activeVideoMinFrameDuration = frameDuration
//                    captureDevice.unlockForConfiguration()
//                } catch {
//                    print("Could not lock device for configuration: \(error)")
//                }
//            }

            guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
                print("Error: could not create AVCaptureDeviceInput")
                return
            }

            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }

            let settings: [String: Any] = [
                kCVPixelBufferMetalCompatibilityKey as String: true,
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA),
            ]

            videoDataOutput.videoSettings = settings
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)

            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
            }

            if captureSession.canAddOutput(depthDataOutput) {
                depthDataOutput.setDelegate(self, callbackQueue: dataOutputQueue)
                depthDataOutput.isFilteringEnabled = true
                captureSession.addOutput(depthDataOutput)
                let depthConnection = depthDataOutput.connection(with: .depthData)
                depthConnection?.videoOrientation = .portrait
            }

            // We want the buffers to be in portrait orientation otherwise they are
            // rotated by 90 degrees. Need to set this _after_ addOutput()!
            videoDataOutput.connection(with: AVMediaType.video)?.videoOrientation = .portrait

            outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [
                videoDataOutput,
                depthDataOutput,
            ])
            outputSynchronizer?.setDelegate(self, queue: dataOutputQueue)

            captureSession.commitConfiguration()

            CVMetalTextureCacheCreate(
                kCFAllocatorDefault,
                nil,
                sharedMetalRenderingDevice.device,
                nil,
                &videoTextureCache
            )

            let success = true
            completion(success)
        }
    }
}

// MARK: - DataManager

class DataManager {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = DataManager()

    var depthPoints = Array(repeating: Float(0), count: 10)
    var sharedDistanceAtXYPoint: Float = 0
}

// MARK: - VideoCapture + AVCaptureVideoDataOutputSampleBufferDelegate

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(
        _: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from _: AVCaptureConnection
    ) {
        Logger().debug("qq Video output delegate")
        processVideo(sampleBuffer: sampleBuffer)
    }
    
    func processVideo(sampleBuffer: CMSampleBuffer) {
        Logger().debug("qq processing video data")
        delegate?.videoCapture(self, didCaptureVideoSampleBuffer: sampleBuffer)
    }

    public func captureOutput(
        _: AVCaptureOutput,
        didDrop _: CMSampleBuffer,
        from _: AVCaptureConnection
    ) {}
}

extension CVPixelBuffer {
    func clamp() {
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)

        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        let floatBuffer = unsafeBitCast(
            CVPixelBufferGetBaseAddress(self),
            to: UnsafeMutablePointer<Float>.self
        )

        // You might be wondering why the for loops below use `stride(from:to:step:)`
        // instead of a simple `Range` such as `0 ..< height`?
        // The answer is because in Swift 5.1, the iteration of ranges performs badly when the
        // compiler optimisation level (`SWIFT_OPTIMIZATION_LEVEL`) is set to `-Onone`,
        // which is eactly what happens when running this sample project in Debug mode.
        // If this was a production app then it might not be worth worrying about but it is still
        // worth being aware of.
        for y in stride(from: 0, to: height, by: 1) {
            for x in stride(from: 0, to: width, by: 1) {
                let pixel = floatBuffer[y * width + x]
                floatBuffer[y * width + x] = min(1.0, max(pixel, 0.0))
            }
        }

        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
    }
}

// MARK: - VideoCapture + AVCaptureDepthDataOutputDelegate

extension VideoCapture: AVCaptureDepthDataOutputDelegate {
    public func depthDataOutput(
        _: AVCaptureDepthDataOutput,
        didOutput depthData: AVDepthData,
        timestamp _: CMTime,
        connection _: AVCaptureConnection
    ) {
        Logger().debug("qq Depth output delegate")
        processDepth(depthData: depthData)
    }
    
    func processDepth(depthData: AVDepthData) {
        Logger().debug("qq Processing depth data")
        var convertedDepth: AVDepthData
        let depthDataType = kCVPixelFormatType_DepthFloat32
        if depthData.depthDataType != depthDataType {
            convertedDepth = depthData.converting(toDepthDataType: depthDataType)
        } else {
            convertedDepth = depthData
        }

        let depthDataMap = convertedDepth.depthDataMap
        CVPixelBufferLockBaseAddress(depthDataMap, CVPixelBufferLockFlags(rawValue: 0))

        // Convert the base address to a safe pointer of the appropriate type
        let floatBuffer = unsafeBitCast(
            CVPixelBufferGetBaseAddress(depthDataMap),
            to: UnsafeMutablePointer<Float32>.self
        )

        for i in 0..<10 {
            DataManager.shared.depthPoints[i] = floatBuffer[28804 + i * 19]
        }

        let middleLocationSimpleInt = 28890
        let distanceAtXYPoint = floatBuffer[middleLocationSimpleInt]
        DataManager.shared.sharedDistanceAtXYPoint = distanceAtXYPoint
    }
}

extension VideoCapture: AVCaptureDataOutputSynchronizerDelegate {
    func deepCopyAVDepthData(depthData: AVDepthData) -> AVDepthData? {
        var auxDataType :NSString?
        guard let dict = depthData.dictionaryRepresentation(forAuxiliaryDataType: &auxDataType),
              let depthDataCopy = try? AVDepthData(fromDictionaryRepresentation: dict)
        else {
            return nil
        }
        return depthDataCopy
    }
    
    // image buffer is not deep copied
//    func deepCopyCMSampleBuffer(sampleBuffer: CMSampleBuffer) -> CMSampleBuffer? {
//        var sampleBufferCopy: CMSampleBuffer?
//        guard let imageBuffer = sampleBuffer.imageBuffer,
//              let formatDescription = sampleBuffer.formatDescription,
//              let sampleTimingInfos = try? sampleBuffer.sampleTimingInfos() else {
//            return nil
//        }
//        CMSampleBufferCreateReadyWithImageBuffer(
//            allocator: kCFAllocatorDefault,
//            imageBuffer: deepCopyCVPixelBuffer(pixelBuffer: imageBuffer)!,
//            formatDescription: formatDescription,
//            sampleTiming: sampleTimingInfos,
//            sampleBufferOut: &sampleBufferCopy
//        )
//        return sampleBufferCopy
//    }
    
    func deepCopyCVPixelBuffer(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        var pixelBufferCopy: CVPixelBuffer?
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            format,
//            CVBufferCopyAttachments(pixelBuffer, .shouldPropagate),
            [
                kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue as Any,
                kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            ] as CFDictionary,
            &pixelBufferCopy
        )
        if let pixelBufferCopy = pixelBufferCopy {
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            CVPixelBufferLockBaseAddress(pixelBufferCopy, CVPixelBufferLockFlags(rawValue: 0))
//            var srcAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
            var destAddress = CVPixelBufferGetBaseAddress(pixelBufferCopy)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
            if var srcAddress = CVPixelBufferGetBaseAddress(pixelBuffer) {
//                destAddress?.copyMemory(from: srcAddress, byteCount: height * bytesPerRow)
                for _ in 0..<height {
                    memcpy(destAddress, srcAddress, bytesPerRow)
//                    destAddress?.copyMemory(from: srcAddress, byteCount: bytesPerRow)
                    destAddress = destAddress?.advanced(by: bytesPerRow)
                    srcAddress = srcAddress.advanced(by: bytesPerRow)
                }
            }
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            CVPixelBufferUnlockBaseAddress(pixelBufferCopy, CVPixelBufferLockFlags(rawValue: 0))
        }
        return pixelBufferCopy
    }
    
    public func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        Logger().debug("aa [OUTPUT] synchronizer delegate")
        var depthData: AVDepthData?
        if let syncedDepthData = synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData {
            if !syncedDepthData.depthDataWasDropped {
                // Holding on to captured data buffer for too long will exhaust the internal pool of
                // memory buffers, causing subsequent data to be dropped.
                depthData = deepCopyAVDepthData(depthData: syncedDepthData.depthData)
            } else {
                Logger().debug("aa Depth data dropped reason: \(String(syncedDepthData.droppedReason.rawValue))")
            }
        }
        var videoData: CVPixelBuffer?
        if let syncedVideoData = synchronizedDataCollection.synchronizedData(for: videoDataOutput) as? AVCaptureSynchronizedSampleBufferData {
            if !syncedVideoData.sampleBufferWasDropped {
                // Holding on to captured data buffer for too long will exhaust the internal pool of
                // memory buffers, causing subsequent data to be dropped.
                if let pixelBuffer = CMSampleBufferGetImageBuffer(syncedVideoData.sampleBuffer) {
                    videoData = deepCopyCVPixelBuffer(pixelBuffer: pixelBuffer)
                }
            } else {
                Logger().debug("aa Video data dropped reason: \(syncedVideoData.droppedReason.rawValue)")
            }
        }
        usleep(3000)
        delegate?.processData(depthData: depthData, videoData: videoData)
    }
   
}

func redirectLogs(flag: Bool) {
    if flag {
        if let documentsPathString = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true
        ).first {
            let logPath = documentsPathString.appending("app.log")
            freopen(logPath.cString(using: String.Encoding.ascii), "a+", stderr)
        }
    }
}
