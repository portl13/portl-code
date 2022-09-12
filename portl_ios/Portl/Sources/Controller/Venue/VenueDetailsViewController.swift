//
//  VenueDetailsViewController.swift
//  Portl
//
//  Created by Jeff Creed on 12/4/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CoreData
import RxSwift
import CSkyUtil
import MapKit

class VenueDetailsViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate, FollowButtonProvidingCellDelegate, VenueInfoTableViewCellDelegate, SegmentedControlTableViewCellDelegate {
	// MARK: SegmentedControlTableViewCellDelegate
	
	func segmentedControlTableViewCell(_ segmentedControlTableViewCell: SegmentedControlTableViewCell, selectedIndex index: Int) {
		upcomingSelected = index == 0
		tableView.reloadSections(IndexSet(arrayLiteral: Section.events.rawValue), with: .none)
	}

	// MARK: VenueInfoTableViewCellDelegate
	
	func venueInfoTableViewCellRequestsDirections(_ venueInfoTableViewCell: VenueInfoTableViewCell) {
		openDirectionsToVenue(venueInfoTableViewCell)
	}
	
	// MARK: FollowButtonProvidingCellDelegate
	
	func followButtonProvidingCellPressedFollowButton(_ followButtonProvingCell: FollowButtonProvidingCell) {
		let isFollowing = (authProfile?.following?.getVenueIDs() ?? []).contains(venue!.identifier)
		profileService.setFollowing(!isFollowing, forVenueID: venue!.identifier)
	}

	// MARK: UITableViewDataSource
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return Section.allCases.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch (Section(rawValue: section)!) {
		case .info:
			return InfoRow.allCases.count
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
			case .follow:
				let cell = tableView.dequeue(VenueFollowTableViewCell.self, for: indexPath)
				let isFollowing = (authProfile?.following?.getVenueIDs() ?? []).contains(venue!.identifier)
				cell.configure(isFollowing: isFollowing)
				cell.followButtonDelegate = self
				cell.configure(forLocation: venue!.location.toLocation())
				return cell
			case .details:
				let cell = tableView.dequeue(VenueInfoTableViewCell.self, for: indexPath)
				var address = venue!.address?.getStreetsString() ?? ""
				let cityState = venue!.address?.getCityStateString() ?? ""
				if address.count > 0 {
					address += "\n\(cityState)"
				} else {
					address = cityState
				}
				
				var distanceString = "-"
				
				if let location = locationService.currentLocation {
					let distance = CLLocation(latitude: venue!.location.latitude, longitude: venue!.location.longitude).distance(from: location)
					distanceString = String(format: "%.1f Miles", (distance / 1609.34))
				}

				cell.configure(withVenueName: venue!.name ?? "", addressString: address, andDistanceString: distanceString)
				cell.delegate = self
				return cell
			case .eventTab:
				let cell = tableView.dequeue(SegmentedControlTableViewCell.self, for: indexPath)
				cell.configure(withSegmentTitles: [VenueDetailsViewController.upcomingTabLabel, VenueDetailsViewController.recentTabLabel], selectedTitle: upcomingSelected ? VenueDetailsViewController.upcomingTabLabel : VenueDetailsViewController.recentTabLabel)
				cell.delegate = self
				return cell
			}
		case .events:
			let cell = tableView.dequeue(VenueEventTableViewCell.self, for: indexPath)
			let event = getEvent(indexPath)
			
			var url: URL? = nil
			if let imageURL = event.imageURL ?? event.artist?.imageURL {
				url = URL(string: imageURL)
			}
			
			let fallbackImage = UIService.defaultImageForEvent(event: event)
			
			cell.configure(forEventTitle: event.title, relativeShortDateString: dateFormatter.string(from: event.startDateTime as Date), imageURL: url, fallbackImage: fallbackImage)

