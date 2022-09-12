//
//  ConnectNotificationsViewController.swift
//  Portl
//
//  Created by Jeff Creed on 8/11/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import RxSwift

protocol ConnectNotificationsViewControllerDelegate: class {
	func connectNotificationsViewControllerRequestsDismissal(_ connectNotificationsViewController: ConnectNotificationsViewController)
}

class ConnectNotificationsViewController: ConnectBaseViewController, UITableViewDataSource, UITableViewDelegate {
	// MARK: ConnectBaseViewController
	
	override func getUid(forCell cell: UITableViewCell) -> String? {
		guard let row = tableView.indexPath(for: cell)?.row, let uid = getUid(forRow: row) else {
			return nil
		}
		return uid
	}
	
	// MARK: Private
	
	private func getUid(forRow row: Int) -> String? {
		return (friendships[row][FirebaseKeys.profileKey] as? Dictionary<String, Any>)?[FirebaseKeys.ProfileKeys.uidKey] as? String
	}
	
	private func relativeDateString(forDate date: Date) -> String {
		let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: Date())
		var result = "Just now"
		
		if let year = components.year, year > 0 {
			result = "\(year) year\(year > 1 ? "s" : "") ago."
		} else if let month = components.month, month > 0 {
			result = "\(month) month\(month > 1 ? "s" : "") ago."
		} else if let week = components.weekOfYear, week > 0 {
			result = "\(week) week\(week > 1 ? "s" : "") ago."
		} else if let day = components.day, day > 0 {
			result = "\(day) day\(day > 1 ? "s" : "") ago."
		} else if let hour = components.hour, hour > 0 {
			result = "\(hour) hour\(hour > 1 ? "s" : "") ago."
		} else if let minute = components.minute, minute > 0 {
			result = "\(minute) minute\(minute > 1 ? "s" : "") ago."
		}
		return result
	}
	
	@IBAction private func dismissNotifications(_ sender: Any) {
		delegate?.connectNotificationsViewControllerRequestsDismissal(self)
	}

	// MARK: UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if !initialLoad {
			noResultsView.isHidden = friendships.count > 0
		}
		
		return friendships.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let profile = friendships[indexPath.row][FirebaseKeys.profileKey] as! Dictionary<String, Any>
		let profileUid = profile[FirebaseKeys.ProfileKeys.uidKey] as! String
		let nameString = profile[FirebaseKeys.ProfileKeys.usernameKey] as! String
		let imageURL = profile[FirebaseKeys.ProfileKeys.avatarKey] as? String
		
		let dateString = friendships[indexPath.row][FirebaseKeys.FriendsKeys.acceptedKey] as? String ?? friendships[indexPath.row][FirebaseKeys.FriendsKeys.invitedKey] as! String
		let friendshipDate = dateFormatter.date(from: dateString)!
		
		var buttonStyle = ConnectButtonStyle.notConnected
		if friendUids.contains(profileUid) {
			buttonStyle = .connected
		} else if sentPendingUids.contains(profileUid) {
			buttonStyle = .sentPending
		} else if receivedPendingUids.contains(profileUid) {
			buttonStyle = .receivedPending
		}
		
		let cell = tableView.dequeue(ConnectNotificationUserTableViewCell.self, for: indexPath)
		cell.configure(withImageURL: imageURL, name: nameString, dateString: relativeDateString(forDate: friendshipDate), andConnectButtonStyle: buttonStyle, showHR: indexPath.row < friendships.count-1)
		cell.delegate = self
		return cell
	}
	
	// MARK: UITableViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if let id = getUid(forRow: indexPath.row) {
			profileIDforSegue = id
			performSegue(withIdentifier: profileSegueIdentifier, sender: self)
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let profile = friendships[indexPath.row][FirebaseKeys.profileKey] as! Dictionary<String, Any>
		let profileUid = profile[FirebaseKeys.ProfileKeys.uidKey] as! String
		let nameString = profile[FirebaseKeys.ProfileKeys.usernameKey] as! String
		
		var buttonStyle = ConnectButtonStyle.notConnected
		if friendUids.contains(profileUid) {
			buttonStyle = .connected
		} else if sentPendingUids.contains(profileUid) {
			buttonStyle = .sentPending
		} else if receivedPendingUids.contains(profileUid) {
			buttonStyle = .receivedPending
		}
		
		let message = ConnectNotificationUserTableViewCell.buildNotificationString(forNameString: nameString, andButtonStyle: buttonStyle)

		return ConnectNotificationUserTableViewCell.heightForCell(withWidth: self.view.frame.size.width, message: message, buttonStyle: buttonStyle)
	}
		
	// MARK: Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissNotifications))
		done.tintColor = .white
		navigationItem.rightBarButtonItem = done
		
		tableView.registerNib(ConnectNotificationUserTableViewCell.self)
		
		friends.orderedFriendshipsWithProfiles.subscribe(onNext: {[unowned self] friendships in
			self.friendships = friendships
			self.initialLoad = false
			self.spinnerView.isHidden = true
		}).disposed(by: disposeBag)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// todo: clear notifications read status
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		Injector.root?.inject(into: inject)
	}
	
	private func inject(notificationDateFormatter: FirebaseDateFormatter) {
		dateFormatter = notificationDateFormatter.value
	}
	
	// MARK: Properties
	
	weak var delegate: ConnectNotificationsViewControllerDelegate?
	
	// MARK: Properties (Private)
	
	private var friendships = Array<Dictionary<String, Any>>() {
		didSet {
			friendshipUids = friendships.map({ (friendship) -> String in
				[friendship[FirebaseKeys.FriendsKeys.userOneKey] as! String, friendship[FirebaseKeys.FriendsKeys.userTwoKey] as! String].filter({$0 != Auth.auth().currentUser?.uid}).first!
			})

			reloadTable()
		}
	}
	
	private var friendshipUids = Array<String>()
	private var dateFormatter: DateFormatter!
}
