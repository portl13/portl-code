//
//  UIViewController+WhiteAlert.swift
//  Portl
//
//  Created by Jeff Creed on 3/26/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil

extension UIViewController {
	func getWhiteAlert(withTitle title: String) -> UIAlertController {
		let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
		alert.view.layer.cornerRadius = 24.0
		alert.view.backgroundColor = PaletteColor.light1.uiColor
		return alert
	}
	
	func getWhiteActionSheet(withTitle title: String) -> UIAlertController {
		let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
		alert.view.layer.cornerRadius = 24.0
		alert.view.backgroundColor = PaletteColor.light1.uiColor
		return alert
	}
}
