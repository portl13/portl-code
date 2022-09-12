//
//  CreateMessageViewController.swift
//  Portl
//
//  Created by Jeff Creed on 3/26/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import AVKit
import SDWebImage

class CreateMessageViewController: UIViewController, UITextViewDelegate {
	
	func configureForEdit(message: String?, imageURL: String?, videoURL: String?, conversationKey: String, messageKey: String) {
		isEdit = true
		text = message
		imageURLForEdit = imageURL
		videoURLForEdit = videoURL
		
		conversationKeyForEdit = conversationKey
		conversationMessageKeyForEdit = messageKey
		
	}

	func configureForExperienceEdit(message: String?, imageURL: String?, videoURL: String?, experienceKey: String) {
		isExperience = true
		isEdit = true
		text = message
		imageURLForEdit = imageURL
		videoURLForEdit = videoURL
		
		experienceKeyForEdit = experienceKey
		
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

	// MARK: Private
	
	private func configureForImageOrVideo() {
		if image != nil || imageURLForEdit != nil {
			videoView.isHidden = true
			playButton.isHidden = true
			messageImageView.isHidden = false

			if image != nil {
				messageImageView.image = image
			} else if let urlString = imageURLForEdit, let url = URL(string: urlString) {
				messageImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
				messageImageView.sd_imageIndicator?.startAnimatingIndicator()
				messageImageView.sd_setImage(with: url) {[weak self] (_, error, _, _) in
					if error != nil {
						self?.messageImageView.isHidden = true
					}
				}
			}
		} else if videoURL != nil || videoURLForEdit != nil {
			videoView.isHidden = false
			playButton.isHidden = false
			messageImageView.isHidden = true
			
			if videoURL != nil {
				loadVideoURL(videoURL!)
			} else if let urlString = videoURLForEdit, let url = URL(string: urlString) {
				loadVideoURL(url)
			}
		}
	}
	
	private func loadVideoURL(_ toLoad: URL) {
		let asset = AVAsset(url: toLoad)
		let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: ["playable"])
		
		player = AVPlayer(playerItem: playerItem)
		
		let newPlayerLayer = AVPlayerLayer(player: player)
		newPlayerLayer.frame = videoView.frame
		newPlayerLayer.videoGravity = .resizeAspectFill
		newPlayerLayer.needsDisplayOnBoundsChange = true
		if let playerLayer = playerLayer {
			videoView.layer.replaceSublayer(playerLayer, with: newPlayerLayer)
		} else {
			videoView.layer.addSublayer(newPlayerLayer)
		}
		playerLayer = newPlayerLayer
		
		videoDuration = player?.currentItem?.asset.duration.seconds
	}
	
	@IBAction private func onClose() {
		navigationController?.dismiss(animated: true, completion: nil)
	}
	
	@IBAction private func onBack() {
		navigationController?.popViewController(animated: true)
	}
	
	@IBAction private func startPlayer(_ sender: Any) {
		if player?.timeControlStatus != .playing && player?.timeControlStatus != .waitingToPlayAtSpecifiedRate {
			playButton.isHidden = true
			player?.play()
			videoView.addGestureRecognizer(stopGestureRecognizer!)
			videoView.isUserInteractionEnabled = true
		}
	}
	
	@IBAction private func stopPlayer(_ sender: Any) {
		if player?.timeControlStatus == .playing {
			player?.pause()
			videoView.isUserInteractionEnabled = false
			videoView.removeGestureRecognizer(stopGestureRecognizer!)
			playButton.isHidden = false
		}
	}

