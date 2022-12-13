//
//  vMainViewController.swift
//  playsoundSwift
//
//  Created by DE4ME on 04.10.2022.
//

import Cocoa;
import mpg123;
import out123;
import syn123;

fileprivate var decoder_default: String = "(default)";

class vMainViewController: NSViewController {

    @IBOutlet var imageView: NSImageView!;
    @IBOutlet var nameTextField: NSTextField!;
    @IBOutlet var playButton: NSButton!;
    
    //MARK: GET
    
    @objc var availableDecoders: [String] {
        var decoders: [String] = [decoder_default];
        if var decoder = mpg123_supported_decoders() {
            while decoder.pointee != nil {
                if let string = String(utf8String: decoder.pointee!) {
                    decoders.append(string);
                }
                decoder = decoder.advanced(by: 1);
            }
        }
        return decoders;
    }
    
    var currentDecoder: String? {
        guard let selectedDecoder = self.selectedDecoder, !selectedDecoder.isEmpty, selectedDecoder != decoder_default else {
            return nil;
        }
        return selectedDecoder;
    }
    
    var allowedFileTypes: [String] {
        ["mp3"];
    }
    
    //MARK: VAR
    
    @objc dynamic var canChangeDecoder: Bool = true;
    var decoderObserver: NSKeyValueObservation?;
    var playbackOperation: cPlaybackOperation?;
    
    private var _selectedDecoder: String = decoder_default;
    @objc dynamic var selectedDecoder: String! {
        get {
            return _selectedDecoder;
        }
        set {
            if let value = newValue, !value.isEmpty {
                self._selectedDecoder = value;
            } else {
                self._selectedDecoder = decoder_default;
            }
        }
    }
    
    //MARK: OBSERV
    
    var url: URL?{
        didSet{
            self.updateUrl(self.url);
        }
    }
    
    override var representedObject: Any? {
        didSet {
            self.updateRepresentedObject(self.representedObject);
        }
    }

    //MARK: OVERRIDE
    
    deinit {
        guard let operation = self.playbackOperation, !operation.isFinished else {
            return;
        }
        operation.cancel();
        operation.waitUntilFinished();
        self.playbackOperation = nil;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.url = nil;
    }
    
    //MARK: UI
    
    func updateUrl(_ url: URL?) {
        if let url = url {
            let values = try? url.resourceValues(forKeys: [.effectiveIconKey]);
            self.imageView.image = values?.effectiveIcon as? NSImage;
            self.nameTextField.stringValue = url.deletingPathExtension().lastPathComponent;
            self.playButton.isEnabled = true;
            NSDocumentController.shared.noteNewRecentDocumentURL(url);
        } else {
            self.imageView.image = nil;
            self.nameTextField.objectValue = nil;
            self.playButton.isEnabled = false;
        }
    }
    
    func updateRepresentedObject(_ object: Any?) {
        switch object {
        case let url as URL:
            self.url = url;
        case let string as String:
            self.url = URL(fileURLWithPath: string);
        default:
            return;
        }
    }
    
    //MARK: FUNC
    
    @objc
    func stopOperation(_ operation: cPlaybackOperation) {
        guard self.playbackOperation == operation else {
            return;
        }
        self.canChangeDecoder = true;
        self.playButton.state = .off;
        self.decoderObserver = nil;
        self.playbackOperation = nil;
    }

    //MARK: ACTION
    
    @IBAction func openDocument(_ sender: Any) {
        let panel = NSOpenPanel();
        panel.allowedFileTypes = self.allowedFileTypes;
        guard panel.runModal() == .OK else {
            return;
        }
        self.url = panel.url;
    }
    
    @IBAction func helpClick(_ sender: Any) {
        var array: [String] = [];
        if var decoder = mpg123_supported_decoders() {
            var decoders: [String] = [];
            decoders.append("<DECODERS>");
            while decoder.pointee != nil {
                if let string = String(utf8String: decoder.pointee!) {
                    decoders.append(string);
                }
                decoder = decoder.advanced(by: 1);
            }
            let string = decoders.joined(separator: "\n");
            array.append(string);
        }
        if let handle = out123_new() {
            defer {
                out123_close(handle);
            }
            var name:UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?;
            var desc:UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?;
            let count = Int( out123_drivers(handle, &name, &desc) );
            if count>0 {
                var modules: [String] = [];
                modules.append("<OUTPUTS>");
                for i in 0..<count {
                    let name_string: String;
                    if let name = name!.advanced(by: i).pointee, name.pointee != 0 {
                        name_string = String(utf8String: name) ?? "?";
                    } else {
                        name_string = "?";
                    }
                    let string: String;
                    if let desc = desc!.advanced(by: i).pointee, desc.pointee != 0 {
                        string = String(format: "%@: %s", name_string, desc);
                    } else {
                        string = name_string;
                    }
                    modules.append(string);
                }
                out123_stringlists_free(name, desc, Int32(count));
                let string = modules.joined(separator: "\n");
                array.append(string);
            }
        }
        let alert = NSAlert();
        alert.alertStyle = .informational;
        alert.informativeText = array.isEmpty ? "Empty" : array.joined(separator: "\n\n");
        alert.messageText = String(format: "mpg123 API: %i\nout123 API: %i\nsyn123 API: %i", MPG123_API_VERSION, OUT123_API_VERSION, SYN123_API_VERSION);
        alert.runModal();
    }
    
    @IBAction func playClick(_ sender: Any) {
        guard let url = self.url else {
            return;
        }
        if self.playbackOperation == nil || self.playbackOperation!.isFinished {
            let playback = cPlaybackOperation(url: url, decoder: self.currentDecoder);
            playback.completionBlock = { [weak self] in
                guard let `self` = self else {
                    return;
                }
                self.performSelector(onMainThread: #selector(self.stopOperation(_:)), with: playback, waitUntilDone: false);
            }
            self.decoderObserver = playback.observe(\.decoder, options: .new) {playback, _ in
                OperationQueue.main.addOperation { [weak self] in
                    guard let `self` = self else {
                        return;
                    }
                    self.selectedDecoder = playback.decoder;
                }
            }
            self.playbackOperation = playback;
            self.playButton.state = .on;
            self.canChangeDecoder = false;
            playback.play();
        } else {
            self.playbackOperation!.cancel();
        }
    }
    
}

