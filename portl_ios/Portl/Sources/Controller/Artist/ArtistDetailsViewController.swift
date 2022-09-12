//
//  ArtistDetailsViewController.swift
//  Portl
//
//  Created by Jeff Creed on 12/3/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import RxSwift
import CoreData
import CSkyUtil

class ArtistDetailsViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate, ShowMoreTableViewCellDelegate, SegmentedControlTableViewCellDelegate, FollowButtonProvidingCellDelegate {
	// MARK: FollowButtonProvidingCellDelegate
	
	func followButtonProvidingCellPressedFollowButton(_ followButtonProvingCell: FollowButtonProvidingCell) {
		let isFollowing = (authProfile?.following?.getArtistIDs() ?? []).contains(artist!.identifier)
		profileService.setFollowing(!isFollowing, forArtistID: artist!.identifier)
	}
	
	// MARK: SegmentedControlTableViewCellDelegate
	
	func segmentedControlTableViewCell(_ segmentedControlTableViewCell: SegmentedControlTableViewCell, selectedIndex index: Int) {
		upcomingSelected = index == 0
		tableView.reloadSections(IndexSet(arrayLiteral: Section.events.rawValue), with: .none)
	}
	
	// MARK: ShowMoreTableViewCellDelegate
	
	func showMoreTableViewCellRequestsToggleShowMore(_ showMoreTableViewCell: ShowMoreTableViewCell) {
		shouldShowMoreBio = !shouldShowMoreBio
		tableView.reloadRows(at: [IndexPath(row: InfoRow.bio.rawValue, section: Section.info.rawValue)], with: .fade)
	}
	
