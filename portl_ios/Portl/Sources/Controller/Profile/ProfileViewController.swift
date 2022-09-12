//
//  ProfileViewController.swift
//  Portl
//
//  Created by Jeff Creed on 5/31/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CoreData
import Service
import RxSwift
import CSkyUtil
import SafariServices

class ProfileViewController: LivefeedListViewController, ProfileEventsTableViewCellDelegate, ProfileInfoTableViewCellDelegate, ConnectEnabledCellDelegate, SFSafariViewControllerDelegate {
	
	func showAlert(withMessage message: String, andCompletion completion: @escaping (UIAlertAction) -> Void) {
		let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: completion))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {[unowned self] (_) in
			self.reloadTableView()
		}))
		present(alert, animated: true, completion: nil)
	}

	// MARK: UITableViewDataSource
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return isPublicProfile || selfProfile ? Section.allCases.count : 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch (Section(rawValue: section)!) {
		case .info, .upcoming:
			return 1
		case .livefeed:
			return super.tableView(tableView, numberOfRowsInSection: section)
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch (Section(rawValue: indexPath.section)!) {
		case .info:
			let cell = tableView.dequeue(ProfileInfoTableViewCell.self, for: indexPath)
			if let profile = profile {
				cell.configure(withProfile: profile, buttonStyle: buttonStyle, authorizedID: Auth.auth().currentUser?.uid)
				cell.delegate = self
				cell.connectDelegate = self
			
				friends.getFriendCount(forUserID: profileID!) { (count) in
					cell.friendCount = count
				}
			}
			
			return cell

		case .upcoming:
			let cell = tableView.dequeue(ProfileEventsTableViewCell.self, for: indexPath)
			cell.configureWith(eventsController: upcomingEventsController, emptyMessage: noJoinedMessage)
			cell.delegate = self
			return cell
		case .livefeed:
			return super.tableView(tableView, cellForRowAt: indexPath)
		}
	}
	
	override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		switch (Section(rawValue: indexPath.section)!) {
		case .info:
			return 229.0
		case .upcoming:
			return 213.0
		case .livefeed:
			return super.tableView(tableView, estimatedHeightForRowAt: indexPath)
		}
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let header = tableView.dequeue(TableViewHeaderView.self)
		switch (Section(rawValue: section)!) {
		case .info:
			return nil
		case .upcoming:
			header.labelText = "UPCOMING"
		case .livefeed:
			header.labelText = "ACTIVITY"
		}
		return header
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		switch (Section(rawValue: section)!) {
		case .info:
			return 0.0
		case .upcoming, .livefeed:
			return 36.0
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		switch (Section(rawValue: indexPath.section)!) {
		case .info:
			return ProfileInfoTableViewCell.heightForCell(withWidth: tableView.bounds.width, andProfile: profile)
		case .upcoming:
			return upcomingEventsController?.hasItems ?? false ? 213.0 : 48.0
		case .livefeed:
			return UITableView.automaticDimension
		}
	}
	
	// MARK: Override
	
	override var livefeedSection: Int {
		get {
			return Section.livefeed.rawValue
		}
		set {}
	}
	
	override var isForProfileView: Bool {
		get {
			return true
		}
		set {}
	}
	
	override func userIDForLivefeedRequest() -> String {
		return profileID!
	}
	
	override var profileForProfileView: FirebaseProfile? {
		get {
			return profile
		}
		set {}
	}
	
	override var shouldShowLivefeed: Bool {
		get {
			return isPublicProfile || selfProfile
		}
		set {}
	}
	
	// MARK: SFSafariViewControllerDelegate
	
	func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
		controller.delegate = nil
		self.tabBarController?.dismiss(animated: true, completion: nil)
	}
	
	// MARK: ConnectEnabledCellDelegate
	
	func connectEnabledCellDidSelectConnect(_ connectEnabledCell: ConnectEnabledCell) {
		guard let uid = profileID else {
			return
		}
		friends.sendInvite(toUid: uid) {[unowned self] (error) in
			if error != nil {
				self.presentErrorAlert(withMessage: nil, completion: nil)
			}
			self.reloadTableView()
		}
	}
	
	func connectEnabledCellDidSelectDisconnect(_ connectEnabledCell: ConnectEnabledCell) {
		guard let uid = profileID else {
			return
		}
		showAlert(withMessage: "Remove from friends?") {[unowned self] (_) in
			self.friends.removeConnection(toUid: uid) {(error) in
				if error != nil {
					self.presentErrorAlert(withMessage: nil, completion: nil)
				}
				self.reloadTableView()
			}
		}
	}
	
	func connectEnabledCellDidSelectCancel(_ connectEnabledCell: ConnectEnabledCell) {
		guard let uid = profileID else {
			return
		}
		showAlert(withMessage: "Delete connect request?") {[unowned self] (_) in
			self.friends.removeConnection(toUid: uid) {(error) in
				if error != nil {
					self.presentErrorAlert(withMessage: nil, completion: nil)
				}
				self.reloadTableView()
			}
		}
	}
	
	func connectEnabledCellDidSelectApprove(_ connectEnabledCell: ConnectEnabledCell) {
		approve(connectEnabledCell)
	}
	
	func connectEnabledCellDidSelectDecline(_ connectEnabledCell: ConnectEnabledCell) {
		decline(connectEnabledCell)
	}
	
	// MARK: ProfileInfoTableViewCellDelegate
	
	func profileInfoTableViewCellSelectedMessage(_ profileInfoTableViewCell: ProfileInfoTableViewCell) {
		messageUser()
	}
	
	func profileInfoTableViewCellSelectedEdit(_ profileInfoTableViewCell: ProfileInfoTableViewCell) {
		if selfProfile {
			performSegue(withIdentifier: profileEditSegueIdentifier, sender: self)
		}
	}
	
	func profileInfoTableViewCellSelectedSettings(_ profileInfoTableViewCell: ProfileInfoTableViewCell) {
		performSegue(withIdentifier: profileSettingsSeguIdentifier, sender: self)
	}
	
	func profileInfoTableViewCellSelectedFriends(_ profileInfoTableViewCell: ProfileInfoTableViewCell) {
		if selfProfile {
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: Notification.Name(gNotificationOpenMyFriends), object: nil)
			}
			navigationController?.dismiss(animated: false, completion: nil)
			navigationController?.popToRootViewController(animated: false)
		} else {
			performSegue(withIdentifier: showFriendsSegueIdentifier, sender: self)
		}
	}
	
	func profileInfoTableViewCellSelectedWebsite(_ profileInfoTableViewCell: ProfileInfoTableViewCell) {
		presetSafariViewControllerForProfileWebsite()
	}
	
	// MARK: ProfileEventsTableViewCellDelegate
	
	func profileEventsTableViewCell(_ profileEventsTableViewCell: ProfileEventsTableViewCell, didSelectEvent event: PortlEvent) {
		eventForDetailSegue = event
		eventsForDetailSegue = upcomingEventsController?.items
		
		performSegue(withIdentifier: eventDetailSegueIdentifier, sender: self)
	}
	
	// MARK: Private
	
	private func presetSafariViewControllerForProfileWebsite() {
		if let website = self.profile?.website, let websiteURL = URL(string: website) {
			let svc = SFSafariViewController(url: websiteURL)
			svc.preferredBarTintColor = UIColor(byteValueRed: 33, byteValueGreen: 0, byteValueBlue: 7)
			svc.preferredControlTintColor = UIColor.white
			svc.delegate = self
			
			guard self.navigationController?.presentingViewController == nil else {
				// todo: need to start using the new root tab view controller to make this possible i think
				return
			}
			
			self.tabBarController?.present(svc, animated: true, completion: nil)
		}
	}
	
	private func reloadTableView() {
		if profile != nil {
			updateButtonStyle()
			
			UIView.performWithoutAnimation {
				self.tableView.reloadData()
			}
			
			if !selfProfile {
				noJoinedMessage = "This person has not joined any upcoming events"
				navigationItem.rightBarButtonItem = nil
			} else {
				navigationItem.rightBarButtonItem = signOutButton
			}
			
			if isPublicProfile || selfProfile {
				processJoinedEvents()
			}
		}
		
	}
	
	@IBAction private func signOut() {
		let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to sign out?", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {[unowned self] action in
			self.fcmTokenManager.currentFCMToken = nil
			FIRFriends.shared().signOut()
			self.friends.signOut()
			FIRPortlAuthenticator.shared().signOut()
			self.tabBarController?.navigationController?.popViewController(animated: true)
		}))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		present(alert, animated: true, completion: nil)
	}
	
	private func processJoinedEvents() {
		guard let profile = profile, let going = profile.events?.going, going.count > 0, isPublicProfile || selfProfile else {
			makeEmptyEventsController()
			UIView.performWithoutAnimation {
				self.tableView.reloadSections(IndexSet(arrayLiteral: Section.upcoming.rawValue), with: .none)
			}
		
			return
		}
		
		portlService.getEvents(forIDs: Array(going.keys)).subscribe(onNext: { [unowned self] IDs in
			let goingEventsController = ProfileEventsController(locationService: self.locationService)
			
			if let goingResultsController = self.portlService.fetchedResultsControllerForFutureEvents(inEventIDs: IDs, delegate: goingEventsController) {
				goingEventsController.fetchedResultsController = goingResultsController
				self.upcomingEventsController = goingEventsController
			} else {
				self.makeEmptyEventsController()
			}
			
			if self.view.isOnWindow {
				UIView.performWithoutAnimation {
					self.tableView.reloadSections(IndexSet(arrayLiteral: Section.upcoming.rawValue), with: .none)
				}
			}
			
			}, onError: { error in
				print("Request for going events failed: \(error)")
		}).disposed(by: disposeBag)
	}
	
	private func makeEmptyEventsController() {
		let eventsController = ProfileEventsController(locationService: locationService)
		if let resultsController = self.portlService.fetchedResultsController(forEventIDs: [], delegate: eventsController) {
			eventsController.fetchedResultsController = resultsController
			upcomingEventsController = eventsController
		}
	}
	
	private func messageUser() {
		if shownFromMessage {
			navigationController?.popViewController(animated: true)
		} else {
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: Notification.Name(gNotificationOpenDirectMessage), object: nil, userInfo: ["username": self.profile!.username, "conversationKey": ConversationService.getDirectConversationID(fromUserID: Auth.auth().currentUser!.uid, andOtherUserID: self.profileID!)])
				self.navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
			}
		}
	}
	
	private func updateButtonStyle() {
		buttonStyle = ConnectButtonStyle.notConnected
		UIView.animate(withDuration: 0.5) {
			self.wantsToConnectViewBottomConstraint.constant = 0
			self.view.layoutIfNeeded()
		}
		
		if friendUids.contains(profileID!) {
			buttonStyle = .connected
		} else if sentPendingUids.contains(profileID!) {
			buttonStyle = .sentPending
		} else if receivedPendingUids.contains(profileID!) {
			buttonStyle = .receivedPending
			
			let username = NSAttributedString(string: profile!.username, attributes: [.font: UIFont.systemFont(ofSize: 16.0, weight: .bold), .foregroundColor: UIColor.white])
			let message = NSMutableAttributedString(string: " wants to connect with you", attributes: [.font: UIFont.systemFont(ofSize: 16.0), .foregroundColor: UIColor(byteValueRed: 204, byteValueGreen: 207, byteValueBlue: 204)])
			message.insert(username, at: 0)
			wantsToConnectLabel.attributedText = message
			
			wantsToConnectView.isHidden = false
			UIView.animate(withDuration: 0.5) { [unowned self] in
				self.wantsToConnectViewBottomConstraint.constant = -self.wantsToConnectView.frame.size.height
				self.view.layoutIfNeeded()
			}
		}
	}
	
	@IBAction private func decline(_ sender: Any?) {
		guard let uid = profileID else {
			return
		}
		showAlert(withMessage: "Ignore connect request?") { (_) in
			self.friends.removeConnection(toUid: uid) {[unowned self] (error) in
				if error != nil {
					self.presentErrorAlert(withMessage: nil, completion: nil)
				}
				self.reloadTableView()
			}
		}
	}
	
	@IBAction private func approve(_ sender: Any?) {
		guard let uid = profileID else {
			return
		}
		FIRFriends.shared().acceptFriendInvitation(from: uid) {[unowned self] (error) in
			if error != nil {
				self.presentErrorAlert(withMessage: nil, completion: nil)
			}
			self.reloadTableView()
		}
	}
	
	// MARK: View Life Cycle

	override func registerNibs() {
		super.registerNibs()
		super.tableView.registerNib(TableViewHeaderView.self)
		super.tableView.registerNib(ProfileInfoTableViewCell.self)
		super.tableView.registerNib(ProfileEventsTableViewCell.self)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		friends.friendProfiles.subscribe(onNext: {[unowned self] friends in
			self.friendUids = friends.map {$0[FirebaseKeys.ProfileKeys.uidKey] as! String}
			
			self.friends.sentPendingUids.subscribe(onNext: {[unowned self]  sp in
				self.sentPendingUids = sp
				
				self.friends.receivedPendingUids.subscribe(onNext: {[unowned self]  rp in
					self.receivedPendingUids = rp
					
					if self.view.isOnWindow {
						self.reloadTableView()
					}
				}).disposed(by: self.disposeBag)
			}).disposed(by: self.disposeBag)
		}).disposed(by: disposeBag)
		
		let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: .plain, target: self, action: #selector(onBack))
		backItem.tintColor = .white
		navigationItem.leftBarButtonItem = backItem		
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		createDisposables()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		clearDisposables()
	}
	
	func createDisposables() {
		profileDisposable?.dispose()
		profileService.clearOtherUserProfile()
		
		// todo: logic to use auth profile already loaded when id is auth profile id ??
		
		profileDisposable = profileService.otherUserProfile.subscribe(onNext: {[weak self] firebaseProfile in
			self?.profile = firebaseProfile
			self?.navigationItem.title = self?.profile?.username
		})
		
		if let profileID = profileID {
			profileService.loadOtherUserProfile(profileID: profileID)
		}
	}
	
	func clearDisposables() {
		profileDisposable?.dispose()
		profileDisposable = nil
	}
	
	// MARK: Navigation
	
	@IBAction private func onBack() {
		self.navigationController?.popViewController(animated: true)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == eventDetailSegueIdentifier {
			if let event = eventForDetailSegue {
				let controller = segue.destination as! EventDetailsViewController
				controller.event = event
				controller.events = eventsForDetailSegue ?? []
				controller.currentEventIndex = eventsForDetailSegue?.firstIndex(of: event) ?? 0
				eventForDetailSegue = nil
				eventsForDetailSegue = nil
			}
		} else if segue.identifier == profileEditSegueIdentifier {
			let controller = segue.destination as! ProfileEditViewController
			controller.profile = profile!
		} else if segue.identifier == profileSettingsSeguIdentifier {
			let controller = segue.destination as! ProfileSettingsViewController
			controller.profileID = profileID!
		} else if segue.identifier == showFriendsSegueIdentifier {
			let controller = segue.destination as! ProfileFriendsViewController
			controller.profileID = profileID!
		} else {
			super.prepare(for: segue, sender: sender)
		}
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		Injector.root!.inject(into: inject)
		
		signOutButton = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signOut))
		signOutButton.tintColor = .white
		
	}
	
	private func inject(portlService: PortlDataProviding, locationService: LocationProviding, friends: Friends, profileService: UserProfileService, fcmTokenManager: FCMTokenManager) {
		self.portlService = portlService
		self.locationService = locationService
		self.friends = friends
		self.fcmTokenManager = fcmTokenManager
	}
	
	// MARK: Properties
	
	@objc var profileID: String? {
		didSet {
			selfProfile = profileID == Auth.auth().currentUser?.uid
			createDisposables()
		}
	}
	
	@objc var shownFromMessage = false
	
	// MARK: Properties (Private DI)
	
	private var portlService: PortlDataProviding!
	private var locationService: LocationProviding!
	private var friends: Friends!
	private var fcmTokenManager: FCMTokenManager!
	
	// MARK: Properties (Private)
	
	private var profileDisposable: Disposable?
	private var profile: FirebaseProfile? {
		didSet {
			if profile != nil {
				isPublicProfile = profile!.showJoined ?? true
				if isViewLoaded {
					reloadTableView()
				}
			}
		}
	}
	private var buttonStyle = ConnectButtonStyle.notConnected
	
	private var selfProfile = false
	private var isPublicProfile = false
	private var signOutButton: UIBarButtonItem!
	private var friendUids = Array<String>()
	private var sentPendingUids = Array<String>()
	private var receivedPendingUids = Array<String>()
	
	private var upcomingEventsController: ProfileEventsController?
	private var eventsForDetailSegue: Array<PortlEvent>?
	
	@IBOutlet private weak var wantsToConnectViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet private weak var wantsToConnectLabel: UILabel!
	@IBOutlet private weak var wantsToConnectView: UIView!
	
	// MARK: Properties (Private, Constant)
	
	private let disposeBag = DisposeBag()
	private let eventDetailSegueIdentifier = "eventDetailSegue"
	private let messageSegueIdentifier = "messageSegue"
	private let profileEditSegueIdentifier = "profileEditSegue"
	private let profileSettingsSeguIdentifier = "profileSettingsSegue"
	private let showFriendsSegueIdentifier = "showFriendsSegueIdentifier"
	private var noJoinedMessage = "You have not joined any upcoming events"
	
	// MARK: Enum
	
	enum Section: Int, CaseIterable {
		case info = 0
		case upcoming
		case livefeed
	}
}
