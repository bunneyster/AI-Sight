//
//  CameraManager.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/16/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import OSLog
import Vision

// MARK: - CameraManager

class CameraManager: NSObject, ObservableObject, VideoCaptureDelegate {
    // MARK: Lifecycle

    override init() {
        self.capturedData = CapturedData()

        if let visionModel = try? VNCoreMLModel(for: segmentationModel.model) {
            self.visionModel = visionModel
        } else {
            fatalError()
        }

        self.videoCapture = VideoCapture()

        super.init()

        self.allObjectsAnnouncer = AllObjectsAnnouncer()
        allObjectsAnnouncer.speaker.synthesizer.delegate = self
        self.announcer = StreamingMainObjectAnnouncer(manager: self)
        self.scanner = StreamingScanner(manager: self)
        self.proximeter = StreamingProximeter(manager: self)

        videoCapture.delegate = self
        videoCapture.setUp(sessionPreset: .hd1280x720) { success in
            if success {
                // A hack to "warm up" the speech synthesizer before starting the AVCaptureSession,
                // to prevent frames getting dropped the first time an utterance is declared.
                Speaker.shared.speak(text: " ")
                self.videoCapture.startStream()
            }
        }

        scanner.refreshUserDefaults()
        proximeter.refreshUserDefaults()
    }

    // MARK: Public

    public enum CaptureMode {
        case paused
        case snapshot
        case streaming
    }

    public func takePhoto() {
        captureMode = .snapshot
        videoCapture.capturePhoto()
    }

    public func pause() {
        captureMode = .paused
        videoCapture.stopStream()
    }

    public func resume() {
        captureMode = .streaming
        videoCapture.startStream()
    }

    // MARK: Internal

    let coreMLRequestQueue = DispatchQueue(
        label: "CoreMLRequestQueue",
        attributes: [],
        autoreleaseFrequency: .workItem,
        target: .global()
    )
    let dataPublisherQueue = DispatchQueue(
        label: "DataPublisherQueue",
        attributes: [],
        autoreleaseFrequency: .workItem,
        target: .global()
    )
    let dataPublisher = PassthroughSubject<CapturedData, Never>()

    @Published
    var dataAvailable = false
    @Published
    var captureMode = CaptureMode.streaming

    var segmentationModel = try! DeepLabV3()
    var visionModel: VNCoreMLModel?
    var allObjectsAnnouncer: AllObjectsAnnouncer!
    var announcer: StreamingMainObjectAnnouncer!
    var scanner: StreamingScanner!
    var proximeter: StreamingProximeter!
    var videoCapture: VideoCapture!
    var capturedData: CapturedData

    func videoVisionRequestDidComplete(
        request: VNRequest,
        pixelBuffer: CVPixelBuffer,
        depthData: AVDepthData
    ) {
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
           let segmentationMap = observations.first?.featureValue.multiArrayValue
        {
            let capturedData = CapturedData(
                pixelBuffer: pixelBuffer,
                segmentationMap: segmentationMap,
                depthData: depthData
            )
            dataPublisherQueue.async {
                self.dataPublisher.send(capturedData)
            }
            DispatchQueue.main.async {
                self.capturedData.pixelBuffer = pixelBuffer
                self.capturedData.segmentationMap = segmentationMap
                self.capturedData.depthData = depthData
                if self.dataAvailable == false {
                    self.dataAvailable = true
                }
            }
        }
    }

    func photoVisionRequestDidComplete(
        request: VNRequest,
        pixelBuffer: CVPixelBuffer,
        depthData: AVDepthData
    ) {
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
           let segmentationMap = observations.first?.featureValue.multiArrayValue
        {
            let capturedData = CapturedData(
                pixelBuffer: pixelBuffer,
                segmentationMap: segmentationMap,
                depthData: depthData
            )
            dataPublisherQueue.async { [self] in
                allObjectsAnnouncer.process(capturedData)
            }
            DispatchQueue.main.async {
                self.capturedData.pixelBuffer = pixelBuffer
                self.capturedData.segmentationMap = segmentationMap
                self.capturedData.depthData = depthData
                if self.dataAvailable == false {
                    self.dataAvailable = true
                }
            }
        }
    }

