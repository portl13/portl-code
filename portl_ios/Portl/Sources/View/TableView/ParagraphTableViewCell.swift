//
//  ParagraphTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 8/30/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil

class ParagraphTableViewCell: UITableViewCell, Named {
	func configure(withText text: String) {
		paragraphLabel.text = text
	}
	
	// MARK: Properties (Private)
	
	@IBOutlet private var paragraphLabel: UILabel!
	
	// MARK: Properties (Named)
	
	static var name = "ParagraphTableViewCell"
}
