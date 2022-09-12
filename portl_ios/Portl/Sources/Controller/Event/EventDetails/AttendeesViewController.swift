//
//  AttendeesViewController.swift
//  Portl
//
//  Created by Jeff Creed on 3/25/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import RxSwift

class AttendeesViewController: ConnectBaseViewController, UITableViewDataSource, UITableViewDelegate {
	
	// MARK: UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return idsToUse?.count ?? 0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let profileID = idsToUse![indexPath.row]
		let cell = tableView.dequeue(ConnectHomeUserTableViewCell.self, for: indexPath)
		var buttonStyle = ConnectButtonStyle.notConnected
		if friendUids.contains(profileID) {
			buttonStyle = .connected
		} else if sentPendingUids.contains(profileID) {
			buttonStyle = .sentPending
		} else if receivedPendingUids.contains(profileID) {
			buttonStyle = .receivedPending
		}
		
		cell.configure(withProfileID: profileID, andConnectButtonStyle: buttonStyle, showHR: indexPath.row < self.idsToUse!.count-1)
		cell.delegate = self
		return cell
	}

	// MARK: UITableViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
		
		if let id = idsToUse?[indexPath.row] {
			idForSegue = id
			self.performSegue(withIdentifier: AttendeesViewController.profileSegueIdentifier, sender: self)
		}
	}
	
	// MARK: Private
	
	override func getUid(forCell cell: UITableViewCell) -> String? {
		guard let row = tableView.indexPath(for: cell)?.row, row < idsToUse?.count ?? 0, let uid = idsToUse?[row] else {
			return nil
		}
		return uid
	}
	
	@IBAction private func segmentSelected(_ sender: Any?) {
		segmentIndex = (sender as! UISegmentedControl).selectedSegmentIndex
	}
	
	override func reloadTable() {
		super.reloadTable()
		tableView.contentOffset = CGPoint(x: 0.0, y: 0.0)
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let controller = segue.destination as? ProfileViewController {
			controller.profileID = idForSegue
		}
	}
	
	@IBAction func onBack() {
		self.navigationController?.popViewController(animated: true)
	}
	
	// MARK: Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: .plain, target: self, action: #selector(onBack))
		backItem.tintColor = PaletteColor.light1.uiColor
		self.navigationItem.leftBarButtonItem = backItem

		tableView.registerNib(ConnectHomeUserTableViewCell.self)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		eventService.clearEvent()
		
		eventDisposable = eventService.event.subscribe(onNext: {[unowned self] firebaseEvent in
			self.firebaseEvent = firebaseEvent
		})
		
		if let id = eventID {
			eventService.loadEvent(withEventID: id)
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		eventDisposable?.dispose()
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		Injector.root!.inject(into: inject)
	}
	
	private func inject(profileService: UserProfileService, eventService: EventService) {
		self.profileService = profileService
		self.eventService = eventService
	}
	
	// MARK: Properties
	
	var eventID: String?

	// MARK: Properties (Private)
	
	@IBOutlet private weak var segmentedControl: UISegmentedControl!
	private var segmentIndex = 0 {
		didSet {
			reloadTable()
		}
	}
	
	private var eventService: EventService!
	private var profileService: UserProfileService!
	
	private var eventDisposable: Disposable?
	private var firebaseEvent: FirebaseEvent? {
		didSet {
			goingIDs = firebaseEvent?.going?.filter({ (goingData) -> Bool in
				return goingData.value.goingStatus() == FirebaseProfile.EventGoingStatus.going
			}).map({ (goingData) -> String in
				return goingData.key
			})
			interestedIDs = firebaseEvent?.going?.filter({ (goingData) -> Bool in
				return goingData.value.goingStatus() == FirebaseProfile.EventGoingStatus.interested
			}).map({ (goingData) -> String in
				return goingData.key
			})
			
			if isViewLoaded {
				reloadTable()
				segmentedControl.setTitle(String(format: AttendeesViewController.goingFormat, goingIDs?.count ?? 0), forSegmentAt: Segment.going.rawValue)
				segmentedControl.setTitle(String(format: AttendeesViewController.interestedFormat, interestedIDs?.count ?? 0), forSegmentAt: Segment.interested.rawValue)
			}
		}
	}

	private var interestedIDs: [String]?
	private var goingIDs: [String]?
	private var idsToUse: [String]? {
		get {
			switch Segment(rawValue: segmentIndex)! {
			case .going:
				return goingIDs
			case .interested:
				return interestedIDs
			}
		}
	}
	private var idForSegue: String?
	
	// MARK: Properties (Private Static)
	
	private static let goingFormat = "%d Going"
	private static let interestedFormat = "%d Interested"
	private static let profileSegueIdentifier = "profileSegue"
	
	// MARK: Enum
	
	enum Segment: Int, CaseIterable {
		case going = 0
		case interested
	}
}
