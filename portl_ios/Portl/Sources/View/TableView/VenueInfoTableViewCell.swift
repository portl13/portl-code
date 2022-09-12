//
//  VenueInfoTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 12/10/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CSkyUtil

protocol VenueInfoTableViewCellDelegate: class {
	func venueInfoTableViewCellRequestsDirections(_ venueInfoTableViewCell: VenueInfoTableViewCell)
}

class VenueInfoTableViewCell: UITableViewCell, Named {
	
	// MARK: Configure
	
	func configure(withVenueName venueName: String, addressString: String, andDistanceString distanceString: String) {
		nameLabel.attributedText = NSAttributedString(string: venueName, textStyle: .h2Bold)
		addressLabel.attributedText = NSAttributedString(string: addressString, textStyle: .body)
		distanceLabel.attributedText = NSAttributedString(string: distanceString, textStyle: .body, overrideColor: .interactive1)
	}
	
	// MARK: Private
	
	@IBAction private func directionsButtonPressed(_ sender: Any) {
		delegate?.venueInfoTableViewCellRequestsDirections(self)
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(directionsButtonPressed))
		distanceLabel.addGestureRecognizer(gestureRecognizer)
	}
	
	// MARK: Properties
	
	weak var delegate: VenueInfoTableViewCellDelegate?
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var nameLabel: UILabel!
	@IBOutlet private weak var addressLabel: UILabel!
	@IBOutlet private weak var distanceLabel: UILabel!
	
	// MARK: Properties (Named)
	
	static var name = "VenueInfoTableViewCell"
}
