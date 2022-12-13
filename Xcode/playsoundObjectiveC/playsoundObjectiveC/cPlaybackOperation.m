//
//  cPlaybackOperation.m
//  playsoundObjectiveC
//
//  Created by DE4ME on 04.10.2022.
//

#import "cPlaybackOperation.h"

@import mpg123;
@import out123;
@import syn123;


@interface cPlaybackOperation()

@property (nonnull) NSURL* url;

@end


@implementation cPlaybackOperation
{
    BOOL _executing;
    BOOL _finished;
}

#if DEBUG
- (void)dealloc {
    NSLog(@"%@: %s", NSStringFromClass(self.class), __func__);
}
#endif

+ (instancetype)playbackOperationWithURL:(NSURL*)url output:(NSString*)output decoder:(NSString*)decoder {
    return [[self new] initWithURL:url output:output decoder:decoder];
}

- (instancetype)initWithURL:(NSURL*)url output:(NSString*)output decoder:(NSString*)decoder {
    if (self = [super init]) {
        self.url = url;
        self.output = output;
        self.decoder = decoder;
        _executing = NO;
        _finished = NO;
    }
    return self;
}

- (BOOL)isConcurrent {
    return YES;
}
 
- (BOOL)isExecuting {
    return _executing;
}
 
- (BOOL)isFinished {
    return _finished;
}

- (void)start {
    if (self.isCancelled) {
       [self willChangeValueForKey:@"isFinished"];
       _finished = YES;
       [self didChangeValueForKey:@"isFinished"];
    } else {
        [self willChangeValueForKey:@"isExecuting"];
        [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
        _executing = YES;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)completeOperation {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    _executing = NO;
    _finished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)main {
    int channels;
    int encoding;
    int framesize;
    long rate;
    int error;
    mpg123_handle *mh = NULL;
    out123_handle *ao = NULL;
    const char *infile = self.url.path.UTF8String;
    const char *output = self.output.UTF8String;
    const char *decoder = self.decoder.UTF8String;
    do {
        mh = mpg123_new(NULL, &error);
        if (mh == NULL) {
            NSLog(@"error: mpg123_new() %s", mpg123_plain_strerror(error));
            break;
        }
        ao = out123_new();
        if (ao == NULL) {
            NSLog(@"error: out123_new()");
            break;
        }
        if (mpg123_open(mh, infile)) {
            NSLog(@"error: mpg123_open() %s", mpg123_strerror(mh));
            break;
        }
        if (mpg123_getformat(mh, &rate, &channels, &encoding)) {
            NSLog(@"error: mpg123_getformat() %s", mpg123_strerror(mh));
            break;
        }
        if (out123_open(ao, output, decoder)) {
            NSLog(@"error: out123_open() %s", out123_strerror(ao));
            break;
        }
        if (out123_driver_info(ao, (char**) &output, (char**) &decoder) == OUT123_OK) {
            self.output = output != NULL && *output != 0 ? [NSString stringWithUTF8String:output] : NULL;
            self.decoder = decoder != NULL && *decoder != 0 ? [NSString stringWithUTF8String:decoder] : NULL;
#if DEBUG
            NSLog(@"Effective output driver: %s", output ? output : "<nil> (default)");
            NSLog(@"Effective output file:   %s", decoder ? decoder : "<nil> (default)");
#endif
        } else {
            NSLog(@"warning: out123_driver_info() %s", out123_strerror(ao));
        }
        mpg123_format_none(mh);
        mpg123_format(mh, rate, channels, encoding);
#if DEBUG
        const char *encname = out123_enc_name(encoding);
        NSLog(@"Playing with %i channels and %li Hz, encoding %s.", channels, rate, encname ? encname : "?");
#endif
        if (out123_start(ao, rate, channels, encoding)) {
            NSLog(@"error: out123_start() %s", out123_strerror(ao));
            break;
        }
        if (out123_getformat(ao, NULL, NULL, NULL, &framesize)) {
            NSLog(@"error: out123_getformat() %s", out123_strerror(ao));
            break;
        }
        size_t buffer_size = mpg123_outblock(mh);
        unsigned char* buffer = malloc(buffer_size);
        if (buffer == NULL) {
            NSLog(@"error: malloc() %zu", buffer_size);
            break;
        }
        size_t done = 0;
        off_t samples = 0;
#if DEBUG
        NSLog(@"Now playing: %s", infile);
#endif
        do {
            size_t played;
            error = mpg123_read(mh, buffer, buffer_size, &done);
            played = out123_play(ao, buffer, done);
            if(played != done) {
                NSLog(@"warning: written less than gotten from libmpg123: %li != %li", (long)played, (long)done);
            }
            samples += played/framesize;
        } while (!self.isCancelled && done && error == MPG123_OK);
#if DEBUG
        NSLog(@"Playback completed: %s", infile);
#endif
        free(buffer);
        if (error != MPG123_DONE && error != MPG123_OK) {
            NSLog(@"warning: decoding ended prematurely because: %s", error == MPG123_ERR ? mpg123_strerror(mh) : mpg123_plain_strerror(error) );
        }
#if DEBUG
        NSLog(@"%li samples written.", (long)samples);
#endif
    } while (false);
    out123_close(ao);
    mpg123_delete(mh);
    [self completeOperation];
}

@end
