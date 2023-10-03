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

let pixelOffsets = [
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

var mode1: Double = 0.0
var mode2: Double = 0.0
var mode3: Double = 0.0
var mode4: Double = 0.0
var mode5: Double = 0.0
var mode6: Double = 0.0
var mode7: Double = 0.0
var mode8: Double = 0.0
var mode9: Double = 0.0
var mode10: Double = 0.0

var liveSound1str:String! = "1"
var liveSound1pan:Float! = 0.0
var liveSound1vol:Float! = 0.0
var liveSound1obj:Int! = 1

var liveSound2str:String! = "2"
var liveSound2pan:Float! = 0.0
var liveSound2vol:Float! = 0.0
var liveSound2obj:Int! = 1

var liveSound3str:String! = "3"
var liveSound3pan:Float! = 0.0
var liveSound3vol:Float! = 0.0
var liveSound3obj:Int! = 1

var liveSound4str:String! = "4"
var liveSound4pan:Float! = 0.0
var liveSound4vol:Float! = 0.0
var liveSound4obj:Int! = 1

var liveSound5str:String! = "5"
var liveSound5pan:Float! = 0.0
var liveSound5vol:Float! = 0.0
var liveSound5obj:Int! = 1

var liveSound6str:String! = "6"
var liveSound6pan:Float! = 0.0
var liveSound6vol:Float! = 0.0
var liveSound6obj:Int! = 1

var liveSound7str:String! = "7"
var liveSound7pan:Float! = 0.0
var liveSound7vol:Float! = 0.0
var liveSound7obj:Int! = 1

var liveSound8str:String! = "8"
var liveSound8pan:Float! = 0.0
var liveSound8vol:Float! = 0.0
var liveSound8obj:Int! = 1

var liveSound9str:String! = "9"
var liveSound9pan:Float! = 0.0
var liveSound9vol:Float! = 0.0
var liveSound9obj:Int! = 1

var liveSound10str:String! = "10"
var liveSound10pan:Float! = 0.0
var liveSound10vol:Float! = 0.0
var liveSound10obj:Int! = 1

//var rtPersonDetectorStr:String! = "5piano"
//var rtPersonDetectorPan:Float! = 0.0
//var rtPersonDetectorVol:Float! = 0.0

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
                    let pixelIndex = pixelOffsets[row] + column * columnWidth
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
    
    // post-processing
    // add to still image
    public func visionRequestDidComplete(request: VNRequest, error: Error?) {
        self.👨‍🔧.🏷(with: "endInference")
        
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
           let segmentationmap = observations.first?.featureValue.multiArrayValue {
            guard let row = segmentationmap.shape[0] as? Int,
                  let col = segmentationmap.shape[1] as? Int else {
                return
            }
            
            guard let cameraTexture = cameraTexture,
                  let segmentationTexture = multitargetSegmentationTextureGenerater.texture(segmentationmap, row, col, numberOfLabels) else {
                return
            }
            
            let imageFrameCoordinates = StillImageViewController.getImageFrameCoordinates(segmentationmap: segmentationmap, row: row, col: col)
            
            let d = imageFrameCoordinates.d
            let x = imageFrameCoordinates.x
            let y = imageFrameCoordinates.y
            // Giles 2a commenting out
            //            print("any value",terminator: Array(repeating: "\n", count: 100).joined())
            
            var objs = [String]()
            var mults = [Float]()
            var x_vals = [Double]()
            var objSizes = [Double]()
            
            //Dean live updating of objects
            let objects=["background", "aeroplane", "bicycle", "bird", "boat", "bottle", "bus", "car", "cat", "chair", "cow", "table", "dog", "horse", "motorbike", "person", "plant", "sheep", "sofa", "train", "tv"]
            
            
            for (k,v) in d {
                if (k==0) {
                    continue
                }
                
                // Deep exhibit 3
                let objectAndPitchMultiplier = StillImageViewController.getObjectAndPitchMultiplier(k:k, v:v, x:x, y:y, row: row, col: col)
                let obj = objectAndPitchMultiplier.obj
                let mult_val = objectAndPitchMultiplier.mult_val
                let x_val = objectAndPitchMultiplier.xValue
                let objSize = objectAndPitchMultiplier.sizes
                
                
                objs.append(obj)
                mults.append(mult_val)
                x_vals.append(x_val)
                objSizes.append(objSize)
                
                
            }
            
            print("DATA MANAGER is reporting \(DataManager.shared.sharedDistanceAtXYPoint)")
            print("Depth Value 1 \(DataManager.shared.depthPoint1)")
            print("Depth Value 2 \(DataManager.shared.depthPoint2)")
            print("Depth Value 3 \(DataManager.shared.depthPoint3)")
            print("Depth Value 4 \(DataManager.shared.depthPoint4)")
            print("Depth Value 5 \(DataManager.shared.depthPoint5)")
            print("Depth Value 6 \(DataManager.shared.depthPoint6)")
            print("Depth Value 7 \(DataManager.shared.depthPoint7)")
            print("Depth Value 8 \(DataManager.shared.depthPoint8)")
            print("Depth Value 9 \(DataManager.shared.depthPoint9)")
            print("Depth Value 10 \(DataManager.shared.depthPoint10)")
            
            var localSharedDistanceAtXYPoint:Float = DataManager.shared.sharedDistanceAtXYPoint
            var intensity:Float = 1
            
            if localSharedDistanceAtXYPoint >= 3 {
                intensity = 0
            }
           else {
               intensity = 1 - (localSharedDistanceAtXYPoint / 3)
           }
            print ("Intensity value is \(intensity)")
            
            //Giles - Haptic engine intensity code is below - can try with live audio feedback.
            
//            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
//                fatalError("Haptics not supported on this device.")
//            }
//
//            do {
//                let hapticEngine = try CHHapticEngine()
//                try hapticEngine.start()
//
//                let hapticEvent = CHHapticEvent(eventType: .hapticContinuous, parameters: [
//                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
//                ], relativeTime: 0)
//
//                let pattern = try CHHapticPattern(events: [hapticEvent], parameterCurves: [])
//                let player = try hapticEngine.makePlayer(with: pattern)
//                try player.start(atTime: CHHapticTimeImmediate)
//
//
//            } catch {
//                print("Error playing haptic feedback: \(error)")
//            }
            
            
            let cnt=x_vals.count
            print(cnt)
            if cnt == 0 {
                centerObj=""
            }
            if (cnt>0) {
                let med=x_vals.sorted(by: <)[cnt / 2]
                var med_ind = 0
                for i in 0...(cnt-1) {
                    if x_vals[i]==med {
                        med_ind=i
                    }
                }
                //Giles Feb 13th added a size threshold below - need to refresh list if object count = 0
                if liveViewVerbalModeActive == 1 {
                    
                    if (objs[med_ind] != centerObj && objSizes[med_ind] >= 0.1) {
                        StillImageViewController.speak(text: objs[med_ind], multiplier: 1.0)
                        centerObj=objs[med_ind]
                    }
                    print(centerObj)
                }
                else {
                    centerObj=""
                }
                    
            }
            
            // Giles - original code used < rather than > which may have created the oversensitivity
            //            let obj = sender.objs[i]
            //            //Giles commented out below
            //            if (obj=="aeroplane" || obj=="sheep" || obj=="cow" || obj=="horse") {
            //                continue;
            //            }
            //            //Giles - Size ignoring could be put here, but size values need to be accessible here. Append size to sender.
            //            let objSizeCheck = sender.objSize[i]
            //            //Giles added Deans code for object ignoring based on size, was < 0.05 but too conservative
            //            if (obj != "bottle" && objSizeCheck <= 0.02) {
            //                continue;
            //            }
            
            
            //Giles10added
            //            let press = CustomPressGestureRecognizer(target: self, action: #selector(pressSelector))
            //            let tap = CustomTapGestureRecognizer(target: self, action: #selector(tapSelector))
            
            // Giles2 - added dispatchqueue - it provided verbal feedback once - it can only speak when NO OBJECTS IDENTIFIED
            // is that because it cannot access tap.objs etc
            
            //            DispatchQueue.main.async {
            
            //                press.objs = objs
            //                press.mults = mults
            //                press.x_vals = x_vals
            //                press.objSize = objSizes
            //                self.view.addGestureRecognizer(press)
            
            //                tap.numberOfTapsRequired = 2
            //                tap.objs = objs
            //                tap.mults = mults
            //                tap.x_vals = x_vals
            //                tap.objSize = objSizes
            //                self.view.addGestureRecognizer(tap)
            //            }
            
            if longSpeechModeActivate == 1 {
                
                usleep(1500000)
                
                let cntLongSpeech = objs.count
                if cntLongSpeech == 0 {
                    StillImageViewController.speak(text: "No Objects Identified", multiplier: 1)
                } else {
                    var sorted=x_vals.enumerated().sorted(by:{$0.element < $1.element})
                    for (i,e) in sorted {
                        let obj = objs[i]
                        //Giles commented out below
                        if (obj=="aeroplane" || obj=="sheep" || obj=="cow" || obj=="horse") {
                            continue;
                        }
                        //Giles - Size ignoring could be put here, but size values need to be accessible here. Append size to sender.
                        let objSizeCheck = objSizes[i]
                        //Giles added Deans code for object ignoring based on size, was < 0.05 but too conservative
                        if (obj != "bottle" && objSizeCheck <= 0.02) {
                            continue;
                        }
                        let mult = mults[i]
                        let x_value = x_vals[i]
                        //sender.x_vals[i]
                        //                 StillImageViewController.speak(text: (obj+String(x_value)), multiplier: mult)
                        StillImageViewController.speak(text: (obj + " " + StillImageViewController.verticalPosition(multiplier: mult) + " " + StillImageViewController.horizontalPosition(posValue:x_value)), multiplier: mult)
                        //                sleep(1)
                        print("The mult value is \(mult)")
                    }
                }
                longSpeechModeActivate = 0
                usleep(1000000)
            }
            
            //Giles this mode works as a simple MODE
//            func mode<T>(_ array: [T]) -> T? {
//                let countedSet = NSCountedSet(array: array)
//                var maxCount = 0
//                var modeValue: T?
//
//                for value in countedSet {
//                    let count = countedSet.count(for: value)
//                    if count > maxCount {
//                        maxCount = count
//                        modeValue = value as? T
//                    }
//                }
//
//                return modeValue
//            }
            
//            func mode(_ array: [Int]) -> Int {
//                let countedSet = NSCountedSet(array: array)
//                var counts = [(value: Int, count: Int)]()
//                var totalCount = 0
//
//                for value in countedSet {
//                    let count = countedSet.count(for: value)
//                    counts.append((value as! Int, count))
//                    totalCount += count
//                }
//
//                counts.sort { $0.count > $1.count }
//
//                if let mode = counts.first, Double(mode.count) / Double(totalCount) > 0.05 {
//                    return mode.value
//                } else {
//                    return 0
//                }
//            }
            
            func mode(_ array: [Int]) -> (Int)? {
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
                var returnValue:Int = 0

                if let mode = counts.first {
                    let modeValue = mode.value
                    let modeValueInt:Int = modeValue
                    
                    let modeCount = Double(mode.count)
                    let modePercentage = modeCount / Double(totalCount) * 100
                    if modePercentage > 5 {
                        returnValue = modeValueInt
                    }
                    else {
                        returnValue = 0
                    }
                   
                }
                return returnValue
            }

            
            if liveViewModeActive == true {
                if let observations = request.results as? [VNCoreMLFeatureValueObservation],
                   let segmentationmap = observations.first?.featureValue.multiArrayValue {
                    guard let row = segmentationmap.shape[0] as? Int,
                          let col = segmentationmap.shape[1] as? Int else {
                        return
                    }

//                    let columnWidth = 51
//                    var modeValues = [Double]()
//                    for columnCounter in 1...10 {
//
//                    }
                    
//                    let columnWidth = 51
                    // 0 - 51 - 102 - 153 - 204 - 255 - 306 - 357 - 408 - 459 - 510
                    var ColumnValues1 = [Int]()
                    for j in 0..<513 {
                        for k in 0..<50 {
                            let value = segmentationmap[[j,k] as [NSNumber]].intValue
                            ColumnValues1.append(value)
                        }
                    }
                    let modeValue1 = mode(ColumnValues1)
                    let modeValue1Int:Int = modeValue1 ?? 0
                    print("Mode value 1 is \(modeValue1Int)")
                    
                    var ColumnValues2 = [Int]()
                    for j in 0..<513 {
                        for k in 51..<101 {
                            let value = segmentationmap[[j,k] as [NSNumber]].intValue
                            ColumnValues2.append(value)
                        }
                    }
                    
                    let modeValue2 = mode(ColumnValues2)
                    let modeValue2Int:Int = modeValue2 ?? 0
                    print("Mode value 2 is \(modeValue2Int)")
                    
                    var ColumnValues3 = [Int]()
                    for j in 0..<513 {
                        for k in 102..<152 {
                            let value = segmentationmap[[j,k] as [NSNumber]].intValue
                            ColumnValues3.append(value)
                        }
                    }
                    let modeValue3 = mode(ColumnValues3)
                    let modeValue3Int:Int = modeValue3 ?? 0
                    print("Mode value 3 is \(modeValue3Int)")
                    
                    var ColumnValues4 = [Int]()
                    for j in 0..<513 {
                        for k in 153..<203 {
                            let value = segmentationmap[[j,k] as [NSNumber]].intValue
                            ColumnValues4.append(value)
                        }
                    }
                    let modeValue4 = mode(ColumnValues4)
                    let modeValue4Int:Int = modeValue4 ?? 0
                    print("Mode value 4 is \(modeValue4Int)")
                    
                    var ColumnValues5 = [Int]()
                    for j in 0..<513 {
                        for k in 204..<254 {
                            let value = segmentationmap[[j,k] as [NSNumber]].intValue
                            ColumnValues5.append(value)
                        }
                    }
                    let modeValue5 = mode(ColumnValues5)
                    let modeValue5Int:Int = modeValue5 ?? 0
                    print("Mode value 5 is \(modeValue5Int)")
                    
                    var ColumnValues6 = [Int]()
                    for j in 0..<513 {
                        for k in 255..<305 {
                            let value = segmentationmap[[j,k] as [NSNumber]].intValue
                            ColumnValues6.append(value)
                        }
                    }
                    let modeValue6 = mode(ColumnValues6)
                    let modeValue6Int:Int = modeValue6 ?? 0
                    print("Mode value 6 is \(modeValue6Int)")
                    
                    var ColumnValues7 = [Int]()
                    for j in 0..<513 {
                        for k in 306..<356 {
                            let value = segmentationmap[[j,k] as [NSNumber]].intValue
                            ColumnValues7.append(value)
                        }
                    }
                    let modeValue7 = mode(ColumnValues7)
                    let modeValue7Int:Int = modeValue7 ?? 0
                    print("Mode value 7 is \(modeValue7Int)")
                    
                    var ColumnValues8 = [Int]()
                    for j in 0..<513 {
                        for k in 357..<407 {
                            let value = segmentationmap[[j,k] as [NSNumber]].intValue
                            ColumnValues8.append(value)
                        }
                    }
                    let modeValue8 = mode(ColumnValues8)
                    let modeValue8Int:Int = modeValue8 ?? 0
                    print("Mode value 8 is \(modeValue8Int)")
                    
                    var ColumnValues9 = [Int]()
                    for j in 0..<513 {
                        for k in 408..<458 {
                            let value = segmentationmap[[j,k] as [NSNumber]].intValue
                            ColumnValues9.append(value)
                        }
                    }
                    let modeValue9 = mode(ColumnValues9)
                    let modeValue9Int:Int = modeValue9 ?? 0
                    print("Mode value 9 is \(modeValue9Int)")
                    
                    var ColumnValues10 = [Int]()
                    for j in 0..<513 {
                        for k in 459..<512 {
                            let value = segmentationmap[[j,k] as [NSNumber]].intValue
                            ColumnValues10.append(value)
                        }
                    }
                    let modeValue10 = mode(ColumnValues10)
                    let modeValue10Int:Int = modeValue10 ?? 0
                    print("Mode value 10 is \(modeValue10Int)")
                    
//                    for i in 0..<10 {
//                        let columnStart = i * columnWidth
//                        let columnEnd = columnStart + columnWidth
//                        var columnValues = [Double]()
//                        for j in 0..<513 {
//                            for k in columnStart..<columnEnd {
//                                let value = segmentationmap[[j,k] as [NSNumber]].doubleValue
//                                columnValues.append(value)
//                            }
//                        }
//
//                        let modeValue = mode(columnValues)
//                            switch i {
//                                case 0:
//                                    mode1 = modeValue ?? 0.0
//                                case 1:
//                                    mode2 = modeValue ?? 0.0
//                                case 2:
//                                    mode3 = modeValue ?? 0.0
//                                case 3:
//                                    mode4 = modeValue ?? 0.0
//                                case 4:
//                                    mode5 = modeValue ?? 0.0
//                                case 5:
//                                    mode6 = modeValue ?? 0.0
//                                case 6:
//                                    mode7 = modeValue ?? 0.0
//                                case 7:
//                                    mode8 = modeValue ?? 0.0
//                                case 8:
//                                    mode9 = modeValue ?? 0.0
//                                case 9:
//                                    mode10 = modeValue ?? 0.0
//                                default:
//                                    break
//                            }
//                        print(mode1)
//                        print(mode2)
//                        print(mode3)
//                        print(mode4)
//                        print(mode5)
//                        print(mode6)
//                        print(mode7)
//                        print(mode8)
//                        print(mode9)
//                        print(mode10)
//                    }
                    //Gileszzz enter live-view music mode (SSD) here
                    let liveEngine = AVAudioEngine()

                    let liveSound1 = AVAudioPlayerNode()
                    let liveSound2 = AVAudioPlayerNode()
                    let liveSound3 = AVAudioPlayerNode()
                    let liveSound4 = AVAudioPlayerNode()
                    let liveSound5 = AVAudioPlayerNode()
                    let liveSound6 = AVAudioPlayerNode()
                    let liveSound7 = AVAudioPlayerNode()
                    let liveSound8 = AVAudioPlayerNode()
                    let liveSound9 = AVAudioPlayerNode()
                    let liveSound10 = AVAudioPlayerNode()

                    // Giles - vertical column of numbers for live view mode
//                    liveSound1obj = (Int(truncating: segmentationmap[2308]))
//                    liveSound2obj = (Int(truncating: segmentationmap[31036]))
//                    liveSound3obj = (Int(truncating: segmentationmap[59764]))
//                    liveSound4obj = (Int(truncating: segmentationmap[88492]))
//                    liveSound5obj = (Int(truncating: segmentationmap[117220]))
//                    liveSound6obj = (Int(truncating: segmentationmap[145948]))
//                    liveSound7obj = (Int(truncating: segmentationmap[174676]))
//                    liveSound8obj = (Int(truncating: segmentationmap[203404]))
//                    liveSound9obj = (Int(truncating: segmentationmap[232132]))
//                    liveSound10obj = (Int(truncating: segmentationmap[260860]))
                    
                    
                    //Giles - Horizontal sweep mode
//                    liveSound1obj = (Int(truncating: segmentationmap[131332]))
//                    liveSound2obj = (Int(truncating: segmentationmap[131388]))
//                    liveSound3obj = (Int(truncating: segmentationmap[131444]))
//                    liveSound4obj = (Int(truncating: segmentationmap[131500]))
//                    liveSound5obj = (Int(truncating: segmentationmap[131556]))
//                    liveSound6obj = (Int(truncating: segmentationmap[131612]))
//                    liveSound7obj = (Int(truncating: segmentationmap[131668]))
//                    liveSound8obj = (Int(truncating: segmentationmap[131724]))
//                    liveSound9obj = (Int(truncating: segmentationmap[131780]))
//                    liveSound10obj = (Int(truncating: segmentationmap[131836]))
                    
                    if liveViewModeColumns == 1 {
                        liveSound1obj = modeValue1Int
                        liveSound2obj = modeValue2Int
                        liveSound3obj = modeValue3Int
                        liveSound4obj = modeValue4Int
                        liveSound5obj = modeValue5Int
                        liveSound6obj = modeValue6Int
                        liveSound7obj = modeValue7Int
                        liveSound8obj = modeValue8Int
                        liveSound9obj = modeValue9Int
                        liveSound10obj = modeValue10Int
                    }
                    else {
                        liveSound1obj = (Int(truncating: segmentationmap[131332]))
                        liveSound2obj = (Int(truncating: segmentationmap[131388]))
                        liveSound3obj = (Int(truncating: segmentationmap[131444]))
                        liveSound4obj = (Int(truncating: segmentationmap[131500]))
                        liveSound5obj = (Int(truncating: segmentationmap[131556]))
                        liveSound6obj = (Int(truncating: segmentationmap[131612]))
                        liveSound7obj = (Int(truncating: segmentationmap[131668]))
                        liveSound8obj = (Int(truncating: segmentationmap[131724]))
                        liveSound9obj = (Int(truncating: segmentationmap[131780]))
                        liveSound10obj = (Int(truncating: segmentationmap[131836]))
                    }
                    

                    print(liveSound1obj!)
                    print(liveSound2obj!)
                    print(liveSound3obj!)
                    print(liveSound4obj!)
                    print(liveSound5obj!)
                    print(liveSound6obj!)
                    print(liveSound7obj!)
                    print(liveSound8obj!)
                    print(liveSound9obj!)
                    print(liveSound10obj!)

                    if (liveSound1obj == 6 || liveSound1obj == 7 || liveSound1obj == 14 || liveSound1obj == 19 || liveSound1obj == 2 || liveSound1obj == 1) {
                        liveSound1str = "1trumpet"
                        liveSound1vol = 1.0
                    }
                    else if (liveSound1obj == 20) {
                        liveSound1str = "1breath"
                        liveSound1vol = 1.0
                    }
                    else if (liveSound1obj == 15) {
                        liveSound1str = "1piano"
                        liveSound1vol = 1.0
                    }
                    else if (liveSound1obj == 8 || liveSound1obj == 12) {
                        liveSound1str = "1cat"
                        liveSound1vol = 1.0
                    }
                    else if (liveSound1obj == 9 || liveSound1obj == 11 || liveSound1obj == 18) {
                        liveSound1str = "1chair"
                        liveSound1vol = 1.0
                    }
                    else if (liveSound1obj == 5) {
                        liveSound1str = "1bottle"
                        liveSound1vol = 1.0
                    }
                    else if (liveSound1obj == 3) {
                        liveSound1str = "1bird"
                        liveSound1vol = 1.0
                    }
                    else if (liveSound1obj >= 1) {
                        liveSound1str = "1"
                        liveSound1vol = 1.0
                    }
                    else
                    {
                        liveSound1str = "1"
                        liveSound1vol = 0.0
                    }


                    if (liveSound2obj == 6 || liveSound2obj == 7 || liveSound2obj == 14 || liveSound2obj == 19 || liveSound2obj == 2 || liveSound2obj == 1) {
                        liveSound2str = "2trumpet"
                        liveSound2vol = 1.0
                    }
                    else if (liveSound2obj == 20) {
                        liveSound2str = "2breath"
                        liveSound2vol = 1.0
                    }
                    else if (liveSound2obj == 15) {
                        liveSound2str = "2piano"
                        liveSound2vol = 1.0
                    }
                    else if (liveSound2obj == 8 || liveSound2obj == 12) {
                        liveSound2str = "2cat"
                        liveSound2vol = 1.0
                    }
                    else if (liveSound2obj == 9 || liveSound2obj == 11 || liveSound2obj == 18) {
                        liveSound2str = "2chair"
                        liveSound2vol = 1.0
                    }
                    else if (liveSound2obj == 5) {
                        liveSound2str = "2bottle"
                        liveSound2vol = 1.0
                    }
                    else if (liveSound2obj == 3) {
                        liveSound2str = "2bird"
                        liveSound2vol = 1.0
                    }
                    else if (liveSound2obj >= 1) {
                        liveSound2str = "2"
                        liveSound2vol = 1.0
                    }
                    else
                    {
                        liveSound2str = "2"
                        liveSound2vol = 0.0
                    }

                    if (liveSound3obj == 6 || liveSound3obj == 7 || liveSound3obj == 14 || liveSound3obj == 19 || liveSound3obj == 2 || liveSound3obj == 1) {
                        liveSound3str = "3trumpet"
                        liveSound3vol = 1.0
                    }
                    else if (liveSound3obj == 20) {
                        liveSound3str = "3breath"
                        liveSound3vol = 1.0
                    }
                    else if (liveSound3obj == 15) {
                        liveSound3str = "3piano"
                        liveSound3vol = 1.0
                    }
                    else if (liveSound3obj == 8 || liveSound3obj == 12) {
                        liveSound3str = "3cat"
                        liveSound3vol = 1.0
                    }
                    else if (liveSound3obj == 9 || liveSound3obj == 11 || liveSound3obj == 18) {
                        liveSound3str = "3chair"
                        liveSound3vol = 1.0
                    }
                    else if (liveSound3obj == 5) {
                        liveSound3str = "3bottle"
                        liveSound3vol = 1.0
                    }
                    else if (liveSound3obj == 3) {
                        liveSound3str = "3bird"
                        liveSound3vol = 1.0
                    }
                    else if (liveSound3obj >= 1) {
                        liveSound3str = "3"
                        liveSound3vol = 1.0
                    }
                    else
                    {
                        liveSound3str = "3"
                        liveSound3vol = 0.0
                    }

                    if (liveSound4obj == 6 || liveSound4obj == 7 || liveSound4obj == 14 || liveSound4obj == 19 || liveSound4obj == 2 || liveSound4obj == 1) {
                        liveSound4str = "4trumpet"
                        liveSound4vol = 1.0
                    }
                    else if (liveSound4obj == 20) {
                        liveSound4str = "4breath"
                        liveSound4vol = 1.0
                    }
                    else if (liveSound4obj == 15) {
                        liveSound4str = "4piano"
                        liveSound4vol = 1.0
                    }
                    else if (liveSound4obj == 8 || liveSound4obj == 12) {
                        liveSound4str = "4cat"
                        liveSound4vol = 1.0
                    }
                    else if (liveSound4obj == 9 || liveSound4obj == 11 || liveSound4obj == 18) {
                        liveSound4str = "4chair"
                        liveSound4vol = 1.0
                    }
                    else if (liveSound4obj == 5) {
                        liveSound4str = "4bottle"
                        liveSound4vol = 1.0
                    }
                    else if (liveSound4obj == 3) {
                        liveSound4str = "4bird"
                        liveSound4vol = 1.0
                    }
                    else if (liveSound4obj >= 1) {
                        liveSound4str = "4"
                        liveSound4vol = 1.0
                    }
                    else
                    {
                        liveSound4str = "4"
                        liveSound4vol = 0.0
                    }

                    if (liveSound5obj == 6 || liveSound5obj == 7 || liveSound5obj == 14 || liveSound5obj == 19 || liveSound5obj == 2 || liveSound5obj == 1) {
                        liveSound5str = "5trumpet"
                        liveSound5vol = 1.0
                    }
                    else if (liveSound5obj == 20) {
                        liveSound5str = "5breath"
                        liveSound5vol = 1.0
                    }
                    else if (liveSound5obj == 15) {
                        liveSound5str = "5piano"
                        liveSound5vol = 1.0
                    }
                    else if (liveSound5obj == 8 || liveSound5obj == 12) {
                        liveSound5str = "5cat"
                        liveSound5vol = 1.0
                    }
                    else if (liveSound5obj == 9 || liveSound5obj == 11 || liveSound5obj == 18) {
                        liveSound5str = "5chair"
                        liveSound5vol = 1.0
                    }
                    else if (liveSound5obj == 5) {
                        liveSound5str = "5bottle"
                        liveSound5vol = 1.0
                    }
                    else if (liveSound5obj == 3) {
                        liveSound5str = "5bird"
                        liveSound5vol = 1.0
                    }
                    else if (liveSound5obj >= 1) {
                        liveSound5str = "5"
                        liveSound5vol = 1.0
                    }
                    else
                    {
                        liveSound5str = "5"
                        liveSound5vol = 0.0
                    }

                    if (liveSound6obj == 6 || liveSound6obj == 7 || liveSound6obj == 14 || liveSound6obj == 19 || liveSound6obj == 2 || liveSound6obj == 1) {
                        liveSound6str = "6trumpet"
                        liveSound6vol = 1.0
                    }
                    else if (liveSound6obj == 20) {
                        liveSound6str = "6breath"
                        liveSound6vol = 1.0
                    }
                    else if (liveSound6obj == 15) {
                        liveSound6str = "6piano"
                        liveSound6vol = 1.0
                    }
                    else if (liveSound6obj == 8 || liveSound6obj == 12) {
                        liveSound6str = "6cat"
                        liveSound6vol = 1.0
                    }
                    else if (liveSound6obj == 9 || liveSound6obj == 11 || liveSound6obj == 18) {
                        liveSound6str = "6chair"
                        liveSound6vol = 1.0
                    }
                    else if (liveSound6obj == 5) {
                        liveSound6str = "6bottle"
                        liveSound6vol = 1.0
                    }
                    else if (liveSound6obj == 3) {
                        liveSound6str = "6bird"
                        liveSound6vol = 1.0
                    }
                    else if (liveSound6obj >= 1) {
                        liveSound6str = "6"
                        liveSound6vol = 1.0
                    }
                    else
                    {
                        liveSound6str = "6"
                        liveSound6vol = 0.0
                    }

                    if (liveSound7obj == 6 || liveSound7obj == 7 || liveSound7obj == 14 || liveSound7obj == 19 || liveSound7obj == 2 || liveSound7obj == 1) {
                        liveSound7str = "7trumpet"
                        liveSound7vol = 1.0
                    }
                    else if (liveSound7obj == 20) {
                        liveSound7str = "7breath"
                        liveSound7vol = 1.0
                    }
                    else if (liveSound7obj == 15) {
                        liveSound7str = "7piano"
                        liveSound7vol = 1.0
                    }
                    else if (liveSound7obj == 8 || liveSound7obj == 12) {
                        liveSound7str = "7cat"
                        liveSound7vol = 1.0
                    }
                    else if (liveSound7obj == 9 || liveSound7obj == 11 || liveSound7obj == 18) {
                        liveSound7str = "7chair"
                        liveSound7vol = 1.0
                    }
                    else if (liveSound7obj == 5) {
                        liveSound7str = "7bottle"
                        liveSound7vol = 1.0
                    }
                    else if (liveSound7obj == 3) {
                        liveSound7str = "7bird"
                        liveSound7vol = 1.0
                    }
                    else if (liveSound7obj >= 1) {
                        liveSound7str = "7"
                        liveSound7vol = 1.0
                    }
                    else
                    {
                        liveSound7str = "7"
                        liveSound7vol = 0.0
                    }

                    if (liveSound8obj == 6 || liveSound8obj == 7 || liveSound8obj == 14 || liveSound8obj == 19 || liveSound8obj == 2 || liveSound8obj == 1) {
                        liveSound8str = "8trumpet"
                        liveSound8vol = 1.0
                    }
                    else if (liveSound8obj == 20) {
                        liveSound8str = "8breath"
                        liveSound8vol = 1.0
                    }
                    else if (liveSound8obj == 15) {
                        liveSound8str = "8piano"
                        liveSound8vol = 1.0
                    }
                    else if (liveSound8obj == 8 || liveSound8obj == 12) {
                        liveSound8str = "8cat"
                        liveSound8vol = 1.0
                    }
                    else if (liveSound8obj == 9 || liveSound8obj == 11 || liveSound8obj == 18) {
                        liveSound8str = "8chair"
                        liveSound8vol = 1.0
                    }
                    else if (liveSound8obj == 5) {
                        liveSound8str = "8bottle"
                        liveSound8vol = 1.0
                    }
                    else if (liveSound8obj == 3) {
                        liveSound8str = "8bird"
                        liveSound8vol = 1.0
                    }
                    else if (liveSound8obj >= 1) {
                        liveSound8str = "8"
                        liveSound8vol = 1.0
                    }
                    else
                    {
                        liveSound8str = "8"
                        liveSound8vol = 0.0
                    }

                    if (liveSound9obj == 6 || liveSound9obj == 7 || liveSound9obj == 14 || liveSound9obj == 19 || liveSound9obj == 2 || liveSound9obj == 1) {
                        liveSound9str = "9trumpet"
                        liveSound9vol = 1.0
                    }
                    else if (liveSound9obj == 20) {
                        liveSound9str = "9breath"
                        liveSound9vol = 1.0
                    }
                    else if (liveSound9obj == 15) {
                        liveSound9str = "9piano"
                        liveSound9vol = 1.0
                    }
                    else if (liveSound9obj == 8 || liveSound9obj == 12) {
                        liveSound9str = "9cat"
                        liveSound9vol = 1.0
                    }
                    else if (liveSound9obj == 9 || liveSound9obj == 11 || liveSound9obj == 18) {
                        liveSound9str = "9chair"
                        liveSound9vol = 1.0
                    }
                    else if (liveSound9obj == 5) {
                        liveSound9str = "9bottle"
                        liveSound9vol = 1.0
                    }
                    else if (liveSound9obj == 3) {
                        liveSound9str = "9bird"
                        liveSound9vol = 1.0
                    }
                    else if (liveSound9obj >= 1) {
                        liveSound9str = "9"
                        liveSound9vol = 1.0
                    }
                    else
                    {
                        liveSound9str = "9"
                        liveSound9vol = 0.0
                    }

                    if (liveSound10obj == 6 || liveSound10obj == 7 || liveSound10obj == 14 || liveSound10obj == 19 || liveSound10obj == 2 || liveSound10obj == 1) {
                        liveSound10str = "10trumpet"
                        liveSound10vol = 1.0
                    }
                    else if (liveSound10obj == 20) {
                        liveSound10str = "10breath"
                        liveSound10vol = 1.0
                    }
                    else if (liveSound10obj == 15) {
                        liveSound10str = "10piano"
                        liveSound10vol = 1.0
                    }
                    else if (liveSound10obj == 8 || liveSound10obj == 12) {
                        liveSound10str = "10cat"
                        liveSound10vol = 1.0
                    }
                    else if (liveSound10obj == 9 || liveSound10obj == 11 || liveSound10obj == 18) {
                        liveSound10str = "10chair"
                        liveSound10vol = 1.0
                    }
                    else if (liveSound10obj == 5) {
                        liveSound10str = "10bottle"
                        liveSound10vol = 1.0
                    }
                    else if (liveSound10obj == 3) {
                        liveSound10str = "10bird"
                        liveSound10vol = 1.0
                    }
                    else if (liveSound10obj >= 1) {
                        liveSound10str = "10"
                        liveSound10vol = 1.0
                    }
                    else
                    {
                        liveSound10str = "10"
                        liveSound10vol = 0.0
                    }

                    let liveFile1 = try! AVAudioFile(forReading: Bundle.main.url(forResource: liveSound1str, withExtension: "wav")!)
                    liveSound1.volume = liveSound1vol

                    let liveFile2 = try! AVAudioFile(forReading: Bundle.main.url(forResource: liveSound2str, withExtension: "wav")!)
                    liveSound2.volume = liveSound2vol

                    let liveFile3 = try! AVAudioFile(forReading: Bundle.main.url(forResource: liveSound3str, withExtension: "wav")!)
                    liveSound3.volume = liveSound3vol

                    let liveFile4 = try! AVAudioFile(forReading: Bundle.main.url(forResource: liveSound4str, withExtension: "wav")!)
                    liveSound4.volume = liveSound4vol

                    let liveFile5 = try! AVAudioFile(forReading: Bundle.main.url(forResource: liveSound5str, withExtension: "wav")!)
                    liveSound5.volume = liveSound5vol

                    let liveFile6 = try! AVAudioFile(forReading: Bundle.main.url(forResource: liveSound6str, withExtension: "wav")!)
                    liveSound6.volume = liveSound6vol

                    let liveFile7 = try! AVAudioFile(forReading: Bundle.main.url(forResource: liveSound7str, withExtension: "wav")!)
                    liveSound7.volume = liveSound7vol

                    let liveFile8 = try! AVAudioFile(forReading: Bundle.main.url(forResource: liveSound8str, withExtension: "wav")!)
                    liveSound8.volume = liveSound8vol

                    let liveFile9 = try! AVAudioFile(forReading: Bundle.main.url(forResource: liveSound9str, withExtension: "wav")!)
                    liveSound9.volume = liveSound9vol

                    let liveFile10 = try! AVAudioFile(forReading: Bundle.main.url(forResource: liveSound10str, withExtension: "wav")!)
                    liveSound10.volume = liveSound10vol

                    let fileDrums = try! AVAudioFile(forReading: Bundle.main.url(forResource: "drum", withExtension: "wav")!)
                    //drums.pan = counterLRpan
                    //drums.volume = 0.5

                    liveEngine.attach(liveSound1)
                    liveEngine.attach(liveSound2)
                    liveEngine.attach(liveSound3)
                    liveEngine.attach(liveSound4)
                    liveEngine.attach(liveSound5)
                    liveEngine.attach(liveSound6)
                    liveEngine.attach(liveSound7)
                    liveEngine.attach(liveSound8)
                    liveEngine.attach(liveSound9)
                    liveEngine.attach(liveSound10)
                    //liveEngine.attach(v2drums)

                    liveEngine.connect(liveSound1, to: liveEngine.mainMixerNode, format: liveFile1.processingFormat)
                    liveEngine.connect(liveSound2, to: liveEngine.mainMixerNode, format: liveFile2.processingFormat)
                    liveEngine.connect(liveSound3, to: liveEngine.mainMixerNode, format: liveFile3.processingFormat)
                    liveEngine.connect(liveSound4, to: liveEngine.mainMixerNode, format: liveFile4.processingFormat)
                    liveEngine.connect(liveSound5, to: liveEngine.mainMixerNode, format: liveFile5.processingFormat)
                    liveEngine.connect(liveSound6, to: liveEngine.mainMixerNode, format: liveFile6.processingFormat)
                    liveEngine.connect(liveSound7, to: liveEngine.mainMixerNode, format: liveFile7.processingFormat)
                    liveEngine.connect(liveSound8, to: liveEngine.mainMixerNode, format: liveFile8.processingFormat)
                    liveEngine.connect(liveSound9, to: liveEngine.mainMixerNode, format: liveFile9.processingFormat)
                    liveEngine.connect(liveSound10, to: liveEngine.mainMixerNode, format: liveFile10.processingFormat)
                    //liveEngine.connect(v2drums, to: liveEngine.mainMixerNode, format: fileDrums.processingFormat)

                    liveEngine.prepare()
                    
                    //Giles old timings
//                    let delayTime1 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.000), atRate: liveFile1.processingFormat.sampleRate)
//                    let delayTime2 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.005), atRate: liveFile2.processingFormat.sampleRate)
//                    let delayTime3 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.010), atRate: liveFile3.processingFormat.sampleRate)
//                    let delayTime4 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.015), atRate: liveFile4.processingFormat.sampleRate)
//                    let delayTime5 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.020), atRate: liveFile5.processingFormat.sampleRate)
//                    let delayTime6 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.025), atRate: liveFile6.processingFormat.sampleRate)
//                    let delayTime7 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.030), atRate: liveFile7.processingFormat.sampleRate)
//                    let delayTime8 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.035), atRate: liveFile8.processingFormat.sampleRate)
//                    let delayTime9 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.040), atRate: liveFile9.processingFormat.sampleRate)
//                    let delayTime10 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.045), atRate: liveFile10.processingFormat.sampleRate)
                    
                    let delayTime1 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.000), atRate: liveFile1.processingFormat.sampleRate)
                    let delayTime2 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.007), atRate: liveFile2.processingFormat.sampleRate)
                    let delayTime3 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.014), atRate: liveFile3.processingFormat.sampleRate)
                    let delayTime4 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.021), atRate: liveFile4.processingFormat.sampleRate)
                    let delayTime5 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.028), atRate: liveFile5.processingFormat.sampleRate)
                    let delayTime6 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.035), atRate: liveFile6.processingFormat.sampleRate)
                    let delayTime7 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.042), atRate: liveFile7.processingFormat.sampleRate)
                    let delayTime8 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.049), atRate: liveFile8.processingFormat.sampleRate)
                    let delayTime9 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.056), atRate: liveFile9.processingFormat.sampleRate)
                    let delayTime10 = AVAudioTime(sampleTime: AVAudioFramePosition(44100 * 0.063), atRate: liveFile10.processingFormat.sampleRate)

                    liveSound1.scheduleFile(liveFile1, at: delayTime1,  completionHandler: nil)
                    liveSound2.scheduleFile(liveFile2, at: delayTime2, completionHandler: nil)
                    liveSound3.scheduleFile(liveFile3, at: delayTime3, completionHandler: nil)
                    liveSound4.scheduleFile(liveFile4, at: delayTime4, completionHandler: nil)
                    liveSound5.scheduleFile(liveFile5, at: delayTime5, completionHandler: nil)
                    liveSound6.scheduleFile(liveFile6, at: delayTime6, completionHandler: nil)
                    liveSound7.scheduleFile(liveFile7, at: delayTime7, completionHandler: nil)
                    liveSound8.scheduleFile(liveFile8, at: delayTime8, completionHandler: nil)
                    liveSound9.scheduleFile(liveFile9, at: delayTime9, completionHandler: nil)
                    liveSound10.scheduleFile(liveFile10, at: delayTime10, completionHandler: nil)

