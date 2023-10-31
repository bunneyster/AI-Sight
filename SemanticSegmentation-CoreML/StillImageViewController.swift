//
//  StillImageViewController.swift
//  SemanticSegmentation-CoreML
//
//  Created by Doyoung Gwak on 20/07/2019.
//  Edited by Sriram Bhimaraju on 27/01/2022
//  Copyright © 2019 Doyoung Gwak. All rights reserved.
//

/*
 * In this view controller, the user selects the still image
 * option in the app. They then select any image in their camera roll
 * for the app to analyze.
 *
 * Current features in the app:
 *   The app says aloud what it sees in the image. Based on how high or low the object is in the image frame, the program speaks in a different tone. An object high in the frame will be announced in a high-pitch female tone, while an object low in the frame will be announced in a deep, male tone
 *
 * Potential features to be added:
 *   HRTF spacialization or changing the right-left headphone balance could be used to indicate an object's horizontal placement in the image frame. Additionally, the app should speak only when the image is double-tapped, so the user can customize when they hear auditory feedback.
 *
 * Limitations:
 *   The app speaks in a slightly jarring and monotonous tone.
 */

import UIKit
import Vision
import AVFoundation

//class CustomTapGestureRecognizer: UITapGestureRecognizer {
//    //var obj_name: String = ""
//    //var mult_val: Float = 0.0
//
//    var objs = [String]()
//    var mults = [Float]()
//    var x_vals = [Double]()
//    // Giles added object size
//    var objSize = [Double] ()
//}

class StillImageViewController: UIViewController {

    // MARK: - UI Properties
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var drawingView: DrawingSegmentationView!
    
    let imagePickerController = UIImagePickerController()
    
    // MARK - Core ML model
    // DeepLabV3(iOS12+), DeepLabV3FP16(iOS12+), DeepLabV3Int8LUT(iOS12+)
    let segmentationModel = DeepLabV3()
    
    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?

    /// Groups the segmentation data per object ID.
    ///
    /// - Parameters:
    ///   - segmentationMap: The 2D map containing the object-level image.
    ///   - row: The number of rows in the segmentation map.
    ///   - col: The number of columns in the segmentation map.
    /// - Returns: A tuple containing 3 maps: `d`, a map of object ID to the number of corresponding
    /// segmentation map elements, `x`, a map of object ID to the sum of the x-coordinates of its
    /// corresponding segmentation map elements, and `y`, a map of object ID to the sum of the
    /// y-coordinates of its corresponding segmentation map elements.
    public static func getImageFrameCoordinates(
        segmentationmap: MLMultiArray, row: Int, col: Int
    ) -> (d: [Int: Int], x: [Int: Int], y: [Int: Int]) {
        var d = [Int: Int](), x = [Int: Int](), y = [Int: Int]()
        for i in 0 ... row - 1 {
            for j in 0 ... col - 1 {
                let key = [i, j] as [NSNumber]
                let k = segmentationmap[key].intValue
                if d.keys.contains(k) {
                    let a: Int = d[k] ?? 0
                    let b: Int = x[k] ?? 0
                    let c: Int = y[k] ?? 0
                    d[k] = a + 1
                    x[k] = b + j
                    y[k] = c + i
                } else {
                    d[k] = 0
                    x[k] = j
                    y[k] = i
                }
            }
        }
        return (d, x, y)
    }