	// MARK: UITableViewDataSource
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return Section.allCases.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch (Section(rawValue: section)!) {
		case .info:
			return InfoRow.allCases.count
		case .links:
			return 0
		case .events:
			if upcomingSelected {
				return upcomingEventsResultsController?.fetchedObjects?.count ?? 0
			} else {
				return pastEventsResultsController?.fetchedObjects?.count ?? 0
			}
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch (Section(rawValue: indexPath.section)!) {
		case .info:
			switch (InfoRow(rawValue: indexPath.row)!) {
			case .image:
				let cell = tableView.dequeue(ArtistImageTableViewCell.self, for: indexPath)
				let isFollowing = (authProfile?.following?.getArtistIDs() ?? []).contains(artist!.identifier)
				cell.configure(withImageURLString: artist!.imageURL, name: artist!.name, andIsFollowing: isFollowing)
				cell.followButtonDelegate = self
				return cell
			case .bio:
				let cell = tableView.dequeue(ArtistBioTableViewCell.self, for: indexPath)
				cell.configure(withAboutInfo: artist!.about, tableWidth: tableView.bounds.width, shouldShowMore: shouldShowMoreBio)
				cell.delegate = self
				return cell
			case .eventTab:
				let cell = tableView.dequeue(SegmentedControlTableViewCell.self, for: indexPath)
				cell.configure(withSegmentTitles: [ArtistDetailsViewController.upcomingTabLabel, ArtistDetailsViewController.recentTabLabel], selectedTitle: upcomingSelected ? ArtistDetailsViewController.upcomingTabLabel : ArtistDetailsViewController.recentTabLabel)
				cell.delegate = self
				return cell
			}
		case .links:
			return UITableViewCell()
		case .events:
			let cell = tableView.dequeue(ArtistEventTableViewCell.self, for: indexPath)
			let event = getEvent(indexPath)
			let dateComponents = Calendar.current.dateComponents(Set([Calendar.Component.day]), from: event.startDateTime as Date)
		
			cell.configure(forMonth: monthOnlyFormatter.string(from: event.startDateTime as Date).uppercased(), day: dateComponents.day!, eventTitle: event.title, relativeShortDateString: dateFormatter.string(from: event.startDateTime as Date), placeString: "\(event.venue.address!.getCityStateString()) - \(event.venue.name!)")
			return cell
		}
	}
	
	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		if InfoRow(rawValue: indexPath.row) == .bio && (artist?.about == nil || (artist?.about?.value.trimmingCharacters(in: .whitespacesAndNewlines).count ?? 0) == 0) {
			return 0.0
		}
		return UITableView.automaticDimension
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if InfoRow(rawValue: indexPath.row) == .bio && (artist?.about == nil || (artist?.about?.value.trimmingCharacters(in: .whitespacesAndNewlines).count ?? 0) == 0) {
			return 0.0
		}
		return UITableView.automaticDimension
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if indexPath.section == Section.events.rawValue {
			eventForSegue = getEvent(indexPath)
			performSegue(withIdentifier: ArtistDetailsViewController.eventDetailsSegueIdentifier, sender: self)
		}
	}
	
	// MARK: Private
	
	private func getEvent(_ indexPath: IndexPath) -> PortlEvent {
		let resultsController = upcomingSelected ? upcomingEventsResultsController : pastEventsResultsController
		return resultsController!.fetchedObjects![indexPath.row]
	}
	
	// MARK: Navigation
	
	@IBAction func onBack() {
		self.navigationController?.popViewController(animated: true)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == ArtistDetailsViewController.eventDetailsSegueIdentifier {
			let controller = segue.destination as! EventDetailsViewController
			controller.event = eventForSegue
		}
	}
	
	// MARK: Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		navigationItem.title = "Artist Details"
		
		let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: .plain, target: self, action: #selector(onBack))
		backItem.tintColor = PaletteColor.light1.uiColor
		self.navigationItem.leftBarButtonItem = backItem

		tableView.registerNib(ArtistImageTableViewCell.self)
		tableView.registerNib(ArtistBioTableViewCell.self)
		tableView.registerNib(SegmentedControlTableViewCell.self)
		tableView.registerNib(ArtistEventTableViewCell.self)
		tableView.rowHeight = UITableView.automaticDimension
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		portlService.getArtist(forIdentifier: artist!.identifier)
			.observeOn(MainScheduler.instance)
			.subscribe(onNext: {[weak self] (objectId: NSManagedObjectID) in
				if let strongSelf = self {
					strongSelf.upcomingEventsResultsController = strongSelf.portlService.fetchedResultsController(forArtistByIdObjectId: objectId, delegate: strongSelf, past: false)
					strongSelf.pastEventsResultsController = strongSelf.portlService.fetchedResultsController(forArtistByIdObjectId: objectId, delegate: strongSelf, past: true)
					strongSelf.tableView.reloadData()
				}
			}, onError: {[weak self] _ in
				if let strongSelf = self {
					print("Request for artist events failed for artist with identifier:\(strongSelf.artist!.identifier)")
				}
			}).disposed(by: disposeBag)

		profileDisposable = profileService.authenticatedProfile
		.observeOn(MainScheduler.instance)
		.subscribe(onNext: {[weak self] firebaseProfile in
			self?.authProfile = firebaseProfile
		})
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		profileDisposable?.dispose()
	}
	
	// MARK: Init
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		monthOnlyFormatter = DateFormatter()
		monthOnlyFormatter.dateFormat = "MMM"
		
		Injector.root!.inject(into: inject)
	}
	
	private func inject(portlService: PortlDataProviding, dateFormatter: DateFormatterQualifier, profileService: UserProfileService) {
		self.portlService = portlService
		self.dateFormatter = dateFormatter.value
		self.profileService = profileService
	}
	
	// MARK: Properties
	
	var artist: PortlArtist?
	
	// MARK: Properties (private)
	
	private var authProfile: FirebaseProfile? {
		didSet {
			UIView.performWithoutAnimation {
				if isViewLoaded {
					tableView.reloadRows(at: [IndexPath(row: InfoRow.image.rawValue, section: Section.info.rawValue)], with: .none)
				}
			}
		}
	}

	@IBOutlet private var tableView: UITableView!
	private var portlService: PortlDataProviding!
	private var profileService: UserProfileService!
	private var dateFormatter: DateFormatter!
	private var disposeBag = DisposeBag()
	private var shouldShowMoreBio = false
	private var upcomingSelected = true
	private var monthOnlyFormatter: DateFormatter!
	
	private var upcomingEventsResultsController: NSFetchedResultsController<PortlEvent>?
	private var pastEventsResultsController: NSFetchedResultsController<PortlEvent>?

	private var eventForSegue: PortlEvent?
	
	private var profileDisposable: Disposable?
	
	private enum Section: Int, CaseIterable {
		case info = 0
		case links
		case events
	}
	
	private enum InfoRow: Int, CaseIterable {
		case image = 0
		case bio
		case eventTab
	}
	
	// MARK: Properties (Private Static)
	
	private static let upcomingTabLabel = "Upcoming Events"
	private static let recentTabLabel = "Recent Events"
	private static let eventDetailsSegueIdentifier = "eventDetailsSegue"
}
