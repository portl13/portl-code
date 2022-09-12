//
//  CommunityVideoTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 1/14/20.
//  Copyright © 2020 Portl. All rights reserved.
//

import AVKit
import SDWebImage

class CommunityMessageVideoTableViewCell: CommunityMessageTableViewCell, VideoPlayerProvidingCell {
	
	override func configure(withConversationMessage message: FirebaseConversation.Message, showHr: Bool, shouldHighlight: Bool) {
		super.configure(withConversationMessage: message, showHr: showHr, shouldHighlight: shouldHighlight)
				
		if message.message == nil {
			messageHeightConstraint = messageLabel.heightAnchor.constraint(equalToConstant: 0)
			messageBottomConstraint.constant = 0
		} else {
			if let constraint = messageHeightConstraint {
				messageLabel.removeConstraint(constraint)
			}
			messageBottomConstraint.constant = messageBottomConstant
		}
		
		setNeedsLayout()
	}

	
	@IBAction func handleVideoButtonTap(_ sender: UIButton) {
		videoDelegate?.videoPlayerProvidingCellTapped(self)
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.clipsToBounds = true
		containerView.layer.cornerRadius = 8.0
		thumbnailView.sd_imageIndicator = SDWebImageActivityIndicator.white
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		thumbnailView.sd_cancelCurrentImageLoad()
		thumbnailView.image = nil
		thumbnailView.sd_imageIndicator?.startAnimatingIndicator()
	}

	// MARK: Properties
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var videoContainerView: UIView!
	@IBOutlet weak var thumbnailView: UIImageView!
	@IBOutlet weak var showVideoButton: UIButton!

	weak var videoDelegate: VideoPlayerProvidingCellDelegate?

	// MARK: Properties (Private)
	
	@IBOutlet private weak var messageBottomConstraint: NSLayoutConstraint!
	private var messageHeightConstraint: NSLayoutConstraint!
	
	private let messageBottomConstant: CGFloat = 16.0
	private let postedImageRatioConstant: CGFloat = 1.54
	
	// MARK: Properties (Named)
	
	override class var name: String {
		return "CommunityMessageVideoTableViewCell"
	}
}
