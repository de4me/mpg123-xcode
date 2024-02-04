//
//  ViewController.swift
//  playsoundSwift-iOS
//
//  Created by DE4ME on 03.02.2024.
//

import UIKit;
import mpg123;
import out123;
import syn123;


class vMainViewController: vLoggingViewController {
    
    @IBOutlet var decodersSegmentedControl: UISegmentedControl!;
    
    //MARK: VAR
    
    var operation: cPlaybackOperation?;
    
    //MARK: GETTER
    
    var availableDecoders: [String] {
        var decoders: [String] = [];
        guard var decoder = mpg123_supported_decoders() else {
            return decoders;
        }
        while decoder.pointee != nil {
            if let string = String(utf8String: decoder.pointee!) {
                decoders.append(string);
            }
            decoder = decoder.advanced(by: 1);
        }
        return decoders;
    }
    
    //MARK: OVERRIDE

    override func viewDidLoad() {
        super.viewDidLoad();
        self.decodersSegmentedControl.removeAllSegments();
        self.availableDecoders.enumerated().forEach { decoder in
            self.decodersSegmentedControl.insertSegment(withTitle: decoder.element, at: decoder.offset, animated: false);
        }
        self.decodersSegmentedControl.selectedSegmentIndex = 0;
    }
    
    //MARK: ACTION

    @IBAction func playClick(_ sender: Any) {
        guard let url = Bundle.main.url(forResource: "sweep", withExtension: "mp3") else {
            DbgLog.printError("File not found");
            return;
        }
        let index = self.decodersSegmentedControl.selectedSegmentIndex;
        let decoder = self.decodersSegmentedControl.titleForSegment(at: index);
        self.operation = .init(url: url, decoder: decoder);
        self.operation?.play();
    }
    
    @IBAction func infoClick(_ sender: Any) {
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
        let message = array.isEmpty ? "Empty" : array.joined(separator: "\n\n");
        let title = String(format: "mpg123 API: %i\nout123 API: %i\nsyn123 API: %i", MPG123_API_VERSION, OUT123_API_VERSION, SYN123_API_VERSION);
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        let close = UIAlertAction(title: "Close", style: .default);
        alert.addAction(close);
        self.present(alert, animated: true);
    }

}

