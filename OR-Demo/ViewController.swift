//
//  ViewController.swift
//  OR-Demo
//
//  Created by Mohamed Derkaoui on 28/11/2018.
//  Copyright © 2018 Mohamed Derkaoui. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!
    
    var requestedItemsArray : [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestedItemsArray = ["water","laptop","stopwatch","watch","sandal", "ballpen", "scooter", "flowerpot","espresso"]
        updateRequesLabel()

        // Start camera capture
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        let input = try! AVCaptureDeviceInput(device: captureDevice)
        captureSession.addInput(input)
        captureSession.startRunning()
        
        // Add camera layer to main VC
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        // Get camera output
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let model = try! VNCoreMLModel(for: Inceptionv3().model)
        let imageRequest = VNCoreMLRequest(model: model) { (finishedRequest, error) in
            let results = finishedRequest.results as! [VNClassificationObservation]
            let firstRes = results.first?.identifier
            let firstConfidence = results.first?.confidence
            
            let separators = NSCharacterSet(charactersIn: ", ")
            let firstResArray = firstRes?.components(separatedBy: separators as CharacterSet)
            
            DispatchQueue.main.async {
                self.updateLabel(name: firstResArray!.first!, acc: firstConfidence!)
                self.testMatching(requested: self.topLabel.text!, scannedArray: firstResArray! )
            }
            print("res array \(firstResArray!.description)")
            print(firstRes!, firstConfidence! )
//            print("requsted obj is \(self.topLabel.text!)")
        }
        try! VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([imageRequest])
    }
    
    func updateLabel(name: String, acc: Float){
        self.resultLabel.text = "\(name) w/ \( (acc * 100))% accuracy"
    }
    
    func testMatching(requested: String, scannedArray: [String]){
        if scannedArray.contains("\(requested)") {
            topLabel.text = "Exact ! "
            topLabel.textColor = UIColor.green
            self.resultLabel.text = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.updateRequesLabel()
            }
        } else {
            topLabel.textColor = UIColor.black
        }
    }
    
    func updateRequesLabel(){
        self.topLabel.text = self.requestedItemsArray!.randomElement()!
    }
}

