//
//  ConnectBaseViewController.swift
//  Portl
//
//  Created by Jeff Creed on 8/11/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import RxSwift

class ConnectBaseViewController: UIViewController, ConnectEnabledCellDelegate {
	// MARK: ConnectEnabledCellDelegate
	
	func connectEnabledCellDidSelectConnect(_ connectEnabledCell: ConnectEnabledCell) {
		guard let uid = getUid(forCell: connectEnabledCell as! UITableViewCell) else {
			return
		}
		friends.sendInvite(toUid: uid) {[weak self] (error) in
			if error != nil {
				self?.presentErrorAlert(withMessage: nil, completion: nil)
			}
			self?.tableView.reloadData()
		}
	}
	
	func connectEnabledCellDidSelectDisconnect(_ connectEnabledCell: ConnectEnabledCell) {
		guard let uid = getUid(forCell: connectEnabledCell as! UITableViewCell) else {
			return
		}
		showAlert(withMessage: "Remove from friends?") {[weak self] (_) in
			self?.friends.removeConnection(toUid: uid) {(error) in
				if error != nil {
					self?.presentErrorAlert(withMessage: nil, completion: nil)
				}
				self?.tableView.reloadData()
			}
		}
	}
	
	func connectEnabledCellDidSelectCancel(_ connectEnabledCell: ConnectEnabledCell) {
		guard let uid = getUid(forCell: connectEnabledCell as! UITableViewCell) else {
			return
		}
		showAlert(withMessage: "Delete connect request?") {[weak self] (_) in
			self?.friends.removeConnection(toUid: uid) {(error) in
				if error != nil {
					self?.presentErrorAlert(withMessage: nil, completion: nil)
				}
				self?.tableView.reloadData()
			}
		}
	}
	
	func connectEnabledCellDidSelectApprove(_ connectEnabledCell: ConnectEnabledCell) {
		guard let uid = getUid(forCell: connectEnabledCell as! UITableViewCell) else {
			return
		}
		FIRFriends.shared().acceptFriendInvitation(from: uid) {[weak self] (error) in
			if error != nil {
				self?.presentErrorAlert(withMessage: nil, completion: nil)
			}
			self?.tableView.reloadData()
		}
	}
	
	func connectEnabledCellDidSelectDecline(_ connectEnabledCell: ConnectEnabledCell) {
		guard let uid = getUid(forCell: connectEnabledCell as! UITableViewCell) else {
			return
		}
		showAlert(withMessage: "Ignore connect request?") {[weak self] (_) in
			self?.friends.removeConnection(toUid: uid) {(error) in
				if error != nil {
					self?.presentErrorAlert(withMessage: nil, completion: nil)
				}
				self?.tableView.reloadData()
			}
		}
	}
	
	func reloadTable() {
		tableView.reloadData()
	}
	
	// MARK: Private
	
	func getUid(forCell cell: UITableViewCell) -> String? {
		// override in subclass
		return nil
	}
	
	func showAlert(withMessage message: String, andCompletion completion: @escaping (UIAlertAction) -> Void) {
		let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: completion))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {[unowned self] (_) in
			self.tableView.reloadData()
		}))
		present(alert, animated: true, completion: nil)
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		
		if segue.identifier == profileSegueIdentifier, let id = profileIDforSegue {
			let controller = segue.destination as! ProfileViewController
			controller.profileID = id
		}
	}
	
	// MARK: View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		friends.friendProfiles.subscribe(onNext: {[unowned self] friends in
			self.friendResults = friends
		}).disposed(by: disposeBag)
		
		friends.sentPendingUids.subscribe(onNext: {[unowned self] sp in
			self.sentPendingUids = sp
		}).disposed(by: disposeBag)
		
		friends.receivedPendingUids.subscribe(onNext: {[unowned self] rp in
			self.receivedPendingUids = rp
		}).disposed(by: disposeBag)
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		Injector.root?.inject(into: inject)
	}
	
	private func inject(friends: Friends, profile: OldProfileService) {
		self.friends = friends
		self.profile = profile
	}
	
	// MARK: Properties (DI)
	
	var friends: Friends!
	var profile: OldProfileService!
	
	// MARK: Properties (Private)
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var noResultsView: UIView!
	@IBOutlet weak var spinnerView: UIView!
	
	var initialLoad = true
	
	func friendResultsDidSet() {
		friendUids = friendResults.map { $0[FirebaseKeys.ProfileKeys.uidKey] as! String }
		reloadTable()
	}
	
	var friendResults = Array<Dictionary<String, Any>>() {
		didSet {
			friendResultsDidSet()
		}
	}
	
	var friendUids = Array<String>()
	var sentPendingUids = Array<String>() {
		didSet {
			reloadTable()
		}
	}
	
	var receivedPendingUids = Array<String>() {
		didSet {
			reloadTable()
		}
	}
	
	var profileIDforSegue: String?
	
	let disposeBag = DisposeBag()
	
	// MARK: Private Const
	
	let profileSegueIdentifier = "profileSegue"
}
