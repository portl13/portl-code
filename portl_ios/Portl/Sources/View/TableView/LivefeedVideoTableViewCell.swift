//
//  LivefeedVideoTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 1/23/20.
//  Copyright © 2020 Portl. All rights reserved.
//

import CSkyUtil
import RxSwift
import SDWebImage

class LivefeedVideoTableViewCell: UITableViewCell, Named, OverflowMenuProvidingCell, VideoPlayerProvidingCell, VoteButtonsProvidingCell {
	
	// MARK: VideoButtonProvidingCell
	
	private func immediateUpdateForVote(isUp: Bool) {
		var delta: Int64 = 0
		if let vote = currentVote {
			if vote != isUp {
				delta = isUp ? 2 : -2
				configure(forVote: isUp)
			} else {
				delta = isUp ? -1 : 1
				configure(forVote: nil)
			}
		} else {
			delta = isUp ? 1 : -1
			configure(forVote: isUp)
		}
		setVoteTotal((voteTotal ?? 0) + delta)
	}

	@IBAction func upvoteButtonPressed(_ sender: Any) {
		immediateUpdateForVote(isUp: true)
		voteDelegate?.voteButtonsProvidingCellSelectedUpvote(self)
	}
	
	@IBAction func downvoteButtonPressed(_ sender: Any) {
		immediateUpdateForVote(isUp: false)
		voteDelegate?.voteButtonsProvidingCellSelectedDownvote(self)
	}
	
	// MARK: Configure
	
	func configure(forVote vote: Bool?) {
		currentVote = vote
		let upImageName = vote == true ? "vote_up_selected" : "vote_up"
		let downImageName = vote == false ? "vote_down_selected" : "vote_down"
		upvoteButton.setImage(UIImage(named: upImageName)!, for: .normal)
		downvoteButton.setImage(UIImage(named: downImageName)!, for: .normal)
	}

	func configure(forPortlEvent portlEvent: PortlEvent?) {
		if let event = portlEvent {
			eventTitle = event.title
		}
	}
	
	func configure(forProfile profile: FirebaseProfile?, isExperience: Bool = false) {
		if let urlString = profile?.avatar {
			profileImageView.sd_setImage(with: URL(string: urlString), placeholderImage: nil, options: .refreshCached) {[weak self] (_, error, _, _) in
				guard error == nil || error!.localizedDescription.contains("2002") else {
					self?.profileImageView.image = UIService.defaultProfileImage
					self?.profileImageView.sd_imageIndicator?.stopAnimatingIndicator()
					return
				}
			}
		} else {
			profileImageView.sd_setImage(with: nil, placeholderImage: UIService.defaultProfileImage)
		}
		
		if let profileID = profile?.uid, let username = profile?.username {
			let isMe = profileID == Auth.auth().currentUser?.uid
			nameToUse = isMe ? "You" : username
			overflowMenuButton.isHidden = !isMe
			
			if isExperience {
				updateActionLabelForExperience()
			}
		}
	}
	
	func setVoteTotal(_ voteTotal: Int64?) {
		self.voteTotal = voteTotal
		if let voteTotal = voteTotal {
			voteTotalLabel.text = "\(voteTotal)"
		} else {
			voteTotalLabel.text = "Vote"
		}
	}
	
	func configure(forRepliesOverView repliesOverview: FirebaseConversation.Overview?, isExperience: Bool) {
		guard let overview = repliesOverview, overview.messageCount > 0 else {
			if isExperience {
				commentCountLabel.text = "Reply"
				commentCountLabel.isHidden = false
			} else {
				commentCountLabel.isHidden = true
			}
			return
		}
		commentCountLabel.isHidden = false
		let repliesString = "\(overview.messageCount) comment" + (overview.messageCount > 1 ? "s" : "")
		commentCountLabel.text = repliesString
	}
	
	func setShowHR(_ show: Bool) {
		horizontalRule.isHidden = !show
	}
	
	func setActionDateString(_ actionDateString: String) {
		actionDateLabel.attributedText = NSAttributedString(string: actionDateString, textStyle: .body)
	}
	
	func setMessage(message: String?) {
		if let message = message {
			if let constraint = messageHeightConstraint {
				messageLabel.removeConstraint(constraint)
				messageHeightConstraint = nil
			}
			messageTopConstraint.constant = 8.0
			messageLabel.attributedText = NSAttributedString(string: message, textStyle: .h3)
		} else {
			messageTopConstraint.constant = 0.0
			//messageHeightConstraint = messageLabel.heightAnchor.constraint(equalToConstant: 0)
			//messageLabel.addConstraint(messageHeightConstraint!)
		}
		layoutIfNeeded()
	}
	
