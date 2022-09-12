//
//  ConnectHomeViewController.swift
//  Portl
//
//  Created by Jeff Creed on 8/3/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import RxSwift

class ConnectHomeViewController: ConnectBaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, ConnectNotificationsViewControllerDelegate {
	// MARK: ConnectNotificationsViewControllerDelegate
	
	func connectNotificationsViewControllerRequestsDismissal(_ connectNotificationsViewController: ConnectNotificationsViewController) {
		notificationButton.customView = makeNotificationBarButtonItemCustomView()
		connectNotificationsViewController.navigationController?.dismiss(animated: true, completion: nil)
	}
	
	// MARK: Private
	
	@IBAction private func invite(_ sender: Any?) {
		let activityViewControlller = UIActivityViewController(activityItems: ["Check out this new app, PORTL\n", URL(string: "https://itunes.apple.com/us/app/portl/id1288817589")!], applicationActivities: nil)
		present(activityViewControlller, animated: true, completion: nil)
	}
	
	@IBAction private func openNotifications(_ sender: Any?) {
		performSegue(withIdentifier: notificationsSegueIdentifier, sender: self)
	}
	
	@IBAction private func segmentSelected(_ sender: Any?) {
		segmentIndex = (sender as! UISegmentedControl).selectedSegmentIndex
		reloadTable()
	}
	
	override func reloadTable() {
		tableView.reloadData()
		
	}
	
	private func makeNotificationBarButtonItemCustomView() -> UIButton {
		let iconImage = receivedPendingUids.count > 0 ? #imageLiteral(resourceName: "icon_alert") : #imageLiteral(resourceName: "icon_alert_empty")
		let button = UIButton(type: .custom)
		button.bounds = CGRect(x: 0, y: 0, width: iconImage.size.width, height: iconImage.size.height)
		button.setImage(iconImage, for: .normal)
		button.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)
		
