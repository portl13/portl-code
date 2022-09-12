//
//  CommunityMessageImageTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 3/27/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import SDWebImage

protocol CommunityMessageImageTableViewCellDelegate: class {
	func communityMessageImageTableViewCell(_ communityMessageImageTableViewCell: CommunityMessageImageTableViewCell, selectedImage image: UIImage)
}

class CommunityMessageImageTableViewCell: CommunityMessageTableViewCell {
	
	func getMessageImage() -> UIImage? {
		return postedImageView.image
	}
	
	override func configure(withConversationMessage message: FirebaseConversation.Message, showHr: Bool, shouldHighlight: Bool) {
		super.configure(withConversationMessage: message, showHr: showHr, shouldHighlight: shouldHighlight)
		
		if let imageURL = message.imageURL, let url = URL(string: imageURL) {
			postedImageView.sd_setImage(with: url, placeholderImage: nil, options: .refreshCached) { (_, error, _, _) in
				// todo: broken image asset on failed load
			}
		} else {
			// todo: broken image asset on failed load
		}
		
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
	
	// MARK: Private
	
	@IBAction private func onImageButtonSelect(_ sender: Any) {
		guard let image = postedImageView.image else {
			return
		}
		
		imageDelegate?.communityMessageImageTableViewCell(self, selectedImage: image)
	}
	
	// MARK: Life Cycle
	
	override func resetCell() {
		super.resetCell()
		
		postedImageView.sd_cancelCurrentImageLoad()
		postedImageView.image = nil
		postedImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		postedImageView.sd_imageIndicator = SDWebImageActivityIndicator.white

		setNeedsLayout()
	}
	
	// MARK: Properties
	
	weak var imageDelegate: CommunityMessageImageTableViewCellDelegate?
	
	// MARK: Properties (Private)

	private var messageHeightConstraint: NSLayoutConstraint!
	private var imageLoading = false
	
	@IBOutlet private weak var postedImageView: UIImageView!
	@IBOutlet private weak var messageBottomConstraint: NSLayoutConstraint!
	
	private let messageBottomConstant: CGFloat = 16.0
	private let postedImageRatioConstant: CGFloat = 1.54
	
	// MARK: Properties (Named)
	
	override class var name: String {
		return "CommunityMessageImageTableViewCell"
	}
}