	@IBAction private func savePost() {
		if !isSaving {
			spinnerView.isHidden = false
			isSaving = true
			if image != nil || videoURL != nil {
				func getCompletionBlock(writeFunc: @escaping (FirebaseConversation.Message) -> Void) -> (String?, CGSize?, String?) -> Void {
					return {[weak self] (urlString: String?, imageSize: CGSize?, videoURLString: String?) in
						if let strongSelf = self {
							if let urlString = urlString {
								let isVideo = strongSelf.videoURL != nil
								let firebaseMessage = FirebaseConversation.Message(profileID: Auth.auth().currentUser!.uid, sent: strongSelf.dateFormatter.string(from: Date()), message: strongSelf.text, isHTML: false, imageURL: urlString , imageHeight: imageSize?.height, imageWidth: imageSize?.width, eventID: nil, eventTitle: nil, videoURL: videoURLString, videoDuration: isVideo ? strongSelf.videoDuration! : nil, voteTotal: nil)
								writeFunc(firebaseMessage)
								strongSelf.navigationController?.dismiss(animated: true, completion: nil)
							} else {
								strongSelf.presentErrorAlert(withMessage: "Error uploading image.", completion: nil)
								strongSelf.isSaving = false
							}
							strongSelf.spinnerView.isHidden = true
						}
					}
				}
				if isExperience {
					if let profileID = Auth.auth().currentUser?.uid {
						if let toUpload = image {
							conversationService.uploadImageForExperience(toUpload, profileID: profileID) {[weak self] (urlString, imageSize) in
								getCompletionBlock(writeFunc: {(experience) in
									self?.conversationService.postExperience(experience: experience)
								})(urlString, imageSize, nil)
							}
						} else if let toUploadURL = videoURL {
							conversationService.uploadVideoForExperience(toUploadURL, profileID: profileID) {[weak self] (urlOnFirebase, thumbURLOnFirebase) in
								getCompletionBlock {[weak self] (experience) in
									self?.conversationService.postExperience(experience: experience)
								}(thumbURLOnFirebase, nil, urlOnFirebase)
							}
						}
					}
				} else {
					if let toUpload = image {
						conversationService.uploadImageForCurrentConversationMessage(toUpload) {[weak self] (urlString, imageSize) in
							getCompletionBlock(writeFunc: { (firebaseMessage) in
								self?.conversationService.postMessageToCurrentConversation(message: firebaseMessage)
							})(urlString, imageSize, nil)
						}
					} else if let toUploadURL = videoURL {
						conversationService.uploadVideoForCurrentConversationMessage(toUploadURL) {[weak self] (urlOnFirebase, thumbURLOnFirebase) in
							getCompletionBlock { (firebaseMessage) in
								self?.conversationService.postMessageToCurrentConversation(message: firebaseMessage)
							}(thumbURLOnFirebase, nil, urlOnFirebase)
						}
					}
				}
			} else if let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), text.count > 0 {
				if isEdit {
					if isExperience {
						guard let experienceKey = experienceKeyForEdit, let profileID = Auth.auth().currentUser?.uid else {
							self.presentErrorAlert(withMessage: "Error editing message") {
								self.navigationController?.dismiss(animated: true, completion: nil)
							}
							return
						}
						self.conversationService.editExperience(profileID: profileID, experienceKey: experienceKey, message: text, imageURLString: imageURLForEdit)
					} else {
						guard let conversationKey = conversationKeyForEdit, let messageKey = conversationMessageKeyForEdit else {
							self.presentErrorAlert(withMessage: "Error editing message") {
								self.navigationController?.dismiss(animated: true, completion: nil)
							}
							return
						}
						self.conversationService.editMessage(conversationKey: conversationKey, message: text, messageKey: messageKey, imageURLString: imageURLForEdit)
					}
					self.navigationController?.dismiss(animated: true, completion: nil)
				} else {
					let firebaseMessage = FirebaseConversation.Message(profileID: Auth.auth().currentUser!.uid, sent: self.dateFormatter.string(from: Date()), message: self.text, isHTML: false, imageURL: nil, imageHeight: nil, imageWidth: nil, eventID: nil, eventTitle: nil, videoURL: nil, videoDuration: nil, voteTotal: nil)
					if isExperience {
						self.conversationService.postExperience(experience: firebaseMessage)
					} else {
						self.conversationService.postMessageToCurrentConversation(message: firebaseMessage)
					}
					spinnerView.isHidden = true
					self.navigationController?.dismiss(animated: true, completion: nil)
				}
			} else {
				presentErrorAlert(withMessage: "Can't post an empty message", completion: nil)
				isSaving = false
				spinnerView.isHidden = true
			}
		}
	}
	
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
		
		navigationItem.title = "Share an Experience"
		
		if self.navigationController?.viewControllers == [self] {
			let closeItem = UIBarButtonItem(image: UIImage(named: "icon_close"), style: .plain, target: self, action: #selector(onClose))
			closeItem.tintColor = PaletteColor.light1.uiColor
			self.navigationItem.leftBarButtonItem = closeItem
		} else {
			let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: .plain, target: self, action: #selector(onBack))
			backItem.tintColor = PaletteColor.light1.uiColor
			self.navigationItem.leftBarButtonItem = backItem
		}

		let postItem = UIBarButtonItem(title: "Post", style: .plain, target: self, action: #selector(savePost))
		postItem.tintColor = PaletteColor.light1.uiColor
		self.navigationItem.rightBarButtonItem = postItem
				
		textViewOutlineView.layer.borderColor = PaletteColor.dark3.cgColor
		textViewOutlineView.layer.borderWidth = 1.0
		textViewOutlineView.layer.cornerRadius = 8
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		textView.text = text
		
		registerForNotifications()
		configureForImageOrVideo()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		stopPlayer(self)
		
		unregisterObservers()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		self.playerLayer?.frame = videoView.bounds
	}

	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		Injector.root!.inject(into: inject)
		stopGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(stopPlayer))
	}
	
	private func inject(conversationService: ConversationService, dateFormatter: FirebaseDateFormatter) {
		self.conversationService = conversationService
		self.dateFormatter = dateFormatter.value
	}
	
	// MARK: Properties
	
	var image: UIImage?
	var videoURL: URL?
	var videoDuration: Double?
	var text: String?
	var isExperience = false
		
	// MARK: Properties (Private)
	
	private var isEdit = false
	private var conversationKeyForEdit: String?
	private var conversationMessageKeyForEdit: String?
	private var imageURLForEdit: String?
	private var videoURLForEdit: String?
	private var experienceKeyForEdit: String?
	
	@IBOutlet private weak var spinnerView: UIView!
	@IBOutlet private weak var textView: UITextView!
	@IBOutlet private weak var textViewOutlineView: UIView!

	@IBOutlet private weak var textViewBottomConstraint: NSLayoutConstraint!
	private var textViewBottomConstraintDefault: CGFloat = 10.0
	
	@IBOutlet private weak var videoView: UIView!
	@IBOutlet private weak var playButton: UIButton!
	
	private var player: AVPlayer?
	private var playerLayer: CALayer?
	private var stopGestureRecognizer: UITapGestureRecognizer?
	
	@IBOutlet private weak var messageImageView: UIImageView!
	
	private var observerTokens = [Any]()
	private var isSaving = false
	
	private var conversationService: ConversationService!
	private var dateFormatter: DateFormatter!
}
