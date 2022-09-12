//
//  ShareFriendSelectViewController.swift
//  Portl
//
//  Created by Jeff Creed on 5/15/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import RxSwift
import CoreData

class ShareFriendSelectViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate {

	// MARK: UISearchBarDelegate
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		timer?.invalidate()
		filterText = searchText
		if searchText.count > 0 {
			timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: {[weak self] _ in
				self?.tableView.reloadData()
			})
		} else {
			tableView.reloadData()
		}
	}
	
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	
	// MARK: NSFetchedResultsControllerDelegate
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.reloadData()
	}
	
	// MARK: UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let numberOfRows = resultsToUse?.count ?? 0
		emptyLabel.isHidden = numberOfRows > 0 && !initialLoad
		initialLoad = false
		return numberOfRows
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let profile = resultsToUse?[indexPath.row]
		let cell = tableView.dequeue(UserSelectTableViewCell.self, for: indexPath)
		cell.resetCell()
		cell.configureCell(forProfile: profile!)
		cell.configureSelectButtonForSelectedState(uidsToSendTo.contains(profile!.uid))
		cell.showHR(indexPath.row < resultsToUse!.count - 1)
		return cell
	}
	
	// MARK: UITablViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
		
		if let profile = resultsToUse?[indexPath.row] {
			if uidsToSendTo.contains(profile.uid) {
				uidsToSendTo.remove(profile.uid)
			} else {
				uidsToSendTo.insert(profile.uid)
			}
		}
		
	}
	
	// MARK: Navigation
	
	@IBAction private func onClose(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}
	
	@IBAction private func segueToShareCreate(_ sender: Any) {
		performSegue(withIdentifier: ShareFriendSelectViewController.friendsToShareSegueIdentifier, sender: self)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == ShareFriendSelectViewController.friendsToShareSegueIdentifier {
			let controller = segue.destination as! ShareViewController
			controller.event = eventForShare
			controller.profileIDsForShare = uidsToSendTo
		} else {
			super.prepare(for: segue, sender: sender)
		}
	}
	
	// MARK: View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.registerNib(UserSelectTableViewCell.self)
		
		navigationItem.title = "Share"
		
		let closeItem = UIBarButtonItem(image: UIImage(named: "icon_close"), style: .plain, target: self, action: #selector(onClose(_:)))
		closeItem.tintColor = PaletteColor.light1.uiColor
		self.navigationItem.leftBarButtonItem = closeItem

		let nextItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(segueToShareCreate(_:)))
		nextItem.tintColor = PaletteColor.light1.uiColor
		nextItem.isEnabled = false
		self.navigationItem.rightBarButtonItem = nextItem
		rightBarButton = nextItem

		if let authID = Auth.auth().currentUser?.uid {
			firebaseService.getFriendProfiles(forUserID: authID) {[weak self] (profileIds, error) in
				if let strongSelf = self {
					guard error == nil else {
						strongSelf.presentErrorAlert(withMessage: error!.localizedDescription, completion: nil)
						return
					}
					strongSelf.spinnerView.isHidden = true
					strongSelf.friendProfilesResultsController = strongSelf.firebaseService.fetchedResultsControllerForProfiles(withIDs: profileIds, delegate: strongSelf)
					strongSelf.tableView.reloadData()
				}
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		registerForNotifications()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		unregisterObservers()
	}
	
	// MARK: Notifications
	
	private func registerForNotifications() {
		unregisterObservers()
		
		observerTokens.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: OperationQueue.main, using: { (notification) in
			guard let userInfo = notification.userInfo as? Dictionary<String, AnyObject>,
				let kbRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
				let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
					return
			}
			
			let convertedRect = self.view.convert(kbRect, from: nil)
			let intersectionHeight = convertedRect.intersection(self.view.bounds).integral.height
			
			UIView.animate(withDuration: animationDuration, animations: {
				self.additionalSafeAreaInsets.bottom = intersectionHeight - (self.view.superview?.safeAreaInsets.bottom ?? 0)
				self.view.layoutIfNeeded()
			})
		}))
		
		observerTokens.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main, using: { (notification) in
			guard let userInfo = notification.userInfo as? Dictionary<String, AnyObject>, let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
				return
			}
			
			UIView.animate(withDuration: animationDuration, animations: {
				self.additionalSafeAreaInsets.bottom = 0
				self.view.layoutIfNeeded()
			})
		}))
	}

	private func unregisterObservers() {
		for token in observerTokens {
			NotificationCenter.default.removeObserver(token)
		}
	}

	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		Injector.root?.inject(into: inject)
	}
	
	private func inject(firebaseService: FirebaseDataProviding) {
		self.firebaseService = firebaseService
	}
	
	// MARK: Properties (Public)
	
	var eventForShare: PortlEvent?
	
	// MARK: Properties (DI)
	
	private var firebaseService: FirebaseDataProviding!

	// MARK: Properties (Private)
	
	private var resultsToUse: [Profile]? {
		get {
			if let text = filterText, !text.isEmpty {
				return friendProfilesResultsController?.fetchedObjects?.filter { $0.username.lowercased().contains(text.lowercased()) }
			} else {
				return friendProfilesResultsController?.fetchedObjects
			}
		}
		set {}
	}
	
	private var friendProfilesResultsController: NSFetchedResultsController<Profile>?
	private var uidsToSendTo = Set<String>() {
		didSet {
			tableView.reloadData()
			rightBarButton?.isEnabled = uidsToSendTo.count > 0
		}
	}
	private var disposeBag = DisposeBag()
	private var initialLoad = true
	private var observerTokens = [Any]()
	private var timer: Timer?
	private var filterText: String?
	private var rightBarButton: UIBarButtonItem?
	
	@IBOutlet private weak var searchBar: UISearchBar!
	@IBOutlet private weak var tableView: UITableView!
	@IBOutlet private weak var spinnerView: UIView!
	@IBOutlet private weak var emptyLabel: UILabel!
	
	private static let friendsToShareSegueIdentifier = "friendsToShareSegue"
}
