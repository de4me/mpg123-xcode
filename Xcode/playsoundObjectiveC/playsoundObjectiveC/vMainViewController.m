//
//  ViewController.m
//  playsoundObjectiveC
//
//  Created by DE4ME on 03.10.2022.
//

#import "vMainViewController.h"
#import <limits.h>
#import "cPlaybackOperation.h"


#if MAC_OS_X_VERSION_MIN_REQUIRED >= 110000
@import UniformTypeIdentifiers;
#endif
@import mpg123;
@import out123;
@import syn123;


@interface vMainViewController()

@property (readonly, nullable) NSString* currentDecoder;
@property (readonly, nonnull) NSArray<NSString*>* availableDecoders;
@property (nullable) NSString* selectedDecoder;
@property (nullable) cPlaybackOperation* playbackOperation;
@property BOOL canChangeDecoder;

@end


@implementation vMainViewController
{
    NSURL* _Nullable _url;
    cPlaybackOperation* _Nullable _playbackOperation;
    NSString* _Nullable _selectedDecoder;
}

NSString* const decoder_default = @"(default)";
char* const decoder_context = "decoder";

//MARK: OVERRIDE

- (void)dealloc {
    [self.playbackOperation cancel];
    [self.playbackOperation waitUntilFinished];
    self.playbackOperation = NULL;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.url = NULL;
    self.canChangeDecoder = YES;
    self.selectedDecoder = NULL;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == decoder_context) {
        NSString* decoder = [change valueForKey:NSKeyValueChangeNewKey];
        [self updateDecoder: [decoder isKindOfClass:NSNull.class] ? NULL : decoder];
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

//MARK: GET/SET

- (NSURL*)url {
    return _url;
}

- (void)setUrl:(NSURL *)url {
    _url = url;
    if (url != NULL) {
        NSImage* image = NULL;
        [url getResourceValue:&image forKey:NSURLEffectiveIconKey error:NULL];
        self.imageView.image = image;
        self.nameTextField.stringValue = url.URLByDeletingPathExtension.lastPathComponent;
        [self.playButton setEnabled:YES];
        [NSDocumentController.sharedDocumentController noteNewRecentDocumentURL:url];
    } else {
        self.imageView.image = NULL;
        self.nameTextField.objectValue = NULL;
        [self.playButton setEnabled:NO];
    }
}

- (id)representedObject {
    return self.url;
}

- (void)setRepresentedObject:(id)representedObject {
    if ([representedObject isKindOfClass:NSURL.class]) {
        self.url = representedObject;
        return;
    }
    if ([representedObject isKindOfClass:NSString.class]) {
        self.url = [NSURL fileURLWithPath:representedObject];
        return;
    }
}

#if MAC_OS_X_VERSION_MIN_REQUIRED >= 110000
- (NSArray<UTType*>*)allowedContentTypes {
    return @[UTTypeMP3];
}
#else
- (NSArray<NSString*>*)allowedFileTypes {
    return @[@"mp3"];
}
#endif

- (NSArray<NSString*>*)availableDecoders {
    NSMutableArray<NSString*>* decoders = [NSMutableArray arrayWithObject:decoder_default];
    const char** decoder = mpg123_supported_decoders();
    if (decoder == NULL) {
        return decoders;
    }
    for(; *decoder; decoder++) {
        NSString* string = [NSString stringWithUTF8String:*decoder];
        if (string) {
            [decoders addObject:string];
        }
    }
    return decoders;
}

- (cPlaybackOperation*)playbackOperation {
    return _playbackOperation;
}

- (void)setPlaybackOperation:(cPlaybackOperation *)playbackOperation {
    [_playbackOperation removeObserver:self forKeyPath:@"decoder" context:decoder_context];
    [playbackOperation addObserver:self forKeyPath:@"decoder" options:NSKeyValueObservingOptionNew context:decoder_context];
    _playbackOperation = playbackOperation;
}

- (NSString*)selectedDecoder {
    return _selectedDecoder;
}

- (void)setSelectedDecoder:(NSString *)selectedDecoder {
    if (selectedDecoder != NULL && selectedDecoder.length > 0) {
        _selectedDecoder = selectedDecoder;
    } else {
        [self willChangeValueForKey:@"selectedDecoder"];
        _selectedDecoder = decoder_default;
        [self didChangeValueForKey:@"selectedDecoder"];
    }
}

- (NSString*)currentDecoder {
    return [self.selectedDecoder isEqualToString:decoder_default] ? NULL : self.selectedDecoder;
}

//MARK: UI

- (void)updateDecoder:(NSString*)decoder {
    if (NSThread.isMainThread) {
        [self willChangeValueForKey:@"currentDecoder"];
        self.selectedDecoder = decoder != NULL ? decoder : decoder_default;
        [self didChangeValueForKey:@"currentDecoder"];
    } else {
        [self performSelectorOnMainThread:@selector(updateDecoder:) withObject:decoder waitUntilDone:FALSE];
    }
}

//MARK: FUNC

- (void)stopOperation:(cPlaybackOperation*)playback {
    if (self.playbackOperation != playback) {
        return;
    }
    self.canChangeDecoder = YES;
    self.playbackOperation = NULL;
    [self.playButton setState:NSControlStateValueOff];
}

//MARK: ACTION

- (IBAction)openDocument:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
#if MAC_OS_X_VERSION_MIN_REQUIRED >= 110000
    panel.allowedContentTypes = self.allowedContentTypes;
#else
    panel.allowedFileTypes = self.allowedFileTypes;
#endif
    if ([panel runModal] != NSModalResponseOK) {
        return;
    }
    self.url = panel.URL;
}

