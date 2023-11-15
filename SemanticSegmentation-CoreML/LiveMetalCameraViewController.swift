//
//  LiveMetalCameraViewController.swift
//  SemanticSegmentation-CoreML
//
//  Created by Doyoung Gwak on 2020/11/16.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import AVFoundation
import UIKit
import Vision

let numColumns = 10
let columnWidth = 56

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

/// The last object to be announced in the center of the frame.
var lastCenterObject = ""

// MARK: - LiveMetalCameraViewController

class LiveMetalCameraViewController: UIViewController {
    // MARK: Internal

    struct Note {
        // MARK: Lifecycle

        init(file: AVAudioFile, pan: Float = 0.0, volume: Float = 0.0) {
            self.file = file
            node.pan = pan
            node.volume = volume
        }

        // MARK: Internal

        var node: AVAudioPlayerNode = .init()
        var file: AVAudioFile
    }

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

    var speaker: Speaker!

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

    let dataProcessingQueue = DispatchQueue(
        label: "DataProcessingQueue",
        attributes: [],
        autoreleaseFrequency: .workItem,
        target: .global()
    )
    let compositionQueue = DispatchQueue(
        label: "CompositionQueue",
        attributes: [],
        autoreleaseFrequency: .workItem,
        target: .global()
    )

    var isComposing = false
    var buttonActivated = false

    // MARK: - Vision Properties

    var lastSegmentationMap: MLMultiArray?
    var visionModel: VNCoreMLModel?

    var isInferencing = false

    let maf1 = MovingAverageFilter()
    let maf2 = MovingAverageFilter()
    let maf3 = MovingAverageFilter()

    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpModel()
        setUpCamera()
        setUpSpeech()
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
                // 초기설정이 끝나면 라이브 비디오를 시작할 수 있음
                self.videoCapture.start()
            }
        }
    }

    // MARK: - Setup speech

    func setUpSpeech() {
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        speaker = Speaker(synthesizer: synthesizer)
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
            lastCenterObject = ""
            Swift.print("Live-Objects Verbal Mode Off")
        }
    }

    @IBAction
    func musicModeV2ButtonTapped(_: Any) {
        buttonActivated = true
        compositionQueue.async { [weak self] in
            self?.isComposing = true

            let engine = AVAudioEngine()

            let shutterNode = AVAudioPlayerNode()
            let shutterFile = try! AVAudioFile(
                forReading: Bundle.main.url(forResource: "Shutter", withExtension: "mp3")!
            )
            engine.attach(shutterNode)
            engine.connect(
                shutterNode,
                to: engine.mainMixerNode,
                format: shutterFile.processingFormat
            )
            engine.prepare()

            shutterNode.scheduleFile(shutterFile, at: nil, completionHandler: nil)
            try! engine.start()
            shutterNode.play()
            usleep(1_000_000)

            if let segmentationMap = self?.lastSegmentationMap {
                var melody: [Note] = []

                for column in 0..<10 {
                    let pan = -0.9 + Float(column) * 0.2 // [-0.9, 0.9] in increments of 0.2
                    let fileDrums = try! AVAudioFile(
                        forReading: Bundle.main.url(forResource: "drum", withExtension: "wav")!
                    )
                    melody.append(Note(file: fileDrums, pan: pan, volume: 0.5))

                    for row in 0..<10 {
                        let pixelIndex = snapshotMusicModePixelOffsets[row] + column * columnWidth
                        let objectId = Int(truncating: segmentationMap[pixelIndex])
                        let fileName = [String(row + 1), objectIdToSound[objectId]]
                            .compactMap { $0 }
                            .joined()
                        let file = try! AVAudioFile(
                            forReading: Bundle.main.url(
                                forResource: fileName,
                                withExtension: "wav"
                            )!
                        )
                        melody.append(Note(
                            file: file,
                            pan: pan,
                            volume: Float(objectId >= 1 ? 1.0 : 0.0)
                        ))
                    }

                    for note in melody {
                        engine.attach(note.node)
                        engine.connect(
                            note.node,
                            to: engine.mainMixerNode,
                            format: note.file.processingFormat
                        )
                        note.node.scheduleFile(note.file, at: nil, completionHandler: nil)
                    }

                    for note in melody {
                        note.node.play()
                        usleep(1000)
                    }

                    melody = []
                    usleep(500_000)
                }
            }
            self?.isComposing = false
        }
        buttonActivated = false
    }

    @IBAction
    func speechModeButtonTapped(_: Any) {
        if let segmentationMap = lastSegmentationMap {
            buttonActivated = true
            compositionQueue.async { [weak self] in
                self?.isComposing = true
                usleep(1_500_000)

                var objs = [String]()
                var mults = [Float]()
                var x_vals = [Double]()
                var objSizes = [Double]()
                (objs, mults, x_vals, objSizes) = LiveMetalCameraViewController
                    .processSegmentationMap(segmentationMap: segmentationMap)

                if objs.isEmpty {
                    self?.speaker.speak(text: "No Objects Identified")
                } else {
                    let ignoredObjects: Set = ["aeroplane", "sheep", "cow", "horse"]
                    let sorted = x_vals.enumerated().sorted(by: { $0.element < $1.element })
                    for (i, _) in sorted {
                        let obj = objs[i]
                        if ignoredObjects.contains(obj) {
                            continue
                        }
                        if obj != "bottle", objSizes[i] <= 0.02 {
                            continue
                        }
                        let mult = mults[i]
                        let x_value = x_vals[i]
                        self?.speaker.speak(
                            objectName: obj,
                            multiplier: mult,
                            posValue: x_value
                        )
                        print("The mult value is \(mult)")
                    }
                }

                usleep(1_000_000)
            }
        }
    }

    // MARK: Private

    // MARK: - Performance Measurement Property

    private let 👨‍🔧 = 📏()
}

