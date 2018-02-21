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
    var fastttCameraDevice = FastttCameraDevice.rear
    var lastPhoto: UIImage? {
        didSet {
            self.lastPhotoImageView.superview!.isHidden = self.lastPhoto == nil
        }
    }

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var lastPhotoButton: UIButton!
    @IBOutlet weak var lastPhotoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let view = self.lastPhotoImageView.superview!
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 4.0
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.borderWidth = 2.0
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
                    self.takePhotoButton.isEnabled = true
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.fastttRemoveChildViewController(self.fastttCamera)
    }
    
    func setupCamera() {
        fastttCamera.delegate = self
        fastttCamera.cropsImageToVisibleAspectRatio = false
        fastttCamera.scalesImage = false
        fastttCamera.normalizesImageOrientations = true
        fastttCamera.cameraDevice = self.fastttCameraDevice
        fastttCamera.mirrorsVideo = self.fastttCameraDevice == .front
        self.fastttAddChildViewController(self.fastttCamera, in: self.cameraView)
    }
    
    @IBAction func lastPhotoButtonPressed(_ sender: Any) {
        UIApplication.shared.openURL(URL(string:"photos-redirect://")!)
    }
    
    @IBAction func takePhotoPressed(_ sender: Any) {
        self.takePhotoButton.isEnabled = false
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
            self.takePhotoButton.isEnabled = true
            return
        }
        self.lastPhoto = image
        assert(Thread.current.isMainThread)
        self.updateLastPhotoImage()
        
        PHPhotoLibrary.shared().performChanges({
            let _ = PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { (success, error) in
            NSLog("Success: \(success), error: \(error)")
            DispatchQueue.main.async {
                if success {
                    self.performSegue(withIdentifier: "segueToPreview", sender: nil)
                } else {
                    self.takePhotoButton.isEnabled = true
                }
            }
        })
    }
    
    func updateLastPhotoImage() {
        guard let image = self.lastPhoto else { return }
        let resizedImage = image.cropImage(toFill: self.lastPhotoImageView.bounds.size.atScreenScale(), opaque: true, scale: 0)
        self.lastPhotoImageView.image = resizedImage
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "segueToPreview", let previewVC = segue.destination as? PreviewViewController {
            previewVC.image = self.lastPhoto
        }
    }
    
    @IBAction func camSwitchPressed(_ sender: Any) {
        self.fastttCamera.stopRunning()
        self.fastttRemoveChildViewController(self.fastttCamera)
        self.fastttCameraDevice = (self.fastttCameraDevice == .front) ? .rear : .front
        self.setupCamera()
    }
}

extension MainViewController : FastttCameraDelegate {
    func cameraController(_ cameraController: FastttCameraInterface!, didFinishNormalizing capturedImage: FastttCapturedImage!) {
        guard let image = capturedImage.fullImage else {
            assert(false, "ERROR")
            self.takePhotoButton.isEnabled = true
            return
        }
        saveImageToCameraRoll(jesusize(image))
    }
}

