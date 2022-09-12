//
//  CommunityViewController.swift
//  Portl
//
//  Created by Jeff Creed on 3/25/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import RxSwift

class CommunityViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CommunityMessageTableViewCellDelgate, CommunityMessageImageTableViewCellDelegate, OverflowMenuProvidingCellDelegate, VideoPlayerProvidingCellDelegate, VoteButtonsProvidingCellDelegate {
	
	// MARK: VoteButtonsProvidingCellDelegate
	
	func voteButtonsProvidingCellSelectedUpvote(_ voteButtonsProvidingCell: VoteButtonsProvidingCell) {
		guard !(Auth.auth().currentUser?.isAnonymous ?? true) else {
			self.presentErrorAlert(withMessage: "You must be signed in to participate.", completion: nil)
			return
		}

		let idx = tableView.indexPath(for: voteButtonsProvidingCell as! UITableViewCell)!.row
		let message = messages![idx]
		let upvoteStatus = profileService.getVoteStatusForConversationMessage(conversationKey: conversationID!, messageKey: message.0)
		let newVoteStatus = upvoteStatus == true ? nil : true
		
		profileService.voteOnConversationMessage(withConversationKey: conversationID!, andMessageKey: message.0, vote: newVoteStatus)
	}
	
	func voteButtonsProvidingCellSelectedDownvote(_ voteButtonsProvidingCell: VoteButtonsProvidingCell) {
		guard !(Auth.auth().currentUser?.isAnonymous ?? true) else {
			self.presentErrorAlert(withMessage: "You must be signed in to participate.", completion: nil)
			return
		}

		let idx = tableView.indexPath(for: voteButtonsProvidingCell as! UITableViewCell)!.row
		let message = messages![idx]
		let upvoteStatus = profileService.getVoteStatusForConversationMessage(conversationKey: conversationID!, messageKey: message.0)
		let newVoteStatus = upvoteStatus == false ? nil : false
		
		profileService.voteOnConversationMessage(withConversationKey: conversationID!, andMessageKey: message.0, vote: newVoteStatus)
	}
	
	// MARK: VideoPlayerProvidingCellDelegate
	
	func videoPlayerProvidingCellTapped(_ cell: VideoPlayerProvidingCell) {
		if let indexPath = tableView.indexPath(for: cell as! UITableViewCell) {
			let message = messages![indexPath.row]
			let messageKey = message.0
			playbackController.present(contentForMessageKey: messageKey, from: self)
		}
	}
	
	// MARK: CommunityMessageImageTableViewCellDelegate
	
	func communityMessageImageTableViewCell(_ communityMessageImageTableViewCell: CommunityMessageImageTableViewCell, selectedImage image: UIImage) {
		guard let controller = UIStoryboard(name: "common", bundle: nil).instantiateViewController(withIdentifier: "ImageFullScreenViewController") as? ImageFullScreenViewController else {
			return
		}
		controller.image = image
		navigationController?.show(controller, sender: self)
	}
	
	// MARK: OverflowMenuProvidingCellDelegate
	
