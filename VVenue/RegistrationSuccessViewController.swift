//
//  RegistrationSuccessViewController.swift
//  VVenue
//
//  Created by Cassidy Wang on 11/13/16.
//  Copyright © 2016 Cassidy Wang. All rights reserved.
//

import UIKit

class RegistrationSuccessViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func returnToRegistration() {
        self.performSegue(withIdentifier: "unwindToRegistration", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is UploadPictureViewController {
            let destinationVC = segue.destination as! UploadPictureViewController
            destinationVC.imageToUse.contentMode = .center
            destinationVC.imageToUse.image = #imageLiteral(resourceName: "Camera-76")
        }
    }
}
