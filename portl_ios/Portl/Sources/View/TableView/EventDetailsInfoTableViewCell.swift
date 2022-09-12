//
//  EventDetailsInfoTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 3/20/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil


class EventDetailsInfoTableViewCell: ShowMoreTableViewCell, Named {
	func configure(withEventTitle title: String, dateString: String, venueName: String?, aboutInfo: About?, andDistanceString distanceString: String, tableWidth: CGFloat, shouldShowMore: Bool) {
		titleLabel.attributedText = NSAttributedString(string: title, textStyle: .h2Bold)
		
		dateLabel.attributedText = NSAttributedString(string: dateString, textStyle: .h3Bold)
		if let venue = venueName {
			venueLabel.attributedText = NSAttributedString(string: venue, textStyle: .body)
		} else {
			venueLabel.attributedText = nil
		}
		
		distanceLabel.attributedText = NSAttributedString(string: distanceString, textStyle: .bodyInteractive)
		
		if let about = aboutInfo {
			expandableLabel.attributedText = about.attributedString(withTextStyle: .body, andColor: PaletteColor.light1.uiColor)
		} else {
			expandableLabel.attributedText = nil
		}
		
		configureShowMoreButton(labelWidth: tableWidth - ShowMoreTableViewCell.leftAboutMargin - ShowMoreTableViewCell.rightAboutMargin, shouldShowMore: shouldShowMore)
	}
		
	// MARK: Properties (Private)
	
	@IBOutlet private weak var titleLabel: UILabel!
	@IBOutlet private weak var dateLabel: UILabel!
	@IBOutlet private weak var venueLabel: UILabel!
	@IBOutlet private weak var distanceLabel: UILabel!
		
	// MARK: Properties (Named)
	
	static let name = "EventDetailsInfoTableViewCell"
}
