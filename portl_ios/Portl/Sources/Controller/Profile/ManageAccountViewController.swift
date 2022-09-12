//
//  ManageAccountViewController.swift
//  Portl
//
//  Created by Jeff Creed on 9/16/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CSkyUtil

class ManageAccountViewController: UIViewController {
	
	// MARK: Private
	
	private func onDeleteConfirmed() {
		spinnerView.isHidden = false
		
		userProfileService.markAccountForDeletion {[weak self] (success) in
			guard success else {
				self?.presentErrorAlert(withMessage: "Error deleting account. Please contact support.", completion: {
					self?.spinnerView.isHidden = true
				})
				return
			}
			
			let successAlert = UIAlertController(title: "Deletion Scheduled", message: "Your account will be deleted in 3 days. You can log back in before then to cancel deletion. Your account will be set to private during the interim period.", preferredStyle: .alert)
			successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
				self?.showJoinedReference?.setValue(false)
				self?.fcmTokenManager.currentFCMToken = nil
				FIRFriends.shared().signOut()
				self?.friends.signOut()
				FIRPortlAuthenticator.shared().signOut()
				self?.spinnerView.isHidden = true
				self?.tabBarController?.navigationController?.popViewController(animated: true)
			}))
			self?.present(successAlert, animated: true, completion: nil)
		}
	}
	
	@IBAction private func onDeleteSelected(_ sender: Any) {
		self.presentDeleteConfirmationAlert(withMessage: "Are you sure you want to delete your account?") { (confirm) in
			guard confirm else {
				return
			}
			self.onDeleteConfirmed()
		}
	}
	
	// MARK: Navigation
	
	@IBAction private func onBack() {
		self.navigationController?.popViewController(animated: true)
	}
	
	// MARK: Life Cycle
	
	override func viewDidLoad() {
		let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: .plain, target: self, action: #selector(onBack))
		backItem.tintColor = .white
		navigationItem.leftBarButtonItem = backItem
		
		deleteButton.layer.cornerRadius = 4
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		showJoinedReference = Database.database().reference().child("v2/profile/\(profileID!)/show_joined")
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		Injector.root?.inject(into: inject)
	}
	
	private func inject(userProfileService: UserProfileService, fcmTokenManager: FCMTokenManager, friends: Friends) {
		self.userProfileService = userProfileService
		self.fcmTokenManager = fcmTokenManager
		self.friends = friends
	}
	
	// MARK: Properties
	
	var profileID: String?
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var deleteButton: UIButton!
	@IBOutlet private weak var spinnerView: UIView!
	
	private var userProfileService: UserProfileService!
	private var fcmTokenManager: FCMTokenManager!
	private var friends: Friends!
    private var showJoinedReference: DatabaseReference?
}
