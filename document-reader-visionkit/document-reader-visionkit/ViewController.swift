//
//  ViewController.swift
//  document-reader-visionkit
//
//  Created by Wiljay Flores on 2020-03-08.
//  Copyright © 2020 Wiljay Flores. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class ViewController: UIViewController {
    
    let cameraController = CameraController()
    var requests = [VNRequest]()

    @IBOutlet weak var capturePreviewView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCameraController()
        startTextDetection()
    }

}

extension ViewController {
    
    func configureCameraController() {
        cameraController.prepare(viewController: self) {(error) in
            if let error = error {
                print(error)
            }
            try? self.cameraController.displayPreview(on: self.capturePreviewView)
        }
    }
    
    func startTextDetection() {
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.detectTextHandler)
        textRequest.reportCharacterBoxes = true
        self.requests = [textRequest]
    }
    

    func detectTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else {
            print("no result")
            return
        }
        let result = observations.map({$0 as? VNTextObservation})
        
        print(result.description)
        
        DispatchQueue.main.async() {
            self.capturePreviewView.layer.sublayers?.removeSubrange(1...)
            for region in result {
                guard let rg = region else {
                    continue
                }
                
                self.highlightWord(box: rg)
                
                if let boxes = region?.characterBoxes {
                    for characterBox in boxes {
                        self.highlightLetters(box: characterBox)
                    }
                }
            }
        }
    }

}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
         guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
             return
         }
             
         var requestOptions:[VNImageOption : Any] = [:]
             
        if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
             requestOptions = [.cameraIntrinsics:camData]
         }
        
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
             
         do {
            try imageRequestHandler.perform(self.requests)
         } catch {
             print(error)
         }
     }
    
}

extension ViewController {
    
    func highlightWord(box: VNTextObservation) {
        guard let boxes = box.characterBoxes else {
            return
        }
            
        var maxX: CGFloat = 9999.0
        var minX: CGFloat = 0.0
        var maxY: CGFloat = 9999.0
        var minY: CGFloat = 0.0
            
        for char in boxes {
            if char.bottomLeft.x < maxX {
                maxX = char.bottomLeft.x
            }
            if char.bottomRight.x > minX {
                minX = char.bottomRight.x
            }
            if char.bottomRight.y < maxY {
                maxY = char.bottomRight.y
            }
            if char.topRight.y > minY {
                minY = char.topRight.y
            }
        }
            
        let xCord = maxX * capturePreviewView.frame.size.width
        let yCord = (1 - minY) * capturePreviewView.frame.size.height
        let width = (minX - maxX) * capturePreviewView.frame.size.width
        let height = (minY - maxY) * capturePreviewView.frame.size.height
            
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.red.cgColor
            
        capturePreviewView.layer.addSublayer(outline)
    }
    
    func highlightLetters(box: VNRectangleObservation) {
        let xCord = box.topLeft.x * capturePreviewView.frame.size.width
        let yCord = (1 - box.topLeft.y) * capturePreviewView.frame.size.height
        let width = (box.topRight.x - box.bottomLeft.x) * capturePreviewView.frame.size.width
        let height = (box.topLeft.y - box.bottomLeft.y) * capturePreviewView.frame.size.height
            
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 1.0
        outline.borderColor = UIColor.blue.cgColor
        
        capturePreviewView.layer.addSublayer(outline)
    }
    
}