// MARK: - LiveMetalCameraViewController + AVSpeechSynthesizerDelegate

extension LiveMetalCameraViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        // FIXME: This callback seems to get triggered before the utterance actually finishes, so
        // any live mode sounds will resume and overlap with the end of a long utterance.
        if buttonActivated == true {
            buttonActivated = false
            isComposing = false
        }
    }
}

// MARK: - LiveMetalCameraViewController + VideoCaptureDelegate

extension LiveMetalCameraViewController: VideoCaptureDelegate {
    func videoCapture(
        _: VideoCapture,
        didCaptureVideoPixelBuffer pixelBuffer: CVPixelBuffer,
        didCaptureVideoDepthData depthData: AVDepthData
    ) {
        dataProcessingQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }

            if !strongSelf.isInferencing {
                strongSelf.isInferencing = true

                // start of measure
                strongSelf.👨‍🔧.🎬👏()

                // predict!
                strongSelf.predict(pixelBuffer: pixelBuffer, depthData: depthData)
            }
        }
    }
}

// MARK: - Inference

extension LiveMetalCameraViewController {
    func predict(pixelBuffer: CVPixelBuffer, depthData: AVDepthData) {
        if let visionModel = visionModel {
            let request = VNCoreMLRequest(
                model: visionModel,
                completionHandler: buildVNRequestCompletionHandler(
                    completionHandler: visionRequestDidComplete(request:pixelBuffer:depthData:),
                    pixelBuffer: pixelBuffer,
                    depthData: depthData
                )
            )
            request.imageCropAndScaleOption = .centerCrop

            // vision framework configures the input size of image following our model's input
            // configuration automatically
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([request])
        } else {
            fatalError()
        }
    }

    static func computeDepthPoints(depthData: AVDepthData) -> [Float] {
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

        CVPixelBufferUnlockBaseAddress(depthDataMap, CVPixelBufferLockFlags(rawValue: 0))

        var depthPoints = Array(repeating: Float(0), count: 10)
        for i in 0..<10 {
            depthPoints[i] = floatBuffer[28804 + i * 19]
        }
        return depthPoints
    }

