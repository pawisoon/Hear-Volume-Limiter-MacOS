//
//  AppDelegate.swift
//  Volume Limiter
//
//  Created by pawisoon on 25/01/2020.
//  Copyright © 2020 Pawel Szydlowski. All rights reserved.
//

import Cocoa
import ServiceManagement
import AudioToolbox
import CoreAudio

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var timer: Timer? = nil
    var volume_timer: Timer? = nil
    var separatorsStatus: NSControl.StateValue = .on
    let helperBundleName = "com.szydlowsky.LauncherApplication"
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        if Preferences.firstRunGone == false {
            // This will be executed on first run
            Preferences.firstRunGone = true

            // Set preferences to their defaults
            Preferences.restore()
        }


        DockIcon.standard.setVisibility(Preferences.showDockIcon)
    }
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let foundHelper = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == helperBundleName
        }
        
        
        DistributedNotificationCenter.default.addObserver(self,
        selector: #selector(volumeChangeEvent(_:)),
        name: NSNotification.Name(rawValue: "com.apple.sound.settingsChangedNotification"),
        object: nil)
        
        
        guard let statusButton = statusBarItem.button else { return }
        statusButton.title = "VL"
//        statusButton.title = Preferences.showSeconds ? Date.now.stringTimeWithSeconds : Date.now.stringTime
//        timer = Timer.scheduledTimer(
//            timeInterval: 1,
//            target: self,
//            selector: #selector(updateStatusText),
//            userInfo: nil,
//            repeats: true
//        )
        
        
        volume_timer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(updateVolume),
            userInfo: nil,
            repeats: true
        )
        
        let statusMenu: NSMenu = NSMenu()
            
        statusMenu.addItem(withTitle: "Volume Limiter", action: nil, keyEquivalent: "")
        statusMenu.addSeparator()
        
        
        let menuItem = NSMenuItem()
        let statusSlider = NSSlider()
        statusSlider.minValue = 1
        statusSlider.maxValue = 100
        statusSlider.sliderType = .linear
        statusSlider.action = #selector(setLimit)
        statusSlider.intValue = Int32(Preferences.volumeLimit)
        

        statusMenu.addItem(NSMenuItem(title: "Set volume limit", action: nil, keyEquivalent: ""))

        menuItem.title = "Set volume limit"
        menuItem.view = statusSlider
        statusSlider.setFrameSize(NSSize(width: 160, height: 16))
        
        let toggleLaunchAtLogin: NSMenuItem = {
            let item = NSMenuItem(
                title: "Launch at Login",
                action: #selector(toggleSeconds),
                keyEquivalent: ""
            )
            
            item.tag = 3
            item.target = self
            item.state = Preferences.showSeconds.stateValue
            
            return item
        }()
        
        let quitApplicationItem: NSMenuItem = {
            let item = NSMenuItem(title: "Quit", action: #selector(terminate), keyEquivalent: "q")
            item.target = self
            
            return item
        }()
        
        statusMenu.addItems(
            menuItem,
            .separator(),
            
            .separator(),
            
            toggleLaunchAtLogin,
            
            .separator(),
            
            quitApplicationItem
        )
        
        statusBarItem.menu = statusMenu
//        RunLoop.main.add(timer!, forMode: .common)
        RunLoop.main.add(volume_timer!, forMode: .common)
    }
}

/*
 * -----------------------
 * MARK: - Actions
 * ------------------------
 */
extension AppDelegate {
    @objc
    func updateVolume(_sender: Timer){
        let set_limit = Float(Preferences.volumeLimit) / 100
//        print(set_limit)
        if(round(100 * NSSound.systemVolume())/100>set_limit){
            print("system volume was")
            print(NSSound.systemVolume())
            print("Changing to allowed limit")
            let a = Float(Preferences.volumeLimit) / 100
            NSSound.setSystemVolume(a)
        }
    }
    
    @objc
    func setLimit(_sender: NSSlider){
//        print(_sender.floatValue)
        Preferences.volumeLimit = Int(_sender.intValue)
//        print("LIMIT set ")
//        print(Preferences.volumeLimit)
        NSSound.setSystemVolume(_sender.floatValue/100)
        
    }
    
    @objc
    func updateStatusText(_ sender: Timer) {
        guard let statusButton = statusBarItem.button else { return }
        var title: String = (Preferences.showSeconds ? Date.now.stringTimeWithSeconds : Date.now.stringTime)

        if Preferences.useFlashDots && Date.now.seconds % 2 == 0 {
            title = title.replacingOccurrences(of: ":", with: " ")
        }

        statusButton.title = title
    }
    
    @objc
    func toggleFlashingSeparators(_ sender: NSMenuItem) {
        Preferences.useFlashDots = !Preferences.useFlashDots
        
        if let menu = statusBarItem.menu, let item = menu.item(withTag: 1) {
            item.state = Preferences.useFlashDots.stateValue
        }
    }
    
    
    @objc
    func toggleDockIcon(_ sender: NSMenuItem) {
        Preferences.showDockIcon = !Preferences.showDockIcon

        DockIcon.standard.setVisibility(Preferences.showDockIcon)

        if let menu = statusBarItem.menu, let item = menu.item(withTag: 2) {
            item.state = Preferences.showDockIcon.stateValue
        }
    }
    
    @objc
    func toggleSeconds(_ sender: NSMenuItem) {
        Preferences.showSeconds = !Preferences.showSeconds
        
        if let menu = statusBarItem.menu, let item = menu.item(withTag: 3) {
            let isAuto = item.state == .on
            SMLoginItemSetEnabled(helperBundleName as CFString, isAuto)
            item.state = Preferences.showSeconds.stateValue
        }
    }
    
    @objc
    func terminate(_ sender: NSMenuItem) {
        NSApp.terminate(sender)
    }
    @objc
    func volumeChangeEvent(_ evt: NSEvent) {
        print("CHANGED")
    }
}
