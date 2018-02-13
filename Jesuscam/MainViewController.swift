//
//  ViewController.swift
//  Jesuscam
//
//  Created by Tim Carr on 2017-10-10.
//  Copyright © 2017 ICF. All rights reserved.
//

import UIKit
import AVFoundation
import FastttCamera
import Photos

class MainViewController: UIViewController {
    var fastttCamera = FastttCamera()

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var takePhotoButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AVCaptureDevice.requestAccess(for: .video) { (granted) in
            guard granted else {
                DispatchQueue.main.async {
                    let alert = UIAlertController.init(title: "Camera Access", message: "Please go to Settings and grant this app permission to your camera", preferredStyle: .alert)
                    alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async {
                    guard status == .authorized else {
                        let alert = UIAlertController.init(title: "Photo Access", message: "Please go to Settings and grant this app permission to your photo library", preferredStyle: .alert)
                        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    self.setupCamera()
                }
            }
        }
    }
    
    func setupCamera() {
        fastttCamera.delegate = self
        fastttCamera.cropsImageToVisibleAspectRatio = false
        fastttCamera.scalesImage = false
        fastttCamera.normalizesImageOrientations = true
        self.fastttAddChildViewController(self.fastttCamera, in: self.cameraView)
    }
    
    @IBAction func takePhotoPressed(_ sender: Any) {
        self.fastttCamera.takePicture(nil)
    }
    
    func jesusize(_ image: UIImage) -> UIImage? {
        let jesus = #imageLiteral(resourceName: "jesus-1000h")
        UIGraphicsBeginImageContext(image.size)
        image.draw(in: CGRect.init(origin: .zero, size: image.size))
        let jesusSize = CGSize.init(width: image.size.width / 2.0, height: image.size.height / 2.0)
        jesus.draw(in: CGRect.init(origin: CGPoint.init(x: jesusSize.width / 2.0, y: jesusSize.height / 2.0), size: jesusSize))
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else {
            assert(false, "ERROR")
            return nil
        }
        UIGraphicsEndImageContext()
        return result
    }
    
    func saveImageToCameraRoll(_ image: UIImage?) {
        guard let image = image else {
            assert(false, "ERROR")
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            let _ = PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { (success, error) in
            print("Success: \(success)")
            DispatchQueue.main.async {
                if success {
                    let alert = UIAlertController.init(title: "Photo saved!", message: "The photo has been saved to your Camera Roll.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        })
    }
}

extension MainViewController : FastttCameraDelegate {
    func cameraController(_ cameraController: FastttCameraInterface!, didFinishNormalizing capturedImage: FastttCapturedImage!) {
        guard let image = capturedImage.fullImage else {
            assert(false, "ERROR")
            return
        }
        saveImageToCameraRoll(jesusize(image))
    }
}

