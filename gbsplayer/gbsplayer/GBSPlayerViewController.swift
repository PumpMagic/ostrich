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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //@todo don't do this. Give the app delegate the Game Boy or use some other architecture
        let appdelegate = NSApplication.shared().delegate as! AppDelegate
        appdelegate.gbsvc = self
    }
}