    static func intensityForDepth(depth: Float) -> Float {
        if depth <= 1.2 {
            return 1
        } else if depth <= 2.2 {
            return 0.2
        } else {
            return 0.05
        }
    }

    static func mode(_ array: [Int]) -> (Int)? {
        let countedSet = NSCountedSet(array: array)
        var counts = [(value: Int, count: Int)]()
        var totalCount = 0

        for value in countedSet {
            let count = countedSet.count(for: value)
            if let intValue = value as? Int, intValue != 0 {
                counts.append((intValue, count))
                totalCount += count
            } else if let _ = value as? Int {
                totalCount += count
            }
        }

        counts.sort { $0.count > $1.count }
        var returnValue = 0

        if let mode = counts.first {
            let modeValue = mode.value
            let modeValueInt: Int = modeValue

            let modeCount = Double(mode.count)
            let modePercentage = modeCount / Double(totalCount) * 100
            if modePercentage > 5 {
                returnValue = modeValueInt
            } else {
                returnValue = 0
            }
        }
        return returnValue
    }

    static func objectIdsInColumn(_ column: Int, segmentationMap: MLMultiArray) -> [Int] {
        var objectIds = [Int]()
        let firstPixel = column * 51
        for row in 0..<513 {
            for col in firstPixel..<(firstPixel + 50) {
                let id = segmentationMap[[row, col] as [NSNumber]].intValue
                objectIds.append(id)
            }
        }
        return objectIds
    }

    static func processSegmentationMap(segmentationMap: MLMultiArray)
        -> ([String], [Float], [Double], [Double])
    {
        var objs = [String]()
        var mults = [Float]()
        var x_vals = [Double]()
        var objSizes = [Double]()

        guard let row = segmentationMap.shape[0] as? Int,
              let col = segmentationMap.shape[1] as? Int
        else {
            return (objs, mults, x_vals, objSizes)
        }

        let imageFrameCoordinates = StillImageViewController.getImageFrameCoordinates(
            segmentationmap: segmentationMap,
            row: row,
            col: col
        )

        let o = imageFrameCoordinates.o
        let x = imageFrameCoordinates.x
        let y = imageFrameCoordinates.y

        for (k, v) in o {
            if k == 0 {
                continue
            }

            let objectAndPitchMultiplier = StillImageViewController.getObjectAndPitchMultiplier(
                k: k,
                v: v,
                x: x,
                y: y,
                row: row,
                col: col
            )
            let obj = objectAndPitchMultiplier.obj
            let mult_val = objectAndPitchMultiplier.mult_val
            let x_val = objectAndPitchMultiplier.xValue
            let objSize = objectAndPitchMultiplier.sizes

            objs.append(obj)
            mults.append(mult_val)
            x_vals.append(x_val)
            objSizes.append(objSize)
        }

        return (objs, mults, x_vals, objSizes)
    }

    static func computeCenterObject(
        objs: [String],
        x_vals: [Double],
        objSizes: [Double],
        threshold: Double
    )
        -> String
    {
        let numObjects = x_vals.count
        if numObjects == 0 {
            return ""
        }
        let med = x_vals.sorted(by: <)[numObjects / 2]
        var med_ind = 0
        for i in 0...(numObjects - 1) {
            if x_vals[i] == med {
                med_ind = i
            }
        }
        return objSizes[med_ind] >= threshold ? objs[med_ind] : ""
    }