	// MARK: OverflowMenuProvidingCell
	
	@IBAction func overflowMenuButtonPressed(_ sender: Any) {
		overflowMenuDelegate?.overflowMenuProvidingCellRequestedMenu(self)
	}

	// MARK: Private
	
	@IBAction private func onSelectProfile(_ sender: Any) {
		delegate?.livefeedTableViewCellSelectedProfile(self)
	}
			
	private func setProfileComponentsHidden(_ hidden: Bool) {
		actionLabel.isHidden = hidden
	}
	
	func updateActionLabel() {
		guard let nameToUse = nameToUse, let eventTitle = eventTitle else {
			return
		}
				
		actionLabel.attributedText = UIService.getActionStringForLivefeed(withProfileName: nameToUse, isSelf: false, eventTitle: eventTitle, andLivefeedActionFormat: .communityVideo)
		actionLabel.isHidden = false
	}

	func updateActionLabelForExperience() {
		guard let nameToUse = nameToUse else {
			return
		}
		
		actionLabel.attributedText = UIService.getActionStringForLivefeed(withProfileName: nameToUse, isSelf: false, eventTitle: nil, andLivefeedActionFormat: .experienceVideo)
		actionLabel.isHidden = false
	}

	@IBAction private func handleTapOnLabel(_ recognizer: UITapGestureRecognizer) {
		guard let text = actionLabel.attributedText?.string else {
			return
		}
		
		if let eventTitle  = eventTitle {
			if let range = text.range(of: eventTitle), recognizer.didTapAttributedTextInLabel(label: actionLabel, inRange: NSRange(range, in: text)) {
				delegate?.livefeedTableViewCellSelectedEvent(self)
			}
		}
		
		if let nameToUse = nameToUse {
			if let range = text.range(of: nameToUse), recognizer.didTapAttributedTextInLabel(label: actionLabel, inRange: NSRange(range, in: text)) {
				delegate?.livefeedTableViewCellSelectedProfile(self)
			}
		}
	}

	@IBAction func handleVideoButtonTap(_ sender: UIButton) {
		videoDelegate?.videoPlayerProvidingCellTapped(self)
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		actionLabel.isUserInteractionEnabled = true
		actionLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnLabel(_:))))
		
		profileImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		thumbnailView.sd_imageIndicator = SDWebImageActivityIndicator.white
		
		containerView.clipsToBounds = true
		containerView.layer.cornerRadius = 8.0

		resetCell()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		resetCell()
	}
	
	func resetCell() {
		setProfileComponentsHidden(true)
		profileImageView.sd_cancelCurrentImageLoad()
		profileImageView.image = nil
		thumbnailView.sd_cancelCurrentImageLoad()
		thumbnailView.image = nil
		
		portlEventDisposable?.dispose()
		messageLabel.text = nil
		commentCountLabel.isHidden = true
		
		profileImageView.sd_imageIndicator?.startAnimatingIndicator()
		thumbnailView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	// MARK: Properties
	
	weak var delegate: LivefeedTableViewCellDelegate?
	weak var overflowMenuDelegate: OverflowMenuProvidingCellDelegate?
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var videoContainerView: UIView!
	@IBOutlet weak var thumbnailView: UIImageView!
	@IBOutlet weak var showVideoButton: UIButton!

	weak var videoDelegate: VideoPlayerProvidingCellDelegate?

	// voting
	@IBOutlet weak var voteTotalLabel: UILabel!
	@IBOutlet weak var upvoteButton: UIButton!
	@IBOutlet weak var downvoteButton: UIButton!
	weak var voteDelegate: VoteButtonsProvidingCellDelegate?
	private var currentVote: Bool? = nil
	private var voteTotal: Int64? = nil

	// MARK: Properties (Private)
	
	private var conversationMessageDisposable: Disposable?
	private var portlEventDisposable: Disposable?
	private var messageHeightConstraint: NSLayoutConstraint?
	
	private var eventTitle: String? {
		didSet {
			updateActionLabel()
		}
	}
	
	private var nameToUse: String? {
		didSet {
			updateActionLabel()
		}
	}
	
	@IBOutlet private weak var profileImageView: UIImageView!
	@IBOutlet private weak var actionLabel: UILabel!
	@IBOutlet private weak var actionDateLabel: UILabel!
	@IBOutlet private weak var messageLabel: UILabel!
	@IBOutlet private weak var messageTopConstraint: NSLayoutConstraint!
	@IBOutlet private weak var horizontalRule: UIView!
	@IBOutlet private weak var overflowMenuButton: UIButton!
	@IBOutlet private weak var commentCountLabel: UILabel!
		
	// MARK: Properties (Named)
	
	static let name = "LivefeedVideoTableViewCell"

}
