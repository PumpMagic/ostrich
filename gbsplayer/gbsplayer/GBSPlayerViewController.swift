//
//  ViewController.swift
//  gbsplayer
//
//  Created by Ryan Conway.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Cocoa
import AudioKit


//@todo general cleanup of this class - need to reuse code and shorten some variable names


// Good GBS files: Castlevania, Double Dragon, Tetris, Dr. Mario.
// Iffy: Super Mario Land (track 5 barfs)

let STARTUP_VOLUME = 2 // out of MAX_VOLUME
let MAX_VOLUME = 5

let COPYRIGHT_STRING = "©"
let VOLUME_STRING = "VOL"
let EMPTY_STRING = ""
let SCROLL_SUFFIX = "   "

let WAVE_DISPLAY_REFRESH_PERIOD_MS = 16
let LABEL_SCROLL_PERIOD_MS = 1000
let LABEL_SCROLL_CHARACTERS_PER_PERIOD = 1

let GB_FONT_POINT = 12
let GB_FONT = NSFont(name: "GameBoy-Super-Mario-Land", size: CGFloat(GB_FONT_POINT))



/// Controller for the interface to our GBS player.
class GBSPlayerViewController: NSViewController {
    let player = GBSPlayer()
    var volume = STARTUP_VOLUME {
        didSet {
            handleUpdatedVolume()
        }
    }
    
    var waveDisplayClocker: DispatchSourceTimer? = nil
    var labelScrollerClocker: DispatchSourceTimer? = nil
    
    // Currently ready-to-play / playing track
    var track = 0 {
        didSet {
            handleUpdatedTrack()
        }
    }
    private var trackString = ""
    
    @IBOutlet weak var screenView: NSBox!
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var authorLabel: NSTextField!
    @IBOutlet weak var copyrightLabel: NSTextField!
    @IBOutlet weak var currentTrackLabel: NSTextField!
    @IBOutlet weak var volumeLabel: NSTextField!
    // A redundant collection of all of our labels, initialized on startup, for easy iteration
    var labels: [NSTextField] = []
    
    private var scrollingTitleLabelIndex = 0
    private var scrollingAuthorLabelIndex = 0
    private var scrollingCopyrightLabelIndex = 0
    
    @IBOutlet weak var pulse1View: PulseWaveView!
    @IBOutlet weak var pulse2View: PulseWaveView!
    private var pulse1Connected = true
    private var pulse2Connected = true
    
    @IBOutlet weak var dPad: GBDPad!
    @IBOutlet weak var playPauseButton: CustomButton!
    @IBOutlet weak var stopButton: CustomButton!
    @IBOutlet weak var pulse1EnableButton: CustomButton!
    @IBOutlet weak var pulse2EnableButton: CustomButton!
    
    @IBOutlet weak var powerLight: GBPowerLight!
    
    private var screenWidth: Float {
        guard let screenView = self.screenView else {
            return 0
        }
        
        return Float(screenView.bounds.width)
    }

    
    
    /** USER INTERACTION HANDLERS */
    
    func updateVolumeLabel() {
        if volume > 0 {
            volumeLabel.stringValue = "\(VOLUME_STRING) \(String(repeating: "-", count: volume))"
        } else {
            volumeLabel.stringValue = VOLUME_STRING
        }
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
            powerLight.state = .Red
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
    
    /// Update the GBS metadata labels, using the GBS player's most recently loaded header.
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
    }
    
    /// Update the current track label - what track we're on, out of how many.
    func updateCurrentTrackLabel() {
        if let header = player.gbsHeader {
            trackString = "\(track) of \(header.numSongs)"
        } else {
            trackString = EMPTY_STRING
        }
        
        currentTrackLabel.stringValue = trackString
    }
    
