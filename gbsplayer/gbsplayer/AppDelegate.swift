//
//  AppDelegate.swift
//  gbsplayer
//
//  Created by Owner on 8/17/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var gbsPlayerViewController: GBSPlayerViewController? = nil
    
    @IBAction func openFile(_ sender: NSMenuItem) {
        let panel = NSOpenPanel()
        panel.begin { result in
            if result == NSFileHandlingPanelOKButton {
                if let gbsPlayerViewController = self.gbsPlayerViewController {
                    let url = panel.urls[0]
                    gbsPlayerViewController.tryLoadingFile(at: url)
                }
            }
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

