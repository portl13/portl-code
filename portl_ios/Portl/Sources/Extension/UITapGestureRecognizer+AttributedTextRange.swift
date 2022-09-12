//
//  UITapGestureRecognizer+AttributedTextRange.swift
//  Portl
//
//  Created by Jeff Creed on 6/6/19.
//  Copyright © 2019 Portl. All rights reserved.
//

extension UITapGestureRecognizer {
	func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
		guard let attrString = label.attributedText else {
			return false
		}
		
		let layoutManager = NSLayoutManager()
		let textContainer = NSTextContainer(size: .zero)
		let textStorage = NSTextStorage(attributedString: attrString)
		
		layoutManager.addTextContainer(textContainer)
		textStorage.addLayoutManager(layoutManager)
		
		textContainer.lineFragmentPadding = 0
		textContainer.lineBreakMode = label.lineBreakMode
		textContainer.maximumNumberOfLines = label.numberOfLines
		let labelSize = label.bounds.size
		textContainer.size = labelSize
		
		let locationOfTouchInLabel = self.location(in: label)
		let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x, y: locationOfTouchInLabel.y)
		let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
		return NSLocationInRange(indexOfCharacter, targetRange)
	}
}