		return button
	}
	
	private func makeNotificationBarButtonItem() -> UIBarButtonItem {
		let button = makeNotificationBarButtonItemCustomView()
		let barButtonItem = UIBarButtonItem(customView: button)
		
		return barButtonItem
	}
	
	// MARK: ConnectBaseViewController
	
	override func getUid(forCell cell: UITableViewCell) -> String? {
		guard let row = tableView.indexPath(for: cell)?.row, let uid = resultsToUse[row][FirebaseKeys.ProfileKeys.uidKey] as? String else {
			return nil
		}
		return uid
	}

	// MARK: UISearchBarDelegate
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		timer?.invalidate()
		if searchText.count > 0 && !isFriendsView {
			timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: {[weak self] _ in
				guard let strongSelf = self else {
					return
				}
				strongSelf.spinnerView.isHidden = false
				strongSelf.searchResults = Array<Dictionary<String, Any>>()
				
				strongSelf.profile.searchUserProfiles(withQuery: searchText.lowercased(), withCompletion: { (results) in
					strongSelf.initialLoad = false
					strongSelf.searchResults = results
					strongSelf.reloadTable()
					if strongSelf.resultsToUse.count > 0 {
						strongSelf.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
					}
					strongSelf.spinnerView.isHidden = true
				})
			})
		} else {
			reloadTable()
		}
	}

	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	
	// MARK: UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if !initialLoad {
			noResultsView.isHidden = resultsToUse.count > 0
		}
		
		return resultsToUse.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let profile = resultsToUse[indexPath.row]
		let cell = tableView.dequeue(ConnectHomeUserTableViewCell.self, for: indexPath)
		var buttonStyle = ConnectButtonStyle.notConnected
		let profileUid = profile[FirebaseKeys.ProfileKeys.uidKey] as! String
		if friendUids.contains(profileUid) {
			buttonStyle = .connected
		} else if sentPendingUids.contains(profileUid) {
			buttonStyle = .sentPending
		} else if receivedPendingUids.contains(profileUid) {
			buttonStyle = .receivedPending
		}
		cell.configure(withProfile: profile, andConnectButtonStyle: buttonStyle, showHR: indexPath.row < resultsToUse.count-1)
		cell.delegate = self
		return cell
	}
	
	// MARK: UITableViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if let id = resultsToUse[indexPath.row][FirebaseKeys.ProfileKeys.uidKey] as? String {
			profileIDforSegue = id
			performSegue(withIdentifier: profileSegueIdentifier, sender: self)
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return ConnectHomeUserTableViewCell.heightForCell()
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == notificationsSegueIdentifier {
			let nav = segue.destination as! UINavigationController
			let controller = nav.viewControllers[0] as! ConnectNotificationsViewController
			controller.delegate = self
		} else {
			super.prepare(for: segue, sender: sender)
		}
	}
	
	// MARK: View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		notificationButton = makeNotificationBarButtonItem()

		let inviteButton = UIBarButtonItem(image: #imageLiteral(resourceName: "icon_plus_large"), style: .plain, target: self, action: #selector(invite))
		inviteButton.tintColor = .white
		
		navigationItem.rightBarButtonItems = [inviteButton, notificationButton]
		
		tableView.registerNib(ConnectHomeUserTableViewCell.self)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		segmentControl.selectedSegmentIndex = segmentIndex
		notificationButton.customView = makeNotificationBarButtonItemCustomView()
		
		tableView.reloadData()
		
		registerForNotifications()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if showNotificationsOnAppear {
			showNotificationsOnAppear = false
			openNotifications(self)
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		segmentIndex = 0
		unregisterObservers()
	}
	
	// MARK: Notifications
	
	private func registerForNotifications() {
		unregisterObservers()
		
		observerTokens.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: OperationQueue.main, using: { (notification) in
			guard let userInfo = notification.userInfo as? Dictionary<String, AnyObject>,
				let kbRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
				let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
					return
			}
			
			let convertedRect = self.view.convert(kbRect, from: nil)
			let intersectionHeight = convertedRect.intersection(self.view.bounds).integral.height
			
			UIView.animate(withDuration: animationDuration, animations: {
				self.additionalSafeAreaInsets.bottom = intersectionHeight
				self.view.layoutIfNeeded()
			})
		}))
		
		observerTokens.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main, using: { (notification) in
			guard let userInfo = notification.userInfo as? Dictionary<String, AnyObject>,
				let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
					return
			}
			
			UIView.animate(withDuration: animationDuration, animations: {
				self.additionalSafeAreaInsets.bottom = 0
				self.view.layoutIfNeeded()
			})
		}))
	}

	private func unregisterObservers() {
		for token in observerTokens {
			NotificationCenter.default.removeObserver(token)
		}
	}

	// MARK: Properties
	
	override func friendResultsDidSet() {
		friendUids = friendResults.map { $0[FirebaseKeys.ProfileKeys.uidKey] as! String }
		if isFriendsView {
			reloadTable()
		}
	}
	
	override var receivedPendingUids: [String] {
		didSet {
			notificationButton.image = receivedPendingUids.count > 0 ? #imageLiteral(resourceName: "icon_alert") : #imageLiteral(resourceName: "icon_alert_empty")
		}
	}
	
	@objc var segmentIndex = 0
	@objc var showNotificationsOnAppear = false
	
	// MARK: Properties (Private)
	
	private var observerTokens = [Any]()

	@IBOutlet private weak var segmentControl: UISegmentedControl!
	@IBOutlet private weak var searchBar: UISearchBar!

	private var timer: Timer?
	private var searchResults = Array<Dictionary<String, Any>>()
	private var notificationButton = UIBarButtonItem()
	
	private var isFriendsView: Bool {
		get {
			return segmentControl.selectedSegmentIndex == 1
		}
	}
	
	private var resultsToUse: Array<Dictionary <String, Any>> {
		get {
			if searchBar.text?.isEmpty ?? true {
				return isFriendsView ? friendResults : searchResults
			} else {
				return isFriendsView ? friendResults.filter({ (profile) -> Bool in
					(profile[FirebaseKeys.ProfileKeys.usernameDKey] as? String ?? "").range(of: searchBar.text!.lowercased()) != nil || (profile[FirebaseKeys.ProfileKeys.firstLastKey] as? String ?? "").range(of: searchBar.text!.lowercased()) != nil
				}) : searchResults
			}
		}
	}
	
	private let notificationsSegueIdentifier = "notificationsSegue"
	private let inviteSegueIdentifier = "inviteSegue"
}
