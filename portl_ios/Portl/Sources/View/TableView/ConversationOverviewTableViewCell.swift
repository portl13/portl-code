//
//  ConversationOverviewTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 5/7/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import SDWebImage
import CSkyUtil


class ConversationOverviewTableViewCell: UITableViewCell, Named {
	
	// MARK: Configuration
	
	func configure(forOverview overview: ConversationOverview, withRelativeDateFormatter dateFormatter: DateFormatter, isLastMessageArchived: Bool) {
		if isLastMessageArchived {
			lastMessageLabel.attributedText = NSAttributedString(string: ConversationOverviewTableViewCell.lastMessageWasArchived, textStyle: .bodyItalic)
		} else if let message = overview.lastMessage {
			lastMessageLabel.attributedText = NSAttributedString(string: message, textStyle: .body)
		} else {
			lastMessageLabel.attributedText = NSAttributedString(string: overview.lastImageURL != nil ? ConversationOverviewTableViewCell.lastMessageWasImage : ConversationOverviewTableViewCell.lastMessageWasShare, textStyle: .bodyItalic)
		}
		
		if let date = overview.lastActivity {
			let dateText = dateFormatter.string(from: date as Date)
			timeLabel.attributedText = NSAttributedString(string: dateText, textStyle: .body)
		} else {
			timeLabel.attributedText = NSAttributedString(string: "", textStyle: .body)
		}
	}
	
	func configure(forProfile profile: Profile?) {
		if let profile = profile, let avatarURLString = profile.avatar, let avatarURL = URL(string: avatarURLString) {
			profileImageView.sd_setImage(with: avatarURL, placeholderImage: nil, options: .refreshCached) {[weak self] (_, error, _, _) in
				guard error == nil || error!.localizedDescription.contains("2002") else {
					self?.profileImageView.sd_setImage(with: nil, placeholderImage: UIService.defaultProfileImage, options: [], context: nil)
					return
				}
			}
		} else {
			profileImageView?.sd_setImage(with: nil, placeholderImage: UIService.defaultProfileImage, options: [], context: nil)
		}
		
		usernameLabel.attributedText = NSAttributedString(string: profile?.username ?? "", textStyle: .h3Bold)
	}
	
	func showHR(_ show: Bool, hasUnread: Bool) {
		horizontalRule.isHidden = !show
		unreadIcon.isHidden = !hasUnread
	}
	
	func setBatched(_ isBatched: Bool) {
		batchSelectControl.isSelected = isBatched
	}

	func resetProfileElements() {
		profileImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		profileImageView.image = nil
		profileImageView.sd_imageIndicator?.startAnimatingIndicator()
		usernameLabel.text = nil
		usernameLabel.attributedText = nil
	}
	
	func resetCell() {
		resetProfileElements()
		lastMessageLabel.text = nil
		lastMessageLabel.attributedText = nil
		timeLabel.text = nil
		timeLabel.attributedText = nil
	}
	
	
	@IBOutlet weak var profileImageView: UIImageView!
	@IBOutlet weak var usernameLabel: UILabel!
	@IBOutlet weak var lastMessageLabel: UILabel!
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var horizontalRule: UIView!
	@IBOutlet weak var unreadIcon: UIImageView!
	@IBOutlet private weak var batchSelectControl: UIButton!

	private static let lastMessageWasImage = "[sent an image]"
	private static let lastMessageWasShare = "[shared an event]"
	private static let lastMessageWasArchived = "[archived by user]"
	
	// MARK: Properties (Named)
	
	static let name = "ConversationOverviewTableViewCell"
}
