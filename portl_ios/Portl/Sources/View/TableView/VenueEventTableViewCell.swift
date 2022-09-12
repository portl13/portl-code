//
//  VenueEventTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 12/10/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CSkyUtil
import SDWebImage

class VenueEventTableViewCell: UITableViewCell, Named {
	func configure(forEventTitle eventTitle: String, relativeShortDateString: String, imageURL: URL?, fallbackImage: UIImage) {
		
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineBreakMode = .byTruncatingTail
		
		let titleMutable = NSMutableAttributedString(string: eventTitle, textStyle: .bodyBold, overrideColor: .light1)
		titleMutable.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: titleMutable.length))
		titleLabel.attributedText = titleMutable
		
		dateLabel.attributedText = NSAttributedString(string: relativeShortDateString, textStyle: .small, overrideColor: .light2)
		
		if let url = imageURL {
			eventImageView.sd_setImage(with: url) {[weak self] (_, error, _, _) in
				guard error == nil || error!.localizedDescription.contains("2002") else {
					self?.eventImageView.image = fallbackImage
					self?.eventImageView.sd_imageIndicator?.stopAnimatingIndicator()
					return
				}
			}
		} else {
			eventImageView.image = fallbackImage
			eventImageView.sd_imageIndicator?.stopAnimatingIndicator()
		}
	}
	
	// MARK: Life Cycle
	
	func resetCell() {
		eventImageView.sd_cancelCurrentImageLoad()
		eventImageView.image = nil
		eventImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
				
		eventImageView.layer.cornerRadius = 4.0
		eventImageView.clipsToBounds = true
		eventImageView.sd_imageIndicator = SDWebImageActivityIndicator.white

		resetCell()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		resetCell()
	}

	// MARK: Properties (Private)
	
	@IBOutlet private weak var eventImageView: UIImageView!
	@IBOutlet private weak var titleLabel: UILabel!
	@IBOutlet private weak var dateLabel: UILabel!
	
	// MARK: Properties (Named)
	
	static var name = "VenueEventTableViewCell"

}
