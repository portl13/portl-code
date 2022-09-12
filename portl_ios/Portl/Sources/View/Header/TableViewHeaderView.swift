//
//  TableViewHeaderView.swift
//  Portl
//
//  Created by Jeff Creed on 4/8/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil

class TableViewHeaderView: UITableViewHeaderFooterView, Named {
	
	var labelText: String? {
		didSet {
			if let text = labelText {
				label.attributedText = UIService.getTableViewHeaderString(forText: text)
			}
		}
	}
	
	@IBOutlet private weak var label: UILabel!
	
	static let name = "TableViewHeaderView"
}
