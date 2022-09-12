//
//  AuthRequiredViewController.swift
//  Portl
//
//  Created by Jeff Creed on 10/2/18.
//  Copyright © 2018 Portl. All rights reserved.
//

class AuthRequiredViewController: UIViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
		
		signInButton.layer.cornerRadius = 5.0
		
		signUpButton.layer.borderColor = UIColor(byteValueRed: 204, byteValueGreen: 207, byteValueBlue: 204).cgColor
		signUpButton.layer.borderWidth = 1.0
		signUpButton.layer.cornerRadius = 5.0
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		messageLabel.text = message
	}
	
	@IBAction private func transitionToSignUp(_ sender: Any?) {
		tabBarController?.performSegue(withIdentifier: signUpSegueIdentifier, sender: self)
	}
	
	@IBAction private func transitionToSignIn(_ sender: Any?) {
		tabBarController?.performSegue(withIdentifier: signInSegueIdentifier, sender: self)
	}
	
	@objc var message: String?
	
	@IBOutlet private weak var messageLabel: UILabel!
	@IBOutlet private weak var signInButton: UIButton!
	@IBOutlet private weak var signUpButton: UIButton!
	
	private let signUpSegueIdentifier = "signUpSegue"
	private let signInSegueIdentifier = "signInSegue"
}
