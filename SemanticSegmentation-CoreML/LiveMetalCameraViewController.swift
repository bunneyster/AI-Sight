//
//  LiveMetalCameraViewController.swift
//  SemanticSegmentation-CoreML
//
//  Created by Doyoung Gwak on 2020/11/16.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

//Giles10added
//class CustomPressGestureRecognizer: UILongPressGestureRecognizer {
//    //var obj_name: String = ""
//    //var mult_val: Float = 0.0
//    
//    var objs = [String]()
//    var mults = [Float]()
//    var x_vals = [Double]()
//    var objSize = [Double]()
//}

import UIKit
import Vision
import AVFoundation

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

// Intervals of 28728
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

//Giles setting variables for live-view music mode aka "live play" - columns CURRENTLY UNUSED
var liveViewModeActive:Bool = false

var liveViewModeColumns:Int = 1

//Giles setting variables for live-view verbal mode aka "live objects" CURRENTLY UNUSED
var liveViewVerbalModeActive:Int = 1

//Dean live updating of objects
var centerObj=""

//Giles activate long speech mode variable
var longSpeechModeActivate:Int=0

//var rtPersonDetector: AVAudioPlayer!

class LiveMetalCameraViewController: UIViewController, AVSpeechSynthesizerDelegate {
    
    // MARK: - UI Properties
    @IBOutlet weak var metalVideoPreview: MetalVideoView!
    @IBOutlet weak var drawingView: DrawingSegmentationView!
    
    @IBOutlet weak var inferenceLabel: UILabel!
    @IBOutlet weak var etimeLabel: UILabel!
    @IBOutlet weak var fpsLabel: UILabel!
    
    // GILES - Adding UI elements for VoiceOver compatibility Feb 27th 2023
    // Could also add a switch for toggling live view or live music
    @IBOutlet weak var SpeechModeButton: UIButton!
    @IBOutlet weak var MusicModeButton: UIButton!
    
    var cameraTextureGenerater = CameraTextureGenerater()
    var multitargetSegmentationTextureGenerater = MultitargetSegmentationTextureGenerater()
    var overlayingTexturesGenerater = OverlayingTexturesGenerater()
    
    var cameraTexture: Texture?
    var segmentationTexture: Texture?
    
    let synthesizer = AVSpeechSynthesizer() // Speech
    var speechDelayTimer: Timer? // Makes sure that it doesn't speak too fast.
    
    
    // MARK: - AV Properties
    var videoCapture: VideoCapture!
    
    // MARK - Core ML model
    /// DeepLabV3(iOS12+), DeepLabV3FP16(iOS12+), DeepLabV3Int8LUT(iOS12+)
    /// - labels: ["background", "aeroplane", "bicycle", "bird", "boat", "bottle", "bus", "car", "cat", "chair", "cow", "diningtable", "dog", "horse", "motorbike", "person", "pottedplant", "sheep", "sofa", "train", "tv"]
    /// - number of labels: 21
    /// FaceParsing(iOS14+)
    /// - labels:  ["background", "skin", "l_brow", "r_brow", "l_eye", "r_eye", "eye_g", "l_ear", "r_ear", "ear_r", "nose", "mouth", "u_lip", "l_lip", "neck", "neck_l", "cloth", "hair", "hat"]
    /// - number of labels: 19
    lazy var segmentationModel = { return try! DeepLabV3() }()
    let numberOfLabels = 21 // <#if you changed the segmentationModel, you have to change the numberOfLabels#>
    
    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    
    var isInferencing = false
    

    
    // MARK: - Performance Measurement Property
    private let 👨‍🔧 = 📏()
    
    let maf1 = MovingAverageFilter()
    let maf2 = MovingAverageFilter()
    let maf3 = MovingAverageFilter()
    
    // MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup ml model
        setUpModel()
        
        // setup camera
        setUpCamera()
        
