//
//  UIViewController+DeleteAlert.swift
//  Portl
//
//  Created by Jeff Creed on 7/18/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation

extension UIViewController {
	@objc func presentDeleteConfirmationAlert(withMessage message: String, completion: @escaping ((Bool) -> Void)) {
		guard presentedViewController == nil else {
			completion(false)
			return
		}
		
		let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
			completion(true)
		}))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
			completion(false)
		}))
		present(alert, animated: true, completion: nil)
	}
}
