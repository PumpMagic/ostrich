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


let READY_STRING = "Ready"
let PLAYING_STRING = "Playing"
let PAUSED_STRING = "Paused"
let LOAD_FAILURE_STRING = "File parse failure"
let COMPOSED_BY_STRING = "Composed by"
let COPYRIGHT_STRING = "Copyright"
let TRACK_STRING = "Track"
let NO_GBS_LOADED_STRING = "No GBS file loaded"
let EMPTY_STRING = ""

let WAVE_DISPLAY_REFRESH_PERIOD_MS = 33


class GBSPlayerViewController: NSViewController {
    let player = GBSPlayer()
    var currentHeader: GBSHeader? = nil
    
    //@todo clean this up
    var waveDisplayClocker: DispatchSourceTimer?
    
    // Currently ready-to-play / playing track
    var track = 0 {
        didSet {
            updateCurrentTrackLabel()
        }
    }
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var authorLabel: NSTextField!
    @IBOutlet weak var copyrightLabel: NSTextField!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var currentTrackLabel: NSTextField!
    
    @IBOutlet weak var pulse1View: PulseWaveView!
    @IBOutlet weak var pulse2View: PulseWaveView!
    
    @IBOutlet weak var someButton: GBRoundButton!
    
    /// Update the playback status label - playing, stopped, etc.
    func updateStatusLabel() {
        let newValue: String
        if player.gbsHeader == nil {
            newValue = NO_GBS_LOADED_STRING
        } else {
            if player.midSong {
                if player.paused {
                    newValue = PAUSED_STRING
                } else {
                    newValue = PLAYING_STRING
                }
            } else {
                newValue = READY_STRING
            }
        }
        
        statusLabel.stringValue = newValue
        statusLabel.sizeToFit()
    }
    
    /// Update the GBS metadata labels, using the GBS player's most recently loaded header
    func updateMetadataLabels() {
        if let header = player.gbsHeader {
            //titleLabel.stringValue = header.title
            titleLabel.stringValue = "butts farts butts farts butts farts butts farts butts farts butts farts"
            authorLabel.stringValue = "\(COMPOSED_BY_STRING) \(header.author)"
            copyrightLabel.stringValue = "\(COPYRIGHT_STRING) \(header.copyright)"
        } else {
            titleLabel.stringValue = EMPTY_STRING
            authorLabel.stringValue = EMPTY_STRING
            copyrightLabel.stringValue = EMPTY_STRING
        }
        
        //titleLabel.sizeToFit()
        authorLabel.sizeToFit()
        copyrightLabel.sizeToFit()
    }
    
    /// Update the current track label - what track we're on, out of how many
    func updateCurrentTrackLabel() {
        if let header = player.gbsHeader {
            currentTrackLabel.stringValue = "\(TRACK_STRING) \(track) / \(header.numSongs)"
        } else {
            currentTrackLabel.stringValue = EMPTY_STRING
        }
        
        currentTrackLabel.sizeToFit()
    }
    
    /// Update every label in the view
    func updateAllLabels() {
        updateStatusLabel()
        updateMetadataLabels()
        updateCurrentTrackLabel()
    }
    
    /// Initialize the next track and track count variables using the GBS player's most recently
    /// loaded header
    func initializeTrackNumber() {
        if let header = player.gbsHeader {
            track = Int(header.firstSong)
        }
    }
    
    /// Handle having loaded a new GBS file in the GBS player
    func handleNewMetadata() {
        updateMetadataLabels()
        initializeTrackNumber()
    }
    
    
    func stopPlayback() {
        player.stopPlayback()
        updateStatusLabel()
    }
    
    func tryPlaying(track: Int) -> Bool {
        let result = player.startPlayback(of: track)
        updateStatusLabel()
        
        return result
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
            } else {
                player.pausePlayback()
            }
        } else {
            let _ = tryPlaying(track: track)
        }
        
        updateStatusLabel()
    }
    
    @IBAction func stopButtonPressed(_ sender: NSButton) {
        stopPlayback()
    }
    
    @IBAction func nextTrackButtonPressed(_ sender: NSButton) {
        if tryPlaying(track: track+1) {
            track += 1
        }
    }
    
    /// Try loading a new file
    func tryLoadingFile(at url: URL) {
        stopPlayback()
        
        if player.loadGBSFile(at: url) {
            track = player.firstTrack
            handleNewMetadata()
        }
        
        updateStatusLabel()
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
    
    /// Tell the app delegate that we exist, so it can pass us events like "file open attempt"
    func reportSelfToAppDelegate() {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.gbsPlayerViewController = self
    }
    
    /// Initialize the wave displays by telling them which channels to display and starting a refresh timer
    func initializeWaveDisplays() {
        pulse1View.channel = player.gameBoy.apu.pulse1
        pulse2View.channel = player.gameBoy.apu.pulse2
        
        let waveDisplayClocker = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        waveDisplayClocker.scheduleRepeating(deadline: .now(), interval: .milliseconds(WAVE_DISPLAY_REFRESH_PERIOD_MS), leeway: .milliseconds(1))
        waveDisplayClocker.setEventHandler() {
            self.pulse1View.setNeedsDisplay(self.pulse1View.bounds)
            self.pulse2View.setNeedsDisplay(self.pulse2View.bounds)
            self.someButton.setNeedsDisplay(self.someButton.bounds)
        }
        self.waveDisplayClocker = waveDisplayClocker
        waveDisplayClocker.resume()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        player.volume = STARTUP_VOLUME
        reportSelfToAppDelegate()
        updateAllLabels()
        initializeWaveDisplays()
    }
}


