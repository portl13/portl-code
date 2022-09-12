//
//  About+Helpers.swift
//  Service
//
//  Created by Jeff Creed on 12/4/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import Foundation

extension About {
	@objc public func isHTML() -> Bool {
		return self.markupType == About.markupHTMLValue
	}
	
	public func attributedString(withTextStyle textStyle: TextStyle, andColor color: UIColor) -> NSAttributedString {
		let paragraphStyle = NSMutableParagraphStyle()
		let attrsDict = [NSAttributedString.Key.font: textStyle.font, NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.foregroundColor: color]

		if isHTML() {
			guard let data = value.data(using: .utf8, allowLossyConversion: true) else {
				return nonHTMLAttributedString(withTextStyle: textStyle, andAttributes: attrsDict)
			}
			
			do {
				let attributedString = try NSMutableAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
				attributedString.addAttributes(attrsDict, range: NSRange(location: 0, length: attributedString.length))
				return attributedString
			} catch {
				return nonHTMLAttributedString(withTextStyle: textStyle, andAttributes: attrsDict)
			}
		} else {
			return nonHTMLAttributedString(withTextStyle: textStyle, andAttributes: attrsDict)
		}
	}
	
	private func nonHTMLAttributedString(withTextStyle textStyle: TextStyle, andAttributes attributes: [NSAttributedString.Key : NSObject]) -> NSAttributedString {
		let result = NSMutableAttributedString(string: value, textStyle: textStyle)
		result.addAttributes(attributes, range: NSRange(location: 0, length: result.length))
		
		return result
	}
	
	private static let markupHTMLValue = "HTML"
}
