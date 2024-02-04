//
//  AppDelegate.swift
//  playsoundSwift-iOS
//
//  Created by DE4ME on 03.02.2024.
//

import UIKit;
import AVFoundation;


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?;

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let audioSession = AVAudioSession.sharedInstance();
        try? audioSession.setCategory(.playback);
        return true
    }

}

