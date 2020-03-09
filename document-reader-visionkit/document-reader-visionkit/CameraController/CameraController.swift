//
//  CameraController.swift
//  document-reader-visionkit
//
//  Created by Wiljay Flores on 2020-03-08.
//  Copyright © 2020 Wiljay Flores. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class CameraController {
    
    var captureSession: AVCaptureSession?
    var rearCameraInput: AVCaptureDeviceInput?
    var rearCamera: AVCaptureDevice?
    var videoOutput: AVCaptureVideoDataOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
}

extension CameraController {
    
    func prepare(viewController: AVCaptureVideoDataOutputSampleBufferDelegate, completionHandler: @escaping (Error?) -> Void) {
        
        func createCaptureSession() {
            self.captureSession = AVCaptureSession()
        }
        
        func configureCaptureDevices() throws {
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
            
            let cameras = session.devices.compactMap({$0})
            guard !cameras.isEmpty else { throw CameraControllerError.noCamerasAvailable }
            
            for camera in cameras {
                
                if camera.position == .back {
                    
                    self.rearCamera = camera
                    
                    try camera.lockForConfiguration()
                    camera.focusMode = .continuousAutoFocus
                    camera.unlockForConfiguration()
                }
            }
        }
        
        func configureDeviceInputs() throws {
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
            captureSession.sessionPreset = AVCaptureSession.Preset.photo
            
            if let rearCamera = self.rearCamera {
                
                self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
                
                if captureSession.canAddInput(self.rearCameraInput!) {
                    captureSession.addInput(self.rearCameraInput!)
                }
            }
        }
        func configurePhotoOutput(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) throws {
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
            captureSession.sessionPreset = AVCaptureSession.Preset.photo
            
            
            self.videoOutput = AVCaptureVideoDataOutput()
            let delegate = delegate
   
            self.videoOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
             self.videoOutput!.setSampleBufferDelegate(delegate, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
            
            if captureSession.canAddOutput(self.videoOutput!) {
                captureSession.addOutput(self.videoOutput!)
            }
            
            captureSession.startRunning()
        }
        
        DispatchQueue(label: "prepare").async {
            do {
                createCaptureSession()
                try configureCaptureDevices()
                try configureDeviceInputs()
                try configurePhotoOutput(delegate: viewController)
            }
                
            catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
        
           self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
           self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
           self.previewLayer?.connection?.videoOrientation = .portrait
           self.previewLayer?.frame = view.bounds
        
           view.layer.insertSublayer(self.previewLayer!, at: 0)
    }
    
}

extension CameraController {
    enum CameraControllerError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
}
