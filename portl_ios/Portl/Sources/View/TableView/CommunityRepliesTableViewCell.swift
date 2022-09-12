//
//  CommunityRepliesTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 8/28/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import SDWebImage

// TODO: DELEGATE

protocol CommunityRepliesTableViewCellDelegate: class {
	func communityRepliesTableViewCellDidSelectProfile(_ communityRepliesTableViewCell: CommunityRepliesTableViewCell)
	func communityRepliesTableViewCellDidSelectDelete(_ communityRepliesTableViewCell: CommunityRepliesTableViewCell)
	func communityRepliesTableViewCell(_ communityRepliesTableViewCell: CommunityRepliesTableViewCell, didSelectImage image: UIImage)
}

class CommunityRepliesTableViewCell: UITableViewCell, Named, VideoPlayerProvidingCell, VoteButtonsProvidingCell {
	
	// MARK: VideoButtonProvidingCell
	
	@IBAction func upvoteButtonPressed(_ sender: Any) {
		voteDelegate?.voteButtonsProvidingCellSelectedUpvote(self)
	}
	
	@IBAction func downvoteButtonPressed(_ sender: Any) {
		voteDelegate?.voteButtonsProvidingCellSelectedDownvote(self)
	}

	// MARK: Configure
	
	func configure(forVote vote: Bool?) {
		let upImageName = vote == true ? "vote_up_selected" : "vote_up"
		let downImageName = vote == false ? "vote_down_selected" : "vote_down"
		upvoteButton.setImage(UIImage(named: upImageName)!, for: .normal)
		downvoteButton.setImage(UIImage(named: downImageName)!, for: .normal)
	}

