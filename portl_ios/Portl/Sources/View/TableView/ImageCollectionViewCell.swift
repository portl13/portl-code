//
//  ImageCollectionViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 3/26/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil

class ImageCollectionViewCell: UICollectionViewCell, Named {
	
	// MARK: Properties
	
	var image: UIImage? {
		get {
			return imageView.image
		}
		set {
			imageView.image = newValue
		}
	}
	
	var videoLengthSeconds: Double? {
		didSet {
			if let value = videoLengthSeconds {
				let minutes: Int = Int(value) / 60
				let seconds = Int(value) % 60
				videoLengthLabel.text = "\(minutes):\(String(format: "%02d", seconds))"
				videoLengthLabel.isHidden = false
			} else {
				videoLengthLabel.text = ""
				videoLengthLabel.isHidden = true
			}
		}
	}
	
	// MARK: Life Cycle
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		videoLengthLabel.isHidden = true
	}
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var imageView: UIImageView!
	@IBOutlet private weak var videoLengthLabel: UILabel!
	
	// MARK: Properties (Named)
	
	static let name = "ImageCollectionViewCell"
}
