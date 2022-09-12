//
//  ProfileEditTextPropertyCollectionViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 6/2/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil

class ProfileEditTextPropertyCollectionViewCell: UICollectionViewCell, Named {
    func configureCell(withName name: String, andValue value: String?, showHorizontalRule: Bool) {
        nameLabel.text = name
        valueLabel.text = value
        HR.isHidden = !showHorizontalRule
    }
    
    // MARK: Properties (Private)
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var valueLabel: UILabel!
    @IBOutlet private weak var HR: UIView!
    
    // MARK: Properties (Named)
    
    static var name = "ProfileEditTextPropertyCollectionViewCell"
    
    // MARK: Static
    
    private static let minHeight: CGFloat = 56.0
    private static let valueTopMargin: CGFloat = 19.0
    private static let valueBottomMargin: CGFloat = 19.0
    private static let valueLeadingMargin: CGFloat = 16.0
    private static let valueTrailingMargin: CGFloat = 25.0
    private static let nameLeadingMargin: CGFloat = 22.0
    private static let nameLabelWidth: CGFloat = 88.0
    private static let hrHeight: CGFloat = 2.0
    
    static func heightForCell(withWidth width: CGFloat, andValueString valueString: String?) -> CGFloat {
        guard let string = valueString else {
            return minHeight
        }
        let constraintRect = CGSize(width: width - nameLeadingMargin - nameLabelWidth - valueLeadingMargin - valueTrailingMargin, height: .greatestFiniteMagnitude)
		let boundingRect = string.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0)], context: nil)
        return max(minHeight, boundingRect.height + valueTopMargin + valueBottomMargin + hrHeight)
    }
    
}
