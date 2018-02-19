//
//  PreviewViewController.swift
//  Jesuscam
//
//  Created by Tim Carr on 2/19/18.
//  Copyright © 2018 ICF. All rights reserved.
//

import UIKit

class PreviewViewController: UIViewController {
    var image: UIImage?
    @IBOutlet weak var imageView: UIImageView!
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = image
    }

    @IBAction func shareButtonPressed(_ sender: UIButton) {
        guard let image = self.image else { return }
        let avc = UIActivityViewController.init(activityItems: [image], applicationActivities: nil)
        avc.completionWithItemsHandler = { (_, completed, _, _) in
            if completed {
                self.dismiss(animated: true, completion: nil)
            }
        }
        let pop = avc.popoverPresentationController
        pop?.sourceView = sender
        self.present(avc, animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
