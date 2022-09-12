//
//  CommunityRepliesViewController.swift
//  Portl
//
//  Created by Jeff Creed on 8/27/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CoreData
import CSkyUtil

class CommunityRepliesViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, CommunityRepliesTableViewCellDelegate, VideoPlayerProvidingCellDelegate, VoteButtonsProvidingCellDelegate {
	// MARK: VoteButtonsProvidingCellDelegate
	
	func voteForIndexPath(indexPath: IndexPath, isUp: Bool) {
		switch TableSections(rawValue: indexPath.section)! {
		case .original:
			if let experienceID = experienceID, let profileID = profileID {
				let voteStatus = profileService.getVoteStatusForExperience(profileID: profileID, experienceKey: experienceID)
				let newVoteStatus = voteStatus == isUp ? nil : isUp

				profileService.voteOnExperience(withProfileID: profileID, andExperienceKey: experienceID, vote: newVoteStatus)
			} else if let messageKey = originalMessageKey, let eventID = eventID {
				let conversationKey = ConversationService.getCommunityConversationID(fromEventID: eventID)
				
				let voteStatus = profileService.getVoteStatusForConversationMessage(conversationKey: conversationKey, messageKey: messageKey)
				let newVoteStatus = voteStatus == isUp ? nil : isUp
				
				profileService.voteOnConversationMessage(withConversationKey: conversationKey, andMessageKey: messageKey, vote: newVoteStatus)
			}
		case .replies:
			if let message = repliesFetchedResultsController?.object(at: getRepliesIndexPath(fromTableViewIndexPath: indexPath)) {
				let voteStatus = profileService.getVoteStatusForConversationMessage(conversationKey: conversationID!, messageKey: message.key)
				let newVoteStatus = voteStatus == isUp ? nil : isUp
				
				profileService.voteOnConversationMessage(withConversationKey: conversationID!, andMessageKey: message.key, vote: newVoteStatus)
			}
		}
	}
	
	func voteButtonsProvidingCellSelectedUpvote(_ voteButtonsProvidingCell: VoteButtonsProvidingCell) {
		guard !(Auth.auth().currentUser?.isAnonymous ?? true) else {
			self.presentErrorAlert(withMessage: "You must be signed in to participate.", completion: nil)
			return
		}

		if let indexPath = tableView.indexPath(for: voteButtonsProvidingCell as! UITableViewCell) {
			voteForIndexPath(indexPath: indexPath, isUp: true)
		}
	}
	
	func voteButtonsProvidingCellSelectedDownvote(_ voteButtonsProvidingCell: VoteButtonsProvidingCell) {
		guard !(Auth.auth().currentUser?.isAnonymous ?? true) else {
			self.presentErrorAlert(withMessage: "You must be signed in to participate.", completion: nil)
			return
		}

		if let indexPath = tableView.indexPath(for: voteButtonsProvidingCell as! UITableViewCell) {
			voteForIndexPath(indexPath: indexPath, isUp: false)
		}
	}

	// MARK: VideoPlayerProvidingCellDelegate
	
	func videoPlayerProvidingCellTapped(_ cell: VideoPlayerProvidingCell) {
		if let indexPath = tableView.indexPath(for: cell as! UITableViewCell), TableSections(rawValue: indexPath.section)! == .original, originalMessage?.videoURL != nil {
			playbackController.present(contentForMessageKey: originalMessage!.key, from: self)
		}
	}
	
	// MARK: CommunityRepliesTableViewCellDelegate
	
	func communityRepliesTableViewCellDidSelectProfile(_ communityRepliesTableViewCell: CommunityRepliesTableViewCell) {
		guard let idx = tableView.indexPath(for: communityRepliesTableViewCell) else {
			return
		}
		
		if idx.section == TableSections.original.rawValue {
			profileIDForSegue = originalMessage?.profileID
		} else {
			guard let message = repliesFetchedResultsController?.object(at: IndexPath(row: idx.row, section: 0)) else {
				return
			}
			
			profileIDForSegue = message.profileID
		}
		
		performSegue(withIdentifier: profileSegueIdentifier, sender: self)
	}
	
