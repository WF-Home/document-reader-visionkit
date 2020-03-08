//
//  ViewController.swift
//  document-reader-visionkit
//
//  Created by Wiljay Flores on 2020-03-08.
//  Copyright © 2020 Wiljay Flores. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let cameraController = CameraController()
    @IBOutlet weak var capturePreviewView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCameraController()
    }
    
    func configureCameraController() {
        cameraController.prepare {(error) in
            if let error = error {
                print(error)
            }
     
            try? self.cameraController.displayPreview(on: self.capturePreviewView)
        }
    }

}


