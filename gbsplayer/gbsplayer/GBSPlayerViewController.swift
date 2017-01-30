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

let STARTUP_VOLUME = 3 // out of 10
let MAX_VOLUME = 10

let COPYRIGHT_STRING = "©"
let TRACK_STRING = "Track"
let VOLUME_STRING = "VOL"
let EMPTY_STRING = ""

let WAVE_DISPLAY_REFRESH_PERIOD_MS = 33

let GB_FONT = NSFont(name: "Early-GameBoy", size: 12)


class GBSPlayerViewController: NSViewController, CustomButtonDelegate {
    let player = GBSPlayer()
    var currentHeader: GBSHeader? = nil
    var volume = STARTUP_VOLUME {
        didSet {
            handleUpdatedVolume()
        }
    }
    
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
    @IBOutlet weak var currentTrackLabel: NSTextField!
    @IBOutlet weak var volumeLabel: NSTextField!
    
    @IBOutlet weak var pulse1View: PulseWaveView!
    @IBOutlet weak var pulse2View: PulseWaveView!
    
    @IBOutlet weak var playPauseButton: GBRoundButton!
    @IBOutlet weak var stopButton: GBRoundButton!
    
    @IBOutlet weak var powerLight: GBPowerLight!
    
    
    func updateVolumeLabel() {
        if volume > 0 {
            volumeLabel.stringValue = "\(VOLUME_STRING) \(String(repeating: "-", count: volume))"
        } else {
            volumeLabel.stringValue = VOLUME_STRING
        }
        
        volumeLabel.sizeToFit()
    }
    
    func updatePlayerVolume() {
        player.volume = self.volume / MAX_VOLUME
    }
    
    func handleUpdatedVolume() {
        updateVolumeLabel()
        updatePlayerVolume()
    }
    
    /// Update the playback status label - playing, stopped, etc.
    func updatePlaybackStatusDisplay() {
        if player.gbsHeader == nil {
            powerLight.state = .Off
        } else {
            if player.midSong {
                if player.paused {
                    powerLight.state = .Yellow
                } else {
                    powerLight.state = .Green
                }
            } else {
                powerLight.state = .Red
            }
        }
    }
    
    /// Update the GBS metadata labels, using the GBS player's most recently loaded header
    func updateMetadataLabels() {
        if let header = player.gbsHeader {
            titleLabel.stringValue = header.title
            authorLabel.stringValue = header.author
            copyrightLabel.stringValue = "\(COPYRIGHT_STRING) \(header.copyright)"
        } else {
            titleLabel.stringValue = EMPTY_STRING
            authorLabel.stringValue = EMPTY_STRING
            copyrightLabel.stringValue = EMPTY_STRING
        }
        
        titleLabel.sizeToFit()
        authorLabel.sizeToFit()
        copyrightLabel.sizeToFit()
    }
    
    /// Update the current track label - what track we're on, out of how many
    func updateCurrentTrackLabel() {
        if let header = player.gbsHeader {
            currentTrackLabel.stringValue = "\(TRACK_STRING) \(track) of \(header.numSongs)"
        } else {
            currentTrackLabel.stringValue = EMPTY_STRING
        }
        
        currentTrackLabel.sizeToFit()
    }
    
    func setDisplayFont() {
        titleLabel.font = GB_FONT
        authorLabel.font = GB_FONT
        copyrightLabel.font = GB_FONT
        currentTrackLabel.font = GB_FONT
        volumeLabel.font = GB_FONT
    }
    
    /// Update every status display in the view
    func updateAllStatusDisplays() {
        updatePlaybackStatusDisplay()
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
        updatePlaybackStatusDisplay()
    }
    
    func tryPlaying(track: Int) -> Bool {
        let result = player.startPlayback(of: track)
        updatePlaybackStatusDisplay()
        
        return result
    }
    
    @IBAction func previousTrackButtonPressed(_ sender: NSButton) {
        if tryPlaying(track: track-1) {
            track -= 1
        }
    }
    
    func playPauseButtonPressed() {
        if player.midSong {
            if player.paused {
                player.resumePlayback()
            } else {
                player.pausePlayback()
            }
        } else {
            let _ = tryPlaying(track: track)
        }
        
        updatePlaybackStatusDisplay()
    }
    
    func stopButtonPressed() {
        stopPlayback()
    }
    
    @IBAction func nextTrackButtonPressed(_ sender: NSButton) {
        if tryPlaying(track: track+1) {
            track += 1
        }
    }
    
    @IBAction func volumeUpButtonPressed(_ sender: NSButton) {
        if volume < MAX_VOLUME {
            volume += 1
        }
    }
    
    @IBAction func volumeDownButtonPressed(_ sender: NSButton) {
        if volume > 0 {
            volume -= 1
        }
    }
    
    
    /// Try loading a new file
    func tryLoadingFile(at url: URL) {
        stopPlayback()
        
        if player.loadGBSFile(at: url) {
            track = player.firstTrack
            handleNewMetadata()
        }
        
        updatePlaybackStatusDisplay()
    }
    
    @IBAction func p1CheckboxChanged(_ sender: NSButton) {
        let newConnectedState = sender.state != 0
        player.gameBoy.alterPulse1Connection(connected: newConnectedState)
    }
    
    
    @IBAction func p2CheckboxChanged(_ sender: NSButton) {
        let newConnectedState = sender.state != 0
        player.gameBoy.alterPulse2Connection(connected: newConnectedState)
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
            self.pulse1View.needsDisplay = true
            self.pulse2View.needsDisplay = true
        }
        self.waveDisplayClocker = waveDisplayClocker
        waveDisplayClocker.resume()
    }
    
    func handleCustomButtonPress(sender: NSView) {
        if sender == playPauseButton {
            playPauseButtonPressed()
        } else if sender == stopButton {
            stopButtonPressed()
        }
    }
    
    func registerAsCustomButtonDelegate() {
        playPauseButton.delegate = self
        stopButton.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDisplayFont()
        handleUpdatedVolume()
        updateAllStatusDisplays()
        initializeWaveDisplays()
        
        registerAsCustomButtonDelegate()
        reportSelfToAppDelegate()
        
//        tryLoadingFile(at: URL(fileURLWithPath: "/Users/owner/Dropbox/emu/tetris.gbs"))
        
    }
}