	func communityRepliesTableViewCellDidSelectDelete(_ communityRepliesTableViewCell: CommunityRepliesTableViewCell) {
		guard let idx = tableView.indexPath(for: communityRepliesTableViewCell), let conversationID = conversationID else {
			return
		}
		
		let messageKey = idx.section == TableSections.original.rawValue ? originalMessageKey! : repliesFetchedResultsController!.object(at: getRepliesIndexPath(fromTableViewIndexPath: idx)).key
		
		let conversationKey: String
		
		if let eventID = eventID {
			conversationKey = idx.section == TableSections.original.rawValue ? ConversationService.getCommunityConversationID(fromEventID: eventID) : conversationID
		} else {
			conversationKey = ConversationService.getRepliesConversationID(fromProfileID: profileID!, andExperienceKey: experienceID!)
		}
		
		spinnerView.isHidden = false
		presentDeleteConfirmationAlert(withMessage: "Delete this message?") { response in
			if response {
				if let eventID = self.eventID {
					self.conversationService.deleteMessage(conversationKey: conversationKey, messageKey: messageKey, completion: {[weak self] in
						self?.spinnerView.isHidden = true
						if idx.section == TableSections.original.rawValue {
							self?.firebaseService.deleteLivefeedNotificationForCommunitMessage(withEventID: eventID, andMessageKey: messageKey)
							self?.navigationController?.popViewController(animated: true)
						}
					})
				} else if let experienceID = self.experienceID {
					if idx.section == TableSections.original.rawValue {
						self.conversationService.deleteExperience(profileID: Auth.auth().currentUser!.uid, experienceKey: experienceID) {[weak self] in
							self?.spinnerView.isHidden = true
							self?.firebaseService.deleteLivefeedNotificationForExperience(withExperienceKey: experienceID)
							self?.navigationController?.popViewController(animated: true)
						}
					} else {
						self.conversationService.deleteMessage(conversationKey: conversationKey, messageKey: messageKey) {[weak self] in
							self?.spinnerView.isHidden = true
							// TODO: delete notification for reply?
							
						}
					}
				}
			} else {
				self.spinnerView.isHidden = true
			}
		}
	}
	
	func communityRepliesTableViewCell(_ communityRepliesTableViewCell: CommunityRepliesTableViewCell, didSelectImage image: UIImage) {
		guard let controller = UIStoryboard(name: "common", bundle: nil).instantiateViewController(withIdentifier: "ImageFullScreenViewController") as? ImageFullScreenViewController else {
			return
		}
		controller.image = image
		navigationController?.show(controller, sender: self)
	}
	
	
	// MARK: UITextViewDelegate
	
