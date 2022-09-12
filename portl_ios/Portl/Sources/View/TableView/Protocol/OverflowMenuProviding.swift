//
//  OverflowMenuProviding.swift
//  Portl
//
//  Created by Jeff Creed on 5/23/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation

protocol OverflowMenuProvidingCell {
	func overflowMenuButtonPressed(_ sender: Any)
	var overflowMenuDelegate: OverflowMenuProvidingCellDelegate? { get set }
}

protocol OverflowMenuProvidingCellDelegate: class {
	func overflowMenuProvidingCellRequestedMenu(_ overflowMenuProvingCell: OverflowMenuProvidingCell)
}
