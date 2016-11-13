//
//  HostViewController.swift
//  VVenue
//
//  Created by Cassidy Wang on 11/12/16.
//  Copyright © 2016 Cassidy Wang. All rights reserved.
//

//
//  HostEventViewController.swift
//  SmartPass
//
//  Created by Cassidy Wang on 10/8/16.
//  Copyright © 2016 Cassidy Wang. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import Alamofire

//TODO: Temporarily disable back button when picture is being analyzed

class HostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate, AlertPresenter {
    
    //Outlets
    @IBOutlet weak var activityIndicatorView: UIVisualEffectView!
    @IBOutlet weak var beginHostingButton: UIButton!
    @IBOutlet weak var queryImage: DynamicImageView!
    @IBOutlet weak var welcomeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        queryImage.isUserInteractionEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(HostViewController.checkImage), name: NSNotification.Name(rawValue: "imageViewDidChange"), object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startHosting() {
        beginHostingButton.isHidden = true
        queryImage.isHidden = false
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func openCamera() {
        self.view.backgroundColor = UIColor.white
        welcomeLabel.isHidden = true
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }

    func checkImage() {
        if !queryImage.image!.size.equalTo(CGSize(width: 0, height: 0)) {
            
            activityIndicatorView.isHidden = false
            
            detectFace(faceImage: queryImage.image!, completion: { (result) in
            })
        } else {
            self.presentAlert(title: "No Picture Detected", message: "Please select a valid picture", type: .notification, sender: self)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            //Make image square
            let squareLength = pickedImage.size.width > pickedImage.size.height ? pickedImage.size.height : pickedImage.size.width
            UIGraphicsBeginImageContextWithOptions(CGSize(width: squareLength, height: squareLength), false, 1)
            let context = UIGraphicsGetCurrentContext()
            context?.setFillColor(UIColor.black.cgColor)
            context?.fill(CGRect(x: 0, y: 0, width: squareLength, height: squareLength))
            pickedImage.draw(in: CGRect(x: (squareLength - pickedImage.size.width) / 2, y: (squareLength - pickedImage.size.height) / 2, width: pickedImage.size.width, height: pickedImage.size.height))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            queryImage.image = newImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func viewTapped(_ sender: UITapGestureRecognizer) {
        if (self.view.backgroundColor == UIColor.green || self.view.backgroundColor == UIColor.red) {
            self.view.backgroundColor = UIColor.white
            openCamera()
        }
    }
    
    // Detect face in image
    func detectFace(faceImage: UIImage, completion: (_ encodingResult: FaceAPIResult<AnyObject, NSError>) -> Void) {
        
        let url = "https://api.projectoxford.ai/face/v1.0/detect?returnFaceId=true"
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("26a1c49867934418bfcceac915443574", forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        
        let pngRepresentation = UIImagePNGRepresentation(faceImage)
        
        let task = URLSession.shared.uploadTask(with: request as URLRequest, from: pngRepresentation) { (data, response, error) in
            
            if let nsError = error {
                print("failure")
            }
            else {
                let httpResponse = response as! HTTPURLResponse
                let statusCode = httpResponse.statusCode
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments)
                    if statusCode == 200 {
                        DispatchQueue.main.async {
                            self.activityIndicatorView.isHidden = true
                        }
                        if (json as AnyObject).count == 0 {
                            DispatchQueue.main.async {
                                self.presentAlert(title: "No face found", message: "We couldn't identify a face. Please try again.", type: .notification, sender: self)
                            }
                        } else {
                            let swiftyJSONED = JSON(json)
                            let faceID = swiftyJSONED[0]["faceId"].stringValue
                            self.identify(faces: [faceID], personGroupId: personGroupID, completion: { (result) in
                                switch result {
                                case .Success(let successJson):
                                    print("Identified face", successJson)
                                case .Failure(let error):
                                    print("Error identifying face", error)
                                }
                            })
                        }
                    }
                }
                catch {
                    print("error")
                }
            }
        }
        task.resume()
        
//        let imageStream = UIImagePNGRepresentation(faceImage)
//
//        print("image size(bytes): \(imageStream!.count) = \(imageStream!.count / 1024) KB")
//        
//        let headers: HTTPHeaders = ["Content-Type": "application/octet-stream", "Ocp-Apim-Subscription-Key": "26a1c49867934418bfcceac915443574"]
//        
//        let parameters: Parameters = [
//            "url": imageStream!
//        ]
//        
//        Alamofire.request("https://api.projectoxford.ai/face/v1.0/detect?returnFaceId=true", method: .post, parameters: parameters, headers: headers)
////            .validate(statusCode: 200..<300)
//            .responseJSON(completionHandler: { response in
//            
//                //Debugging
//                debugPrint(response)
//                
//                switch response.result {
//                case .success:
//                    print("Detect validation successful")
//                case .failure(let error):
//                    let errorJson = JSON(error)
//                    print(errorJson)
//                    print(error)
//                    print("Error calling POST on detect")
//                    return
//                }
//                
//                //Response code
//                if let json = response.result.value {
//                    print("Detect successful")
//                    print("JSON: \(json)")
//                    DispatchQueue.main.async {
//                        self.activityIndicatorView.isHidden = true
//                    }
//                    let detectResponse = JSON(json)
//                    if detectResponse.count == 0 {
//                        DispatchQueue.main.async {
//                            self.presentAlert(title: "No face found", message: "We couldn't identify a face. Please try again.", type: .notification, sender: self)
//                        }
//                    } else {
//                        let faceID = detectResponse[0]["faceId"].stringValue
//                        print("faceID: \(faceID)")
//                        self.identify(faces: [faceID], personGroupId: personGroupID, completion: { (result) in
//                            switch result {
//                            case .Success(let successJson):
//                                print("Identified face", successJson)
//                            case .Failure(let error):
//                                print("Error identifying face", error)
//                            }
//                        })
//                    }
//                }
//        })
    }
    
    func identify(faces faceIDs: [String], personGroupId: String, completion: (_ encodingResult: FaceAPIResult<JSON, NSError>) -> Void) {
        
        let url = "https://api.projectoxford.ai/face/v1.0/identify"
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("26a1c49867934418bfcceac915443574", forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        
        let json: [String: Any] = ["personGroupId": personGroupId, "faceIds": faceIDs]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            
            if let nsError = error {
                print("identify error: \(nsError)")
                //                completion(result: .Failure(Error.UnexpectedError(nsError: nsError)))
            }
            else {
                let httpResponse = response as! HTTPURLResponse
                let statusCode = httpResponse.statusCode
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments)
                    if statusCode == 200 {
                        DispatchQueue.main.async {
                            let pID: String = JSON(json)[0]["candidates"][0]["personId"].stringValue
                            self.retrievePersonData(personId: pID, personGroupId: personGroupId)
                            let confidenceLevel = JSON(json)[0]["candidates"][0]["confidence"].floatValue
                            if confidenceLevel >= 0.80 {
                                self.view.backgroundColor = UIColor.green
                                self.welcomeLabel.text = "Welcome, \(JSON(json)[0]["candidates"][0]["name"])!"
                                self.welcomeLabel.isHidden = false
                            } else if confidenceLevel >= 0.50 {
                                self.view.backgroundColor = UIColor.orange
                                DispatchQueue.main.async {
                                    self.performSegue(withIdentifier: "toVoiceVerification", sender: self)
                                }
                            } else {
                                self.view.backgroundColor = UIColor.red
                                print("no recognition")
                            }
                            //                        completion(result: .Success(json))
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            self.view.backgroundColor = UIColor.red
                            print("JSON error")
                            //                        completion(result: .Failure(Error.ServiceError(json: json as! JSONDictionary)))
                        }
                    }
                }
                catch {
                    DispatchQueue.main.async {
                        print("JSON serialization error")
                        self.view.backgroundColor = UIColor.red
                        //                    completion(result: .Failure(Error.JSonSerializationError))
                    }
                }
            }
        }
        task.resume()
        
//        let headers: HTTPHeaders = ["Content-Type": "application/json", "Ocp-Apim-Subscription-Key": "26a1c49867934418bfcceac915443574"]
//        
//        let parameters: Parameters = [
//            "faceIds": faceIDs,
//            "personGroupId": personGroupId,
//            "maxNumOfCandidatesReturned": 1
//        ]
//        
//        Alamofire.request("https://api.projectoxford.ai/face/v1.0/identify", method: .post, parameters: parameters, headers: headers)
////            .validate(statusCode: 200..<300)
//            .responseJSON(completionHandler: { response in
//                
//                //Debugging
//                debugPrint(response)
//                
//                switch response.result{
//                case .success:
//                    print("Identify validation successful")
//                case .failure(let error):
//                    print(error)
//                    print("Error calling POST on identify")
//                    return
//                }
//                
//                //Response code
//                if let json = response.result.value {
//                    print("Identify successful")
//                    print("JSON: \(json)")
//                    let identifyResponse = JSON(json)
//                    
//                    if identifyResponse.count == 0 {
//                        DispatchQueue.main.async {
//                            self.view.backgroundColor = UIColor.red
//                        }
//                    } else {
//                        let pID = identifyResponse[0]["candidates"][0]["personId"].stringValue
//                        print("personId: \(pID)")
//                        
//                        let confidenceLevel = identifyResponse[0]["candidates"][0]["confidence"].floatValue
//                        print("Confidence: \(confidenceLevel)")
//                        
//                        self.retrievePersonData(personId: pID, personGroupId: personGroupId)
//                        
//                        if confidenceLevel >= 0.80 {
//                            self.view.backgroundColor = UIColor.green
//                        } else if confidenceLevel >= 0.50 {
//                            self.view.backgroundColor = UIColor.orange
//                            DispatchQueue.main.async {
//                                self.performSegue(withIdentifier: "toVoiceVerification", sender: self)
//                            }
//                        } else {
//                            self.view.backgroundColor = UIColor.red
//                        }
//                    }
//                }
//        })
    }
        
    func retrievePersonData(personId: String, personGroupId: String) {
        
        let headers: HTTPHeaders = ["Ocp-Apim-Subscription-Key": "26a1c49867934418bfcceac915443574"]
        
        Alamofire.request("https://api.projectoxford.ai/face/v1.0/persongroups/\(personGroupId)/persons/\(personId)", method: .get, headers: headers)
            .validate(statusCode: 200..<300)
            .responseJSON(completionHandler: { response in
                //Debugging
//                debugPrint(response)
                
                switch response.result{
                case .success:
                    print("Get person validation successful")
                case .failure(let error):
                    print(error)
                    print("Error calling GET on get person")
                    return
                }
                
                //Response code
                if let json = response.result.value {
                    let getResponse = JSON(json)
                    
                    let name = getResponse["name"].stringValue
                    currentKey = getResponse["userData"].stringValue
                    retrievedName = name
                }
        })
    }
    
    @IBAction func unwindToHostEvent(sender: UIStoryboardSegue) {
    }
}
