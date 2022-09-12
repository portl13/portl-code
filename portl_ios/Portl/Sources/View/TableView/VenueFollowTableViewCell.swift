//
//  VenueFollowTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 12/10/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CSkyUtil

class VenueFollowTableViewCell: MapTableViewCell, FollowButtonProvidingCell {
	
	// MARK: Configuration
	
	public func configure(isFollowing: Bool) {
		followButton.isSelected = isFollowing
	}
	
	// MARK: FollowButtonProvidingCell
	
	@IBAction func followButtonPressed(_ sender: Any) {
		followButtonDelegate?.followButtonProvidingCellPressedFollowButton(self)
	}
		
	// MARK: Properties
	
	weak var followButtonDelegate: FollowButtonProvidingCellDelegate?
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var followButton: FollowButton!
	
	// MARK: Properties (Named)
	
	override class var name: String {
		return "VenueFollowTableViewCell"
	}
}