	func overflowMenuProvidingCellRequestedMenu(_ overflowMenuProvingCell: OverflowMenuProvidingCell) {
		let idx = tableView.indexPath(for: overflowMenuProvingCell as! UITableViewCell)!.row
		let message = messages![idx]
		let alert = UIAlertController(title: nil, message: "Manage Post/Comment", preferredStyle: .actionSheet)
		
		alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: {[unowned self] (_) in
			let nav = UIStoryboard(name: "message", bundle: nil).instantiateViewController(withIdentifier: "BuildTextMessageScene") as! UINavigationController
			let controller = nav.viewControllers[0] as! CreateMessageViewController
			controller.configureForEdit(message: message.1.message, imageURL: message.1.imageURL, videoURL: message.1.videoURL, conversationKey: self.conversationID!, messageKey: message.0)
			
			nav.modalPresentationStyle = .overFullScreen
			self.tabBarController?.present(nav, animated: true, completion: nil)
		}))
		
		alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {[unowned self] (_) in
			self.conversationService.deleteMessage(conversationKey: self.conversationID!, messageKey: message.0, completion: {
				//self.messages?.remove(at: idx)
			})
		}))
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		present(alert, animated: true, completion: nil)
	}
	
	// MARK: CommunityMessageTableViewCellDelegate
	
	func goToProfile(forProfileID profileID: String) {
		profileIDForSegue = profileID
		self.performSegue(withIdentifier: "profileSegue", sender: self)
	}
	
	// MARK: UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return messages?.count ?? 0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let message = messages![indexPath.row]
		
		let cell: CommunityMessageTableViewCell
		
		if message.1.videoURL != nil {
			let videoCell = tableView.dequeue(CommunityMessageVideoTableViewCell.self, for: indexPath) as CommunityMessageVideoTableViewCell
			if let thumbURLString = message.1.imageURL {
				videoCell.thumbnailView.sd_setImage(with: URL(string: thumbURLString)) { (_, error, _, _) in
					guard error == nil else {
						videoCell.thumbnailView.image = nil
						return
					}
				}
			} else {
				videoCell.thumbnailView.sd_cancelCurrentImageLoad()
			}
			
			videoCell.videoDelegate = self
			cell = videoCell
		} else if message.1.imageURL != nil {
			cell = tableView.dequeue(CommunityMessageImageTableViewCell.self, for: indexPath)
			(cell as! CommunityMessageImageTableViewCell).imageDelegate = self
		} else {
			cell = tableView.dequeue(CommunityMessageTableViewCell.self, for: indexPath)
		}
				
		let shouldHighlight = message.0 == messageKeyToHighlight
		
		cell.configure(withConversationMessage: messages![indexPath.row].1, showHr: indexPath.row < messages!.count - 1, shouldHighlight: shouldHighlight)
		
		if let overview = messageIDToOverview[message.0] {
			cell.configure(forRepliesOverView: overview)
		} else if threadIDs != nil {
			conversationService.conversationOverviews[ConversationService.getRepliesConversationID(fromMessageKey: message.0)]?
				.observeOn(MainScheduler.instance)
				.subscribe(onNext: {[weak self] firebaseConversationOverview in
					if firebaseConversationOverview != nil {
						self?.messageIDToOverview[message.0] = firebaseConversationOverview
						self?.overviewLoaded(messageKey: message.0)
					}
				}).disposed(by: disposeBag)
		}
		
		let profileID = message.1.profileID
		
		if let profile = idToLoadedProfile[profileID] {
			cell.configure(forProfile: profile, message: message.1)
		} else {
			firebaseService.getProfile(withProfileID: profileID, forConversationKey: conversationID!, completion: {[weak self] (error, profile) in
					if profile != nil {
						self?.idToLoadedProfile[profileID] = profile
						self?.profileLoaded(profileID: profileID)
					}
				}, withContext: nil)
		}
		
		cell.overflowMenuDelegate = self
		cell.delegate = self
		
		cell.configure(forVote: profileService.getVoteStatusForConversationMessage(conversationKey: conversationID!, messageKey: message.0))
		cell.voteDelegate = self
		
		return cell
	}
	
	// MARK: UITableViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
		let message = messages![indexPath.row]
		messageForSegue = message.1
		messageKeyForSegue = message.0
		
		performSegue(withIdentifier: communityPostDetailSegueIdentifier, sender: self)
	}
		
	// MARK: Private
	
	private func messageLoaded(messageKey: String) {
		reloadVisibleRows { (message) -> Bool in
			return message.0 == messageKey
		}
	}
	
	private func profileLoaded(profileID: String) {
		reloadVisibleRows { (message) -> Bool in
			return message.1.profileID == profileID
		}
	}
	
	private func overviewLoaded(messageKey: String) {
		reloadVisibleRows { (message) -> Bool in
			return message.0 == messageKey
		}
	}
	
	private func reloadVisibleRows(usingPredicate predicate:((String, FirebaseConversation.Message)) -> Bool) {
		var toReload = [IndexPath]()
		if let indexPaths = tableView.indexPathsForVisibleRows {
			for indexPath in indexPaths {
				if let message = messages?[indexPath.row] {
					if predicate(message) {
						toReload.append(indexPath)
					}
				}
			}
			
			UIView.performWithoutAnimation {
				tableView.reloadRows(at: toReload, with: .none)
			}
		}
	}
	
	private func createDisposables() {
		spinner.startAnimating()
		if let id = conversationID {
			conversationService.clearConversation()
			
			conversationDisposable = conversationService.conversation.subscribe(onNext: {[weak self] firebaseConversation in
				self?.firebaseConversation = firebaseConversation
			})
			
			conversationService.loadConversationForID(forID: id)
			conversationService.clearConversationOverviews()
		}
	}
	
	private func disposeDisposables() {
		conversationDisposable?.dispose()
	}
		
	@IBAction private func onBack(_ sender: Any) {
		self.navigationController?.popViewController(animated: true)
	}
	
	private func authUserIsGoing() -> Bool {
		return (try? profileService.authenticatedProfile.value()?.events?.going?[eventID!]?.goingStatus() == FirebaseProfile.EventGoingStatus.going) ?? false
	}
	
	private func reloadTableView() {
		tableView.reloadData()
		tableView.layoutIfNeeded()
		tableView.setContentOffset(.zero, animated: false)
	}
	
	@IBAction private func onPostButtonPress(_ sender: Any) {
		UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: {
			if let imageView = self.postButton.imageView {
				imageView.transform = self.messageYConstraint.constant == 0 ? CGAffineTransform(rotationAngle: .pi / 4) : CGAffineTransform.identity
			}
			self.messageButton.isHidden = false
			self.messageButton.layer.shadowOpacity = self.messageYConstraint.constant == 0 ? 0.8 : 0
			self.messageYConstraint.constant = self.messageYConstraint.constant == 0 ? -48 : 0
			self.cameraButton.isHidden = false
			self.cameraButton.layer.shadowOpacity = self.cameraYConstraint.constant == 0 ? 0.8 : 0
			self.cameraYConstraint.constant = self.cameraYConstraint.constant == 0 ? -96 : 0
			self.view.layoutIfNeeded()
		}, completion: { complete in
			self.messageButton.isHidden = self.messageYConstraint.constant == 0
			self.cameraButton.isHidden = self.cameraYConstraint.constant == 0
		})
	}
	
	@IBAction private func startPost(_ sender: Any) {
		onPostButtonPress(self)
		
		guard !(Auth.auth().currentUser?.isAnonymous ?? true) else {
			self.presentErrorAlert(withMessage: "You must be signed in to participate.", completion: nil)
			return
		}
		
		if sender as? UIButton == cameraButton {
			if let controller = UIStoryboard(name: "message", bundle: nil).instantiateViewController(withIdentifier: "BuildPhotoMessageScene") as? UINavigationController {
				controller.modalPresentationStyle = .overFullScreen
				self.tabBarController?.present(controller, animated: true, completion: nil)
			}
		} else if sender as? UIButton == messageButton {
			if let controller = UIStoryboard(name: "message", bundle: nil).instantiateViewController(withIdentifier: "BuildTextMessageScene") as? UINavigationController {
				controller.modalPresentationStyle = .overFullScreen
				self.tabBarController?.present(controller, animated: true, completion: nil)
			}
		}
	}

	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "profileSegue" {
			let controller = segue.destination as! ProfileViewController
			controller.profileID = profileIDForSegue
		} else if segue.identifier == communityPostDetailSegueIdentifier {
			let controller = segue.destination as! CommunityRepliesViewController
			controller.originalMessageKey = messageKeyForSegue
			controller.eventID = eventID!
		} else {
			super.prepare(for: segue, sender: sender)
		}
	}
	
	// MARK: Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		navigationItem.title = "Community"
		
		let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: .plain, target: self, action: #selector(onBack))
		backItem.tintColor = PaletteColor.light1.uiColor
		self.navigationItem.leftBarButtonItem = backItem
				
		cameraButton.layer.borderColor = PaletteColor.light1.cgColor
		cameraButton.layer.borderWidth = 1.0
		cameraButton.layer.cornerRadius = 8.0
		
		cameraButton.layer.shadowColor = PaletteColor.dark1.cgColor
		cameraButton.layer.shadowOpacity = 0
		cameraButton.layer.shadowRadius = 8.0
		cameraButton.layer.shadowOffset = CGSize(width:12.0, height:12.0)
		
		messageButton.layer.borderColor = PaletteColor.light1.cgColor
		messageButton.layer.borderWidth = 1.0
		messageButton.layer.cornerRadius = 8.0
		
		messageButton.layer.shadowColor = PaletteColor.dark1.cgColor
		messageButton.layer.shadowOpacity = 0
		messageButton.layer.shadowRadius = 8.0
		messageButton.layer.shadowOffset = CGSize(width:12.0, height:12.0)

		postButton.layer.cornerRadius = 8.0
		postButton.layer.shadowColor = PaletteColor.dark1.cgColor
		postButton.layer.shadowOpacity = 0.8
		postButton.layer.shadowRadius = 8.0
		postButton.layer.shadowOffset = CGSize(width:12.0, height:12.0)

		postButton.imageView?.clipsToBounds = false
		postButton.imageView?.contentMode = .center
		
		tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 72.0, right: 0.0)

		tableView.registerNib(CommunityMessageTableViewCell.self)
		tableView.registerNib(CommunityMessageImageTableViewCell.self)
		tableView.registerNib(CommunityMessageVideoTableViewCell.self)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		createDisposables()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if let messageKey = messageKeyToHighlight, let index = messages?.firstIndex(where: { return $0.0 == messageKey }) {
			self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		messageKeyToHighlight = nil
		disposeDisposables()
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		Injector.root!.inject(into: inject)
	}
	
	private func inject(conversationService: ConversationService, profileService: UserProfileService, firebaseFormatter: FirebaseDateFormatter, firebaseService: FirebaseDataProviding) {
		self.conversationService = conversationService
		self.profileService = profileService
		self.firebaseFormatter = firebaseFormatter.value
		self.firebaseService = firebaseService
		self.playbackController = PlaybackController()
	}
	
	// MARK: Properties
	
	var eventID: String? {
		didSet {
			if let id = eventID {
				conversationID = ConversationService.getCommunityConversationID(fromEventID: id)
			}
		}
	}
	
	var messageKeyToHighlight: String?
	
	var eventDate: Date?
	
	private var conversationID: String?
	private var profileIDForSegue: String?
	private var messageForSegue: FirebaseConversation.Message?
	private var messageKeyForSegue: String?
	
	// MARK: Properties (Private)
	
	private var playbackController: PlaybackController!
	private var wantsFullScreen = false
	
	@IBOutlet private weak var tableView: UITableView!
	@IBOutlet private weak var emptyView: UIView!
	@IBOutlet private weak var spinner: UIActivityIndicatorView!
	@IBOutlet weak var postButton: UIButton!
	@IBOutlet weak var cameraButton: UIButton!
	@IBOutlet weak var cameraYConstraint: NSLayoutConstraint!
	@IBOutlet weak var messageButton: UIButton!
	@IBOutlet weak var messageYConstraint: NSLayoutConstraint!

	private var conversationService: ConversationService!
	private var profileService: UserProfileService!
	private var firebaseFormatter: DateFormatter!
	private var firebaseService: FirebaseDataProviding!
	
	private var conversationDisposable: Disposable?
	private var firebaseConversation: FirebaseConversation? {
		didSet {
			messages = firebaseConversation?.messages?.sorted(by: { (message, otherMessage) -> Bool in
				let date1 = firebaseFormatter.date(from: message.value.sent)!
				let date2 = firebaseFormatter.date(from: otherMessage.value.sent)!
				return date1.compare(date2) == .orderedDescending
			})
		}
	}
	
	private var messages: [(String, FirebaseConversation.Message)]? {
		didSet {
			threadIDs = messages?.map { ConversationService.getRepliesConversationID(fromMessageKey: $0.0)} ?? []
			
			let videoMessages = messages?.filter { $0.1.videoURL != nil}
			for message in videoMessages ?? [] {
				if !playbackController.videos.keys.contains(message.0) {
					playbackController.videos[message.0] = Video(hlsUrl: URL(string: message.1.videoURL!)!, duration: message.1.videoDuration!)
				}
			}
			
			if isViewLoaded {
				UIView.performWithoutAnimation {
					tableView.reloadData()
				}
									
				spinner.stopAnimating()
				emptyView.isHidden = !initialLoad && messages?.count ?? 0 > 0
				
				if initialLoad, let messageKey = messageKeyToHighlight, let index = messages?.firstIndex(where: { return $0.0 == messageKey }) {
					self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
				}
				
				initialLoad = false
			}
		}
	}
	
	private var threadIDs: [String]? {
		didSet {
			if let IDs = threadIDs {
				conversationService.createOverviewObservables(forIDs: IDs)
				conversationService.loadConversationOverviews(forIDs: IDs)
			}
		}
	}
	private var idToLoadedProfile = [String: Profile]()
	private var messageIDToOverview = [String: FirebaseConversation.Overview]()
	private var initialLoad = true
	private var disposeBag = DisposeBag()
	
	private let communityPostDetailSegueIdentifier = "communityPostDetailSegue"
}
