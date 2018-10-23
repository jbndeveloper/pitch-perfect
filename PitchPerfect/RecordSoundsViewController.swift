//
//  RecordSoundsViewController.swift
//  PitchPerfect
//
//  Created by Joao Neto on 15/10/18.
//  Copyright © 2018 Joao Neto. All rights reserved.
//

import UIKit
import AVFoundation

class RecordSoundsViewController: UIViewController {
    
    //MARK: - Variables
    fileprivate enum Strings {
        static let descActivate = "Recording in Progress"
        static let descDesative = "Tap to Record"
        static let vcIdentify = "stopRecording"
        static let errorRecord = "recording was not successful"
    }
    
    fileprivate var audioRecorder: AVAudioRecorder?
    
    //MARK: - IBOutlet
    @IBOutlet weak var btnPlayRecord: UIButton!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var btnStopRecord: UIButton!
    
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureUI(isRecording: false)
        title = "Pitch Perfect"
    }

    //MARK: - IBAction
    @IBAction func actionPlayRecord(_ sender: UIButton) {
        
        configureUI(isRecording: true)
        //directory for file
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                          .userDomainMask,
                                                          true)[0] as String
        //name file
        let recordingName = "recordedVoice.wave"
        //final path file
        let pathArray = [dirPath, recordingName]
        //url file
        guard let filePath = URL(string: pathArray.joined(separator: "/")) else { return }
        //get session audio singleton
        let session = AVAudioSession.sharedInstance()

        do {
            //ios 12 new set category
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
            //set audio record
            try audioRecorder = AVAudioRecorder(url: filePath, settings: [:])
        } catch {
            print(error)
        }
        
        audioRecorder?.delegate = self
        
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
        audioRecorder?.record()
        
    }
    
    @IBAction func actionStopRecord(_ sender: UIButton) {
        configureUI(isRecording: false)
        
        audioRecorder?.stop()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
        } catch {
            print(error)
        }
    }
    
    //MARK: - Helper Methods
    fileprivate func configureUI(isRecording recording: Bool) {
        lblDescription.text = recording ? Strings.descActivate : Strings.descDesative
        btnPlayRecord.isEnabled = recording ? false : true
        btnStopRecord.isEnabled = recording ? true : false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Strings.vcIdentify,
        let vc = segue.destination as? PlaySoundsViewController {
            if let url = sender as? URL {
                vc.setDataViewController(url)
            }
        }
    }
}

//MARK: - RecordSoundsViewController: AVAudioRecorderDelegate
extension RecordSoundsViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            performSegue(withIdentifier: Strings.vcIdentify, sender: audioRecorder?.url)
        }
        
    }

}

