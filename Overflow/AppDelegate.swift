//
//  AppDelegate.swift
//  Overflow
//
//  Created by Dallas McNeil on 8/05/2015.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    /// Status bar item of the application
    var statusItem:NSStatusItem?

    /// The menu contained by the status bar item
    var menu:NSMenu = NSMenu()
    
    /// Whether the trash will be checked and moved or not
    var working:Bool = true
    
    /// File manager to manage trash and desktop files
    var manager:FileManager = FileManager()
    
    /// List of files located inside the trash folder
    var files:[NSString] = []
    
    /// File path to the trash
    var trashPath:String = "/Users/\(NSUserName())/.Trash"
    
    /// File path to the desktop
    var desktopPath:String = "/Users/\(NSUserName())/Desktop"
    
    /// The minimum number of files in trash before Overflow will take action
    var minLoad:Int = 50
    
    /// The maximum number of files in the trash before Overflow will always take action
    var maxLoad:Int = 250
    
    /// The maximum number of files that can overflow when the maximum is reached
    var magnitude:Int = 10
    
    /// Time between each update to check for trash changing. Smaller time intervals will cause worse performance
    let updateTime:TimeInterval = 1
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Create status bar with icon
        statusItem = NSStatusBar.system().statusItem(withLength: 24)
        statusItem!.image = NSImage(named: "recycle")
        
        // Create menu items for stauts bar
        let title = NSMenuItem(title:"Overflow: Ver 1.0", action: nil, keyEquivalent: "")
        let onOrOff = NSMenuItem(title: "Turn Overflow Off", action: #selector(AppDelegate.turnOff(_:)), keyEquivalent: "")
        let about = NSMenuItem(title:"About", action: #selector(AppDelegate.about(_:)), keyEquivalent: "")
        let quit = NSMenuItem(title:"Quit", action: #selector(AppDelegate.quit(_:)), keyEquivalent: "")

        // Add menu items to menu
        menu.addItem(title)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(onOrOff)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(about)
        menu.addItem(quit)
        NSWorkspace.shared()
        // Set menu to be status bars menu
        statusItem!.menu = menu
        
        // Get path of all files in trash
        let tempFiles = (try! manager.contentsOfDirectory(atPath: trashPath))
        for file in tempFiles {
            files.append(NSString(string:file))
        }
        
        // Set a timer to call 'update' after a period of time
        Timer.scheduledTimer(timeInterval: updateTime, target: self, selector: #selector(AppDelegate.update), userInfo: nil, repeats: true)
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    /// Disable overflow taking action
    func turnOff(_ sender:AnyObject) {
        let item = menu.item(withTitle: "Turn Overflow Off")
        item!.title = "Turn Overflow On"
        item!.action = #selector(AppDelegate.turnOn(_:))
        working = false
    }
    
    /// Enable overflow taking action
    func turnOn(_ sender:AnyObject) {
        let item = menu.item(withTitle: "Turn Overflow On")
        item!.title = "Turn Overflow Off"
        item!.action = #selector(AppDelegate.turnOff(_:))
        working = true
    }
    
    /// Quit the application
    func quit(_ sender:AnyObject) {
        NSApplication.shared().terminate(self)
    }
    
    /// Present information about Overflow
    func about(_ sender:AnyObject) {
        let alert:NSAlert = NSAlert()
        alert.alertStyle = NSAlertStyle.informational
        alert.informativeText = "Overflow treats your trash like it should be. Pile too much up and it's bound to fall out. Keep your trash under control or your dektop will be full of clutter. For best results, add this application to your Login Items in System Preferences under the Users and Groups section. Made by Dallas McNeil"
        alert.messageText = "Overflow Version 1.0"
        alert.runModal()
        
    }
    
    /// Called every updateTime and will see if it needs to move files to the desktop
    func update() {
        
        // Check if application is allowed to move files
        if working {
            
            // Check files in trash and see if there are more than before
            var trashFiles:[NSString] = []
            var tempFiles = (try! manager.contentsOfDirectory(atPath: trashPath))
            for file in tempFiles {
                trashFiles.append(NSString(string:file))
            }
            if trashFiles.count > files.count {
            
                // Calculate the chance that files will be moved based on current load
                let theChance = Int(arc4random()%UInt32(maxLoad-minLoad))
                if theChance < trashFiles.count-minLoad {
                    
                    // Multiplier based on the amount of files in the trash
                    var multiplier = (trashFiles.count-minLoad)/(maxLoad-minLoad)
                    if multiplier > 1 {
                        multiplier = 1
                    }
                    
                    // Calculate the number of files that will be moved
                    let theMagnitude = Int(arc4random()%UInt32(magnitude*multiplier))
                    print(theMagnitude)
                    // Choose randomly which files will be moved by sorting files randomly and picking first ones
                    trashFiles = trashFiles.sorted {_, _ in arc4random() % 2 == 0}

                    // Use index to manage how many files have moved and stop if exceeded
                    var currentIndex = 0
                    
                    // Iterate over files and move first ones
                    for file in trashFiles {
                    
                        // Break loop if exceeded file limit
                        if currentIndex >= theMagnitude {
                            break
                        }
                        
                        // If file is not .DS_Store then move the file
                        if file != ".DS_Store" {
                    
                            // Try to move file and if not possible, print error
                            do {
                                try manager.moveItem(atPath: "\(trashPath)/\(file)", toPath: "\(desktopPath)/CRUMPLED-\(file)")
                            } catch let error as NSError {
                                print(error)
                            }
                            
                            NSWorkspace.shared()
                            
                            // Iterate current index to represent move
                            currentIndex += 1
                            
                        }
                    }
                }
                
                // Update files to represent changes to trash
                files = []
                tempFiles = (try! manager.contentsOfDirectory(atPath: trashPath))
                for file in tempFiles {
                    files.append(NSString(string:file))
                }
            }

        }
    }
}

