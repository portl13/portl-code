//
//  ProfileSettingsViewController.swift
//  Portl
//
//  Created by Jeff Creed on 6/6/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation

class ProfileSettingsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return SettingsRow.count.rawValue
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let label = labels[indexPath.row]
        let subLabel = subLabels[indexPath.row]
		let settingsRow = SettingsRow(rawValue: indexPath.item)!
		
		switch settingsRow {
        case .accountPrivacy:
            let cell = collectionView.dequeue(SettingsSwitchCollectionViewCell.self, for: indexPath)
			cell.configureCell(withText: label, subText: subLabel, andValue: !showJoined, showHR: true)
            return cell
        default:
			let cell = collectionView.dequeue(SettingsCollectionViewCell.self, for: indexPath)
            cell.configureCell(withText: label, subText: subLabel, showHR:settingsRow != .privacy)
            return cell
        }
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: false)
		
		switch SettingsRow(rawValue: indexPath.row)! {
        case .accountPrivacy:
            toggleAccountPrivacy()
        case .notifications:
            openPushNotificationsSettings()
		case .manageAccount:
			performSegue(withIdentifier: manageSegueIdentifier, sender: self)
        case .terms:
            performSegue(withIdentifier: termsSegueIdentifier, sender: self)
		case .privacy:
			performSegue(withIdentifier: privacySegueIdentifier, sender: self)
        default:
            presentPasswordChangeAlert()
        }
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		if SettingsRow(rawValue: indexPath.row) == .accountPrivacy {
			return SettingsSwitchCollectionViewCell.sizeForCell(withWidth: collectionView.bounds.width, andText: labels[indexPath.row], subText: subLabels[indexPath.row])
		} else {
			return SettingsCollectionViewCell.sizeForCell(withWidth: collectionView.bounds.width, andText: labels[indexPath.row], subText: subLabels[indexPath.row])
		}
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingsCollectionView.registerNib(SettingsCollectionViewCell.self)
        settingsCollectionView.registerNib(SettingsSwitchCollectionViewCell.self)
        
        navigationItem.title = "Settings"

        let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: .plain, target: self, action: #selector(onBack))
        backItem.tintColor = .white
        navigationItem.leftBarButtonItem = backItem
    }
    
    // MARK: Navigation
    
    @objc private func onBack() {
        self.navigationController?.popViewController(animated: true)
    }
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == manageSegueIdentifier {
			let controller = segue.destination as! ManageAccountViewController
			controller.profileID = profileID
		} else {
			super.prepare(for: segue, sender: sender)
		}
	}
    
    // MARK: Private
    
    private func presentPasswordChangeAlert() {
        let alert = UIAlertController(title: nil, message: "Enter current password", preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "current password"
            field.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {[unowned self] action in
            guard let provided = alert.textFields?[0].text else {
                return
            }
            
            let user = Auth.auth().currentUser!
            let credential = EmailAuthProvider.credential(withEmail: user.email!, password: provided)
			user.reauthenticateAndRetrieveData(with: credential, completion: {[unowned self] (result, error) in
				let newAlert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
				
				guard error == nil else {
					newAlert.message = "Incorrect old password provided"
					newAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
					self.present(newAlert, animated: true, completion: nil)
					return
				}
				
				newAlert.message = "Enter new password twice"
				newAlert.addTextField(configurationHandler: { field in
					field.placeholder = "new password"
					field.isSecureTextEntry = true
				})
				newAlert.addTextField(configurationHandler: { field in
					field.placeholder = "confirm password"
					field.isSecureTextEntry = true
				})
				newAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: {[unowned self] action in
					let finalAlert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
					finalAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
					
					guard let password = newAlert.textFields?[0].text, password.count > 0, let confirmed = newAlert.textFields?[1].text, confirmed.count > 0 else {
						finalAlert.message = "Password must not be blank"
						self.present(finalAlert, animated: true, completion: nil)
						return
					}
					if password != confirmed {
						finalAlert.message = "Passwords did not match"
						self.present(finalAlert, animated: true, completion: nil)
					} else {
						Auth.auth().currentUser!.updatePassword(to: password) {[unowned self] error in
							guard error == nil else {
								finalAlert.message = "Error updating password. Please try again"
								self.present(finalAlert, animated: true, completion: nil)
								return
							}
							finalAlert.message = "Password updated successfully"
							self.present(finalAlert, animated: true, completion: nil)
						}
					}
				}))
				self.present(newAlert, animated: true, completion: nil)
			})
			
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func openPushNotificationsSettings() {
        let alert = UIAlertController(title: nil, message: "Go to notification settings?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
			UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func toggleAccountPrivacy() {
        guard profileID != nil else {
            print("No profile ID set!")
            return
        }
        
        let newValue = !showJoined
        showJoinedReference?.setValue(newValue)
    }
    
    // MARK: Init
    
    deinit {
        showJoinedReference!.removeObserver(withHandle: showJoinedObserverHandle!)
    }
    
    // MARK: Properties
    
    var profileID: String? {
        didSet {
            showJoinedReference = Database.database().reference().child("v2/profile/\(profileID!)/show_joined")
            showJoinedObserverHandle = showJoinedReference!.observe(.value) {[unowned self] snapshot in
                if let value = snapshot.value as? Bool {
                   self.showJoined = value
                }
                if self.isViewLoaded {
                    self.settingsCollectionView.reloadItems(at: [IndexPath(item: SettingsRow.accountPrivacy.rawValue, section: 0)])
                }
            }
        }
    }
    
    var showJoinedReference: DatabaseReference?
    var showJoinedObserverHandle: UInt?
    var showJoined = true
    
    // MARK: Properties (Private)
    
    private enum SettingsRow: Int {
		case accountPrivacy = 0
		case password
        case notifications
		case manageAccount
        case terms
		case privacy
        case count
    }
    
    // MARK: Properties (Private Constant)
    
    private let labels = ["Set account to private", "Change password", "Push notifications", "Manage account", "View terms of service", "View privacy policy"]
	private let subLabels = ["Setting your account to private hides your activity from all users.", nil, nil, nil, nil, nil]
    private let termsSegueIdentifier = "termsSegue"
	private let privacySegueIdentifier = "privacySegue"
	private let manageSegueIdentifier = "manageAccountSegue"
    @IBOutlet private weak var settingsCollectionView: UICollectionView!
    
}
