//
//  ShowMoreTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 12/3/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation

protocol ShowMoreTableViewCellDelegate: class {
	func showMoreTableViewCellRequestsToggleShowMore(_ showMoreTableViewCell: ShowMoreTableViewCell)
}

class ShowMoreTableViewCell: UITableViewCell {
	
	@IBAction func toggleShowMore(_ sender: Any) {
		delegate?.showMoreTableViewCellRequestsToggleShowMore(self)
	}
	
	// MARK: Private
	
	func configureShowMoreButton(labelWidth: CGFloat, shouldShowMore: Bool) {
		if shouldShowMore {
			expandableLabel.numberOfLines = 0
			showMoreButton.isHidden = false

			let showLessText = NSAttributedString(string: ShowMoreTableViewCell.showLessText, textStyle: .bodyInteractive)
			showMoreButton.setAttributedTitle(showLessText, for: .normal)
		} else {
			expandableLabel.numberOfLines = ShowMoreTableViewCell.collapsedNumberOfLines
			
			let textHeight = expandableLabel.attributedText?.height(containerWidth: labelWidth) ?? 0.0
			let needsButton = textHeight > CGFloat(expandableLabel.numberOfLines) * ShowMoreTableViewCell.singleLineHeight
			
			showMoreButton.isHidden = !needsButton
			
			if needsButton {
				let showMoreText = NSAttributedString(string: ShowMoreTableViewCell.showMoreText, textStyle: .bodyInteractive)
				showMoreButton.setAttributedTitle(showMoreText, for: .normal)
			}
		}
	}

	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		resetShowMoreState()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		resetShowMoreState()
	}
	
	func resetShowMoreState() {
		showMoreButton.isHidden = true
		expandableLabel.numberOfLines = ShowMoreTableViewCell.collapsedNumberOfLines
	}
	
	// MARK: Properties
	
	weak var delegate: ShowMoreTableViewCellDelegate?
	
	@IBOutlet weak var showMoreButton: UIButton!
	@IBOutlet weak var expandableLabel: UILabel!

	// MARK: Properties (Static)
	
	static let leftAboutMargin: CGFloat = 16.0
	static let rightAboutMargin: CGFloat = 40.0

	// MARK: Properties (Private Static)
	
	private static let showMoreText = "Show More"
	private static let showLessText = "Show Less"
	private static let collapsedNumberOfLines = 4
	private static let singleLineHeight: CGFloat = 14.5
	
}
