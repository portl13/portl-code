//
//  ShareMessagingViewController.swift
//  Portl
//
//  Created by Jeff Creed on 3/29/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import RxSwift
import CSkyUtil
import CoreData
import Service
import SDWebImage

class ShareMessagingViewController: UIViewController, NSFetchedResultsControllerDelegate, UITextViewDelegate {

	func showProfileWithID(_ profileID: String) {
		profileIDForSegue = profileID
		performSegue(withIdentifier: ShareMessagingViewController.profileSegue, sender: self)
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

	// MARK: Private
	
	@IBAction private func saveNewMessage(_ sender: Any) {
		guard let message = newMessage?.trimmingCharacters(in: .whitespacesAndNewlines), message.count > 0 else {
			presentErrorAlert(withMessage: "Message must not be empty.", completion: nil)
			return
		}
		
		textView.resignFirstResponder()
		
		let actionDateString = notificationFormatter.string(from: Date())
		let firebaseMessage = FirebaseConversation.Message(profileID: Auth.auth().currentUser!.uid, sent: actionDateString, message: message, isHTML: false, imageURL: nil, imageHeight: nil, imageWidth: nil, eventID: nil, eventTitle: nil, videoURL: nil, videoDuration: nil, voteTotal: nil)
		conversationService.postMessageToCurrentConversation(message: firebaseMessage)
		DispatchQueue.main.async {
			self.textView.text = nil
			self.sendButton.isHidden = true
			self.shareMessagesViewController?.postedNew = true
		}
	}
	
	private func setActiveViewController(viewController: UIViewController) {
		guard viewController !== currentContentViewController else {
			return
		}
		
		currentContentViewController?.willMove(toParent: nil)
		addChild(viewController)
		
		viewController.view.frame = containerView.frame
		viewController.view.translatesAutoresizingMaskIntoConstraints = false
		currentContentViewController?.view.removeFromSuperview()
		
		containerView.addSubview(viewController.view)
		containerView.addConstraint(viewController.view.topAnchor.constraint(equalTo: containerView.topAnchor))
		containerView.addConstraint(viewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor))
		containerView.addConstraint(viewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor))
		containerView.addConstraint(viewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor))
		
		currentContentViewController?.removeFromParent()
		viewController.didMove(toParent: self)
		
		currentContentViewController = viewController
	}
		
	@IBAction func onBack() {
		self.navigationController?.popViewController(animated: true)
	}
	
	@IBAction private func segmentSelected(_ sender: Any?) {
		segmentIndex = (sender as! UISegmentedControl).selectedSegmentIndex
		configureForSegmentIndex()
	}
	
	private func configureForSegmentIndex() {
		switch Segment(rawValue: segmentIndex)! {
		case .going:
			shareGoingViewController.userIDs = goingIDs
			setActiveViewController(viewController: shareGoingViewController)
			textViewOutlineView.isHidden = true
		case .interested:
			if shareInterestedViewController == nil {
				shareInterestedViewController = UIStoryboard(name: "share", bundle: nil).instantiateViewController(withIdentifier: "ShareGoingViewController") as? ShareGoingViewController
				shareInterestedViewController?.userIDs = interestedIDs ?? []
			}
			setActiveViewController(viewController: shareInterestedViewController!)
			textViewOutlineView.isHidden = true
		case .comments:
			if shareMessagesViewController == nil {
				shareMessagesViewController = UIStoryboard(name: "share", bundle: nil).instantiateViewController(withIdentifier: "ShareMessagesViewController") as? ShareMessagesViewController
				shareMessagesViewController?.conversation = conversation
			}
			setActiveViewController(viewController: shareMessagesViewController!)
			textViewOutlineView.isHidden = false
		}
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
				if kbRect.height > 0 {
					self.textViewBottomConstraint.constant = kbRect.height + self.textViewBottomConstraintDefault - (self.tabBarController?.tabBar.frame.height ?? 0.0)
					self.view.layoutIfNeeded()
				}
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

	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == ShareMessagingViewController.shareGoingEmbedSegue {
			shareGoingViewController = segue.destination as? ShareGoingViewController
			shareGoingViewController.userIDs = goingIDs
			currentContentViewController = shareGoingViewController
		} else if segue.identifier == ShareMessagingViewController.profileSegue {
			if let controller = segue.destination as? ProfileViewController {
				controller.profileID = profileIDForSegue
			}
		} else {
			super.prepare(for: segue, sender: sender)
		}
	}

	// MARK: Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: .plain, target: self, action: #selector(onBack))
		backItem.tintColor = PaletteColor.light1.uiColor
		self.navigationItem.leftBarButtonItem = backItem
		
		eventImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		eventImageView.sd_imageIndicator?.startAnimatingIndicator()
		eventTitleLabel.isHidden = true
		eventDateLabel.isHidden = true
		shareMessageLabel.isHidden = true
		
		textViewOutlineView.layer.borderColor = PaletteColor.dark3.cgColor
		textViewOutlineView.layer.borderWidth = 1.0
		textViewOutlineView.layer.cornerRadius = 8
		
		sendButton.layer.borderColor = PaletteColor.light1.cgColor
		sendButton.layer.borderWidth = 1.0
		sendButton.layer.cornerRadius = 4
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		registerForNotifications()

		eventService.clearEvent()
		
		eventDisposable = eventService.event.subscribe(onNext: {[unowned self] firebaseEvent in
			self.firebaseEvent = firebaseEvent
		})
		
		conversationService.clearConversation()

		conversationDisposable = conversationService.conversation.subscribe(onNext: {[unowned self] convo in
			self.conversation = convo
			self.shareMessagesViewController?.conversation = convo
		})

		if let notification = livefeedNotification, let eventID = notification.eventID {
			
			eventService.loadEvent(withEventID: eventID)
			
			let conversationID = ConversationService.getShareConversationID(fromEventID: eventID, userID: notification.userID, andActionDateString: notificationFormatter.string(from: notification.date as Date))
			conversationService.loadConversationForID(forID: conversationID)
			
			self.fetchedResultsController = self.portlService.fetchedResultsController(forEventIDs: [eventID], delegate: self)

			portlService.getEvents(forIDs: [eventID]).subscribe(onCompleted: {[unowned self] in
				self.portlEvent = self.fetchedResultsController?.fetchedObjects?.first
			}).disposed(by: disposeBag)
		}
		
		segmentedControl.selectedSegmentIndex = segmentIndex
		configureForSegmentIndex()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		eventDisposable?.dispose()
		conversationDisposable?.dispose()
		unregisterObservers()
	}

	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		Injector.root!.inject(into: inject)
	}
	
	private func inject(conversationService: ConversationService, profileService: UserProfileService, eventService: EventService, portlService: PortlDataProviding, eventDateFormatter: LongDateFormatterQualifier, notificationFormatter: FirebaseDateFormatter) {
		self.profileService = profileService
		self.eventService = eventService
		self.portlService = portlService
		self.eventDateFormatter = eventDateFormatter.value
		self.conversationService = conversationService
		self.notificationFormatter = notificationFormatter.value
	}
	
	// MARK: Properties
	
	var livefeedNotification: LivefeedNotification?
	var segmentIndex = 0

	// MARK: Properties (Private)
	
	private var eventService: EventService!
	private var profileService: UserProfileService!
	private var conversationService: ConversationService!
	private var portlService: PortlDataProviding!
	private var eventDateFormatter: DateFormatter!
	private var notificationFormatter: DateFormatter!
	
	private var portlEvent: PortlEvent? {
		didSet {
			if let event = portlEvent {
				if let urlString = event.imageURL ?? event.artist?.imageURL, let url = URL(string: urlString) {
					eventImageView.sd_setImage(with: url) {[weak self] (_, error, _, _) in
						if error != nil {
							self?.eventImageView.image = UIService.defaultImageForEvent(event: event)
							self?.eventImageView.sd_imageIndicator?.stopAnimatingIndicator()
						}
					}
				} else {
					eventImageView.image = UIService.defaultImageForEvent(event: event)
					eventImageView.sd_imageIndicator?.stopAnimatingIndicator()
				}
				
				eventTitleLabel.attributedText = NSAttributedString(string: event.title, textStyle: .bodyBold)
				let dateString = eventDateFormatter.string(from: event.startDateTime as Date)
				eventDateLabel.attributedText = NSAttributedString(string: dateString, textStyle: .small)
				
				DispatchQueue.main.async {
					self.eventTitleLabel.isHidden = false
					self.eventDateLabel.isHidden = false
				}
			}
		}
	}
	
	private var fetchedResultsController: NSFetchedResultsController<PortlEvent>?
	private var disposeBag = DisposeBag()
	
	private var eventDisposable: Disposable?
	private var firebaseEvent: FirebaseEvent? {
		didSet {
			goingIDs = firebaseEvent?.going?.filter({ (goingData) -> Bool in
				return goingData.value.goingStatus() == FirebaseProfile.EventGoingStatus.going
			}).map({ (goingData) -> String in
				return goingData.key
			})
			interestedIDs = firebaseEvent?.going?.filter({ (goingData) -> Bool in
				return goingData.value.goingStatus() == FirebaseProfile.EventGoingStatus.interested
			}).map({ (goingData) -> String in
				return goingData.key
			})
			
			if isViewLoaded {
				segmentedControl.setTitle(String(format: ShareMessagingViewController.goingFormat, goingIDs?.count ?? 0), forSegmentAt: Segment.going.rawValue)
				segmentedControl.setTitle(String(format: ShareMessagingViewController.interestedFormat, interestedIDs?.count ?? 0), forSegmentAt: Segment.interested.rawValue)
			}
		}
	}
	
	private var conversationDisposable: Disposable?
	private var conversation: FirebaseConversation? {
		didSet {
			if isViewLoaded {
				segmentedControl.setTitle(String(format: ShareMessagingViewController.commentsFormat, conversation?.overview?.commentCount ?? 0), forSegmentAt: Segment.comments.rawValue)
				if let message = conversation?.overview?.firstMessage {
					shareMessageLabel.attributedText = NSAttributedString(string: message, textStyle: .body)
					DispatchQueue.main.async {
						self.shareMessageLabel.isHidden = false
						self.shareMessageLabel.setNeedsLayout()
					}
				}
			}
		}
	}
	
	private var interestedIDs: [String]? {
		didSet {
			shareInterestedViewController?.userIDs = interestedIDs
		}
	}
	private var goingIDs: [String]? {
		didSet {
			shareGoingViewController.userIDs = goingIDs
		}
	}
	
	private var observerTokens = [Any]()

	private var profileIDForSegue: String?
	private var newMessage: String?
	
	private var currentContentViewController: UIViewController?
	private var shareGoingViewController: ShareGoingViewController!
	private var shareInterestedViewController: ShareGoingViewController?
	private var shareMessagesViewController: ShareMessagesViewController?
	
	@IBOutlet private weak var eventImageView: UIImageView!
	@IBOutlet private weak var eventTitleLabel: UILabel!
	@IBOutlet private weak var eventDateLabel: UILabel!
	@IBOutlet private weak var shareMessageLabel: UILabel!
	@IBOutlet private weak var segmentedControl: UISegmentedControl!
	@IBOutlet private weak var containerView: UIView!
	@IBOutlet private weak var closeKeyboardButton: UIButton!
	@IBOutlet private weak var textView: UITextView!
	@IBOutlet private weak var sendButton: UIButton!
	@IBOutlet private weak var textViewOutlineView: UIView!
	@IBOutlet private weak var textViewBottomConstraint: NSLayoutConstraint!
	private var textViewBottomConstraintDefault: CGFloat = 10.0

	// MARK: Properties (Private Static)
	
	private static let goingFormat = "%d Going"
	private static let interestedFormat = "%d Interested"
	private static let commentsFormat = "%d Comments"
	private static let profileSegue = "profileSegue"
	private static let shareGoingEmbedSegue = "shareGoingEmbedSegue"
	
	// MARK: Enum
	
	enum Segment: Int, CaseIterable {
		case going = 0
		case interested
		case comments
	}
}
