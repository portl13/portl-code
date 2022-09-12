//
//  CommunityMessageTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 3/25/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CSkyUtil
import SDWebImage

protocol CommunityMessageTableViewCellDelgate: class {
	func goToProfile(forProfileID profileID: String)
}

class CommunityMessageTableViewCell: UITableViewCell, Named, OverflowMenuProvidingCell, VoteButtonsProvidingCell {
	
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
	
	func setVoteTotal(_ voteTotal: Int64?) {
		self.voteTotal = voteTotal
		if let voteTotal = voteTotal {
			voteTotalLabel.text = "\(voteTotal)"
		} else {
			voteTotalLabel.text = "Vote"
		}
	}

	func configure(withConversationMessage message: FirebaseConversation.Message, showHr: Bool, shouldHighlight: Bool) {
		let dateString = toFormatter.string(from: fromFormatter.date(from: message.sent)!)
		dateLabel.attributedText = NSAttributedString(string: dateString, textStyle: .small)
		
		if let text = message.message {
			messageLabel.attributedText = NSAttributedString(string: text, textStyle: .h3)
		}
		
		let isMe = message.profileID == Auth.auth().currentUser?.uid
		self.overflowMenuButton.isHidden = !isMe
		
		if isMe {
			nameToUse = "You"
			self.actionLabel.attributedText = self.getActionString(forMessage: message, andUsername: "You")
		}
		
		horizontalRule.isHidden = !showHr
		
		backgroundColor = shouldHighlight ? PaletteColor.interactive2HalfAlpha.uiColor : PaletteColor.dark1.uiColor
		
		setVoteTotal(message.voteTotal)
		
		layoutIfNeeded()
	}
	
	func configure(forProfile profile: Profile, message: FirebaseConversation.Message) {
		profileID = profile.uid
		
		if let urlString = profile.avatar, let url = URL(string: urlString) {
			self.profileImageView.sd_setImage(with: url, completed: { (_, error, _, _) in
				guard error == nil || error!.localizedDescription.contains("2002") else {
					self.profileImageView.sd_setImage(with: nil, placeholderImage: UIService.defaultProfileImage)
					return
				}
			})
		} else {
			self.profileImageView.sd_setImage(with: nil, placeholderImage: UIService.defaultProfileImage)
		}

		let isMe = profileID == Auth.auth().currentUser?.uid
		self.overflowMenuButton.isHidden = !isMe
		
		if !isMe {
			nameToUse = profile.username
			self.actionLabel.attributedText = self.getActionString(forMessage: message, andUsername: profile.username)
		}
		
		setVoteTotal(message.voteTotal)
		
		layoutIfNeeded()
	}
	
	func configure(forRepliesOverView repliesOverview: FirebaseConversation.Overview?) {
		guard let overview = repliesOverview, overview.messageCount > 0 else {
			commentCountLabel.isHidden = true
			return
		}
		commentCountLabel.isHidden = false
		let repliesString = "\(overview.messageCount) comment" + (overview.messageCount > 1 ? "s" : "")
		commentCountLabel.text = repliesString
	}
	
	func configure(forVote vote: Bool?) {
		currentVote = vote
		let upImageName = vote == true ? "vote_up_selected" : "vote_up"
		let downImageName = vote == false ? "vote_down_selected" : "vote_down"
		upvoteButton.setImage(UIImage(named: upImageName)!, for: .normal)
		downvoteButton.setImage(UIImage(named: downImageName)!, for: .normal)
	}
	
	// MARK: OverflowMenuProvidingCell
	
	@IBAction func overflowMenuButtonPressed(_ sender: Any) {
		overflowMenuDelegate?.overflowMenuProvidingCellRequestedMenu(self)
	}

	// MARK: Private
	
	private func getActionString(forMessage message: FirebaseConversation.Message, andUsername username: String) -> NSAttributedString {
		let communityFormat: PostActionFormat
		if message.videoURL != nil {
			communityFormat = PostActionFormat.video
		} else if message.imageURL != nil {
			communityFormat = PostActionFormat.photo
		} else {
			communityFormat = PostActionFormat.comment
		}
		
		return UIService.getActionStringForPost(withProfileName: username, andCommunityActionFormat: communityFormat)
	}
	
	@IBAction private func goToProfile(_ sender: Any) {
		if let profileID = profileID {
			delegate?.goToProfile(forProfileID: profileID)
		}
	}
	
	@IBAction private func handleTapOnLabel(_ recognizer: UITapGestureRecognizer) {
		guard let text = actionLabel.attributedText?.string else {
			return
		}
				
		if let nameToUse = nameToUse {
			if let range = text.range(of: nameToUse), recognizer.didTapAttributedTextInLabel(label: messageLabel, inRange: NSRange(range, in: text)) {
				goToProfile(self)
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
		profileImageView.sd_cancelCurrentImageLoad()
		profileImageView.image = nil
		profileImageView.sd_imageIndicator?.startAnimatingIndicator()
		actionLabel.attributedText = nil
		dateLabel.attributedText = nil
		messageLabel.attributedText = nil
		commentCountLabel.isHidden = true
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		Injector.root!.inject(into: inject)
	}
	
	private func inject(fromFormatter: FirebaseDateFormatter, toFormatter: DateFormatterQualifier) {
		self.fromFormatter = fromFormatter.value
		self.toFormatter = toFormatter.value
	}
	
	// MARK: Properties
	
	@IBOutlet weak var messageLabel: UILabel!
	@IBOutlet weak var commentCountLabel: UILabel!
	
	weak var delegate: CommunityMessageTableViewCellDelgate?
	weak var overflowMenuDelegate: OverflowMenuProvidingCellDelegate?

	// voting
	@IBOutlet weak var voteTotalLabel: UILabel!
	@IBOutlet weak var upvoteButton: UIButton!
	@IBOutlet weak var downvoteButton: UIButton!
	weak var voteDelegate: VoteButtonsProvidingCellDelegate?
	private var currentVote: Bool? = nil
	private var voteTotal: Int64? = nil

	// MARK: Properties (Private)
	
	@IBOutlet private weak var profileImageView: UIImageView!
	@IBOutlet private weak var actionLabel: UILabel!
	@IBOutlet private weak var dateLabel: UILabel!
	@IBOutlet private weak var horizontalRule: UIView!
	@IBOutlet private weak var overflowMenuButton: UIButton!
	
	private var fromFormatter: DateFormatter!
	private var toFormatter: DateFormatter!
	private var profileService: UserProfileService!
	private var profileID: String?
	private var nameToUse: String?
	
	// MARK: Properties (Named)
	
	class var name: String {
		return "CommunityMessageTableViewCell"
	}
}
