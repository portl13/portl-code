//
//  UIViewController+ErrorAlert.swift
//  Portl
//
//  Created by Jeff Creed on 8/31/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation

extension UIViewController {
	@objc func presentErrorAlert(withMessage message: String?, completion: (() -> Void)?) {
		DispatchQueue.main.async { [weak self] in
			guard self?.presentedViewController == nil else {
				completion?()
				return
			}

			let alert = UIAlertController(title: nil, message: message ?? "Error contacting server", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
				completion?()
			}))

			self?.present(alert, animated: true, completion: nil)
		}
	}
}