    func videoCapture(
        _: VideoCapture,
        didCaptureVideoPixelBuffer pixelBuffer: CVPixelBuffer,
        didCaptureVideoDepthData depthData: AVDepthData
    ) {
        coreMLRequestQueue.async { [weak self] in
            self?.predictVideo(pixelBuffer: pixelBuffer, depthData: depthData)
        }
    }

    func photoCapture(
        _: VideoCapture,
        didCapturePhotoPixelBuffer pixelBuffer: CVPixelBuffer,
        didCapturePhotoDepthData depthData: AVDepthData,
        didCapturePhotoOrientation orientation: UInt32
    ) {
        coreMLRequestQueue.async { [weak self] in
            self?.predictPhoto(
                pixelBuffer: pixelBuffer,
                depthData: depthData,
                orientation: orientation
            )
        }
    }

    func predictVideo(pixelBuffer: CVPixelBuffer, depthData: AVDepthData) {
        if let visionModel = visionModel {
            let request = VNCoreMLRequest(
                model: visionModel,
                completionHandler: buildVNRequestCompletionHandler(
                    completionHandler: videoVisionRequestDidComplete(
                        request:pixelBuffer:depthData:
                    ),
                    pixelBuffer: pixelBuffer,
                    depthData: depthData
                )
            )
            request.imageCropAndScaleOption = .centerCrop

            // vision framework configures the input size of image following our model's input
            // configuration automatically
            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .right,
                options: [:]
            )
            try? handler.perform([request])
        } else {
            fatalError()
        }
    }

    func predictPhoto(
        pixelBuffer: CVPixelBuffer,
        depthData: AVDepthData,
        orientation: UInt32
    ) {
        if let visionModel = visionModel,
           let orientationValue = CGImagePropertyOrientation(rawValue: orientation)
        {
            let request = VNCoreMLRequest(
                model: visionModel,
                completionHandler: buildVNRequestCompletionHandler(
                    completionHandler: photoVisionRequestDidComplete(
                        request:pixelBuffer:depthData:
                    ),
                    pixelBuffer: pixelBuffer,
                    depthData: depthData.applyingExifOrientation(orientationValue)
                )
            )
            request.imageCropAndScaleOption = .centerCrop

            // vision framework configures the input size of image following our model's input
            // configuration automatically
            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: orientationValue,
                options: [:]
            )
            try? handler.perform([request])
        } else {
            fatalError()
        }
    }

    func buildVNRequestCompletionHandler(
        completionHandler: @escaping (VNRequest, CVPixelBuffer, AVDepthData) -> Void,
        pixelBuffer: CVPixelBuffer,
        depthData: AVDepthData
    ) -> (VNRequest, Error?) -> Void {
        return { request, _ in
            completionHandler(request, pixelBuffer, depthData)
        }
    }

    func connectAnnouncer() {
        dataPublisher.share().throttle(for: 0.2, scheduler: dataPublisherQueue, latest: true)
            .subscribe(announcer)
    }

    func disconnectAnnouncer() {
        announcer.cancel()
        lastMainObjectChange = MainObjectChange(object: nil, time: Date())
    }

    func connectScanner() {
        dataPublisher.share().subscribe(scanner)
    }

    func disconnectScanner() {
        scanner.cancel()
    }

    func connectProximeter() {
        dataPublisher.share().throttle(for: 0.2, scheduler: dataPublisherQueue, latest: true)
            .subscribe(proximeter)
    }

    func disconnectProximeter() {
        proximeter.cancel()
    }
}

// MARK: AVSpeechSynthesizerDelegate

extension CameraManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        if captureMode == .snapshot {
            captureMode = .streaming
            videoCapture.startStream()
        }
    }
}
