//
//  ProfileFriendsViewController.swift
//  Portl
//
//  Created by Jeff Creed on 9/12/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation

class ProfileFriendsViewController: ConnectBaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
	// MARK: UISearchBarDelegate
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		timer?.invalidate()
		reloadTable()
	}
	
	func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
		reloadTable()
	}
	
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	
	// MARK: UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if !initialLoad {
			noResultsView.isHidden = filteredProfiles.count > 0
		}
		
		return filteredProfiles.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let profile = filteredProfiles[indexPath.row]
		let cell = tableView.dequeue(ConnectHomeUserTableViewCell.self, for: indexPath)
		var buttonStyle = ConnectButtonStyle.notConnected
		let profileUid = profile[FirebaseKeys.ProfileKeys.uidKey] as! String
		if friendUids.contains(profileUid) {
			buttonStyle = .connected
		} else if sentPendingUids.contains(profileUid) {
			buttonStyle = .sentPending
		} else if receivedPendingUids.contains(profileUid) {
			buttonStyle = .receivedPending
		}
		cell.configure(withProfile: profile, andConnectButtonStyle: buttonStyle, showHR:true)
		cell.delegate = self
		return cell
	}
	
	// MARK: UITableViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if let id = filteredProfiles[indexPath.row][FirebaseKeys.ProfileKeys.uidKey] as? String {
			profileIDforSegue = id
			performSegue(withIdentifier: profileSegueIdentifier, sender: self)
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return ConnectHomeUserTableViewCell.heightForCell()
	}
	
	// MARK: Private
	
	@IBAction private func onBack() {
		self.navigationController?.popViewController(animated: true)
	}
	
	// MARK: ConnectBaseViewController
	
	override func getUid(forCell cell: UITableViewCell) -> String? {
		return filteredProfiles[tableView.indexPath(for: cell)!.row][FirebaseKeys.ProfileKeys.uidKey] as? String
	}
	
	// MARK: View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.registerNib(ConnectHomeUserTableViewCell.self)

		let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: .plain, target: self, action: #selector(onBack))
		backItem.tintColor = .white
		navigationItem.leftBarButtonItem = backItem
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		friends.getFriendProfiles(forUserID: profileID!) { (profiles, error) in
			guard error == nil else {
				self.presentErrorAlert(withMessage: nil, completion: {
					self.spinnerView.isHidden = true
				})
				return
			}
			self.initialLoad = false
			self.spinnerView.isHidden = true
			self.profiles = profiles.filter({ (p) -> Bool in
				(p[FirebaseKeys.ProfileKeys.uidKey] as! String) != Auth.auth().currentUser?.uid
			})
			self.reloadTable()
		}
	}
	
	// MARK: Properties
	
	var profileID: String?
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var searchBar: UISearchBar!
	private var timer: Timer?
	private var profiles = Array<Dictionary<String, Any>>()
	private var filteredProfiles: Array<Dictionary<String, Any>> {
		get {
			if searchBar.text?.isEmpty ?? true {
				return profiles
			} else {
				return profiles.filter({ (profile) -> Bool in
					(profile[FirebaseKeys.ProfileKeys.usernameDKey] as? String ?? "").range(of: searchBar.text!.lowercased()) != nil || (profile[FirebaseKeys.ProfileKeys.firstLastKey] as? String ?? "").range(of: searchBar.text!.lowercased()) != nil
				})
			}
		}
	}
}
