//
//  FollowButtonProviding.swift
//  Portl
//
//  Created by Jeff Creed on 12/3/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation

protocol FollowButtonProvidingCell {
	func followButtonPressed(_ sender: Any)
	var followButtonDelegate: FollowButtonProvidingCellDelegate? { get set }
}

protocol FollowButtonProvidingCellDelegate: class {
	func followButtonProvidingCellPressedFollowButton(_ followButtonProvingCell: FollowButtonProvidingCell)
}
