//
//  EventDetailsSourceLogoTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 3/21/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil

class EventDetailsSourceLogoTableViewCell: UITableViewCell, Named {
	
	func configure(forEventSource source: EventSource) {
		iconImageView.image = UIService.smallLogoForEventSource(source: source)
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		sourceLabel.attributedText = NSAttributedString(string: EventDetailsSourceLogoTableViewCell.poweredBy, textStyle: .smallLight2)
	}
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var iconImageView: UIImageView!
	@IBOutlet private weak var sourceLabel: UILabel!
	private static let poweredBy = "Search powered by PORTL"
	
	// MARK: Properties (Named)
	
	static let name = "EventDetailsSourceLogoTableViewCell"
}