    func handleUpdatedTrack() {
        updateCurrentTrackLabel()
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
    
    func volumeUpButtonPressed() {
        if volume < MAX_VOLUME {
            volume += 1
        }
    }
    
    func volumeDownButtonPressed() {
        if volume > 0 {
            volume -= 1
        }
    }
    
    func previousTrackButtonPressed() {
        if tryPlaying(track: track-1) {
            track -= 1
        }
    }
    
    func nextTrackButtonPressed() {
        if tryPlaying(track: track+1) {
            track += 1
        }
    }
    
    func dpadPressed(direction: GBDPad.Direction) {
        switch direction {
        case .Neutral:
            break
        case .Up:
            volumeUpButtonPressed()
        case .Down:
            volumeDownButtonPressed()
        case .Left:
            previousTrackButtonPressed()
        case .Right:
            nextTrackButtonPressed()
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
    
    func playbackButtonPressed(sender: NSView) {
        if sender == playPauseButton {
            playPauseButtonPressed()
        } else if sender == stopButton {
            stopButtonPressed()
        }
    }
    
    func p1EnableButtonPressed() {
        let newState = !pulse1Connected
        player.gameBoy.alterPulse1Connection(connected: newState)
        pulse1Connected = newState
    }
    
    func p2EnableButtonPressed() {
        let newState = !pulse2Connected
        player.gameBoy.alterPulse2Connection(connected: newState)
        pulse2Connected = newState
    }
    
    func waveformDisplayButtonPressed(sender: NSView) {
        if sender == pulse1EnableButton {
            p1EnableButtonPressed()
        } else if sender == pulse2EnableButton {
            p2EnableButtonPressed()
        }
    }
    
    /// Try loading a new file.
    func tryLoadingFile(at url: URL) {
        stopPlayback()
        
        if player.loadGBSFile(at: url) {
            track = player.firstTrack
            handleNewMetadata()
        }
        
        updatePlaybackStatusDisplay()
    }
    
    
    
    /** PERIODIC DISPLAY UPDATE ROUTINES */
    
    func scroll(text: String, across label: NSTextField, by characters: Int, lastIndex: Int) -> Int {
        // Only scroll if we need to
        let numDisplayableCharacters = Int(label.bounds.width) / GB_FONT_POINT
        let numDesiredCharacters = text.characters.count
        
        if numDesiredCharacters > numDisplayableCharacters {
            // The width of the complete string exceeds the width of the view; we need to scroll it
            let stringToScroll = "\(text)\(SCROLL_SUFFIX)"
            let stringToScrollNumCharacters = stringToScroll.characters.count
            
            // Advance the starting index of the string we'll display
            let newIndex = (lastIndex + characters) % stringToScrollNumCharacters
            
            // Rotate the source string around the start index and clip it to get our output
            let splitIndex = stringToScroll.index(stringToScroll.startIndex, offsetBy: newIndex)
            let leftSide = stringToScroll.substring(to: splitIndex)
            let rightSide = stringToScroll.substring(from: splitIndex)
            let rotated = "\(rightSide)\(leftSide)"
            let output = rotated.substring(to: rotated.index(rotated.startIndex, offsetBy: numDisplayableCharacters))
            
            label.stringValue = output
            
            return newIndex
        } else {
            label.stringValue = text
            return 0
        }
    }
    
    /// Scroll all scrollable labels by a given number of characters.
    /// This function assumes the relevant labels' fonts are monospaced.
    func scrollLabels(by characters: Int) {
        guard let currentHeader = self.player.gbsHeader else {
            return
        }
        
        scrollingTitleLabelIndex = scroll(text: currentHeader.title, across: titleLabel, by: LABEL_SCROLL_CHARACTERS_PER_PERIOD, lastIndex: scrollingTitleLabelIndex)
        scrollingAuthorLabelIndex = scroll(text: currentHeader.author, across: authorLabel, by: LABEL_SCROLL_CHARACTERS_PER_PERIOD, lastIndex: scrollingAuthorLabelIndex)
        scrollingCopyrightLabelIndex = scroll(text: "\(COPYRIGHT_STRING) \(currentHeader.copyright)", across: copyrightLabel, by: LABEL_SCROLL_CHARACTERS_PER_PERIOD, lastIndex: scrollingCopyrightLabelIndex)
    }
    
    
    
    /** INITIALIZATION ROUTINES */
    
    func collectLabels() {
        self.labels = [titleLabel, authorLabel, copyrightLabel, currentTrackLabel, volumeLabel]
    }
    
    func setLabelFonts() {
        labels.forEach {
            $0.font = GB_FONT
        }
    }
    
    func setLabelPlaceholderColors() {
        let attributes: [String : AnyObject] = [NSForegroundColorAttributeName: GAMEBOY_PALLETTE_01]
        
        labels.forEach {
            if let placeholderString = $0.placeholderString {
                if $0 != currentTrackLabel {
                    // Default behavior
                    $0.placeholderAttributedString = NSAttributedString(string: placeholderString, attributes: attributes)
                } else {
                    // Workaround for NSTextField / NSAttributedString missing a setAttribute()-like method to
                    // preserve the right-justifcation of the current track label
                    let rightAlignedParagraphStyle = NSMutableParagraphStyle()
                    rightAlignedParagraphStyle.alignment = .right
                    var rightAlignedAttributes = attributes
                    rightAlignedAttributes[NSParagraphStyleAttributeName] = rightAlignedParagraphStyle
                    $0.placeholderAttributedString = NSAttributedString(string: placeholderString, attributes: rightAlignedAttributes)
                }
            }
        }
    }
    
    /// Initialize the wave displays by telling them which channels to display and starting a refresh timer.
    func initializeWaveDisplays() {
        pulse1View.channel = player.gameBoy.apu.pulse1
        pulse2View.channel = player.gameBoy.apu.pulse2
        
        //@todo this shouldn't need to go in the main queue, since it doesn't directly draw things?
        let waveDisplayClocker = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        waveDisplayClocker.scheduleRepeating(deadline: .now(),
                                             interval: .milliseconds(WAVE_DISPLAY_REFRESH_PERIOD_MS),
                                             leeway: .milliseconds(1))
        waveDisplayClocker.setEventHandler() {
            self.pulse1View.needsDisplay = true
            self.pulse2View.needsDisplay = true
        }
        self.waveDisplayClocker = waveDisplayClocker
        waveDisplayClocker.resume()
    }
    
    func initializeLabelScrollers() {
        //@todo this shouldn't need to go in the main queue, since it doesn't directly draw things?
        let labelScrollerClocker = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        labelScrollerClocker.scheduleRepeating(deadline: .now(),
                                               interval: .milliseconds(LABEL_SCROLL_PERIOD_MS),
                                               leeway: .milliseconds(10))
        labelScrollerClocker.setEventHandler() {
            self.scrollLabels(by: LABEL_SCROLL_CHARACTERS_PER_PERIOD)
        }
        self.labelScrollerClocker = labelScrollerClocker
        labelScrollerClocker.resume()
    }
    
    
    func registerAsButtonDelegate() {
        playPauseButton.setEventHandler(callback: self.playbackButtonPressed)
        stopButton.setEventHandler(callback: self.playbackButtonPressed)
        pulse1EnableButton.setEventHandler(callback: self.waveformDisplayButtonPressed)
        pulse2EnableButton.setEventHandler(callback: self.waveformDisplayButtonPressed)
        dPad.setEventHandler(callback: self.dpadPressed)
    }
    
    /// Tell the app delegate that we exist, so it can pass us events like "file open attempt".
    func reportSelfToAppDelegate() {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.gbsPlayerViewController = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectLabels()
        setLabelFonts()
        setLabelPlaceholderColors()
        handleUpdatedVolume()
        updateAllStatusDisplays()
        initializeLabelScrollers()
        initializeWaveDisplays()
        
        registerAsButtonDelegate()
        reportSelfToAppDelegate()
    }
}


