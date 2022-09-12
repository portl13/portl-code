//
//  FollowButton.swift
//  Portl
//
//  Created by Jeff Creed on 12/9/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CSkyUtil

class FollowButton: UIButton {
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		layer.cornerRadius = 4
		layer.borderWidth = 1
		layer.borderColor = PaletteColor.light1.cgColor
		
		setTitleColor(PaletteColor.dark1.uiColor, for: .selected)
		setTitle(FollowButton.followingText, for: .selected)
		
		setTitleColor(PaletteColor.dark4.uiColor, for: .highlighted)
		setTitleColor(PaletteColor.dark1.uiColor, for: [.selected, .highlighted])
		setTitle(FollowButton.followingText, for: [.selected, .highlighted])
		
		setTitleColor(PaletteColor.light1.uiColor, for: .normal)
		setTitle(FollowButton.followText, for: .normal)
	}
	
	
	// MARK: Properties
	
	override var isHighlighted: Bool {
		didSet {
			layer.borderColor = isHighlighted ? PaletteColor.dark4.cgColor : PaletteColor.light1.cgColor
			if isSelected {
				backgroundColor = isHighlighted ? PaletteColor.dark4.uiColor : PaletteColor.light1.uiColor
			}
		}
	}
	
	override var isSelected: Bool {
		didSet {
			DispatchQueue.main.async {
				self.backgroundColor = self.isSelected ? PaletteColor.light1.uiColor : PaletteColor.dark1.uiColor
			}
		}
	}
	
	// MARK: Properties
	
	var isFollowing = false
	
	// MARK: Properties (Private Static)
	
	private static let followingText = "Following"
	private static let followText = "Follow"
}
