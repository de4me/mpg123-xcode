//
//  cPlaybackOperation.swift
//  playsoundSwift
//
//  Created by DE4ME on 04.10.2022.
//

import Cocoa;
import mpg123;
import out123;


class cPlaybackOperation: Operation {
    
    //MARK: STATIC
    
    fileprivate static let operationQueue: OperationQueue = .init();
    
    //MARK: CONST
    
    let url: URL;
    
    //MARK: VAR
    
    @objc dynamic var output: String?;
    @objc dynamic var decoder: String?;
    
    //MARK: OVERRIDE
    
#if DEBUG
    deinit{
        print(#function, NSStringFromClass(type(of: self)));
    }
#endif
    
    init(url: URL, output: String? = nil, decoder: String? = nil) {
        self.url = url;
        self.output = output;
        self.decoder = decoder;
    }
    
    override func main() {
        do {
            var channels: Int32 = 0;
            var encoding: Int32 = 0;
            var framesize: Int32 = 0;
            var rate: Int = 0;
            var error: Int32 = 0;
            let infile = self.url.path;
            let output = self.output;
            let decoder = self.decoder;
            guard let mh = mpg123_new(nil, &error) else {
                throw mpg123Error(code: error);
            }
            defer {
                mpg123_delete(mh);
            }
            guard let ao = out123_new() else {
                throw out123Error(OUT123_DOOM);
            }
            defer {
                out123_del(ao);
            }
            guard mpg123_open(mh, infile) == MPG123_OK.rawValue,
                  mpg123_getformat(mh, &rate, &channels, &encoding) == MPG123_OK.rawValue
            else {
                throw mpg123Error(mh);
            }
            guard out123_open(ao, output, decoder) == OUT123_OK.rawValue else {
                throw out123Error(ao);
            }
            var output_buffer: UnsafeMutablePointer<CChar>?;
            var decoder_buffer: UnsafeMutablePointer<CChar>?;
            if out123_driver_info(ao, &output_buffer, &decoder_buffer) == OUT123_OK.rawValue {
                self.output = String(utf8Buffer: output_buffer);
                self.decoder = String(utf8Buffer: decoder_buffer);
#if DEBUG
                print("Effective output driver: \( self.output ?? "<nil> (default)" )");
                print("Effective output file:   \( self.decoder ?? "<nil> (default)" )");
#endif
            } else {
                print("warning: out123_driver_info() \(out123Error(ao))");
            }
            mpg123_format_none(mh);
            mpg123_format(mh, rate, channels, encoding);
#if DEBUG
            let encname = out123_enc_name(encoding);
            print("Playing with \(channels) channels and \(rate) Hz, encoding \( String(utf8Buffer: encname) ?? "?").");
#endif
            guard out123_start(ao, rate, channels, encoding) == OUT123_OK.rawValue,
                  out123_getformat(ao, nil, nil, nil, &framesize) == OUT123_OK.rawValue
            else {
                throw out123Error(ao);
            }
            let buffer_size = mpg123_outblock(mh);
            let buffer = malloc(buffer_size);
            guard buffer != nil else {
                throw mpg123Error(MPG123_OUT_OF_MEM);
            }
            defer {
                free(buffer);
            }
            var done: Int = 0;
            var samples: Int64 = 0;
#if DEBUG
            print("Now playing: \(self.url.path)");
#endif
            repeat {
                error = mpg123_read(mh, buffer, buffer_size, &done);
                let played = out123_play(ao, buffer, done);
#if DEBUG
                if played != done {
                    print("warning: written less than gotten from libmpg123: \(played) != \(done)");
                }
#endif
                samples += Int64(played) / Int64(framesize);
            } while !self.isCancelled && done > 0 && error == MPG123_OK.rawValue;
#if DEBUG
            print("Playback completed: \(self.url.path)");
            if error != MPG123_DONE.rawValue, error != MPG123_OK.rawValue {
                let result = error == MPG123_ERR.rawValue ? mpg123Error(mh) : mpg123Error(code: error);
                print("warning: decoding ended prematurely because: \(result)");
            }
            print("\(samples) samples written.");
#endif
        }
        catch {
            print(error);
        }
    }
    
    //MARK: FUNC
    
    func play() {
        cPlaybackOperation.operationQueue.addOperation(self);
    }

}
