//
//  LiveMetalCameraViewController.swift
//  SemanticSegmentation-CoreML
//
//  Created by Doyoung Gwak on 2020/11/16.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import AVFoundation
import Combine
import OSLog
import UIKit
import Vision

let numColumns = 10
let columnWidth = 56

let labels = [
    "background",
    "aeroplane",
    "bicycle",
    "bird",
    "boat",
    "bottle",
    "bus",
    "car",
    "cat",
    "chair",
    "cow",
    "table",
    "dog",
    "horse",
    "motorbike",
    "person",
    "plant",
    "sheep",
    "sofa",
    "train",
    "tv",
]

let objectIdToSound = [
    0: "", // Background
    1: "trumpet", // Aeroplane
    2: "trumpet", // Bicycle
    3: "bird", // Bird
    4: "", // Boat
    5: "bottle", // Bottle
    6: "trumpet", // Bus
    7: "trumpet", // Car
    8: "cat", // Cat
    9: "chair", // Chair
    10: "", // Cow
    11: "chair", // Dining table
    12: "cat", // Dog
    13: "", // Horse
    14: "trumpet", // Motorbike
    15: "piano", // Person
    16: "", // Potted plant
    17: "", // Sheep
    18: "chair", // Sofa
    19: "trumpet", // Train
    20: "breath", // TV
]

/// Intervals of 28728
let snapshotMusicModePixelOffsets = [
    2056,
    30784,
    59512,
    88240,
    116_968,
    145_696,
    174_424,
    203_152,
    231_880,
    260_608,
]

let liveMusicModePixelOffset = 131_332

var liveViewModeActive: Bool = false

var liveViewModeColumns: Int = 1

var liveViewVerbalModeActive: Int = 1

// MARK: - CaptureMode

enum CaptureMode {
    case snapshotMusic
    case snapshotSpeech
    case streaming
}

var captureMode = CaptureMode.streaming

// MARK: - LiveMetalCameraViewController

class LiveMetalCameraViewController: UIViewController {
    // MARK: - UI Properties

    @IBOutlet
    var metalVideoPreview: MetalVideoView!
    @IBOutlet
    var drawingView: DrawingSegmentationView!

    @IBOutlet
    var inferenceLabel: UILabel!
    @IBOutlet
    var etimeLabel: UILabel!
    @IBOutlet
    var fpsLabel: UILabel!

    @IBOutlet
    var SpeechModeButton: UIButton!
    @IBOutlet
    var MusicModeButton: UIButton!

    var cameraTextureGenerater = CameraTextureGenerater()
    var multitargetSegmentationTextureGenerater = MultitargetSegmentationTextureGenerater()
    var overlayingTexturesGenerater = OverlayingTexturesGenerater()

    var cameraTexture: Texture?
    var segmentationTexture: Texture?

    // MARK: - AV Properties

    var videoCapture: VideoCapture!

    /// MARK: - Core ML model
    /// DeepLabV3(iOS12+), DeepLabV3FP16(iOS12+), DeepLabV3Int8LUT(iOS12+)
    /// - labels: ["background", "aeroplane", "bicycle", "bird", "boat", "bottle", "bus", "car",
    /// "cat", "chair", "cow", "diningtable", "dog", "horse", "motorbike", "person", "pottedplant",
    /// "sheep", "sofa", "train", "tv"]
    /// - number of labels: 21
    /// FaceParsing(iOS14+)
    /// - labels:  ["background", "skin", "l_brow", "r_brow", "l_eye", "r_eye", "eye_g", "l_ear",
    /// "r_ear", "ear_r", "nose", "mouth", "u_lip", "l_lip", "neck", "neck_l", "cloth", "hair",
    /// "hat"]
    /// - number of labels: 19
    lazy var segmentationModel = try! DeepLabV3()
    let numberOfLabels =
        21 // <#if you changed the segmentationModel, you have to change the numberOfLabels#>

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

    let streamingPublisher = PassthroughSubject<CapturedData, Never>()
    let snapshotMusicPublisher = PassthroughSubject<CapturedData, Never>()
    let snapshotSpeechPublisher = PassthroughSubject<CapturedData, Never>()

    // MARK: - Vision Properties

    var visionModel: VNCoreMLModel?

