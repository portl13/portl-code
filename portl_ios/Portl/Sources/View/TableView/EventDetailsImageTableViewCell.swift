//
//  EvenDetailsImageTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 3/20/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import SDWebImage

class EventDetailsImageTableViewCell: UITableViewCell, Named {
	func configure(withImageURL imageURL: String?, fallbackImage: UIImage) {
		if let urlString = imageURL {
			eventImageView.sd_setImage(with: URL(string: urlString)) {[weak self] (_, error, _, _) in
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
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		eventImageView.sd_imageIndicator = SDWebImageActivityIndicator.whiteLarge
		eventImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		eventImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var eventImageView: UIImageView!
	
	// MARK: Properties (Named)
	
	static let name = "EventDetailsImageTableViewCell"
}
