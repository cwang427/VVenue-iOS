//
//  SetVoiceKeyViewController.swift
//  VVenue
//
//  Created by Cassidy Wang on 11/13/16.
//  Copyright © 2016 Cassidy Wang. All rights reserved.
//

import Foundation
import UIKit
import Speech
import AudioKit
import SwiftyJSON

class SetVoiceKeyViewController: UIViewController, AlertPresenter, SFSpeechRecognizerDelegate {
    
    //Outlets
    @IBOutlet var audioInputPlot: EZAudioPlot!
    @IBOutlet weak var toggleListenButton: UIButton!
    @IBOutlet weak var keyLabel: UILabel!
    @IBOutlet weak var activityIndicatorView: UIVisualEffectView!
    
    //Constants
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    
    //Variables
    var mic: AKMicrophone!
    //    var micOn: Bool = false
    var engineOn: Bool = false
    var mixer: AKMixer!
    var plot: AKNodeOutputPlot!
    //    var boosted: AKBooster!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Set up live plot
        AKSettings.audioInputEnabled = true
        mic = AKMicrophone()
        
        //        let hpFiltered = AKHighPassFilter(mic, cutoffFrequency: 200, resonance: 0)
        //        let lpFiltered = AKLowPassFilter(hpFiltered, cutoffFrequency: 2000, resonance: 0)
        //        boosted = AKBooster(lpFiltered, gain: 0)
        
        //Set up speech recognition
        toggleListenButton.isEnabled = false
        speechRecognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization({ (authStatus) in
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
            case .denied:
                isButtonEnabled = false
                self.presentAlert(title: "No access", message: "User denied access to speech recognition", type: .notification, sender: self)
            case .restricted:
                isButtonEnabled = false
                self.presentAlert(title: "No access", message: "Speech recognition restricted on this device", type: .notification, sender: self)
            case .notDetermined:
                isButtonEnabled = false
                self.presentAlert(title: "No access", message: "Speech recognition not yet authorized", type: .notification, sender: self)
            }
            OperationQueue.main.addOperation {
                self.toggleListenButton.isEnabled = isButtonEnabled
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //TODO: Verify that this doesn't crash if user goes back then forward
        AudioKit.start()
        setupPlot()
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            toggleListenButton.isEnabled = true
        } else {
            toggleListenButton.isEnabled = false
        }
    }
 
    @IBAction func toggleMic() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            plot.color = UIColor.red
            toggleListenButton.setTitle("Start listening", for: .normal)
        } else {
            startRecording()
            plot.color = UIColor.blue
            print("listening on")
            toggleListenButton.setTitle("Stop listening", for: .normal)
        }
    }
    
    func setupPlot() {
        plot = AKNodeOutputPlot(mic, frame: audioInputPlot.bounds)
        plot.plotType = .buffer
        plot.shouldFill = true
        plot.shouldMirror = true
        plot.color = UIColor.red
        audioInputPlot.addSubview(plot)
    }
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            self.presentAlert(title: "Audio session error", message: "Audio session properties not set", type: .notification, sender: self)
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            if result != nil {
                
                self.keyLabel.text = result?.bestTranscription.formattedString
                self.audioEngine.stop()
                recognitionRequest.endAudio()
                self.plot.color = UIColor.red
                self.toggleListenButton.setTitle("Start listening", for: .normal)
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.toggleListenButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            presentAlert(title: "Audio engine error", message: "Audio engine could not start", type: .notification, sender: self)
        }
        
        keyLabel.text = "[listening...]"
    }
    
    @IBAction func submitRegistration(_ sender: UIBarButtonItem) {
        
        createPerson()
        
        self.performSegue(withIdentifier: "completedRegistration", sender: self)
    }
    
    func createPerson() {
        let url = "https://api.projectoxford.ai/face/v1.0/persongroups/\(personGroupID)/persons"
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("26a1c49867934418bfcceac915443574", forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        
        let json: [String: Any] = [
            "name": userName,
            "voiceWord": self.keyLabel.text!
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            
            print("Create person initiated")
            
            if let nsError = error {
                print("failure")
            } else {
                let httpResponse = response as! HTTPURLResponse
                let statusCode = httpResponse.statusCode
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments)
                    if statusCode == 200 {
                        print("success")
                        print(json)
                        let swiftyJSONED = JSON(json)
                        let personID = swiftyJSONED["personId"].stringValue
                        print("new person ID: \(personID)")
                        self.addFace(pID: personID)
                    }
                }
                catch {
                    print("error")
                }
            }
        }
        task.resume()
    }
    
    func addFace(pID: String) {
        let url = "https://api.projectoxford.ai/face/v1.0/persongroups/\(personGroupID)/persons/\(pID)/persistedFaces"
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("26a1c49867934418bfcceac915443574", forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        
        let task = URLSession.shared.uploadTask(with: request as URLRequest, from: userImage) { (data, response, error) in
            
            print("Add face initiated")
            
            if let nsError = error {
                print("failure")
            } else {
                let httpResponse = response as! HTTPURLResponse
                let statusCode = httpResponse.statusCode
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments)
                    if statusCode == 200 {
                        print("success")
                        print(json)
                        let swiftyJSONED = JSON(json)
                        let faceID = swiftyJSONED["persistedFaceId"].stringValue
                        print("faceID: \(faceID)")
                        self.trainSet()
                    }
                }
                catch {
                    print("error")
                }
            }
        }
        task.resume()
    }
    
    func trainSet() {
        let url = "https://api.projectoxford.ai/face/v1.0/persongroups/\(personGroupID)/train"
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        
        request.httpMethod = "POST"
        request.setValue("26a1c49867934418bfcceac915443574", forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            
            print("Train set initiated")
            
            if let nsError = error {
                print("failure")
            } else {
                let httpResponse = response as! HTTPURLResponse
                let statusCode = httpResponse.statusCode
                
                if statusCode == 202 {
                    DispatchQueue.main.async {
                        self.activityIndicatorView.isHidden = true
                    }
                    print("success")
                }
            }
        }
        task.resume()
    }
}
