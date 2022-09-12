//
//  ShareGoingViewController.swift
//  Portl
//
//  Created by Jeff Creed on 3/29/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation

class ShareGoingViewController: ConnectBaseViewController, UITableViewDataSource, UITableViewDelegate {
	
	// MARK: UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return userIDs?.count ?? 0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let profileID = userIDs![indexPath.row]
		let cell = tableView.dequeue(ConnectHomeUserTableViewCell.self, for: indexPath)
		var buttonStyle = ConnectButtonStyle.notConnected
		if friendUids.contains(profileID) {
			buttonStyle = .connected
		} else if sentPendingUids.contains(profileID) {
			buttonStyle = .sentPending
		} else if receivedPendingUids.contains(profileID) {
			buttonStyle = .receivedPending
		}
		
		cell.configure(withProfileID: profileID, andConnectButtonStyle: buttonStyle, showHR: indexPath.row < self.userIDs!.count-1)
		cell.delegate = self
		return cell
	}
	
	// MARK: UITableViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
		
		if let identifier = userIDs?[indexPath.row], let parent = parent as? ShareMessagingViewController {
			parent.showProfileWithID(identifier)
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 80.0
	}
		
	// MARK: Private
	
	override func getUid(forCell cell: UITableViewCell) -> String? {
		guard let row = tableView.indexPath(for: cell)?.row, row < userIDs?.count ?? 0, let uid = userIDs?[row] else {
			return nil
		}
		return uid
	}
	
	// MARK: Navigation
		
	@IBAction func onBack() {
		self.navigationController?.popViewController(animated: true)
	}
	
	// MARK: Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.registerNib(ConnectHomeUserTableViewCell.self)
		
		if userIDs != nil {
			spinnerView.isHidden = true
		}
	}
	
	var userIDs: [String]? {
		didSet {
			if isViewLoaded {
				tableView.reloadData()
				spinnerView.isHidden = true
			}
		}
	}
}