			return cell
		}
	}
	
	// MARK: UITableViewDelegate
	
	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableView.automaticDimension
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
		if indexPath.section == Section.events.rawValue {
			eventForSegue = getEvent(indexPath)
			performSegue(withIdentifier: VenueDetailsViewController.eventDetailsSegueIdentifier, sender: self)
		}
	}
	
	// MARK: Private
	
	private func getEvent(_ indexPath: IndexPath) -> PortlEvent {
		let resultsController = upcomingSelected ? upcomingEventsResultsController : pastEventsResultsController
		return resultsController!.fetchedObjects![indexPath.row]
	}

	@IBAction private func openDirectionsToVenue(_ sender: Any) {
		if let venueLocation = venue?.location {
			let coordinate = CLLocationCoordinate2DMake(venueLocation.latitude, venueLocation.longitude)
			let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
			mapItem.name = venue?.name
			mapItem.url = venue?.url.flatMap {URL(string: $0)}
			mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
		}
	}
	
	// MARK: Navigation
	
	@IBAction func onBack() {
		self.navigationController?.popViewController(animated: true)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == VenueDetailsViewController.eventDetailsSegueIdentifier {
			let controller = segue.destination as! EventDetailsViewController
			controller.event = eventForSegue
		}
	}

	// MARK: Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		navigationItem.title = "Venue Details"
		
		let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: .plain, target: self, action: #selector(onBack))
		backItem.tintColor = PaletteColor.light1.uiColor
		self.navigationItem.leftBarButtonItem = backItem

		let directionsItem = UIBarButtonItem(image: UIImage(named: "icon_directions"), style: .plain, target: self, action: #selector(openDirectionsToVenue))
		directionsItem.tintColor = PaletteColor.light1.uiColor
		self.navigationItem.rightBarButtonItem = directionsItem
		
		tableView.registerNib(VenueFollowTableViewCell.self)
		tableView.registerNib(VenueInfoTableViewCell.self)
		tableView.registerNib(SegmentedControlTableViewCell.self)
		tableView.registerNib(VenueEventTableViewCell.self)
		tableView.rowHeight = UITableView.automaticDimension
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		portlService.getVenue(forIdentifier: venue!.identifier)
			.observeOn(MainScheduler.instance)
			.subscribe(onNext: {[weak self] (objectId: NSManagedObjectID) in
				if let strongSelf = self {
					strongSelf.upcomingEventsResultsController = strongSelf.portlService.fetchedResultsController(forVenueByIdObjectId: objectId, delegate: strongSelf, past: false)
					strongSelf.pastEventsResultsController = strongSelf.portlService.fetchedResultsController(forVenueByIdObjectId: objectId, delegate:strongSelf, past: true)
					strongSelf.tableView.reloadData()
				}
			}, onError: {[weak self] _ in
				if let strongSelf = self {
					print("Request for venue events failed for venue with identifier:\(strongSelf.venue!.identifier)")
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
		
		Injector.root!.inject(into: inject)
	}
	
	private func inject(portlService: PortlDataProviding, dateFormatter: DateFormatterQualifier, profileService: UserProfileService, locationService: LocationProviding) {
		self.portlService = portlService
		self.dateFormatter = dateFormatter.value
		self.profileService = profileService
		self.locationService = locationService
	}
	
	// MARK: Properties
	
	var venue: PortlVenue?

	// MARK: Properties (Private)
		
	private var authProfile: FirebaseProfile? {
		didSet {
			UIView.performWithoutAnimation {
				if isViewLoaded {
					tableView.reloadRows(at: [IndexPath(row: InfoRow.follow.rawValue, section: Section.info.rawValue)], with: .none)
				}
			}
		}
	}

	@IBOutlet private weak var tableView: UITableView!
	
	private var portlService: PortlDataProviding!
	private var profileService: UserProfileService!
	private var locationService: LocationProviding!
	private var dateFormatter: DateFormatter!
	private var disposeBag = DisposeBag()
	private var upcomingSelected = true
	
	private var upcomingEventsResultsController: NSFetchedResultsController<PortlEvent>?
	private var pastEventsResultsController: NSFetchedResultsController<PortlEvent>?

	private var eventForSegue: PortlEvent?
	
	private var profileDisposable: Disposable?
	
	private enum Section: Int, CaseIterable {
		case info = 0
		case events
	}
	
	private enum InfoRow: Int, CaseIterable {
		case follow = 0
		case details
		case eventTab
	}
	
	// MARK: Properties (Private Static)
	
	private static let upcomingTabLabel = "Upcoming Events"
	private static let recentTabLabel = "Recent Events"
	private static let eventDetailsSegueIdentifier = "eventDetailsSegue"
}
