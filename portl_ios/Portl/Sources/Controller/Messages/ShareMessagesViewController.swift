//
//  ShareMessagesViewController.swift
//  Portl
//
//  Created by Jeff Creed on 3/30/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CSkyUtil

class ShareMessagesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ShareMessageTableViewCellDelegate {
	
	// MARK: ShareMessageTableViewCellDelegate
	
	func shareMessageTableViewCellSelectedProfile(_ shareMessageTableViewCell: ShareMessageTableViewCell) {
		if let indexPath = tableView.indexPath(for: shareMessageTableViewCell), let parent = parent as? ShareMessagingViewController {
			parent.showProfileWithID(messages![indexPath.row].profileID)
		}
	}
	
	// MARK: UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return messages?.count ?? 0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let message = messages![indexPath.row]
		let cell = tableView.dequeue(ShareMessageTableViewCell.self, for: indexPath)
		let profileObservable = livefeedService.getProfileObservable(forProfileID: message.profileID)
		cell.configure(forMessage: message.message!, profileRx: profileObservable)
		cell.delegate = self
		return cell
	}
	
	// MARK: Private
	
	@IBAction private func refresh(_ sender: Any) {
		self.tableView.reloadData()
		self.refreshControl.endRefreshing()
	}
	
	// MARK: Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.registerNib(ShareMessageTableViewCell.self)
		
		tableView.refreshControl = refreshControl
		refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		Injector.root!.inject(into: inject)
	}
	
	private func inject(livefeedService: LivefeedService, notificationDateFormatter: FirebaseDateFormatter) {
		self.livefeedService = livefeedService
		self.notificationDateFormatter = notificationDateFormatter.value
	}
	
	// MARK: Properties

	@IBOutlet weak var tableView: UITableView!

	var conversation: FirebaseConversation? {
		didSet {
			if let convo = conversation, let convoMessages = convo.messages {
				messages = Array(convoMessages.sorted(by: { (one, other) -> Bool in
					let date1 = notificationDateFormatter.date(from: one.value.sent)!
					let date2 = notificationDateFormatter.date(from: other.value.sent)!
					return date1.compare(date2) == .orderedAscending
				}).map({ (keyVelue) -> FirebaseConversation.Message in
					keyVelue.value
				}).dropFirst())
			}
		}
	}
	
	var postedNew = false
	
	// MARK: Properties (Private)
	
	private var refreshControl = UIRefreshControl()
	
	private var livefeedService: LivefeedService!
	private var notificationDateFormatter: DateFormatter!
	
	private var messages: [FirebaseConversation.Message]? {
		didSet {
			if isViewLoaded {
				DispatchQueue.main.async {
					if oldValue == nil || self.postedNew {
						self.tableView.reloadData()
						self.tableView.contentOffset = CGPoint(x: 0, y: max(self.tableView.contentSize.height - self.tableView.bounds.height, 0))
						self.postedNew = false
					}
				}
			}
		}
	}
}