    let maf1 = MovingAverageFilter()
    let maf2 = MovingAverageFilter()
    let maf3 = MovingAverageFilter()

    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpModel()
        setUpCamera()
        setUpNotifications()
    }

    override func didReceiveMemoryWarning() { // override
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) { // override
        super.viewWillAppear(animated)
        videoCapture.start()
    }

    override func viewWillDisappear(_ animated: Bool) { // override
        super.viewWillDisappear(animated)
        videoCapture.stop()
    }

    // MARK: - Setup Core ML

    func setUpModel() {
        if let visionModel = try? VNCoreMLModel(for: segmentationModel.model) {
            self.visionModel = visionModel
        } else {
            fatalError()
        }
    }

    // MARK: - Setup camera

    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 50
        videoCapture.setUp(sessionPreset: .hd1280x720) { success in
            if success {
                // A hack to "warm up" the speech synthesizer before starting the AVCaptureSession,
                // to prevent frames getting dropped the first time an utterance is declared.
                Speaker.shared.speak(text: " ")
                self.videoCapture.start()
            }
        }
    }

    // MARK: - Setup notifications

    func setUpNotifications() {
        streamingPublisher
            .throttle(for: 0.2, scheduler: dataPublisherQueue, latest: true)
            .subscribe(StreamingCompletionHandler())
        snapshotMusicPublisher
            .throttle(for: 0.5, scheduler: dataPublisherQueue, latest: true)
            .subscribe(SnapshotMusicCompletionHandler())
        snapshotSpeechPublisher
            .throttle(for: 0.5, scheduler: dataPublisherQueue, latest: true)
            .subscribe(SnapshotSpeechCompletionHandler())
    }

    @IBAction
    func LiveMusicColumnsOn(_: Any) {
        if liveViewModeColumns == 0 {
            liveViewModeColumns = 1
            Swift.print("Live-View Columns Mode On")
        } else {
            liveViewModeColumns = 0
            Swift.print("Live-View Columns Mode Off")
        }
    }

    @IBAction
    func LiveMusicSwitchOn(_: Any) {
        if liveViewModeActive == false {
            liveViewModeActive = true
            Swift.print("Live-View Mode On")
        } else {
            liveViewModeActive = false
            Swift.print("Live-View Mode Off")
        }
    }

    @IBAction
    func LiveVerbalSwitchOn(_: Any) {
        if liveViewVerbalModeActive == 0 {
            liveViewVerbalModeActive = 1
            Swift.print("Live-Objects Verbal Mode On")
        } else {
            liveViewVerbalModeActive = 0
            lastMainObjectChange = MainObjectChange(object: nil, time: Date())
            Swift.print("Live-Objects Verbal Mode Off")
        }
    }

    @IBAction
    func musicModeV2ButtonTapped(_: Any) {
        captureMode = CaptureMode.snapshotMusic
        Speaker.shared.stop()
        videoCapture.capturePhoto()
    }

    @IBAction
    func speechModeButtonTapped(_: Any) {
        captureMode = CaptureMode.snapshotSpeech
        Speaker.shared.stop()
        videoCapture.capturePhoto()
    }
}

// MARK: VideoCaptureDelegate

extension LiveMetalCameraViewController: VideoCaptureDelegate {
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
                    depthData: depthData
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

    public func videoVisionRequestDidComplete(
        request: VNRequest,
        pixelBuffer: CVPixelBuffer,
        depthData: AVDepthData
    ) {
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
           let segmentationMap = observations.first?.featureValue.multiArrayValue
        {
            let completionHandler = DispatchWorkItem {
                let capturedData = CapturedData(
                    segmentationMap: segmentationMap,
                    videoBufferHeight: CVPixelBufferGetHeight(pixelBuffer),
                    videoBufferWidth: CVPixelBufferGetWidth(pixelBuffer),
                    depthData: depthData
                )
                self.streamingPublisher.send(capturedData)
            }
            dataPublisherQueue.async(execute: completionHandler)

            render(pixelBuffer: pixelBuffer, segmentationMap: segmentationMap)
        }
    }

    public func photoVisionRequestDidComplete(
        request: VNRequest,
        pixelBuffer: CVPixelBuffer,
        depthData: AVDepthData
    ) {
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
           let segmentationMap = observations.first?.featureValue.multiArrayValue
        {
            let completionHandler = DispatchWorkItem {
                let capturedData = CapturedData(
                    segmentationMap: segmentationMap,
                    videoBufferHeight: CVPixelBufferGetHeight(pixelBuffer),
                    videoBufferWidth: CVPixelBufferGetWidth(pixelBuffer),
                    depthData: depthData
                )
                switch captureMode {
                case .snapshotMusic:
                    self.snapshotMusicPublisher.send(capturedData)
                case .snapshotSpeech:
                    self.snapshotSpeechPublisher.send(capturedData)
                case .streaming:
                    break
                }
                captureMode = CaptureMode.streaming
            }
            completionHandler.notify(queue: dataPublisherQueue) {
                self.videoCapture.start()
            }
            dataPublisherQueue.async(execute: completionHandler)

            render(pixelBuffer: pixelBuffer, segmentationMap: segmentationMap)
        }
    }

    public func render(pixelBuffer: CVPixelBuffer, segmentationMap: MLMultiArray) {
        guard let cameraTexture = cameraTextureGenerater.texture(
            from: pixelBuffer,
            pixelFormat: .bgra8Unorm
        ),
            let segmentationTexture = multitargetSegmentationTextureGenerater.texture(
                segmentationMap,
                numberOfLabels
            )
        else {
            return
        }
        let overlayedTexture = overlayingTexturesGenerater.texture(
            cameraTexture,
            segmentationTexture
        )

        DispatchQueue.main.async { [weak self] in
            self?.metalVideoPreview.currentTexture = overlayedTexture
        }
    }
}

// MARK: 📏Delegate

extension LiveMetalCameraViewController: 📏Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int, objectIndex _: Int) {
        maf1.append(element: Int(inferenceTime * 1000.0))
        maf2.append(element: Int(executionTime * 1000.0))
        maf3.append(element: fps)

        inferenceLabel.text = "inference: \(maf1.averageValue) ms"
        etimeLabel.text = "execution: \(maf2.averageValue) ms"
        fpsLabel.text = "fps: \(maf3.averageValue)"
    }
}
