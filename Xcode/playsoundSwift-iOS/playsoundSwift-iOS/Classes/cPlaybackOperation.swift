//
//  cPlaybackOperation.swift
//  playsoundSwift-iOS
//
//  Created by DE4ME on 04.10.2022.
//

import Foundation;
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
            DbgLog.printInfo("BEGIN");
            var channels: Int32 = 0;
            var encoding: Int32 = 0;
            var framesize: Int32 = 0;
            var rate: Int = 0;
            var error: Int32 = 0;
            let infile = self.url.path;
            let output = self.output;
            let decoder = self.decoder;
            guard let mh = mpg123_new(nil, &error) else {
                throw mpg123Error.mpg(error);
            }
            defer {
                mpg123_delete(mh);
            }
            guard let ao = out123_new() else {
                throw mpg123Error(OUT123_DOOM);
            }
            defer {
                out123_del(ao);
            }
            guard mpg123_open(mh, infile) == MPG123_OK,
                  mpg123_getformat(mh, &rate, &channels, &encoding) == MPG123_OK
            else {
                throw mpg123Error(mpg: mh);
            }
            guard out123_open(ao, output, decoder) == OUT123_OK else {
                throw mpg123Error(out: ao);
            }
            var output_buffer: UnsafeMutablePointer<CChar>?;
            var decoder_buffer: UnsafeMutablePointer<CChar>?;
            if out123_driver_info(ao, &output_buffer, &decoder_buffer) == OUT123_OK {
                self.output = String(utf8Buffer: output_buffer);
                self.decoder = String(utf8Buffer: decoder_buffer);
#if DEBUG
                DbgLog.printInfo("Effective output driver: \( self.output ?? "<nil> (default)" )");
                DbgLog.printInfo("Effective output file:   \( self.decoder ?? "<nil> (default)" )");
#endif
            } else {
                DbgLog.printError("warning: out123_driver_info() \(mpg123Error(out: ao))");
            }
            mpg123_format_none(mh);
            mpg123_format(mh, rate, channels, encoding);
#if DEBUG
            let encname = out123_enc_name(encoding);
            DbgLog.printInfo("Playing with \(channels) channels and \(rate) Hz, encoding \( String(utf8Buffer: encname) ?? "?").");
#endif
            guard out123_start(ao, rate, channels, encoding) == OUT123_OK,
                  out123_getformat(ao, nil, nil, nil, &framesize) == OUT123_OK
            else {
                throw mpg123Error(out: ao);
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
            DbgLog.printInfo("Now playing: \(self.url.lastPathComponent)");
#endif
            repeat {
                error = mpg123_read(mh, buffer, buffer_size, &done);
                let played = out123_play(ao, buffer, done);
#if DEBUG
                if played != done {
                    DbgLog.printError("warning: written less than gotten from libmpg123: \(played) != \(done)");
                }
#endif
                samples += Int64(played) / Int64(framesize);
            } while !self.isCancelled && done > 0 && error == MPG123_OK;
#if DEBUG
            DbgLog.printInfo("Playback completed: \(self.url.lastPathComponent)");
            if error != MPG123_DONE, error != MPG123_OK {
                let result = error == MPG123_ERR ? mpg123Error(mpg: mh) : mpg123Error.mpg(error);
                DbgLog.printError("warning: decoding ended prematurely because: \(result)");
            }
            DbgLog.printInfo("\(samples) samples written.");
#endif
            DbgLog.printInfo("END");
        }
        catch {
            DbgLog.printError(error.localizedDescription);
        }
    }
    
    //MARK: FUNC
    
    func play() {
        cPlaybackOperation.operationQueue.addOperation(self);
    }

}
