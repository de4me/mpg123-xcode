//
//  AppDelegate.m
//  playsoundObjectiveC
//
//  Created by DE4ME on 03.10.2022.
//

#import "AppDelegate.h"

@import mpg123;


@interface AppDelegate ()

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    mpg123_init();
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    mpg123_exit();
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    sender.keyWindow.contentViewController.representedObject = filename;
    return YES;
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
