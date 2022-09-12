//
//  ArtistEventTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 12/3/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CSkyUtil

class ArtistEventTableViewCell: UITableViewCell, Named {
	func configure(forMonth month: String, day: Int, eventTitle: String, relativeShortDateString: String, placeString: String) {
		monthLabel.attributedText = NSAttributedString(string: month, textStyle: .bodyBold, overrideColor: .light1, overrideAlignment: .center)
		dayLabel.attributedText = NSAttributedString(string: "\(day)", textStyle: .h3Bold, overrideColor: .light1, overrideAlignment: .center)
		
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineBreakMode = .byTruncatingTail
		
		let titleMutable = NSMutableAttributedString(string: eventTitle, textStyle: .bodyBold, overrideColor: .light1)
		titleMutable.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: titleMutable.length))
		titleLabel.attributedText = titleMutable
		
		let dateMutable = NSMutableAttributedString(string: relativeShortDateString, textStyle: .small, overrideColor: .light2)
		dateMutable.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: dateMutable.length))
		dateLabel.attributedText = dateMutable
		
		let placeMutable = NSMutableAttributedString(string: placeString, textStyle: .small, overrideColor: .light2)
		placeMutable.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: placeMutable.length))
		placeLabel.attributedText = placeMutable
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		dateView.layer.cornerRadius = 4.0
		dateView.clipsToBounds = true
	}
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var monthLabel: UILabel!
	@IBOutlet private weak var dayLabel: UILabel!
	@IBOutlet private weak var titleLabel: UILabel!
	@IBOutlet private weak var dateLabel: UILabel!
	@IBOutlet private weak var placeLabel: UILabel!
	@IBOutlet private weak var dateView: UIView!
	
	// MARK: Properties (Named)
	
	static var name = "ArtistEventTableViewCell"
}