    /// Computes the vocalized attributes for a given object.
    ///
    /// - Parameters:
    ///   - k: The object ID.
    ///   - v: The number of segmentation map elements corresponding to the given object ID.
    ///   - x: A map of object ID to the sum of the x-coordinates of the corresponding segmentation
    /// map elements.
    ///   - y: A map of object ID to the sum of the y-coordinates of the corresponding segmentation
    /// map elements.
    ///   - row: The number of rows in the segmentation map.
    ///   - col: The number of columns in the segmentation map.
    /// - Returns: A tuple containing 4 elements: `obj`, the object name, `mult_val`, the pitch
    /// multiplier, `xValue`, the representative x-coordinate, and `sizes`, the size of the object
    /// relative to its containing image.
    public static func getObjectAndPitchMultiplier(
        k: Int,
        v: Int,
        x: [Int: Int],
        y: [Int: Int],
        row: Int,
        col: Int
    ) -> (obj: String, mult_val: Float, xValue: Double, sizes: Double) {
        let objects = [
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

        let b: Int = x[k] ?? 0
        let c: Int = y[k] ?? 0
        let size = Double(v) / (Double(row) * Double(col))
        let multiplier = 0.7 + Float(1 - Double(c) / Double(v) / Double(row))
        let xValue = Double(b) / Double(v) / Double(col)

        return (objects[k], multiplier, xValue, size)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // image picker delegate setup
        imagePickerController.delegate = self
        
        // setup ml model
        setUpModel()
    }
    
    @IBAction func tapCamera(_ sender: Any) {
        self.present(imagePickerController, animated: true)
    }
    
    // MARK: - Setup Core ML
    func setUpModel() {
        if let visionModel = try? VNCoreMLModel(for: segmentationModel.model) {
            self.visionModel = visionModel
            request?.imageCropAndScaleOption = .centerCrop
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            
            print ("----- Segmentation Model Type ------")
            print (type(of: segmentationModel))
            // DeepLabV3
            print ("------------------------------------")

        } else {
            fatalError()
        }
    }
}


// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension StillImageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print ("INSIDE StillImageViewController")
        

        // speak(text: "test String")
        
        if let image = info[.originalImage] as? UIImage,
            let url = info[.imageURL] as? URL {
            mainImageView.image = image
            self.predict(with: url)
        }
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Inference
extension StillImageViewController {
    // prediction
    func predict(with url: URL) {
        guard let request = request else { fatalError() }
        
        // vision framework configures the input size of image following our model's input configuration automatically
        let handler = VNImageRequestHandler(url: url, options: [:])
        try? handler.perform([request])
    }

    
    // post-processing
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        print ("INSIDE STILL IMAGE visionRequestDidComplete")
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            let segmentationmap = observations.first?.featureValue.multiArrayValue {
            
            guard let row = segmentationmap.shape[0] as? Int,
                let col = segmentationmap.shape[1] as? Int else {
                    return
            }
            
            let imageFrameCoordinates = StillImageViewController.getImageFrameCoordinates(segmentationmap: segmentationmap, row: row, col: col)
            
            let d = imageFrameCoordinates.d
            let x = imageFrameCoordinates.x
            let y = imageFrameCoordinates.y

            //Giles commenting out
//            print("any value",terminator: Array(repeating: "\n", count: 100).joined())
            var objs = [String]()
            var mults = [Float]()
            var x_vals = [Double]()
            // Giles added
            var objSizes = [Double]()
            
            for (k,v) in d {
                if (k==0) {
                    continue
                }

                let objectAndPitchMultiplier = StillImageViewController.getObjectAndPitchMultiplier(k:k, v:v, x:x, y:y, row: row, col: col)
                let obj = objectAndPitchMultiplier.obj
                let mult_val = objectAndPitchMultiplier.mult_val
                let x_val = objectAndPitchMultiplier.xValue
                // Giles to add - was size, now sizes
                let objSize = objectAndPitchMultiplier.sizes

                objs.append(obj)
                mults.append(mult_val)
                x_vals.append(x_val)
                // Giles added append objSize
                objSizes.append(objSize)
                
                // DispatchQueue.main.asyncAfter(deadline: .now() + 2)
            }
            
//            let tap = CustomTapGestureRecognizer(target: self, action: #selector(tapSelector))
//
//            tap.objs = objs
//            tap.mults = mults
//            tap.x_vals = x_vals
//            // Giles added object size
//            tap.objSize = objSizes
//            tap.numberOfTapsRequired = 2
//            view.addGestureRecognizer(tap)
            
            drawingView.segmentationmap = SegmentationResultMLMultiArray(mlMultiArray: segmentationmap)
        }
    }
}