//                    liveSound1.scheduleFile(liveFile1, at: nil, completionHandler: {
//                        liveSound1.play()})

                    //v2drums.scheduleFile(fileDrums, at: nil, completionHandler: nil)

                    try! liveEngine.start()
//Giles was -0.9 to 0.9
                    liveSound1.pan = -0.9
                    liveSound2.pan = -0.7
                    liveSound3.pan = -0.5
                    liveSound4.pan = -0.3
                    liveSound5.pan = -0.1
                    liveSound6.pan = 0.1
                    liveSound7.pan = 0.3
                    liveSound8.pan = 0.5
                    liveSound9.pan = 0.7
                    liveSound10.pan = 0.9
                    ///v2drums.pan = 0.0
//                    let delayTime1 = AVAudioTime(hostTime: mach_absolute_time() + UInt64(0.1 * Double(NSEC_PER_SEC)))
//                    let delayTime2 = AVAudioTime(hostTime: mach_absolute_time() + UInt64(0.2 * Double(NSEC_PER_SEC)))
//                    let delayTime3 = AVAudioTime(hostTime: mach_absolute_time() + UInt64(0.3 * Double(NSEC_PER_SEC)))
//                    let delayTime4 = AVAudioTime(hostTime: mach_absolute_time() + UInt64(0.4 * Double(NSEC_PER_SEC)))
//                    let delayTime5 = AVAudioTime(hostTime: mach_absolute_time() + UInt64(0.5 * Double(NSEC_PER_SEC)))
//                    let delayTime6 = AVAudioTime(hostTime: mach_absolute_time() + UInt64(0.6 * Double(NSEC_PER_SEC)))
//                    let delayTime7 = AVAudioTime(hostTime: mach_absolute_time() + UInt64(0.7 * Double(NSEC_PER_SEC)))
//                    let delayTime8 = AVAudioTime(hostTime: mach_absolute_time() + UInt64(0.8 * Double(NSEC_PER_SEC)))
//                    let delayTime9 = AVAudioTime(hostTime: mach_absolute_time() + UInt64(0.9 * Double(NSEC_PER_SEC)))
//                    let delayTime10 = AVAudioTime(hostTime: mach_absolute_time() + UInt64(1.0 * Double(NSEC_PER_SEC)))
                    //                    v2drums.play()
                    //                    usleep(1000)
                    liveSound1.play()
//                    usleep(30000)
                    liveSound2.play()
//                    usleep(30000)
                    liveSound3.play()
//                    usleep(30000)
                    liveSound4.play()
//                    usleep(30000)
                    liveSound5.play()
//                    usleep(30000)
                    liveSound6.play()
//                    usleep(30000)
                    liveSound7.play()
//                    usleep(30000)
                    liveSound8.play()
//                    usleep(30000)
                    liveSound9.play()
//                    usleep(30000)
                    liveSound10.play()
//                    usleep(30000)
                    usleep(500000)
                    try! liveEngine.stop()
                }
            }
            
            
            
            
            //Giles10 commented out all the below
            //            tap.objs = objs
            //            tap.mults = mults
            //            tap.x_vals = x_vals
            //            // Giles added below
            //            tap.objSize = objSizes
            
            //tap.numberOfTapsRequired = 2
            //view.addGestureRecognizer(tap)
            
            let overlayedTexture = overlayingTexturesGenerater.texture(cameraTexture, segmentationTexture)
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
