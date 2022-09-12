//
//  WhiteLabelSectionHeaderView.swift
//  Portl
//
//  Created by Jeff Creed on 8/30/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil

class WhiteLabelSectionHeaderView: UITableViewHeaderFooterView, Named, NibInstantiable {
	
	// MARK: Properties
	
	@IBOutlet weak var label: UILabel!
	
	// MARK: Properties (Named)
	
	static var name = "WhiteLabelSectionHeaderView"
}
