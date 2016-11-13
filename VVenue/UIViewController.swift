//
//  UIViewController.swift
//  VVenue
//
//  Created by Cassidy Wang on 11/12/16.
//  Copyright © 2016 Cassidy Wang. All rights reserved.
//

import Foundation

extension UIViewController {
    
    func hideKeyboardOnTap() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}
