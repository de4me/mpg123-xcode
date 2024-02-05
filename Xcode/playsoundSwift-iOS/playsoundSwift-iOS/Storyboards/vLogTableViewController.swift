//
//  vLogTableViewController.swift
//  playsoundSwift-iOS
//
//  Created by DE4ME on 30.01.2024.
//

import UIKit;


typealias DbgLog = vLogTableViewController;


enum Message {
	case info(String);
	case error(String);
}


class vLoggingViewController: UIViewController {
    
    //MARK: VAR
	
	private var logController: vLogTableViewController!;

    //MARK: OVERRIDE
    
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated);
		DbgLog.begin(self.logController);
	}
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        DbgLog.end();
    }
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.destination {
		case let controller as vLogTableViewController:
			self.logController = controller;
		default:
			break;
		}
	}
    
}


class vLogTableViewController: UITableViewController {

    //MARK: CONST
    
    static private let mutex = DispatchSemaphore(value: 1);
    
    //MARK: STATIC
    
	static private var current: vLogTableViewController?;
	static private var currentMessagesArray: [Message] = [];

	//MARK: VAR
	
	private var messagesArray: [Message] = [];
	private var timer: Timer?;
	
    //MARK: STATIC FUNC
	
	static func begin(_ current: vLogTableViewController) {
		Self.mutex.wait();
		Self.currentMessagesArray.removeAll();
		Self.current = current;
		Self.mutex.signal();
	}
	
	static func end() {
		Self.mutex.wait();
		Self.current = nil;
		Self.mutex.signal();
	}
	
	static func printInfo(_ text: String) {
		Self.addMessage(.info(text));
	}
	
	static func printError(_ text: String) {
		Self.addMessage(.error(text));
	}
	
	static func addMessage(_ message: Message) {
		Self.mutex.wait();
		Self.currentMessagesArray.append(message);
		Self.mutex.signal();
	}
    
    //MARK: OVERRIDE
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated);
		self.startTimer();
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated);
		self.stopTimer();
	}
	
	private func startTimer() {
		self.timer = .scheduledTimer(timeInterval: 1 / 3, target: self, selector: #selector(self.updateLog(_:)), userInfo: nil, repeats: true);
	}
	
	private func stopTimer() {
		self.timer?.invalidate();
	}
	
	@objc private func updateLog(_ timer: Timer) {
		vLogTableViewController.mutex.wait();
		let array = vLogTableViewController.currentMessagesArray;
		vLogTableViewController.mutex.signal();
		guard array.count > 0, array.count != self.messagesArray.count else {
			return;
		}
		let start = self.messagesArray.count;
		let end = array.count - 1;
		if end >= start {
			let indexes = (start...end).map{ IndexPath(row: $0, section: 0) };
			self.messagesArray = array;
			UIView.performWithoutAnimation {
				self.tableView.insertRows(at: indexes, with: .none);
				guard let last = indexes.last else {
					return;
				}
				self.tableView.scrollToRow(at: last, at: .bottom, animated: false);
			}
		} else {
			self.messagesArray = array;
			UIView.performWithoutAnimation {
				self.tableView.reloadData();
				let index = IndexPath(row: array.count - 1, section: 0);
				self.tableView.scrollToRow(at: index, at: .bottom, animated: false);
			}
		}
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
		return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.messagesArray.count;
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let message = self.messagesArray[indexPath.row];
		switch message {
		case .info(let text):
			let cell = tableView.dequeueReusableCell(withIdentifier: "info", for: indexPath);
			cell.textLabel?.text = text;
			return cell;
		case .error(let text):
			let cell = tableView.dequeueReusableCell(withIdentifier: "error", for: indexPath);
			cell.textLabel?.text = text;
			return cell;
		}
    }

}
