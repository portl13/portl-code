//
//  EventDetailsVenueTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 3/22/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil

class EventDetailsVenueTableViewCell: UITableViewCell, Named {
	
	func configure(withVenueName venueName: String, andVenueAddress venueAddress: String) {
		venueNameLabel.attributedText = NSAttributedString(string: venueName, textStyle: .h3Bold)
		venueAddressLabel.attributedText = NSAttributedString(string: venueAddress, textStyle: .body)
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		venueLabel.attributedText = UIService.getTableViewHeaderString(forText: EventDetailsVenueTableViewCell.venueText)
	}
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var venueLabel: UILabel!
	@IBOutlet private weak var venueNameLabel: UILabel!
	@IBOutlet private weak var venueAddressLabel: UILabel!
	
	// MARK: Properties (Private Static)
	
	private static let venueText = "VENUE"
	
	// MARK: Properties (Named)
	
	static let name = "EventDetailsVenueTableViewCell"
}