        // setup delegate for performance measurement
        // 👨‍🔧.delegate = self
    }
    
    override func didReceiveMemoryWarning() { // override
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) { // override
        super.viewWillAppear(animated)
        self.videoCapture.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) { // override
        super.viewWillDisappear(animated)
        self.videoCapture.stop()
    }
    
    // MARK: - Setup Core ML
    func setUpModel() {
        if let visionModel = try? VNCoreMLModel(for: segmentationModel.model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .centerCrop
        } else {
            fatalError()
        }
    }
    
    // MARK: - Setup camera
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        //Giles5 - change FPS? was 50
        videoCapture.fps = 50
        videoCapture.setUp(sessionPreset: .hd1280x720) { success in
            
            if success {
                // 초기설정이 끝나면 라이브 비디오를 시작할 수 있음
                self.videoCapture.start()
            }
        }
    }
    
    @IBAction func LiveMusicColumnsOn(_ sender: Any) {
        
        if liveViewModeColumns == 0
        {
            liveViewModeColumns = 1
            Swift.print("Live-View Columns Mode On")
        }
        else
        {
            liveViewModeColumns = 0
            Swift.print("Live-View Columns Mode Off")
        }
        
    }
    
    @IBAction func LiveMusicSwitchOn(_ sender: Any) {
        
        if liveViewModeActive == false
        {
            liveViewModeActive = true
            Swift.print("Live-View Mode On")
        }
        else
        {
            liveViewModeActive = false
            Swift.print("Live-View Mode Off")
        }
    }
    
    @IBAction func LiveVerbalSwitchOn(_ sender: Any) {

        if liveViewVerbalModeActive == 0
        {
            liveViewVerbalModeActive = 1
            Swift.print("Live-Objects Verbal Mode On")
        }
        else
        {
            liveViewVerbalModeActive = 0
            Swift.print("Live-Objects Verbal Mode Off")
        }
            
    }
    
    struct Note {
        var node: AVAudioPlayerNode = .init()
        var file: AVAudioFile

        init(file: AVAudioFile, pan: Float = 0.0, volume: Float = 0.0) {
            self.file = file
            self.node.pan = pan
            self.node.volume = volume
        }
    }

    @IBAction
    func musicModeV2ButtonTapped(_: Any) {
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

        if let observations = request?.results as? [VNCoreMLFeatureValueObservation],
           let segmentationmap = observations.first?.featureValue.multiArrayValue
        {
            var melody: [Note] = []

            for column in 0..<10 {
                let pan = -0.9 + Float(column) * 0.2 // [-0.9, 0.9] in increments of 0.2
                let fileDrums = try! AVAudioFile(
                    forReading: Bundle.main.url(forResource: "drum", withExtension: "wav")!
                )
                melody.append(Note(file: fileDrums, pan: pan, volume: 0.5))

                for row in 0..<10 {
                    let pixelIndex = snapshotMusicModePixelOffsets[row] + column * columnWidth
                    let objectId = Int(truncating: segmentationmap[pixelIndex])
                    let fileName = [String(row + 1), objectIdToSound[objectId]].compactMap { $0 }
                        .joined()
                    let file = try! AVAudioFile(
                        forReading: Bundle.main.url(forResource: fileName, withExtension: "wav")!
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
    }

    //Giles added button tap functionality
    @IBAction func speechModeButtonTapped(_ sender: Any) {
//        usleep(1000000)
        longSpeechModeActivate=1
//        usleep(1000000)
//        longSpeechModeActivate=0
    }
    
//    @IBAction func musicModeButtonTapped(_ sender: Any) {
//        print("Function disabled")
//    }
    
}
// MARK: - VideoCaptureDelegate
extension LiveMetalCameraViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoSampleBuffer sampleBuffer: CMSampleBuffer) {
        
        // 카메라 프리뷰 텍스쳐
        cameraTexture = cameraTextureGenerater.texture(from: sampleBuffer)
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        if !isInferencing {
            isInferencing = true

            // start of measure
            self.👨‍🔧.🎬👏()

            // predict!
            predict(with: pixelBuffer)
        }
    }
}

// MARK: - Inference
extension LiveMetalCameraViewController {
    // prediction
    func predict(with pixelBuffer: CVPixelBuffer) {
        guard let request = request else { fatalError() }
        
        // vision framework configures the input size of image following our model's input configuration automatically
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
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

    func objectIdsInColumn(_ column: Int, segmentationMap: MLMultiArray) -> [Int] {
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

    public func visionRequestDidComplete(request: VNRequest, error _: Error?) {
        self.👨‍🔧.🏷(with: "endInference")

        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
           let segmentationmap = observations.first?.featureValue.multiArrayValue
        {
            guard let row = segmentationmap.shape[0] as? Int,
                  let col = segmentationmap.shape[1] as? Int
            else {
                return
            }

            let imageFrameCoordinates = StillImageViewController.getImageFrameCoordinates(
                segmentationmap: segmentationmap,
                row: row,
                col: col
            )

            let d = imageFrameCoordinates.d
            let x = imageFrameCoordinates.x
            let y = imageFrameCoordinates.y

            var objs = [String]()
            var mults = [Float]()
            var x_vals = [Double]()
            var objSizes = [Double]()

            for (k, v) in d {
                if k == 0 {
                    continue
                }

                // Deep exhibit 3
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

            let numObjects = x_vals.count
            print(numObjects)
            if numObjects == 0 {
                centerObj = ""
            } else if numObjects > 0 {
                let med = x_vals.sorted(by: <)[numObjects / 2]
                var med_ind = 0
                for i in 0...(numObjects - 1) {
                    if x_vals[i] == med {
                        med_ind = i
                    }
                }
                if liveViewVerbalModeActive == 1 {
                    if objs[med_ind] != centerObj, objSizes[med_ind] >= 0.1 {
                        StillImageViewController.speak(text: objs[med_ind])
                        centerObj = objs[med_ind]
                    }
                    print(centerObj)
                } else {
                    centerObj = ""
                }
            }

            if longSpeechModeActivate == 1 {
                usleep(1_500_000)

                if objs.isEmpty {
                    StillImageViewController.speak(text: "No Objects Identified")
                } else {
                    let ignoredObjects: Set = ["aeroplane", "sheep", "cow", "horse"]
                    var sorted = x_vals.enumerated().sorted(by: { $0.element < $1.element })
                    for (i, e) in sorted {
                        let obj = objs[i]
                        if ignoredObjects.contains(obj) {
                            continue
                        }
                        if obj != "bottle", objSizes[i] <= 0.02 {
                            continue
                        }
                        let mult = mults[i]
                        let x_value = x_vals[i]
                        StillImageViewController.speak(
                            objectName: obj,
                            multiplier: mult,
                            posValue: x_value
                        )
                        print("The mult value is \(mult)")
                    }
                }
                longSpeechModeActivate = 0
                usleep(1_000_000)
            }

            print(
                "DATA MANAGER is reporting \(DataManager.shared.sharedDistanceAtXYPoint)"
            )
            for (i, point) in DataManager.shared.depthPoints.enumerated() {
                print("Depth Value \(i + 1) \(point)")
            }

            var columnIntensities: [Float] = []
            for column in 0..<numColumns {
                let intensity = LiveMetalCameraViewController
                    .intensityForDepth(depth: DataManager.shared.depthPoints[column])
                columnIntensities.append(intensity)
                print("Intensity \(column + 1) is \(intensity)")
            }

//            var intensity: Float = 1
//            var localSharedDistanceAtXYPoint: Float = DataManager.shared.sharedDistanceAtXYPoint
//            if localSharedDistanceAtXYPoint >= 3 {
//                intensity = 0
//            } else {
//                intensity = 1 - (localSharedDistanceAtXYPoint / 3)
//                intensity = intensity * intensity
//            }

            if liveViewModeActive == true {
                if let observations = request.results as? [VNCoreMLFeatureValueObservation],
                   let segmentationmap = observations.first?.featureValue.multiArrayValue
                {
                    var columnModes = [Int]()
                    for column in 0..<numColumns {
                        let mode = LiveMetalCameraViewController.mode(objectIdsInColumn(
                            column,
                            segmentationMap: segmentationmap
                        )) ?? 0
                        columnModes.append(mode)
                        print("Mode value \(column + 1) is \(mode)")
                    }

                    let liveEngine = AVAudioEngine()

                    var melody: [Note] = []
                    var columnObjectIds: [Int] = []
                    var columnVolumes: [Float] = []
                    for column in 0..<numColumns {
                        let objectId = liveViewModeColumns == 1 ? columnModes[column] :
                            Int(truncating: segmentationmap[
                                liveMusicModePixelOffset + column * columnWidth
                            ])
                        print(objectId)
                        columnObjectIds.append(objectId)

                        columnVolumes
                            .append(liveViewModeColumns == 1 ? 1.0 : columnIntensities[column])

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
            }

            guard let cameraTexture = cameraTexture,
                  let segmentationTexture = multitargetSegmentationTextureGenerater.texture(
                      segmentationmap,
                      row,
                      col,
                      numberOfLabels
                  )
            else {
                return
            }
            let overlayedTexture = overlayingTexturesGenerater.texture(
                cameraTexture,
                segmentationTexture
            )
            metalVideoPreview.currentTexture = overlayedTexture

            DispatchQueue.main.async { [weak self] in
                self?.👨‍🔧.🎬🤚()
                self?.isInferencing = false
            }
        } else {
            // end of measure
            self.👨‍🔧.🎬🤚()
            isInferencing = false
        }
    }
}

// MARK: - 📏(Performance Measurement) Delegate

extension LiveMetalCameraViewController: 📏Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int, objectIndex: Int) {
     

        self.maf1.append(element: Int(inferenceTime*1000.0))
        self.maf2.append(element: Int(executionTime*1000.0))
        self.maf3.append(element: fps)
        
        self.inferenceLabel.text = "inference: \(self.maf1.averageValue) ms"
        self.etimeLabel.text = "execution: \(self.maf2.averageValue) ms"
        self.fpsLabel.text = "fps: \(self.maf3.averageValue)"
    }
}
