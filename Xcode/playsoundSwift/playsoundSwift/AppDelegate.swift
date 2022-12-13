//
//  AppDelegate.swift
//  playsoundSwift
//
//  Created by DE4ME on 04.10.2022.
//

import Cocoa;
import mpg123;


@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        mpg123_init();
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        mpg123_exit();
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        sender.keyWindow?.contentViewController?.representedObject = filename;
        return true;
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true;
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true;
    }

}

