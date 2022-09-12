//
//  DirectConversationViewController.swift
//  Portl
//
//  Created by Jeff Creed on 5/8/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CoreData
import CSkyUtil
import RxSwift
import CoreLocation

class DirectConversationViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
	
	// MARK: UITextViewDelegate
	
	func textViewDidChange(_ textView: UITextView) {
		sendButton.isHidden = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).count < 1
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		if text == "\n" {
			textView.resignFirstResponder()
			return false
		}
		return true
	}
	
	// MARK: NSFetchedResultsControllerDelegate
	
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.beginUpdates()
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		UIView.performWithoutAnimation {
			switch(type) {
			case .insert:
				if let indexPath = nsfrcIndexPathToSectionedIndexPath(nsfrgIndexPath: newIndexPath) {
					tableView.insertRows(at: [indexPath], with: .none)
					tableView.contentOffset = CGPoint(x: 0, y:tableView.contentSize.height - tableView.frame.height)
				}
				break
			case .update:
				if let indexPath = nsfrcIndexPathToSectionedIndexPath(nsfrgIndexPath: indexPath) {
					tableView.cellForRow(at: indexPath)
					// todo: configure cell? can't edit direct messages, only delete so not needed now really
				}
				break
			case .move:
				if let indexPath = nsfrcIndexPathToSectionedIndexPath(nsfrgIndexPath: indexPath) {
					tableView.deleteRows(at: [indexPath], with: .none)
				}
				
				if let newIndexPath = nsfrcIndexPathToSectionedIndexPath(nsfrgIndexPath: newIndexPath) {
					tableView.insertRows(at: [newIndexPath], with: .none)
				}
				break
			case .delete:
				if let indexPath = nsfrcIndexPathToSectionedIndexPath(nsfrgIndexPath: indexPath) {
					tableView.deleteRows(at: [indexPath], with: .none)
				}
				break
			@unknown default:
				print("ERROR: Handling unknown NSFetchedResultsChangeType...")
			}
		}
	}
	
	private func nsfrcIndexPathToSectionedIndexPath(nsfrgIndexPath: IndexPath?) -> IndexPath? {
		var result: IndexPath?
		
		if let original = nsfrgIndexPath {
			var row = original.row
			for (index, section) in sectionedMessages.enumerated() {
				if row < section.count {
					result = IndexPath(row: row, section: index)
				} else {
					row -= section.count
				}
			}
		}
		return result
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.endUpdates()
		userProfileService.markConversationSeen(conversationKey: conversationKey!)
	}
	
	// MARK: UITableViewDataSource
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return sectionedMessages.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sectionedMessages[section].count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let message = sectionedMessages[indexPath.section][indexPath.row]
		let authID = Auth.auth().currentUser!.uid
		
		var cell: BaseDirectMessageTableViewCell
		if message.profileID != authID {
			cell = tableView.dequeue(DirectMessageReceivedTableViewCell.self, for: indexPath)
			cell.setBatched(receivedMessageKeysBatch.contains(message.key))
		} else {
			cell = tableView.dequeue(DirectMessageSentTableViewCell.self, for: indexPath)
			cell.setBatched(sentMessageKeysBatch.contains(message.key))
		}
		
		configureMessageCell(cell, message: message, indexPath: indexPath)
		return cell
	}
	
	private func configureMessageCell(_ cell: BaseDirectMessageTableViewCell, message: ConversationMessage, indexPath: IndexPath) {
		if let urlString = message.imageURL {
			cell.willHaveImage = true
			cell.configure(withImageURL: urlString)
		}
		if let eventID = message.eventIdentifier {
			cell.willHaveEvent = true
			if let event = requiredEvents[eventID] {
				let meters = locationService.currentLocation!.distance(from: CLLocation(latitude: event.venue.location.latitude, longitude: event.venue.location.longitude))
				let distanceString = String(format:"%.1f mi", meters/METERS_ONE_MILE)
				let dateString = eventDateFormatter.string(from: event.startDateTime as Date)
				let defaultImage = UIService.defaultImageForEvent(event: event)
				cell.configureForEvent(withTitle: event.title, imageURL: event.imageURL ?? event.artist?.imageURL, defaultImage: defaultImage, date: dateString, andDistance: distanceString)
			} else {
				portlService.getEvent(forIdentifier: eventID).subscribe(onNext: {[weak self] managedObjectID in
					self?.portlService.getEvent(forManagedObjectID: managedObjectID, completion: { (event) in
						DispatchQueue.main.async {
							self?.requiredEvents[eventID] = event
							UIView.performWithoutAnimation {
								self?.tableView.reloadRows(at: [indexPath], with: .none)
							}
						}
					})
				}).disposed(by: disposeBag)
			}
		}
		
		cell.configure(forConversationMessage: message)
		cell.transform = CGAffineTransform(scaleX: 1, y: -1)
		
		if !seenMessageKeys.contains(message.key) {
			userProfileService.markConversationMessagesSeen(messageKeys: [message.key])
			seenMessageKeys.insert(message.key)
		}
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let footerView = tableView.dequeue(WhiteLabelSectionHeaderView.self)
		let firstItem = sectionedMessages[section][0]
		footerView.label.text = sectionDateFormatter.string(from: firstItem.sent as Date)
		footerView.transform = CGAffineTransform(scaleX: 1, y: -1)
		return footerView
	}
	
	// MARK: UITableViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
		
		if tableView.isEditing {
			// add / remove message key from batch
			batchMessage(forIndexPath: indexPath)
		} else {
			
			let message = sectionedMessages[indexPath.section][indexPath.row]
			if let eventID = message.eventIdentifier, let event = requiredEvents[eventID] {
				DispatchQueue.main.async {
					NotificationCenter.default.post(name: Notification.Name(gNotificationOpenEventDetail), object: nil, userInfo: ["event": event])
				}
			} else if let imageMessageCell = tableView.cellForRow(at: indexPath) as? BaseDirectMessageTableViewCell, let image = imageMessageCell.getMessageImage() {
				guard let controller = UIStoryboard(name: "common", bundle: nil).instantiateViewController(withIdentifier: "ImageFullScreenViewController") as? ImageFullScreenViewController else {
					return
				}
				controller.image = image
				navigationController?.show(controller, sender: self)
			}
		}
	}
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return .none
	}
	
	// MARK: Private
	
	func batchMessage(forIndexPath indexPath:IndexPath) {
		let message = sectionedMessages[indexPath.section][indexPath.row]
		
		let authID = Auth.auth().currentUser!.uid
		if message.profileID == authID {
			if sentMessageKeysBatch.contains(message.key) {
				sentMessageKeysBatch.remove(message.key)
			} else {
				sentMessageKeysBatch.insert(message.key)
			}
		} else {
			if receivedMessageKeysBatch.contains(message.key) {
				receivedMessageKeysBatch.remove(message.key)
			} else {
				receivedMessageKeysBatch.insert(message.key)
			}
		}
		
		tableView.reloadRows(at: [indexPath], with: .none)
	}
	
	@IBAction private func send(_ sender: Any) {
		let message = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
		
		guard message.count > 0 else {
			presentErrorAlert(withMessage: "Message must not be empty.", completion: nil)
			return
		}
		
		textView.resignFirstResponder()
		let actionDateString = notificationFormatter.string(from: Date())
		let firebaseMessage = FirebaseConversation.Message(profileID: Auth.auth().currentUser!.uid, sent: actionDateString, message: message, isHTML: false, imageURL: nil, imageHeight: nil, imageWidth: nil, eventID: nil, eventTitle: nil, videoURL: nil, videoDuration: nil, voteTotal: nil)
		conversationService.postMessageToConversation(withConversationKey: conversationKey!, message: firebaseMessage)
		DispatchQueue.main.async {
			self.textView.text = ""
		}
	}
	
	@IBAction private func openCamera(_ sender: Any) {
		if let controller = UIStoryboard(name: "message", bundle: nil).instantiateViewController(withIdentifier: "BuildPhotoMessageScene") as? UINavigationController {
			controller.modalPresentationStyle = .overFullScreen
			self.tabBarController?.present(controller, animated: true, completion: nil)
		}
	}
	
	@IBAction private func onEditCancel(_ sender: Any) {
		toggleEdit()
	}
	
	private func toggleEdit() {
		tableView.setEditing(!tableView.isEditing, animated: true)
		editCancelButton.title = tableView.isEditing ? "Cancel" : "Edit"
		
		sentMessageKeysBatch.removeAll()
		receivedMessageKeysBatch.removeAll()
		
		UIView.animate(withDuration: 0.25) {
			self.batchActionsViewBottomConstraint.constant = self.tableView.isEditing ? 0 : -self.batchActionsView.bounds.height
			self.view.layoutIfNeeded()
		}
	}
	
	@IBAction private func onDeleteBatchedMessages(_ sender: Any) {
		guard let convoKey = conversationKey, receivedMessageKeysBatch.count + sentMessageKeysBatch.count > 0 else {
			return
		}
		
		presentDeleteConfirmationAlert(withMessage: "Delete the selected messages?") { (response) in
			if response {
				self.editCancelButton.isEnabled = false
				self.spinnerView.isHidden = false
				self.messagesFetchedResultsController?.delegate = nil
				
				// for sent: delete from conversation
				self.conversationService.deleteMessages(conversationKey: convoKey, messageKeys: self.sentMessageKeysBatch)
				
				// for received: add keys to profile as archived messages
				self.userProfileService.archiveMesssages(inConversationWithKey: convoKey, messageKeys: self.receivedMessageKeysBatch) {[weak self] (receivedMessagesError) in
					if receivedMessagesError != nil {
						self?.presentErrorAlert(withMessage: "Error deleting messages.", completion: nil)
					}
					
					self?.requestConversation()
					self?.spinnerView.isHidden = true
					self?.editCancelButton.isEnabled = true
					self?.toggleEdit()
				}
			}
		}
	}
	
	private func reloadTableView() {
		calculateSections()
		
		UIView.performWithoutAnimation {
			tableView.reloadData()
		}
		
		spinnerView.isHidden = true
		emptyLabel.isHidden = messagesFetchedResultsController?.fetchedObjects?.count ?? 0 != 0
	}
	
	private func calculateSections() {
		sectionedMessages.removeAll()
		
		var lastSectionTime: NSDate? = nil
		var currentSectionItems = Array<ConversationMessage>()
		
		messagesFetchedResultsController?.fetchedObjects?.enumerated().forEach({ (index, message) in
			if let sectionTime = lastSectionTime {
				
				if abs(Calendar.current.dateComponents([.minute], from: sectionTime as Date, to: message.sent as Date).minute ?? 0)  > 60 {
					sectionedMessages.append(currentSectionItems)
					lastSectionTime = message.sent
					currentSectionItems.removeAll()
					currentSectionItems.append(message)
				} else {
					currentSectionItems.append(message)
				}
				
			} else {
				lastSectionTime = message.sent
				currentSectionItems.append(message)
			}
			
			if index == messagesFetchedResultsController!.fetchedObjects!.count - 1 {
				sectionedMessages.append(currentSectionItems)
			}
			
		})
	}
	
	private func markMessagesRead() {
		if let messages = messagesFetchedResultsController?.fetchedObjects {
			userProfileService.markConversationMessagesSeen(messageKeys: messages.map { $0.key })
		}
	}
	
	// MARK: Navigation
	
	@IBAction private func segueToProfile(_ sender: Any) {
		guard profileId != nil else {
			return
		}
		
		performSegue(withIdentifier: profileSegueIdentifier, sender: self)
	}
	
	@IBAction private func onBack() {
		if isModal {
			dismiss(animated: true, completion: nil)
		} else {
			navigationController?.popViewController(animated: true)
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == profileSegueIdentifier {
			let controller = segue.destination as! ProfileViewController
			controller.profileID = profileId
			controller.shownFromMessage = true
		} else {
			super.prepare(for: segue, sender: sender)
		}
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
			
			self.editCancelButton.isEnabled = false
			
			UIView.animate(withDuration: animationDuration, animations: {
				self.textViewBottomConstraint.constant = kbRect.height + self.textViewBottomConstraintDefault - (self.tabBarController?.tabBar.frame.height ?? 0.0)
				self.view.layoutIfNeeded()
			})
		}))
		
		observerTokens.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main, using: { (notification) in
			guard let userInfo = notification.userInfo as? Dictionary<String, AnyObject>, let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
				return
			}
			
			self.editCancelButton.isEnabled = true
			
			UIView.animate(withDuration: animationDuration, animations: {
				self.textViewBottomConstraint.constant = self.textViewBottomConstraintDefault
				self.view.layoutIfNeeded()
			})
		}))
		
		observerTokens.append(NotificationCenter.default.addObserver(forName: Notification.Name(gNotificationMessageRoomsUpdated), object: nil, queue: OperationQueue.main, using: { (notification) in
			// we need to do this to account for unread message information showing up after message is received while in the conversation
			// no data actually gets sent to firebase unless there are messages in this conversation that have been seen but still are in the unread messages of the user's profile
			self.markMessagesRead()
		}))
	}
	
	private func unregisterObservers() {
		for token in observerTokens {
			NotificationCenter.default.removeObserver(token)
		}
	}
	
	private func requestConversation() {
		guard let archived = try? userProfileService.authenticatedProfile.value()?.conversation?[conversationKey!]?.archivedMessages ?? [:] else {
			return
		}
		
		firebaseService.getConversation(withKey: conversationKey!, archivedMessageKeys: Array(archived.keys)) {[weak self] (error) in
			if let strongSelf = self {
				strongSelf.messagesFetchedResultsController = strongSelf.firebaseService.fetchedResultsController(forMessagesWithConversationKey: strongSelf.conversationKey!, delegate: strongSelf, ascending: false)
				
				strongSelf.reloadTableView()
				
				if error == nil {
					strongSelf.userProfileService.markConversationSeen(conversationKey: strongSelf.conversationKey!)
				}
			}
		}
	}
	
	// MARK: Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		textViewOutlineView.layer.borderColor = PaletteColor.dark3.cgColor
		textViewOutlineView.layer.borderWidth = 1.0
		textViewOutlineView.layer.cornerRadius = 8
		
		cameraButtonOutlineView.layer.borderColor = PaletteColor.light1.cgColor
		cameraButtonOutlineView.layer.borderWidth = 1.0
		cameraButtonOutlineView.layer.cornerRadius = 8
		
		sendButton.layer.borderColor = PaletteColor.light1.cgColor
		sendButton.layer.borderWidth = 1.0
		sendButton.layer.cornerRadius = 4
		
		tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
		tableView.registerNib(DirectMessageSentTableViewCell.self)
		tableView.registerNib(DirectMessageReceivedTableViewCell.self)
		tableView.registerNib(WhiteLabelSectionHeaderView.self)
		tableView.allowsSelectionDuringEditing = true
		
		navigationItem.title = username
		
		let usernameButton =  UIButton(type: .custom)
		usernameButton.setTitle(username!, textStyle: .h3Bold, for: .normal)
		usernameButton.addTarget(self, action: #selector(segueToProfile), for: .touchUpInside)
		usernameButton.sizeToFit()
		navigationItem.titleView = usernameButton
		
		if isModal {
			let closeItem = UIBarButtonItem(image: UIImage(named: "icon_close"), style: .plain, target: self, action: #selector(onBack))
			closeItem.tintColor = PaletteColor.light1.uiColor
			self.navigationItem.leftBarButtonItem = closeItem
		} else {
			let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: .plain, target: self, action: #selector(onBack))
			backItem.tintColor = PaletteColor.light1.uiColor
			self.navigationItem.leftBarButtonItem = backItem
		}
		
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		spinnerView.isHidden = false
		
		requestConversation()
		
		conversationService.loadConversationForID(forID: conversationKey!)
		
		registerForNotifications()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		messagesFetchedResultsController?.delegate = nil
		
		firebaseService.removeConversationHandle(forConversationWithKey: conversationKey!)
		
		unregisterObservers()
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		Injector.root!.inject(into: inject)
	}
	
	private func inject(portlService: PortlDataProviding, firebaseService: FirebaseDataProviding, conversationService: ConversationService, notificationFormatter: FirebaseDateFormatter, dateFormatter: DateFormatterQualifier, locationService: LocationProviding, noTimeFormatter: NoTimeDateFormatterQualifier, userProfileService: UserProfileService) {
		self.portlService = portlService
		self.firebaseService = firebaseService
		self.conversationService = conversationService
		self.notificationFormatter = notificationFormatter.value
		sectionDateFormatter = dateFormatter.value
		self.locationService = locationService
		self.eventDateFormatter = noTimeFormatter.value
		self.userProfileService = userProfileService
	}
	
	// MARK: Properties
	
	@objc var conversationKey: String?
	@objc var username: String?
	@objc var profileId: String?
	var isModal = false
	
	// MARK: Properties (Private)
	
	private var portlService: PortlDataProviding!
	private var firebaseService: FirebaseDataProviding!
	private var messagesFetchedResultsController: NSFetchedResultsController<ConversationMessage>?
	private var conversationService: ConversationService!
	private var userProfileService: UserProfileService!
	private var notificationFormatter: DateFormatter!
	private var sectionDateFormatter: DateFormatter!
	private var locationService: LocationProviding!
	private var eventDateFormatter: DateFormatter!
	private var disposeBag = DisposeBag()
	
	private var sectionedMessages = Array<Array<ConversationMessage>>()
	private var requiredImages = Dictionary<String, UIImage>()
	private var observerTokens = [Any]()
	private var requiredEvents = Dictionary<String, PortlEvent>()
	private var seenMessageKeys = Set<String>()
	
	@IBOutlet private weak var tableView: UITableView!
	@IBOutlet private weak var spinnerView: UIView!
	@IBOutlet private weak var emptyLabel: UILabel!
	@IBOutlet private weak var textView: UITextView!
	@IBOutlet private weak var sendButton: UIButton!
	@IBOutlet private weak var cameraButton: UIButton!
	@IBOutlet private weak var textViewOutlineView: UIView!
	@IBOutlet private weak var cameraButtonOutlineView: UIView!
	@IBOutlet private weak var textViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet private weak var editCancelButton: UIBarButtonItem!
	@IBOutlet private weak var batchActionsView: UIView!
	@IBOutlet private weak var batchActionsViewBottomConstraint: NSLayoutConstraint!
	
	private var textViewBottomConstraintDefault: CGFloat = 10.0
	private var profileSegueIdentifier = "profileSegue"
	
	private var sentMessageKeysBatch = Set<String>()
	private var receivedMessageKeysBatch = Set<String>()
}