    static func composeLiveMusic(
        segmentationMap: MLMultiArray,
        depthPoints: [Float]
    ) -> [Note] {
        var columnModes = [Int]()
        for column in 0..<numColumns {
            let mode = LiveMetalCameraViewController.mode(objectIdsInColumn(
                column,
                segmentationMap: segmentationMap
            )) ?? 0
            columnModes.append(mode)
            print("Mode value \(column + 1) is \(mode)")
        }

        var melody: [Note] = []
        var columnObjectIds: [Int] = []
        var columnVolumes: [Float] = []
        for column in 0..<numColumns {
            let objectId = liveViewModeColumns == 1 ? columnModes[column] :
                Int(truncating: segmentationMap[
                    liveMusicModePixelOffset + column * columnWidth
                ])
            print(objectId)
            columnObjectIds.append(objectId)

            let intensity = LiveMetalCameraViewController
                .intensityForDepth(depth: depthPoints[column])
            columnVolumes
                .append(liveViewModeColumns == 1 ? 1.0 : intensity)

            let fileName = [String(column + 1), objectIdToSound[objectId]]
                .compactMap { $0 }
                .joined()
            let file = try! AVAudioFile(
                forReading: Bundle.main.url(
                    forResource: fileName,
                    withExtension: "wav"
                )!
            )
            melody.append(Note(
                file: file,
                pan: -0.9 + Float(column) * 0.2,
                volume: Float(objectId >= 1 ? columnVolumes[column] : 0.0)
            ))
        }
        return melody
    }

    static func playMusic(melody: [Note]) {
        let liveEngine = AVAudioEngine()

        for note in melody {
            liveEngine.attach(note.node)
            liveEngine.connect(
                note.node,
                to: liveEngine.mainMixerNode,
                format: note.file.processingFormat
            )
        }

        for (column, note) in melody.enumerated() {
            let delayTime = AVAudioTime(
                sampleTime: AVAudioFramePosition(44100 * Float(column) * 0.007),
                atRate: note.file.processingFormat.sampleRate
            )
            note.node.scheduleFile(note.file, at: delayTime, completionHandler: nil)
        }

        liveEngine.prepare()
        try! liveEngine.start()

        for note in melody {
            note.node.play()
        }
        usleep(500_000)

        try! liveEngine.stop()
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

    public func visionRequestDidComplete(
        request: VNRequest,
        pixelBuffer: CVPixelBuffer,
        depthData: AVDepthData
    ) {
        👨‍🔧.🏷(with: "endInference")

        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
           let segmentationMap = observations.first?.featureValue.multiArrayValue
        {
            lastSegmentationMap = segmentationMap

            // Video data is captured faster than it takes to compose the sound for a single output,
            // so composition can be skipped for data that is captured while a composition is
            // already in progress.
            if !isComposing && !buttonActivated {
                isComposing = true
                compositionQueue.async { [weak self] in
                    var objs = [String]()
                    _ = [Float]()
                    var x_vals = [Double]()
                    var objSizes = [Double]()
                    (objs, _, x_vals, objSizes) = LiveMetalCameraViewController
                        .processSegmentationMap(segmentationMap: segmentationMap)

                    if liveViewVerbalModeActive == 1 {
                        let centerObject = LiveMetalCameraViewController.computeCenterObject(
                            objs: objs,
                            x_vals: x_vals,
                            objSizes: objSizes,
                            threshold: 0.1
                        )
                        if centerObject != lastCenterObject {
                            self?.speaker.speak(text: centerObject)
                            lastCenterObject = centerObject
                        }
                    }

                    if liveViewModeActive == true {
                        let depthPoints = LiveMetalCameraViewController
                            .computeDepthPoints(depthData: depthData)
                        let melody = LiveMetalCameraViewController.composeLiveMusic(
                            segmentationMap: segmentationMap,
                            depthPoints: depthPoints
                        )

                        LiveMetalCameraViewController.playMusic(melody: melody)
                    }
                    self?.isComposing = false
                }
            }

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
                self?.👨‍🔧.🎬🤚()
                self?.isInferencing = false
            }
        } else {
            // end of measure
            👨‍🔧.🎬🤚()
            isInferencing = false
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