	func configure(forProfile profile: Profile, isOriginal: Bool) {
		if let urlString = profile.avatar {
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
		
		let isMe = profile.uid == Auth.auth().currentUser?.uid
		nameToUse = isMe ? "You" : profile.username
		deleteButton.isHidden = !isMe //&& !isOriginal
	}
	
	func configure(forMessage message: ConversationMessage, usingDateFormatter dateFormatter: DateFormatter, shouldHighlight: Bool) {
		self.message = message
		if message.imageURL == nil && message.videoURL == nil {
			if let constraint = photoAspectConstraint {
				photoImageView.removeConstraint(constraint)
			}
			if let constraint = photoNoHeightConstraint {
				photoImageView.addConstraint(constraint)
			}
			photoBottomConstraint.constant = 0
		} else {
			if let constraint = photoNoHeightConstraint {
				photoImageView.removeConstraint(constraint)
			}
			if let constraint = photoAspectConstraint {
				photoImageView.addConstraint(constraint)
			}
			
			photoBottomConstraint.constant = CommunityRepliesTableViewCell.photoBottomConstraintDefault
			if message.imageURL != nil {
				photoImageView.sd_setImage(with: URL(string: message.imageURL!), completed: nil)
			}
			
			containerView.isHidden = message.videoURL == nil
			playVideoButton.isHidden = message.videoURL == nil
		}
		
		let actionDateString = dateFormatter.string(from: message.sent as Date)
		actionDateLabel.attributedText = NSAttributedString(string: actionDateString, textStyle: .small)
		
		contentView.backgroundColor = shouldHighlight ? PaletteColor.interactive2HalfAlpha.uiColor : PaletteColor.dark1.uiColor

		if let voteTotal = message.voteTotal {
			voteTotalLabel.text = "\(voteTotal)"
		} else {
			voteTotalLabel.text = "Vote"
		}

		layoutIfNeeded()
	}
	
	// TODO: REMOVE ONCE LIVEFEED AND COMMUNITY PROVIDE CORE DATA MESSAGE
	func configure(forMessage message: FirebaseConversation.Message, usingDateFormatter dateFormatter: DateFormatter) {
		legacyMessage = message
		if message.imageURL == nil && message.videoURL == nil {
			if let constraint = photoAspectConstraint {
				photoImageView.removeConstraint(constraint)
			}
			if let constraint = photoNoHeightConstraint {
				photoImageView.addConstraint(constraint)
			}
			photoBottomConstraint.constant = 0
		} else {
			if let constraint = photoNoHeightConstraint {
				photoImageView.removeConstraint(constraint)
			}
			if let constraint = photoAspectConstraint {
				photoImageView.addConstraint(constraint)
			}

			photoBottomConstraint.constant = CommunityRepliesTableViewCell.photoBottomConstraintDefault
			if message.imageURL != nil {
				photoImageView.sd_setImage(with: URL(string: message.imageURL!), completed: nil)
			}
			
			containerView.isHidden = message.videoURL == nil
			playVideoButton.isHidden = message.videoURL == nil
		}
		
		let tempDateFormatter = DateFormatter()
		tempDateFormatter.locale = Locale(identifier: "en_US")
		tempDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss z"
		
		let actionDateString = dateFormatter.string(from: tempDateFormatter.date(from: message.sent)!)
		actionDateLabel.attributedText = NSAttributedString(string: actionDateString, textStyle: .small)
				
		layoutIfNeeded()
	}
	
	func showHR(_ show: Bool) {
		horizontalRule.isHidden = !show
	}
	
	// MARK: Private
	
	@IBAction func handleVideoButtonTap(_ sender: UIButton) {
		videoDelegate?.videoPlayerProvidingCellTapped(self)
	}

	private func updateMessageLabel() {
		guard let name = nameToUse, let message = message else {
			// TODO: REMOVE ONCE LIVEFEED AND COMMUNITY PROVIDE CORE DATA MESSAGE

			guard let name = nameToUse, let message = legacyMessage else {
				return
			}
			
			commentLabel.attributedText = UIService.getInlineProfileNameAndMessage(withProfileName: name, andMessageText: message.message)
			commentLabel.isHidden = false
			return
		}
		
		commentLabel.attributedText = UIService.getInlineProfileNameAndMessage(withProfileName: name, andMessageText: message.message)
		commentLabel.isHidden = false
	}
	
	@IBAction private func onDelete(_ sender: Any) {
		delegate?.communityRepliesTableViewCellDidSelectDelete(self)
	}
	
	@IBAction private func onSelectProfile(_ sender: Any) {
		delegate?.communityRepliesTableViewCellDidSelectProfile(self)
	}
	
	@IBAction private func onSelectPhoto(_ sender: Any) {
		if let image = photoImageView.image {
			delegate?.communityRepliesTableViewCell(self, didSelectImage: image)
		}
	}
	
	@IBAction private func handleTapOnLabel(_ recognizer: UITapGestureRecognizer) {
		guard let text = commentLabel.attributedText?.string else {
			return
		}
				
		if let nameToUse = nameToUse {
			if let range = text.range(of: nameToUse), recognizer.didTapAttributedTextInLabel(label: commentLabel, inRange: NSRange(range, in: text)) {
				onSelectProfile(self)
			}
		}
	}
	
	private func resetCell() {
		commentLabel.isHidden = true
		deleteButton.isHidden = true
		profileImageView.sd_cancelCurrentImageLoad()
		photoImageView.sd_cancelCurrentImageLoad()
		profileImageView.sd_imageIndicator?.startAnimatingIndicator()
		photoImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		commentLabel.isUserInteractionEnabled = true
		commentLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnLabel(_:))))

		profileImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		photoImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		resetCell()
		
		photoAspectConstraint = NSLayoutConstraint(item: photoImageView, attribute: .width, relatedBy: .equal, toItem: photoImageView, attribute: .height, multiplier: 1.54839, constant: 0.0)
		photoNoHeightConstraint = NSLayoutConstraint(item: photoImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 0.0)
	}
	
	// MARK: Properties
	
	override func prepareForReuse() {
		super.prepareForReuse()
		resetCell()
	}
	
	// MARK: Properties
	
	weak var delegate: CommunityRepliesTableViewCellDelegate?
	var videoDelegate: VideoPlayerProvidingCellDelegate?
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var videoContainerView: UIView!
	@IBOutlet weak var playVideoButton: UIButton!
	
	// voting
	@IBOutlet weak var voteTotalLabel: UILabel!
	@IBOutlet weak var upvoteButton: UIButton!
	@IBOutlet weak var downvoteButton: UIButton!
	weak var voteDelegate: VoteButtonsProvidingCellDelegate?
	
	// MARK: Properties (Private)
	
	private var nameToUse: String? {
		didSet {
			updateMessageLabel()
		}
	}
	
	private var message: ConversationMessage? {
		didSet {
			updateMessageLabel()
		}
	}

	// TODO: REMOVE ONCE LIVEFEED AND COMMUNITY PROVIDE CORE DATA MESSAGE
	private var legacyMessage: FirebaseConversation.Message? {
		didSet {
			updateMessageLabel()
		}
	}
	
	@IBOutlet private weak var profileImageView: UIImageView!
	@IBOutlet private weak var profileButton: UIButton!
	@IBOutlet private weak var commentLabel: UILabel!
	@IBOutlet private weak var photoImageView: UIImageView!
	@IBOutlet private weak var photoBottomConstraint: NSLayoutConstraint!
	@IBOutlet private weak var photoButton: UIButton!
	@IBOutlet private weak var actionDateLabel: UILabel!
	@IBOutlet private weak var deleteButton: UIButton!
	@IBOutlet private weak var horizontalRule: UIView!
	
	private var photoAspectConstraint: NSLayoutConstraint?
	private var videoAspectConstraint: NSLayoutConstraint?
	private var photoNoHeightConstraint: NSLayoutConstraint?

	
	// MARK: Properties (Private Static)
	
	private static let photoBottomConstraintDefault: CGFloat = 8.0
	
	// MARK: Properties (Named)
	
	static let name = "CommunityRepliesTableViewCell"
}
