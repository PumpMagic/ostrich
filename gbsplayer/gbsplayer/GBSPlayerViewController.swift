//
//  ViewController.swift
//  gbsplayer
//
//  Created by Ryan Conway.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Cocoa
import AudioKit


// Good GBS files: Castlevania, Double Dragon, Tetris, Dr. Mario.
// Iffy: Super Mario Land (track 5 barfs)

/// Volume on startup. Be sure to synchronize this with the volume slider's default value in the UI builder
let STARTUP_VOLUME = 0.25


class GBSPlayerViewController: NSViewController {
    let player = GBSPlayer()
    
    // Currently ready-to-play / playing track
    var track = 1
    
    @IBOutlet weak var statusLabel: NSTextField!
    
    func updateStatusLabel(withText text: String) {
        statusLabel.stringValue = text
        statusLabel.sizeToFit()
    }
    
    
    func stopPlayback() {
        player.stopPlayback()
        updateStatusLabel(withText: "Playback stopped")
    }
    
    func tryPlaying(track: Int) -> Bool {
        if player.startPlayback(of: track) {
            updateStatusLabel(withText: "Playing track \(track)")
            return true
        } else {
            stopPlayback()
        }
        
        return false
    }
    
    @IBAction func previousTrackButtonPressed(_ sender: NSButton) {
        if tryPlaying(track: track-1) {
            track -= 1
        }
    }
    
    @IBAction func playPauseButtonPressed(_ sender: NSButton) {
        if player.midSong {
            if player.paused {
                player.resumePlayback()
                updateStatusLabel(withText: "Playing track \(track)")
            } else {
                player.pausePlayback()
                updateStatusLabel(withText: "Paused on track \(track)")
            }
        } else {
            tryPlaying(track: track)
        }
    }
    
    @IBAction func stopButtonPressed(_ sender: NSButton) {
        stopPlayback()
    }
    
    @IBAction func nextTrackButtonPressed(_ sender: NSButton) {
        if tryPlaying(track: track+1) {
            track += 1
        }
    }
    
    func tryLoadingFile(at url: URL) {
        stopPlayback()
        
        if player.loadGBSFile(at: url) {
            track = player.firstTrack
            updateStatusLabel(withText: "Playback ready")
        } else {
            updateStatusLabel(withText: "File load failed. GBS format?")
        }
    }
    
    @IBAction func p1CheckboxChanged(_ sender: NSButton) {
        let newConnectedState = sender.state != 0
        player.gameBoy.alterPulse1Connection(connected: newConnectedState)
    }
    
    
    @IBAction func p2CheckboxChanged(_ sender: NSButton) {
        let newConnectedState = sender.state != 0
        player.gameBoy.alterPulse2Connection(connected: newConnectedState)
    }
    
    
    @IBAction func volumeSliderChanged(_ sender: NSSlider) {
        player.volume = sender.integerValue/100.0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        player.volume = STARTUP_VOLUME
        
        // Tell the app delegate that we exist, so it can pass us events like "file open attempt"
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.gbsvc = self
    }
}


