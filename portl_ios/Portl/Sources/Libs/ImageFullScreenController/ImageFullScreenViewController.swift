//
//  ImageFullScreenViewController.swift
//  Portl
//
//  Created by Jeff Creed on 6/13/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation

protocol ImageFullScreenViewControllerDelegate: class {
	func imageFullScreenViewControllerRequestsDismissal(_ imageFullScreenViewController: ImageFullScreenViewController)
}

class ImageFullScreenViewController: UIViewController {
	
	override func viewWillAppear(_ animated: Bool) {
		navigationController?.navigationBar.isHidden = true
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if let image = image {
			imageScrollView.displayImage(image)
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		navigationController?.navigationBar.isHidden = false
	}
	
	@IBAction private func onClose(_ sender: Any) {
		let transition = CATransition()
		transition.duration = 0.3
		transition.type = .fade
		transition.subtype = .fromTop
		
		navigationController?.view.layer.add(transition, forKey: kCATransition)
		navigationController?.popViewController(animated: false)
	}
	
	@objc var image: UIImage?
	weak var delegate: ImageFullScreenViewControllerDelegate?
	
	@IBOutlet private weak var imageScrollView: ImageScrollView!
}
