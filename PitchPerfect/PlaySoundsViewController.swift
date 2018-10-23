//
//  DetailViewController.swift
//  PitchPerfect
//
//  Created by Joao Neto on 15/10/18.
//  Copyright © 2018 Joao Neto. All rights reserved.
//

import UIKit
import AVFoundation

class PlaySoundsViewController: UIViewController {
    
    //MARK: - Variables
    fileprivate var recordedAudioURL: URL?
    fileprivate var audioFile: AVAudioFile?
    fileprivate var audioEngine: AVAudioEngine?
    fileprivate var audioPlayerNode: AVAudioPlayerNode?
    fileprivate var stopTimer: Timer?
    fileprivate var objPlayer: AVAudioPlayer?
    
    enum AudioType: CaseIterable {
        case slow
        case fast
        case chipmunk
        case vader
        case echo
        case reverb
    }
    
    //MARK: - IBOutlet
    @IBOutlet weak var btnSlow: UIButton! {
        didSet {
            btnSlow.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        }
    }
    @IBOutlet weak var btnFast: UIButton! {
        didSet {
            btnFast.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        }
    }
    @IBOutlet weak var btnLowPitch: UIButton! {
        didSet {
            btnLowPitch.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        }
    }
    @IBOutlet weak var btnHighPitch: UIButton! {
        didSet {
            btnHighPitch.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        }
    }
    @IBOutlet weak var btnEcho: UIButton! {
        didSet {
            btnEcho.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        }
    }
    @IBOutlet weak var btnReverb: UIButton! {
        didSet {
            btnReverb.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        }
    }
    @IBOutlet weak var btnStop: UIButton! {
        didSet {
            btnStop.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        }
    }
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Pitch Perfect"
        setupAudio()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureUI(.notPlaying)
    }
    
    //MARK: - IBAction
    @IBAction func actionStartPlay(_ sender: UIButton) {
        switch sender {
        case btnSlow:
            playSound(rate: 0.5)
        case btnFast:
            playSound(rate: 1.5)
        case btnHighPitch:
            playSound(pitch: 1000)
        case btnLowPitch:
            playSound(pitch: -1000)
        case btnEcho:
            playSound(echo: true)
        case btnReverb:
            playSound(reverb: true)
        default: break }
        
        configureUI(.playing)
        
    }
    
    @IBAction func actionStopPlay(_ sender: UIButton) {
        stopAudio()
    }
    
    //MARK: - Helper Methods
    public func setDataViewController(_ data: Any?) {
        if let data = data as? URL {
            recordedAudioURL = data
        }
    }
}

//MARK: - PlaySoundsViewController: AVAudioPlayerDelegate
extension PlaySoundsViewController: AVAudioPlayerDelegate {
    
    //MARK: Alerts
    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let RecordingDisabledTitle = "Recording Disabled"
        static let RecordingDisabledMessage = "You've disabled this app from recording your microphone. Check Settings."
        static let RecordingFailedTitle = "Recording Failed"
        static let RecordingFailedMessage = "Something went wrong with your recording."
        static let AudioRecorderError = "Audio Recorder Error"
        static let AudioSessionError = "Audio Session Error"
        static let AudioRecordingError = "Audio Recording Error"
        static let AudioFileError = "Audio File Error"
        static let AudioEngineError = "Audio Engine Error"
    }
    
    //MARK: PlayingState (raw values correspond to sender tags)
    enum PlayingState { case playing, notPlaying }
    
    //MARK: Audio Functions
    func setupAudio() {
        guard let url = recordedAudioURL else { return }
        // initialize (recording) audio file
        do {
            audioFile = try AVAudioFile(forReading: url)
        } catch {
            showAlert(Alerts.AudioFileError, message: String(describing: error))
        }
    }
    
    func playSound(rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false) {
        // initialize audio engine components
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        // node for playing audio
        audioPlayerNode = AVAudioPlayerNode()
        guard let audioPlayerNode = audioPlayerNode else { return }
        
        audioEngine.attach(audioPlayerNode)
        
        // node for adjusting rate/pitch
        let changeRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            changeRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            changeRatePitchNode.rate = rate
        }
        audioEngine.attach(changeRatePitchNode)
        
        // node for echo
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(echoNode)
        
        // node for reverb
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attach(reverbNode)
        
        // connect nodes
        if echo == true && reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
        } else if echo == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, audioEngine.outputNode)
        } else if reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, reverbNode, audioEngine.outputNode)
        } else {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, audioEngine.outputNode)
        }
        
        guard let audioFile = audioFile else { return }
        // schedule to play and start the engine!
        audioPlayerNode.stop()
        audioPlayerNode.scheduleFile(audioFile, at: nil) {
            
            var delayInSeconds: Double = 0
            
            if let lastRenderTime = self.audioPlayerNode?.lastRenderTime, let playerTime = self.audioPlayerNode?.playerTime(forNodeTime: lastRenderTime) {
                
                if let rate = rate {
                    delayInSeconds = Double(audioFile.length - playerTime.sampleTime) / Double(audioFile.processingFormat.sampleRate) / Double(rate)
                } else {
                    delayInSeconds = Double(audioFile.length - playerTime.sampleTime) / Double(audioFile.processingFormat.sampleRate)
                }
            }
            
            // schedule a stop timer for when audio finishes playing
            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(PlaySoundsViewController.stopAudio), userInfo: nil, repeats: false)
            RunLoop.main.add(self.stopTimer!, forMode: RunLoop.Mode.default)
        }
        
        do {
            try audioEngine.start()
        } catch {
            showAlert(Alerts.AudioEngineError, message: String(describing: error))
            return
        }
        
        // play the recording!
        audioPlayerNode.play()
    }
    
    @objc func stopAudio() {
        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }
        
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        
        configureUI(.notPlaying)
        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    //MARK: Connect List of Audio Nodes
    func connectAudioNodes(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine?.connect(nodes[x], to: nodes[x+1], format: audioFile?.processingFormat)
        }
    }
    
    //MARK: UI Functions
    func configureUI(_ playState: PlayingState) {
        switch playState {
        case .playing:
            setPlayButtonsEnabled(false)
            btnStop.isEnabled = true
        case .notPlaying:
            setPlayButtonsEnabled(true)
            btnStop.isEnabled = false
        }
    }
    
    func setPlayButtonsEnabled(_ enabled: Bool) {
        btnSlow.isEnabled = enabled
        btnFast.isEnabled = enabled
        btnHighPitch.isEnabled = enabled
        btnLowPitch.isEnabled = enabled
        btnEcho.isEnabled = enabled
        btnReverb.isEnabled = enabled
    }
    
    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
