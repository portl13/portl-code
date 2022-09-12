//
//  NSAttributedString+Height.swift
//  Portl
//
//  Created by Jeff Creed on 7/31/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation

extension NSAttributedString {
	func height(containerWidth: CGFloat) -> CGFloat {
		let rect = self.boundingRect(with: CGSize(width: containerWidth, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
		return rect.size.height
	}
}
