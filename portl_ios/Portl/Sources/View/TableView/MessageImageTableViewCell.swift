//
//  MessageImageTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 3/26/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import SDWebImage

class MessageImageTableViewCell: UITableViewCell, Named {
	
	var messageImage: UIImage? {
		get {
			return messageImageView.image
		}
		set {
			if let newValue = newValue {
				let ratio = newValue.size.width / newValue.size.height
				let newHeight = messageImageView.frame.width / ratio
				heightConstraint.constant = newHeight
				messageImageView.image = newValue
				layoutIfNeeded()
			}
		}
	}
	
	var messageImageURL: URL? {
		didSet {
			if let newValue = messageImageURL {
				messageImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
				messageImageView.sd_setImage(with: newValue) { (image, error, _, _) in
					self.messageImage = image
				}
			}
		}
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		messageImageView.layer.cornerRadius = 4
	}
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var messageImageView: UIImageView!
	@IBOutlet private weak var heightConstraint: NSLayoutConstraint!
	
	// MARK: Properties (Named)
	
	static let name = "MessageImageTableViewCell"
}
