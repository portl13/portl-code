//
//  ArtistBioTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 12/3/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CSkyUtil

class ArtistBioTableViewCell: ShowMoreTableViewCell, Named {
	func configure(withAboutInfo aboutInfo: About?, tableWidth: CGFloat, shouldShowMore: Bool) {
		if let about = aboutInfo {
			expandableLabel.attributedText = about.attributedString(withTextStyle: .body, andColor: PaletteColor.light1.uiColor)
		} else {
			expandableLabel.attributedText = nil
		}
		
		configureShowMoreButton(labelWidth: tableWidth - ShowMoreTableViewCell.leftAboutMargin - ShowMoreTableViewCell.rightAboutMargin, shouldShowMore: shouldShowMore)
	}
	
	// MARK: Properties (Named)
	
	static var name = "ArtistBioTableViewCell"
}
