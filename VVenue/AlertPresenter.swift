//
//  AlertPresenter.swift
//  VVenue
//
//  Created by Cassidy Wang on 11/12/16.
//  Copyright © 2016 Cassidy Wang. All rights reserved.
//

import Foundation
import UIKit

protocol AlertPresenter {
    func presentAlert(title: String, message: String, type: CustomAlertPresentationType, sender: UIViewController)
}

extension AlertPresenter {
    func presentAlert(title: String, message: String, type: CustomAlertPresentationType, sender: UIViewController) {
        switch type {
        case .notification:
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            sender.present(alert, animated: true, completion: nil)
        default:
            let alert = UIAlertController(title: "Default alert", message: "Please contact developers", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            sender.present(alert, animated: true, completion: nil)
        }
    }
}
