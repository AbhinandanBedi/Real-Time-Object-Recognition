//
//  ViewController.swift
//  Real Time Object Recognition
//
//  Created by Abhinandan Bedi on 14/12/17.
//  Copyright © 2017 Abhinandan Bedi. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{

    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var outputLabel: UILabel!
    var output = "Hello!"
    let speechsynthesizer = AVSpeechSynthesizer()
    override func viewDidLoad() {
        super.viewDidLoad()
        openCamera()
        speak(sender: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func openCamera(){
        let captureSession = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        captureSession.startRunning()
        
        self.view.addSubview(detailView)
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoOutput"))
        captureSession.addOutput(dataOutput)
        
        
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else { return }
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            guard let firstObservation = results.first else { return }
            print(firstObservation.identifier, firstObservation.confidence)
            DispatchQueue.main.async {
                if(firstObservation.confidence as Float > 0.25){
                    if(self.output.caseInsensitiveCompare(firstObservation.identifier) == ComparisonResult.orderedSame){
                        print("Its the same thing, So no output!")
                    }
                    else{
                        self.output = firstObservation.identifier
                        self.speak(sender: self)
                    }
                    self.output = firstObservation.identifier
                    print(self.output)
                    self.outputLabel.text = firstObservation.identifier
                    self.confidenceLabel.text = "\(firstObservation.confidence * 100)%"
                }
                
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    func speak(sender: AnyObject) {
        let speechUtterance = AVSpeechUtterance(string: self.output)
        speechsynthesizer.speak(speechUtterance)
    }
    

}

