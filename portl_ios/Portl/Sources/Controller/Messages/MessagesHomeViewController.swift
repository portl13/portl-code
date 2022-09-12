//
//  MessageHomeViewController.swift
//  Portl
//
//  Created by Jeff Creed on 4/26/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import CoreData
import RxSwift

class MessagesHomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
	
	// MARK: NSFetchedResultsControllerDelegate
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.reloadData()
		emptyLabel.isHidden = overviewFetchedResultsController?.fetchedObjects?.count ?? 0 != 0
	}
	
	private func reloadTableView() {
		tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .none)

		spinnerView.isHidden = true
		emptyLabel.isHidden = overviewFetchedResultsController?.fetchedObjects?.count ?? 0 != 0
	}
	
	// MARK: UITableViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
		
		if tableView.isEditing {
			batchConversation(forIndexPath: indexPath)
		} else {
			if let overview = overviewFetchedResultsController?.object(at: indexPath) {
				overviewForSegue = overview
				DispatchQueue.main.async {
					self.performSegue(withIdentifier: self.conversationDetailSegueIdentifier, sender: self)
				}
			}
		}
	}
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return .none
	}
	
	// MARK: UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return overviewFetchedResultsController?.fetchedObjects?.count ?? 0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeue(ConversationOverviewTableViewCell.self, for: indexPath)
		cell.resetCell()
		
		if let overview = overviewFetchedResultsController?.object(at: indexPath) {
			cell.configure(forOverview: overview, withRelativeDateFormatter: dateFormatter, isLastMessageArchived: archivedMessageKeys.contains(overview.lastMessageKey ?? ""))
			if let profile = overview.directProfile {
				cell.configure(forProfile: profile)
			}
			
			let hasUnread = unreadStatus[overview.conversationKey] ?? false
			cell.showHR(indexPath.row < overviewFetchedResultsController!.fetchedObjects!.count - 1, hasUnread: hasUnread)
			cell.setBatched(overviewBatch.contains(overview))
		}
		
		return cell
	}
	
	// MARK: Private
	
	@IBAction private func managedObjectsDidChangeHandler(notification: NSNotification) {
		reloadTableView()
	}
	
	private func getConversationOverviews() {
		let authProfileID = Auth.auth().currentUser!.uid
		firebaseService.getDirectConversationOverviews(forProfileID: authProfileID) {[weak self] (error) in
			if let strongSelf = self {
				strongSelf.overviewFetchedResultsController = strongSelf.firebaseService.fetchedResultsControllerForDirectConversationOverviews(forProfileID: authProfileID, delegate: strongSelf)
				
				strongSelf.reloadTableView()
			}
		}
	}

	@IBAction private func onEditCancel(_ sender: Any) {
		toggleEdit()
	}
	
	private func toggleEdit() {
		tableView.setEditing(!tableView.isEditing, animated: true)
		editCancelButton.title = tableView.isEditing ? "Cancel" : "Edit"
		overviewBatch.removeAll()

		UIView.animate(withDuration: 0.25) {
			self.batchActionsViewBottomConstraint.constant = self.tableView.isEditing ? 0 : -self.batchActionsView.bounds.height
			self.view.layoutIfNeeded()
		}
	}
	
	func batchConversation(forIndexPath indexPath:IndexPath) {
		let conversationOverview = overviewFetchedResultsController!.fetchedObjects![indexPath.row]
		
		if overviewBatch.contains(conversationOverview) {
			overviewBatch.remove(conversationOverview)
		} else {
			overviewBatch.insert(conversationOverview)
		}
		
		tableView.reloadRows(at: [indexPath], with: .none)
	}
	
	@IBAction private func archiveBatchedConversations(_ sender: Any) {
		presentDeleteConfirmationAlert(withMessage: "Delete selected conversations?") { (response) in
			if response {
				self.spinnerView.isHidden = false
				
				let total = self.overviewBatch.count
				var done = 0
				
				self.overviewBatch.forEach { (overview) in
					self.userProfileService.archiveConversation(withKey: overview.conversationKey, completion: {[weak self] (errorMessage) in
						guard errorMessage == nil else {
							self?.presentErrorAlert(withMessage: "Error deleting conversation.", completion: nil)
							return
						}
						self?.firebaseService.deleteConversationOverview(overview)
						done += 1
						
						if done == total {
							self?.spinnerView.isHidden = true
							self?.toggleEdit()
						}
					})
				}
			}
		}
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == conversationDetailSegueIdentifier {
			let controller = segue.destination as! DirectConversationViewController
			controller.conversationKey = overviewForSegue?.conversationKey
			controller.username = overviewForSegue?.directProfile?.username
			controller.profileId = overviewForSegue?.directProfile?.uid
		} else {
			super.prepare(for: segue, sender: sender)
		}
	}
	
	// MARK: Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.registerNib(ConversationOverviewTableViewCell.self)
		tableView.allowsSelectionDuringEditing = true
		
		navigationItem.title = "Messages"
		
		NotificationCenter.default.addObserver(forName: .authStateChanged, object: nil, queue: nil) {[weak self] (_) in
			if let user = Auth.auth().currentUser, !user.isAnonymous {
				self?.getConversationOverviews()
			} else {
				self?.overviewFetchedResultsController?.delegate = nil
				self?.overviewFetchedResultsController = nil
			}
		}
		
		navigationItem.rightBarButtonItem = editCancelButton
		
		self.getConversationOverviews()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		spinnerView.isHidden = false

		if overviewFetchedResultsController != nil {
			overviewFetchedResultsController!.delegate = self
			reloadTableView()
		}
		
		
		profileDisposable = userProfileService.authenticatedProfile.subscribe(onNext: {[weak self] profile in
			var keysToReload = Set<String>()
			
			self?.archivedMessageKeys = Set(profile?.conversation?.flatMap({ (arg: (key: String, value: FirebaseProfile.ConversationInfo)) -> Array<String> in
				let (_, info) = arg
				return info.archivedMessages?.keys.shuffled() ?? []
			}) ?? [])
			
			profile?.conversation?.forEach { profileConversation in
				let localUnread = self?.unreadStatus[profileConversation.key]
				if localUnread != profileConversation.value.hasNew {
					keysToReload.insert(profileConversation.key)
					self?.unreadStatus[profileConversation.key] = profileConversation.value.hasNew
				}
			}
			
			let indicesToReload = keysToReload.compactMap({ (key) -> IndexPath? in
				guard let conversation = self?.overviewFetchedResultsController?.fetchedObjects?.filter({$0.conversationKey == key}).first else {
					return nil
				}
				return self?.overviewFetchedResultsController?.indexPath(forObject: conversation)
			})
			
			self?.tableView.reloadRows(at: indicesToReload, with: .fade)
		})
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		overviewFetchedResultsController?.delegate = nil
		
		profileDisposable?.dispose()
	}

	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		Injector.root!.inject(into: inject)
		
		editCancelButton = UIBarButtonItem(title: "Edit", style: UIBarButtonItem.Style.plain, target: self, action: #selector(onEditCancel(_:)))
		editCancelButton.tintColor = PaletteColor.light1.uiColor
	}
	
	private func inject(firebaseService: FirebaseDataProviding, dateFormatter: DateFormatterQualifier, userProfileService: UserProfileService) {
		self.firebaseService = firebaseService
		self.dateFormatter = dateFormatter.value
		self.userProfileService = userProfileService
	}
	
	@IBOutlet private weak var tableView: UITableView!
	@IBOutlet private weak var emptyLabel: UILabel!
	@IBOutlet private weak var batchActionsView: UIView!
	@IBOutlet private weak var batchActionsViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet private weak var spinnerView: UIView!
	
	private var editCancelButton: UIBarButtonItem!
	
	private var firebaseService: FirebaseDataProviding!
	private var dateFormatter: DateFormatter!
	private var userProfileService: UserProfileService!
	
	private var overviewFetchedResultsController: NSFetchedResultsController<ConversationOverview>?
	private var overviewForSegue: ConversationOverview?
	
	private var profileDisposable: Disposable?
	private var unreadStatus = [String: Bool]()
	
	private let conversationDetailSegueIdentifier = "conversationDetailSegue"

	private var overviewBatch = Set<ConversationOverview>()
	
	private var archivedMessageKeys = Set<String>()
}
