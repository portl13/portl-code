//
//  EventImageTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 6/28/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import SDWebImage

@objc class EventImageTableViewCell: UITableViewCell {
    @objc func configure(withImageURL imageURL: String?, fallbackImage: UIImage) {
        guard let imageURL = imageURL else {
            self.eventImageView.image = fallbackImage
            return
        }
        
        eventImageView.sd_setImage(with: URL(string: imageURL)) {[weak self] (image, error, cacheType, imageURL) in
			guard error == nil || error!.localizedDescription.contains("2002") else {
                self?.eventImageView.image = fallbackImage
				self?.eventImageView.sd_imageIndicator?.stopAnimatingIndicator()
				return
            }
        }
    }
	
	// MARK: Life Cycle
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		eventImageView.image = nil
		eventImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		eventImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		eventImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
    // MARK: Properties (Private)
    
    @IBOutlet private weak var eventImageView: UIImageView!
}