	func textViewDidChange(_ textView: UITextView) {
		sendButton.isHidden = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).count < 1
		newMessage = textView.text
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
		if controller == repliesFetchedResultsController {
			tableView.beginUpdates()
		}
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		if controller == repliesFetchedResultsController {
			switch type {
			case .insert:
				tableView.insertRows(at: [getTableViewIndexPath(fromRepliesIndexPath: newIndexPath!)], with: .fade)
			case .update:
				let message = repliesFetchedResultsController!.object(at: indexPath!)
				if let cell = tableView.cellForRow(at: getTableViewIndexPath(fromRepliesIndexPath: indexPath!)) as? CommunityRepliesTableViewCell {
					let shouldHighlight = message.key == messageKeyToHighlight

					cell.configure(forMessage: message, usingDateFormatter: actionDateFormatter, shouldHighlight: shouldHighlight)
				}
			case .move:
				tableView.deleteRows(at: [getTableViewIndexPath(fromRepliesIndexPath: indexPath!)], with: .fade)
				tableView.insertRows(at: [getTableViewIndexPath(fromRepliesIndexPath: newIndexPath!)], with: .fade)
			case .delete:
				tableView.deleteRows(at: [getTableViewIndexPath(fromRepliesIndexPath: indexPath!)], with: .fade)
			default:
				break
			}
		}
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		if controller == repliesFetchedResultsController {
			tableView.endUpdates()
		}
	}
	
	// MARK: UITableViewDataSource
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return TableSections.allCases.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch TableSections(rawValue: section)! {
		case .original:
			return originalMessage != nil ? 1 : 0
		case .replies:
			return repliesFetchedResultsController?.fetchedObjects?.count ?? 0
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeue(CommunityRepliesTableViewCell.self, for: indexPath)
		
		switch TableSections(rawValue: indexPath.section)! {
		case .original:
			if let profileID = originalMessage?.profileID, let profile = idToLoadedProfile[profileID] {
				cell.configure(forProfile: profile, isOriginal: true)
			} else {
				firebaseService.getProfile(withProfileID: originalMessage!.profileID, forConversationKey: conversationID!, completion: {[weak self] (error, profile) in
					if let strongSelf = self {
						strongSelf.idToLoadedProfile[strongSelf.originalMessage!.profileID] = profile
						strongSelf.reloadVisibleRows(forProfileWithID: strongSelf.originalMessage!.profileID)
					}
				}, withContext: nil)
			}
						
			var voteStatus: Bool? = nil
			if let experienceID = experienceID, let profileID = profileID {
				voteStatus = profileService.getVoteStatusForExperience(profileID: profileID, experienceKey: experienceID)
			} else if let messageKey = originalMessage?.key, let eventID = eventID {
				let conversationKey = ConversationService.getCommunityConversationID(fromEventID: eventID)
				voteStatus = profileService.getVoteStatusForConversationMessage(conversationKey: conversationKey, messageKey: messageKey)
			}
			cell.configure(forVote: voteStatus)
			
			cell.configure(forMessage: originalMessage!, usingDateFormatter: actionDateFormatter, shouldHighlight: false)
			cell.videoDelegate = self
			cell.showHR(true)

		case .replies:
			if let message = repliesFetchedResultsController?.object(at: getRepliesIndexPath(fromTableViewIndexPath: indexPath)) {

				if let profile = idToLoadedProfile[message.profileID] {
					cell.configure(forProfile: profile, isOriginal: true)
				} else {
					firebaseService.getProfile(withProfileID: message.profileID, forConversationKey: conversationID!, completion: {[weak self] (error, profile) in
						if let strongSelf = self {
							strongSelf.idToLoadedProfile[message.profileID] = profile
							strongSelf.reloadVisibleRows(forProfileWithID: message.profileID)
						}
						}, withContext: nil)
				}

				let shouldHighlight = message.key == messageKeyToHighlight

				cell.configure(forVote: profileService.getVoteStatusForConversationMessage(conversationKey: conversationID!, messageKey: message.key))
				cell.configure(forMessage: message, usingDateFormatter: actionDateFormatter, shouldHighlight: shouldHighlight)
			}
			cell.showHR(false)
		}
		cell.delegate = self
		cell.voteDelegate = self
		
		return cell
	}
	
	// MARK: Private
	
	private func getTableViewIndexPath(fromRepliesIndexPath repliesIndexPath: IndexPath) -> IndexPath {
		return IndexPath(row: repliesIndexPath.row, section: TableSections.replies.rawValue)
	}
	
	private func getRepliesIndexPath(fromTableViewIndexPath tableViewIndexPath: IndexPath) -> IndexPath {
		return IndexPath(row: tableViewIndexPath.row, section: 0)
	}
	
	@IBAction private func saveNewMessage(_ sender: Any) {
		guard let message = newMessage?.trimmingCharacters(in: .whitespacesAndNewlines), message.count > 0 else {
			presentErrorAlert(withMessage: "Message must not be empty.", completion: nil)
			return
		}
		
		textView.resignFirstResponder()
		
		// TODO: MOVE INTO PORTLSERVICE
		let actionDateString = firebaseDateFormatter.string(from: Date())
		let firebaseMessage = FirebaseConversation.Message(profileID: Auth.auth().currentUser!.uid, sent: actionDateString, message: message, isHTML: false, imageURL: nil, imageHeight: nil, imageWidth: nil, eventID: eventID, eventTitle: nil, videoURL: nil, videoDuration: nil, voteTotal: nil)
		conversationService.postMessageToCurrentConversation(message: firebaseMessage)
		
		DispatchQueue.main.async {
			self.textView.text = nil
			self.sendButton.isHidden = true
		}
	}

	@IBAction private func onBack() {
		self.navigationController?.popViewController(animated: true)
	}

	@IBAction private func closeKeyboard(_ sender: Any) {
		textView.resignFirstResponder()
	}
	
	private func registerForNotifications() {
		unregisterObservers()
		
		observerTokens.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: OperationQueue.main, using: { (notification) in
			self.closeKeyboardButton.isHidden = false
			
			guard let userInfo = notification.userInfo as? Dictionary<String, AnyObject>,
				let kbRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
				let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
					return
			}
			
			UIView.animate(withDuration: animationDuration, animations: {
				self.textViewBottomConstraint.constant = kbRect.height + self.textViewBottomConstraintDefault - (self.tabBarController?.tabBar.frame.height ?? 0.0)
				self.view.layoutIfNeeded()
			})
		}))
		
		observerTokens.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main, using: { (notification) in
			self.closeKeyboardButton.isHidden = true
			
			guard let userInfo = notification.userInfo as? Dictionary<String, AnyObject>, let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
				return
			}
			
			UIView.animate(withDuration: animationDuration, animations: {
				self.textViewBottomConstraint.constant = self.textViewBottomConstraintDefault
				self.view.layoutIfNeeded()
			})
		}))
	}
	
	private func unregisterObservers() {
		for token in observerTokens {
			NotificationCenter.default.removeObserver(token)
		}
	}
	
	private func reloadVisibleRows(forProfileWithID profileID: String) {
		var toReload = [IndexPath]()
		
		if let indexPaths = tableView.indexPathsForVisibleRows {
			for indexPath in indexPaths {
				if indexPath.section == TableSections.original.rawValue {
					if let message = originalMessage {
						if message.profileID == profileID {
							if let cell = tableView.cellForRow(at: indexPath) as? CommunityRepliesTableViewCell, let profile = idToLoadedProfile[profileID] {
								cell.configure(forProfile: profile, isOriginal: true)
							}
						}
					}
				} else {
					if let message = repliesFetchedResultsController?.fetchedObjects?[indexPath.row] {
						if message.profileID == profileID {
							toReload.append(indexPath)
						}
					}
					
					UIView.performWithoutAnimation {
						tableView.reloadRows(at: toReload, with: .none)
					}
				}
			}
		}
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == profileSegueIdentifier {
			let controller = segue.destination as! ProfileViewController
			controller.profileID = profileIDForSegue
		}
	}

	// MARK: Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		navigationItem.title = "Comments"
		let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: .plain, target: self, action: #selector(onBack))
		backItem.tintColor = PaletteColor.light1.uiColor
		self.navigationItem.leftBarButtonItem = backItem
		
		tableView.registerNib(CommunityRepliesTableViewCell.self)
		tableView.rowHeight = UITableView.automaticDimension
		
		textViewOutlineView.layer.borderColor = PaletteColor.dark3.cgColor
		textViewOutlineView.layer.borderWidth = 1.0
		textViewOutlineView.layer.cornerRadius = 8
		
		sendButton.layer.borderColor = PaletteColor.light1.cgColor
		sendButton.layer.borderWidth = 1.0
		sendButton.layer.cornerRadius = 4
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		spinnerView.isHidden = false
		
		registerForNotifications()

		if let messageKey = originalMessageKey {
			conversationID = ConversationService.getRepliesConversationID(fromMessageKey: messageKey)
		} else {
			conversationID = ConversationService.getRepliesConversationID(fromProfileID: profileID!, andExperienceKey: experienceID!)
		}
		
		
		// TOD: USE PORTL SERVICE ONCE ALL FIREBASE INFO IS IN CORE DATA
		conversationService.loadConversationForID(forID: conversationID!)

		let onMessageLoad = { [weak self] in
			if let conversationID = self?.conversationID {
				self?.firebaseService.getConversation(withKey: conversationID, archivedMessageKeys: nil) { [weak self] (conversationError) in
					guard let strongSelf = self else {
						return
					}
				
					if conversationError != nil {
						strongSelf.presentErrorAlert(withMessage: conversationError!.localizedDescription, completion: nil)
					}
				
					strongSelf.repliesFetchedResultsController = strongSelf.firebaseService.fetchedResultsController(forMessagesWithConversationKey: strongSelf.conversationID!, delegate: strongSelf, ascending: true)
					
					if strongSelf.originalMessage?.videoURL != nil && !strongSelf.playbackController.videos.keys.contains(strongSelf.originalMessage!.key) {
						strongSelf.playbackController.videos[strongSelf.originalMessage!.key] = Video(hlsUrl: URL(string: strongSelf.originalMessage!.videoURL!)!, duration: strongSelf.originalMessage!.videoDuration!.doubleValue)
					}
					
					UIView.performWithoutAnimation {
						strongSelf.tableView.reloadData()
						strongSelf.spinnerView.isHidden = true
					}
				}
			}
		}
		
		if let eventID = eventID, let messageKey = originalMessageKey {
			firebaseService.getConversationMessage(forConversationKey: ConversationService.getCommunityConversationID(fromEventID: eventID), andMessageKey: messageKey) {[weak self] (message) in
				self?.originalMessage = message
				onMessageLoad()
			}
		} else if let profileID = profileID, let experienceID = experienceID {
			firebaseService.getExperience(forProfileID: profileID, andExperienceKey: experienceID) {[weak self] (message) in
				self?.originalMessage = message
				onMessageLoad()
			}
		}
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		repliesFetchedResultsController?.delegate = nil
		
		unregisterObservers()

		// TODO: service func to remove listener for convo
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		Injector.root?.inject(into: inject)
	}
	
	private func inject(firebaseService: FirebaseDataProviding, conversationService: ConversationService, actionDateFormatter: DateFormatterQualifier, firebaseDateFormatter: FirebaseDateFormatter, profileService: UserProfileService) {
		self.firebaseService = firebaseService
		self.conversationService = conversationService
		self.actionDateFormatter = actionDateFormatter.value
		self.firebaseDateFormatter = firebaseDateFormatter.value
		self.playbackController = PlaybackController()
		self.profileService = profileService
	}
	
	// MARK: Properties
	
	var messageKeyToHighlight: String?

	var originalMessageKey: String?
	var eventID: String?
	var profileID: String?
	var repliesFetchedResultsController: NSFetchedResultsController<ConversationMessage>?
	var experienceID: String?
	
	// MARK: Properties (Private)
	
	private var playbackController: PlaybackController!
	private var wantsFullScreen = false
	private var hasVideo = false
	private var profileService: UserProfileService!
	
	private var conversationID: String?
	private var originalMessage: ConversationMessage?
	private var firebaseService: FirebaseDataProviding!
	private var conversationService: ConversationService!
	private var actionDateFormatter: DateFormatter!
	private var firebaseDateFormatter: DateFormatter!
	private var idToLoadedProfile = [String: Profile]()

	private var profileIDForSegue: String?
	
	private var observerTokens = [Any]()
	private var newMessage: String?

	@IBOutlet private weak var tableView: UITableView!
	@IBOutlet private weak var closeKeyboardButton: UIButton!
	@IBOutlet private weak var textView: UITextView!
	@IBOutlet private weak var sendButton: UIButton!
	@IBOutlet private weak var textViewOutlineView: UIView!
	@IBOutlet private weak var textViewBottomConstraint: NSLayoutConstraint!
	private var textViewBottomConstraintDefault: CGFloat = 10.0
	@IBOutlet private weak var spinnerView: UIView!
	
	private enum TableSections: Int, CaseIterable {
		case original = 0
		case replies
	}
	
	private let profileSegueIdentifier = "profileSegue"
}