- (IBAction)helpClick:(id)sender {
    NSMutableArray<NSString*>* array = [NSMutableArray new];
    const char** decoder = mpg123_supported_decoders();
    if (decoder) {
        NSMutableArray<NSString*>* decoders = [NSMutableArray array];
        [decoders addObject:@"<DECODERS>"];
        for(; *decoder; decoder++) {
            NSString* string = [NSString stringWithUTF8String:*decoder];
            if (string) {
                [decoders addObject:string];
            }
        }
        NSString* string = [decoders componentsJoinedByString:@"\n"];
        if (string) {
            [array addObject:string];
        }
    }
    out123_handle* handle = out123_new();
    if (handle) {
        char** name;
        char** desc;
        int count = out123_drivers(handle, &name, &desc);
        if (count>0) {
            NSMutableArray<NSString*>* modules = [NSMutableArray arrayWithCapacity:count];
            [modules addObject:@"<OUTPUTS>"];
            for (int i = 0; i<count; i++) {
                char* _name = name[i] ? : "?";
                char* _desc = desc[i];
                NSString* string;
                if (_desc != NULL && *_desc != 0) {
                    string = [NSString stringWithFormat:@"%s: %s", _name, _desc];
                } else {
                    string = [NSString stringWithUTF8String:_name];
                }
                if (string) {
                    [modules addObject:string];
                }
            }
            out123_stringlists_free(name, desc, count);
            NSString* string = [modules componentsJoinedByString:@"\n"];
            if (string) {
                [array addObject:string];
            }
        }
        out123_close(handle);
    }
    NSAlert* alert = [NSAlert new];
    alert.alertStyle = NSAlertStyleInformational;
    alert.informativeText = array.count > 0 ? [array componentsJoinedByString:@"\n\n"] : @"Empty";
    alert.messageText = [NSString stringWithFormat:@"mpg123 API: %i\nout123 API: %i\nsyn123 API: %i", MPG123_API_VERSION, OUT123_API_VERSION, SYN123_API_VERSION];
    [alert runModal];
}

-(IBAction)playClick:(NSButton*)sender {
    if (self.url == NULL) {
        return;
    }
    if (self.playbackOperation == NULL || self.playbackOperation.isFinished) {
        cPlaybackOperation* playback;
        self.playbackOperation = playback = [cPlaybackOperation playbackOperationWithURL:self.url output:NULL decoder:self.currentDecoder];
        __weak vMainViewController* weakSelf = self;
        self.playbackOperation.completionBlock = ^{
            [weakSelf performSelectorOnMainThread:@selector(stopOperation:) withObject:playback waitUntilDone:NO];
        };
        [self.playButton setState:NSControlStateValueOn];
        self.canChangeDecoder = NO;
        [self.playbackOperation start];
    } else {
        [self.playbackOperation cancel];
    }
}

@end
