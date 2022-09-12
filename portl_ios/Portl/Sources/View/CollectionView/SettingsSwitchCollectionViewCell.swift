//
//  SettingsSwitchCollectionViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 6/6/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil

class SettingsSwitchCollectionViewCell: UICollectionViewCell, Named {
	// MARK: Configuration
	
	func configureCell(withText text: String, subText: String?, andValue value: Bool, showHR: Bool) {
        label.attributedText = NSAttributedString(string: text, textStyle: .h3Bold)
		if let subText = subText {
			subLabel.attributedText = NSAttributedString(string: subText, textStyle: .body)
		} else {
			subLabel.attributedText = nil
		}
        toggle.setOn(value, animated: true)
		
		hr.isHidden = !showHR
    }
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		label.text = nil
		subLabel.text = nil
	}
	
	// MARK: Static
	
	static func sizeForCell(withWidth width: CGFloat, andText text: String, subText: String?) -> CGSize {
		let labelConstraintRect = CGSize(width: width - labelLeftRightMargin * 2 - switchWidthAndRightMargin, height: .greatestFiniteMagnitude)
		let labelBoundingRect = text.boundingRect(with: labelConstraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0)], context: nil)
		let subLabelBoundingRect = subText?.boundingRect(with: labelConstraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0)], context: nil)
		
		var computed: CGFloat = labelBoundingRect.height + labelTopMargin
		
		if let subBoundingRect = subLabelBoundingRect {
			computed += subBoundingRect.height + labelBottomMargin
		}
		computed += subLabelBottomMargin + 1.0
		
		return CGSize(width: width, height: max(minCellHeight, ceil(computed)))
	}

    // MARK: Properties (Private)
    
    @IBOutlet private weak var label: UILabel!
	@IBOutlet private weak var subLabel: UILabel!
    @IBOutlet private weak var toggle: UISwitch!
	@IBOutlet private weak var hr: UIView!

	// MARK: Properties (Private Static Constant)
	
	private static let labelLeftRightMargin: CGFloat = 16.0
	private static let labelTopMargin: CGFloat = 16.0
	private static let labelBottomMargin: CGFloat = 4.0
	private static let subLabelBottomMargin: CGFloat = 16.0
	private static let switchWidthAndRightMargin: CGFloat = 67.0
	private static let minCellHeight: CGFloat = 70.0
	
    // MARK: Properties (Named)
    
    static var name = "SettingsSwitchCollectionViewCell"
}
