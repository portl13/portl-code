//
//  ShareViewController.swift
//  Portl
//
//  Created by Jeff Creed on 3/29/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import SDWebImage
import Service
import CoreLocation

class ShareViewController: UIViewController, UITextViewDelegate {
	
	func configureForEdit(event: PortlEvent, message: String?, conversationKey: String) {
		isEdit = true
		self.event = event
		self.text = message
		self.conversationKeyForEdit = conversationKey
	}
	
	// MARK: UITextViewDelegate
	
	func textViewDidChange(_ textView: UITextView) {
		text = textView.text
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		if text == "\n" {
			textView.resignFirstResponder()
			return false
		}
		return true
	}

	// MARK: IBAction
	
	@IBAction func onDone(_ sender: Any) {
		guard let eventID = event?.identifier, let eventTitle = event?.title else {
			return
		}
		
		spinnerView.isHidden = false
		
		if isEdit {
			conversationService.editMessage(conversationKey: conversationKeyForEdit!, message: self.text ?? "", messageKey: conversationMessageKeyForEdit!, imageURLString: nil)
			self.navigationController?.dismiss(animated: true, completion: nil)
		} else {
			if let profileIDs = profileIDsForShare {
				conversationService.share(eventID: eventID, eventTitle: eventTitle, withMessage: self.text, withProfileIDs: profileIDs)
				self.spinnerView.isHidden = true
				self.navigationController?.dismiss(animated: true, completion: nil)
			} else {
				profileService.shareEvent(eventID, completion: {[unowned self] actionDateString in
					self.conversationService.createConversationForShare(shareData: [actionDateString : eventID], message: self.text ?? "")
			
					self.spinnerView.isHidden = true
					self.navigationController?.dismiss(animated: true, completion: nil)
				})
			}
		}
	}
	
	@IBAction func onClose(_ sender: Any) {
		self.navigationController?.dismiss(animated: true, completion: nil)
	}
	
	@IBAction func onBack(_ sender: Any) {
		self.navigationController?.popViewController(animated: true)
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
			
			UIView.animate(withDuration: animationDuration, animations: {
				self.textViewBottomConstraint.constant = kbRect.height + self.textViewBottomConstraintDefault - (self.tabBarController?.tabBar.frame.height ?? 0.0)
				self.view.layoutIfNeeded()
			})
		}))
		
		observerTokens.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main, using: { (notification) in
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

	
	// MARK: Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let backItem = UIBarButtonItem(image: UIImage(named: profileIDsForShare != nil ? "icon_arrow_left" : "icon_close"), style: .plain, target: self, action: profileIDsForShare != nil ? #selector(onBack) : #selector(onClose))
		backItem.tintColor = PaletteColor.light1.uiColor
		self.navigationItem.leftBarButtonItem = backItem
		
		let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))
		doneItem.tintColor = PaletteColor.light1.uiColor
		self.navigationItem.rightBarButtonItem = doneItem
		
		textViewOutlineView.layer.borderColor = PaletteColor.dark3.cgColor
		textViewOutlineView.layer.borderWidth = 1.0
		textViewOutlineView.layer.cornerRadius = 8

		eventImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		
		if let event = event {
			let defaultImage = UIService.defaultImageForEvent(event: event)
			if let urlString = event.imageURL ?? event.artist?.imageURL, let url = URL(string: urlString) {
				eventImageView.sd_setImage(with: url) { (_, error, _, _) in
					if error != nil {
						self.eventImageView.image = defaultImage
						self.eventImageView.sd_imageIndicator?.stopAnimatingIndicator()
					}
				}
			} else {
				eventImageView.image = defaultImage
				self.eventImageView.sd_imageIndicator?.stopAnimatingIndicator()
			}
			
			eventTitleLabel.attributedText = NSAttributedString(string: event.title, textStyle: .bodyBold)
			eventDateLabel.attributedText = NSAttributedString(string: eventDateFormatter.string(from: event.startDateTime as Date))
			if let myLocation = locationService.currentLocation {
				let distance = myLocation.distance(from: CLLocation(latitude: event.venue.location.latitude, longitude: event.venue.location.longitude)) / 1609.34
				let distanceString = String(format: "%.1f mi", distance)
				distanceLabel.attributedText = NSAttributedString(string: distanceString, textStyle: .small)
			}
		}
		
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		registerForNotifications()

		if isEdit {
			spinnerView.isHidden = false
			textView.text = text
			firebaseService.getConversation(withKey: conversationKeyForEdit!, archivedMessageKeys: nil) {[weak self] (error) in
				guard let key = self?.conversationKeyForEdit else {
					self?.presentErrorAlert(withMessage: "Error loading share messages", completion: {
						self?.navigationController?.dismiss(animated: true, completion: nil)
					})
					return
				}
				
				guard let messageKey = self?.firebaseService.getKeyForFirstMessageOfConversation(withKey: key) else {
					self?.presentErrorAlert(withMessage: "Error loading share messages", completion: {
						self?.navigationController?.dismiss(animated: true, completion: nil)
					})
					return
				}
				
				self?.conversationMessageKeyForEdit = messageKey
				self?.spinnerView.isHidden = true
			}
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		unregisterObservers()
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		Injector.root?.inject(into: inject)
	}
	
	private func inject(profileService: UserProfileService, conversationService: ConversationService, eventDateFormatter: LongDateFormatterQualifier, locationService: LocationProviding, firebaseService: FirebaseDataProviding) {
		self.firebaseService = firebaseService
		self.conversationService = conversationService
		self.eventDateFormatter = eventDateFormatter.value
		self.locationService = locationService
		self.profileService = profileService
	}
	
	// MARK: Properties
	
	var event: PortlEvent?
	var profileIDsForShare: Set<String>?
	
	// MARK: Properties (Private)
	
	private var profileService: UserProfileService!
	private var conversationService: ConversationService!
	private var eventDateFormatter: DateFormatter!
	private var locationService: LocationProviding!
	private var firebaseService: FirebaseDataProviding!
	
	private var text: String?
	private var isEdit: Bool = false
	private var conversationKeyForEdit: String?
	private var conversationMessageKeyForEdit: String?
	private var observerTokens = [Any]()

	@IBOutlet private weak var eventImageView: UIImageView!
	@IBOutlet private weak var eventTitleLabel: UILabel!
	@IBOutlet private weak var eventDateLabel: UILabel!
	@IBOutlet private weak var distanceLabel: UILabel!
	@IBOutlet private weak var spinnerView: UIView!
	@IBOutlet private weak var textView: UITextView!
	@IBOutlet private weak var textViewOutlineView: UIView!
	@IBOutlet private weak var textViewBottomConstraint: NSLayoutConstraint!
	private var textViewBottomConstraintDefault: CGFloat = 10.0

	// MARK: Private (Static)
	
	private static let placeholderText = "Enter your comment..."
}
