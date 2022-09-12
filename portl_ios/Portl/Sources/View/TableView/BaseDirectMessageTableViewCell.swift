//
//  BaseDirectMessageTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 5/16/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import SDWebImage

class BaseDirectMessageTableViewCell: UITableViewCell {
	
	func getMessageImage() -> UIImage? {
		return messageImageView.image
	}
	
	func configure(forConversationMessage conversationMessage: ConversationMessage) {
		messageLabel.text = conversationMessage.message
		
		if conversationMessage.message != nil{
			bubbleHeightConstraint?.isActive = false
			bubble.isHidden = false
		} else {
			bubbleHeightConstraint = bubble.heightAnchor.constraint(equalToConstant: 0.0)
			bubbleHeightConstraint?.isActive = true
			bubble.isHidden = true
		}
	}
	
	func configure(withImageURL imageURL: String) {
		messageImageView.sd_setImage(with: URL(string: imageURL)!)
	}
	
	func configureForEvent(withTitle title: String, imageURL: String?, defaultImage: UIImage, date: String, andDistance distance: String) {
		if let urlString = imageURL {
			eventImageView.sd_setImage(with: URL(string: urlString)) {[weak self] (_, error, _, _) in
				guard error == nil || error!.localizedDescription.contains("2002") else {
					self?.eventImageView.sd_setImage(with: nil, placeholderImage: defaultImage, options: [], context: nil)
					return
				}
			}
		} else {
			eventImageView.sd_setImage(with: nil, placeholderImage: defaultImage, options: [], context: nil)
		}
		let titleText = NSAttributedString(string: title, textStyle: .bodyBold)
		eventTitleLabel.attributedText = titleText
		let dateText = NSAttributedString(string: date, textStyle: .small)
		eventDateLabel.attributedText = dateText
		let distanceText = NSAttributedString(string: distance, textStyle: .small)
		eventDistanceLabel.attributedText = distanceText
		eventTitleLabel.isHidden = false
		eventDateLabel.isHidden = false
		eventDistanceLabel.isHidden = false
	}
	
	func setBatched(_ isBatched: Bool) {
		batchSelectControl.isSelected = isBatched
	}
	
	// MARK: Private
	
	private func resetCell() {
		messageImageView.sd_cancelCurrentImageLoad()
		messageImageView.image = nil
		eventImageView.sd_cancelCurrentImageLoad()
		eventImageView.image = nil
		messageImageView.sd_imageIndicator?.startAnimatingIndicator()
		eventImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		messageImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		eventImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		messageImageView.layer.cornerRadius = 8.0
		messageEventView.layer.cornerRadius = 8.0
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		supplementalViewHeightConstraint.constant = 0.0
		messageEventView.isHidden = true
		messageImageView.isHidden = true
		bubbleHeightConstraint?.isActive = false
	}
	
	// MARK: Properties
	
	var willHaveImage = false {
		didSet {
			if willHaveImage {
				supplementalViewHeightConstraint.constant = 220.0
				messageImageView.isHidden = false
				messageImageView.sd_imageIndicator?.startAnimatingIndicator()
			}
		}
	}
	
	var willHaveEvent = false {
		didSet {
			if willHaveEvent {
				supplementalViewHeightConstraint.constant = 220.0
				messageEventView.isHidden = false
				eventImageView.sd_imageIndicator?.startAnimatingIndicator()
				eventTitleLabel.isHidden = true
				eventDateLabel.isHidden = true
				eventDistanceLabel.isHidden = true
			}
		}
	}
		
	// MARK: Properties (Private)
	
	@IBOutlet private weak var messageLabel: UILabel!
	@IBOutlet private weak var messageImageView: UIImageView!
	@IBOutlet private weak var bubble: UIImageView!
	@IBOutlet private weak var messageEventView: UIView!
	@IBOutlet private weak var eventImageView: UIImageView!
	@IBOutlet private weak var eventTitleLabel: UILabel!
	@IBOutlet private weak var eventDateLabel: UILabel!
	@IBOutlet private weak var eventDistanceLabel: UILabel!
	@IBOutlet private weak var supplementalViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet private weak var batchSelectControl: UIButton!
	
	private var bubbleHeightConstraint: NSLayoutConstraint?
}
