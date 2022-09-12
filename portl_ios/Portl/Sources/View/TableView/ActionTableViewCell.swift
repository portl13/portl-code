//
//  ActionTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 8/30/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil

class ActionTableViewCell: UITableViewCell, Named {
	
	@IBOutlet weak var actionLabel: UILabel!
	
	// MARK: Properties (Named)
	
	static var name = "ActionTableViewCell"
}
