//
//  SegmentedControlTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 12/3/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CSkyUtil

protocol SegmentedControlTableViewCellDelegate: class {
	func segmentedControlTableViewCell(_ segmentedControlTableViewCell: SegmentedControlTableViewCell, selectedIndex index: Int)
}

class SegmentedControlTableViewCell: UITableViewCell, Named {
	
	// MARK: Configure
	
	func configure(withSegmentTitles titles: [String], selectedTitle: String) {
		segmentedControl.removeAllSegments()
		titles.reversed().forEach { title in
			segmentedControl.insertSegment(withTitle: title, at: 0, animated: false)
		}
		segmentedControl.selectedSegmentIndex = titles.firstIndex(of: selectedTitle) ?? 0
	}
	
	// MARK: Private
	
	@IBAction private func segmentedControlChanged(_ sender: UISegmentedControl) {
		delegate?.segmentedControlTableViewCell(self, selectedIndex: sender.selectedSegmentIndex)
	}
	
	// MARK: Properties
	
	weak var delegate: SegmentedControlTableViewCellDelegate?
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var segmentedControl: UISegmentedControl!
	
	// MARK: Properties (Named)
	
	static var name = "SegmentedControlTableViewCell"
}
