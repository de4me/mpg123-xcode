//
//  ViewController.h
//  playsoundObjectiveC
//
//  Created by DE4ME on 03.10.2022.
//

#import <Cocoa/Cocoa.h>
#import "cPlaybackOperation.h"


@interface vMainViewController : NSViewController

@property IBOutlet NSImageView* imageView;
@property IBOutlet NSTextField* nameTextField;
@property IBOutlet NSButton* playButton;

@property NSURL* url;

@end

