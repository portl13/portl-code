//
//  LivefeedCommunityMessageTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 3/29/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import RxSwift
import SDWebImage

class LivefeedCommunityMessageTableViewCell: UITableViewCell, Named, OverflowMenuProvidingCell, VoteButtonsProvidingCell {
	
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
	
	func setShowHR(_ show: Bool) {
		horizontalRule.isHidden = !show
	}
	
	func setActionDateString(_ actionDateString: String) {
		actionDateLabel.attributedText = NSAttributedString(string: actionDateString, textStyle: .body)
	}
	
	func configure(forProfile profile: FirebaseProfile?, hasNoEvent: Bool = false, isReply: Bool = false) {
		if let urlString = profile?.avatar {
			profileImageView.sd_setImage(with: URL(string: urlString), placeholderImage: nil, options: .refreshCached) {[weak self] (_, error, _, _) in
				self?.profileImageView.isHidden = false
				guard error == nil || error!.localizedDescription.contains("2002") else {
					self?.profileImageView.sd_setImage(with: nil, placeholderImage: UIService.defaultProfileImage)
					return
				}
			}
		} else {
			profileImageView.sd_setImage(with: nil, placeholderImage: UIService.defaultProfileImage)
			profileImageView.isHidden = false
		}
		
		if let profileID = profile?.uid, let username = profile?.username {
			let isMe = profileID == Auth.auth().currentUser?.uid
			nameToUse = isMe ? "You" : username
			overflowMenuButton.isHidden = !isMe
			
			if hasNoEvent {
				updateActionLabelForExperience(isReply: isReply)
			}
		}
	}
	
	func setMessage(message: String?) {
		if let message = message {
			messageLabel.attributedText = NSAttributedString(string: message, textStyle: .h3)
			messageLabel.heightAnchor.constraint(equalToConstant: determineHeightForComment(comment: message))
		} else {
			messageLabel.attributedText = nil
			messageLabel.heightAnchor.constraint(equalToConstant: 0.0)
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
	
	func configure(forRepliesOverView repliesOverview: FirebaseConversation.Overview?, isReply: Bool) {
		guard let overview = repliesOverview, overview.messageCount > 0 else {
			if !isReply {
				commentCountLabel.text = "Reply"
				commentCountLabel.isHidden = false
			} else {
				commentCountLabel.isHidden = true
			}
			return
		}
		let repliesString = "\(overview.messageCount) comment" + (overview.messageCount > 1 ? "s" : "")
		commentCountLabel.text = repliesString
		commentCountLabel.isHidden = false
	}
	
	// MARK: OverflowMenuProvidingCell
	
	@IBAction func overflowMenuButtonPressed(_ sender: Any) {
		overflowMenuDelegate?.overflowMenuProvidingCellRequestedMenu(self)
	}

	// MARK: Private
	
	func updateActionLabelForExperience(isReply: Bool = false) {
		guard let nameToUse = nameToUse else {
			return
		}
		
		actionLabel.attributedText = UIService.getActionStringForLivefeed(withProfileName: nameToUse, isSelf: false, eventTitle: nil, andLivefeedActionFormat: isReply ? .experienceReply : .experience)
		actionLabel.isHidden = false
	}
	
	func updateActionLabel(_ format: LivefeedActionFormat = .community) {
		guard let nameToUse = nameToUse, let eventTitle = eventTitle else {
			return
		}
		
		actionLabel.attributedText = UIService.getActionStringForLivefeed(withProfileName: nameToUse, isSelf: false, eventTitle: eventTitle, andLivefeedActionFormat: format)
		actionLabel.isHidden = false
	}
	
	@IBAction private func onSelectProfile(_ sender: Any) {
		delegate?.livefeedTableViewCellSelectedProfile(self)
	}
	
	private func setProfileComponentsHidden(_ hidden: Bool) {
		profileImageView.isHidden = hidden
		actionLabel.isHidden = hidden
	}

	private func determineHeightForComment(comment: String) -> CGFloat {
		let constraintRect = CGSize(width: self.bounds.width - 16.0 - 16.0, height: .greatestFiniteMagnitude)
		return comment.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0)], context: nil).height
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

	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		actionLabel.isUserInteractionEnabled = true
		actionLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnLabel(_:))))
		
		profileImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
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
		portlEventDisposable?.dispose()
		messageLabel.text = nil
		profileImageView.sd_imageIndicator?.startAnimatingIndicator()
		commentCountLabel.isHidden = true
	}
	
	// MARK: Properties
	
	var isReply = false
	weak var delegate: LivefeedTableViewCellDelegate?
	weak var overflowMenuDelegate: OverflowMenuProvidingCellDelegate?

	// voting
	@IBOutlet weak var voteTotalLabel: UILabel!
	@IBOutlet weak var upvoteButton: UIButton!
	@IBOutlet weak var downvoteButton: UIButton!
	weak var voteDelegate: VoteButtonsProvidingCellDelegate?
	private var currentVote: Bool? = nil
	private var voteTotal: Int64? = nil

	// MARK: Properties (Private)
	
	private var portlEventDisposable: Disposable?
	private var eventTitle: String? {
		didSet {
			updateActionLabel(isReply ? .communityReply : .community)
		}
	}
	
	private var nameToUse: String? {
		didSet {
			updateActionLabel(isReply ? .communityReply : .community)
		}
	}
	
	@IBOutlet private weak var profileImageView: UIImageView!
	@IBOutlet private weak var actionLabel: UILabel!
	@IBOutlet private weak var actionDateLabel: UILabel!
	@IBOutlet private weak var messageLabel: UILabel!
	@IBOutlet private weak var horizontalRule: UIView!
	@IBOutlet private weak var overflowMenuButton: UIButton!
	@IBOutlet private weak var commentCountLabel: UILabel!
		
	// MARK: Properties (Named)
	
	static let name = "LivefeedCommunityMessageTableViewCell"

}
