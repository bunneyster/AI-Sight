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

class CameraManager: ObservableObject, VideoCaptureDelegate {
    // MARK: Lifecycle

    init() {
        self.capturedData = CapturedData()

        if let visionModel = try? VNCoreMLModel(for: segmentationModel.model) {
            self.visionModel = visionModel
        } else {
            fatalError()
        }

        self.videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.setUp(sessionPreset: .hd1280x720) { success in
            if success {
                // A hack to "warm up" the speech synthesizer before starting the AVCaptureSession,
                // to prevent frames getting dropped the first time an utterance is declared.
                Speaker.shared.speak(text: " ")
                self.videoCapture.start()
            }
        }

        scanner.refreshUserDefaults()
        proximitySensor.refreshUserDefaults()

        if UserDefaults.standard.bool(forKey: "announcer") {
            startAnnouncer()
        }
        if UserDefaults.standard.bool(forKey: "scanner") {
            startScanner()
        }
        if UserDefaults.standard.string(forKey: "objectProximity") != "None" {
            startObjectProximity()
        }
    }

    // MARK: Public

    public func takePhoto() {
        captureMode = CaptureMode.snapshot
        Speaker.shared.stop()
        videoCapture.capturePhoto()
    }

    // MARK: Internal

    enum CaptureMode {
        case snapshot
        case streaming
    }

    var captureMode = CaptureMode.streaming

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
    let announcer = StreamingMainObjectAnnouncer()
    let scanner = StreamingScanner()
    let proximitySensor = StreamingProximitySensor()

    @Published
    var dataAvailable = false

    var segmentationModel = try! DeepLabV3()
    var visionModel: VNCoreMLModel?
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
            // Dimensions are flipped because default camera orientation is landscape.
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
            // Dimensions are flipped because default camera orientation is landscape.
            let capturedData = CapturedData(
                pixelBuffer: pixelBuffer,
                segmentationMap: segmentationMap,
                depthData: depthData
            )
            let completionHandler = DispatchWorkItem { [self] in
                if captureMode == .snapshot {
                    AllObjectsAnnouncer().process(capturedData)
                }
                captureMode = CaptureMode.streaming
            }
            completionHandler.notify(queue: dataPublisherQueue) {
                self.videoCapture.start()
            }
            dataPublisherQueue.async(execute: completionHandler)
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

    func startAnnouncer() {
        dataPublisher.share().throttle(for: 0.2, scheduler: dataPublisherQueue, latest: true)
            .subscribe(announcer)
    }

    func shutDownAnnouncer() {
        announcer.cancel()
        lastMainObjectChange = MainObjectChange(object: nil, time: Date())
    }

    func startScanner() {
        dataPublisher.share().subscribe(scanner)
    }

    func shutDownScanner() {
        scanner.cancel()
    }

    func startObjectProximity() {
        dataPublisher.share().throttle(for: 0.2, scheduler: dataPublisherQueue, latest: true)
            .subscribe(proximitySensor)
    }

    func shutDownObjectProximity() {
        proximitySensor.cancel()
    }
}
