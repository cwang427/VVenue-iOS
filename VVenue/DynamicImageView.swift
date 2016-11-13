//
//  DynamicImageView.swift
//  VVenue
//
//  Created by Cassidy Wang on 11/12/16.
//  Copyright © 2016 Cassidy Wang. All rights reserved.
//

import Foundation
import UIKit

class DynamicImageView: UIImageView {
    
    override var image: UIImage? {
        didSet {
            super.image = image
            NotificationCenter.default.post(Notification.init(name: Notification.Name(rawValue: "imageViewDidChange")))
        }
    }
    
}
