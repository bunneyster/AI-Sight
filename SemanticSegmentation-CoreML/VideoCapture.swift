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
    func videoCapture(
        _ capture: VideoCapture,
        didCaptureVideoPixelBuffer: CVPixelBuffer,
        didCaptureVideoDepthData: AVDepthData
    )
}

// MARK: - VideoCapture

public class VideoCapture: NSObject {
    // MARK: Public

    public var previewLayer: AVCaptureVideoPreviewLayer?
    public weak var delegate: VideoCaptureDelegate?
    public weak var depthDelegate: AVCaptureDepthDataOutputDelegate?

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

    let sessionQueue = DispatchQueue(
        label: "SessionQueue",
        attributes: [],
        autoreleaseFrequency: .workItem,
        target: .global()
    )
    let dataOutputQueue = DispatchQueue(
        label: "DataOutputQueue",
        attributes: [],
        autoreleaseFrequency: .workItem,
        target: .global()
    )
    var outputSynchronizer: AVCaptureDataOutputSynchronizer?
    var videoTextureCache: CVMetalTextureCache?

    /// Giles change .front (selfie) to .back for the back camera
    /// Giles5 - what other cameras and FoV options are available?
    func setUpCamera(
        sessionPreset: AVCaptureSession.Preset,
        position _: AVCaptureDevice.Position? = .back,
        completion: @escaping (_ success: Bool) -> Void
    ) {
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

        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }

        if captureSession.canAddOutput(depthDataOutput) {
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

// MARK: AVCaptureDataOutputSynchronizerDelegate

extension VideoCapture: AVCaptureDataOutputSynchronizerDelegate {
    public func dataOutputSynchronizer(
        _: AVCaptureDataOutputSynchronizer,
        didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection
    ) {
        var videoData: CVPixelBuffer?
        if let syncedVideoData = synchronizedDataCollection
            .synchronizedData(for: videoDataOutput) as? AVCaptureSynchronizedSampleBufferData
        {
            if !syncedVideoData.sampleBufferWasDropped {
                if let pixelBuffer = CMSampleBufferGetImageBuffer(syncedVideoData.sampleBuffer) {
                    // Use a deep copy to release the memory buffer pool, which will otherwise drop
                    // frames if exhausted.
                    videoData = pixelBuffer.clone()
                }
            } else {
                Logger()
                    .debug(
                        "[VideoCapture] video data dropped: \(syncedVideoData.droppedReason.rawValue)"
                    )
            }
        }

        var depthData: AVDepthData?
        if let syncedDepthData = synchronizedDataCollection
            .synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData
        {
            if !syncedDepthData.depthDataWasDropped {
                // Use a deep copy to release the memory buffer pool, which will otherwise drop
                // frames if exhausted.
                depthData = syncedDepthData.depthData.clone()
            } else {
                Logger()
                    .debug(
                        "[VideoCapture] depth data dropped: \(syncedDepthData.droppedReason.rawValue)"
                    )
            }
        }

        if let videoData = videoData,
           let depthData = depthData
        {
            delegate?.videoCapture(
                self,
                didCaptureVideoPixelBuffer: videoData,
                didCaptureVideoDepthData: depthData
            )
        }
    }
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

    func clone() -> CVPixelBuffer? {
        var clone: CVPixelBuffer?
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        let format = CVPixelBufferGetPixelFormatType(self)
        let attrs = [
            kCVPixelBufferMetalCompatibilityKey: true,
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
        ] as CFDictionary
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, format, attrs, &clone)

        if let clone = clone {
            CVPixelBufferLockBaseAddress(self, .readOnly)
            CVPixelBufferLockBaseAddress(clone, CVPixelBufferLockFlags(rawValue: 0))
            if let srcAddress = CVPixelBufferGetBaseAddress(self),
               let destAddress = CVPixelBufferGetBaseAddress(clone)
            {
                let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
                destAddress.copyMemory(from: srcAddress, byteCount: height * bytesPerRow)
            }
        }

        return clone
    }
}

extension AVDepthData {
    func clone() -> AVDepthData? {
        var auxDataType: NSString?
        guard let dict = dictionaryRepresentation(forAuxiliaryDataType: &auxDataType),
              let clone = try? AVDepthData(fromDictionaryRepresentation: dict) else { return nil }
        return clone
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
