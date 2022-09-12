//
//  EventDetailsViewController.swift
//  Portl
//
//  Created by Jeff Creed on 3/20/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import RxSwift
import SafariServices
import FirebaseStorage
import MapKit

class EventDetailsViewController: UIViewController, Named, StoryboardInstantiable, UITableViewDataSource, UITableViewDelegate, EventDetailsActionTableViewCellDelegate, SFSafariViewControllerDelegate, ShowMoreTableViewCellDelegate, MapTableViewCellDelegate {
	
	// MARK: MapTableViewCellDelegate
	
	func mapTableViewCellRequestsDirections(_ mapTableViewCell: MapTableViewCell) {
		getDirections()
	}
	
	// MARK: EventDetailsInfoTableViewCellDelegate
	
	func showMoreTableViewCellRequestsToggleShowMore(_ showMoreTableViewCell: ShowMoreTableViewCell) {
		shouldShowMoreAbout = !shouldShowMoreAbout
		self.tableView.reloadRows(at: [IndexPath(row: EventRow.info.rawValue, section: 0)], with: .fade)
	}
	
	// MARK: SFSafariViewControllerDelegate
	
	func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
		controller.delegate = nil
		self.tabBarController?.dismiss(animated: true, completion: nil)
	}
	
	// MARK: EventActionTableViewCellDelegate
	
	func eventActionTableViewCellDidSelectGoing(_ eventActionTableViewCell: EventDetailsActionTableViewCell) {
		guard authProfile != nil else {
			presentAuthAlert(forActionName: "mark events as going")
			return
		}
		let goingStatus = authProfile?.events?.going?[event!.identifier]?.goingStatus() ?? .none
		let actionDateString = firebaseDateFormatter.string(from: Date())
		let eventDateString = firebaseDateFormatter.string(from: event!.startDateTime as Date)
		let goingData = goingStatus == .going ? nil : FirebaseProfile.Events.GoingData(actionDate: actionDateString, status: "g", eventDate: eventDateString)
		profileService.setGoingData(goingData, forEventID: event!.identifier)
	}
	
	func eventActionTableViewCellDidSelectInterested(_ eventActionTableViewCell: EventDetailsActionTableViewCell) {
		guard authProfile != nil else {
			presentAuthAlert(forActionName: "mark events as interested")
			return
		}
		let goingStatus = authProfile?.events?.going?[event!.identifier]?.goingStatus() ?? .none
		let actionDateString = firebaseDateFormatter.string(from: Date())
		let eventDateString = firebaseDateFormatter.string(from: event!.startDateTime as Date)
		let goingData = goingStatus == .interested ? nil : FirebaseProfile.Events.GoingData(actionDate: actionDateString, status: "i", eventDate: eventDateString)
		profileService.setGoingData(goingData, forEventID: event!.identifier)
	}
	
	func eventActionTableViewCellDidSelectBookmark(_ eventActionTableViewCell: EventDetailsActionTableViewCell) {
		guard authProfile != nil else {
			presentAuthAlert(forActionName: "bookmark events")
			return
		}
		let isBookmarked = authProfile?.events?.favorite?[event!.identifier] != nil
		let actionDateString = firebaseDateFormatter.string(from: Date())
		let eventDateString = firebaseDateFormatter.string(from: event!.startDateTime as Date)
		let favoriteData = isBookmarked ? nil : FirebaseProfile.Events.EventActionData(actionDate: actionDateString, eventDate: eventDateString)
		profileService.setFavorite(favoriteData, forEventID: event!.identifier)
	}
	
	func eventActionTableViewCellDidSelectDirections(_ eventActionTableViewCell: EventDetailsActionTableViewCell) {
		getDirections()
	}
	
	func eventActionTableViewCell(_ eventActionTableViewCell: EventDetailsActionTableViewCell, requestsOpenExternalURL URL: URL) {
		presetSafariViewController(withURL: URL)
	}
	
	// MARK: UICollectionViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return rowsToUse.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch rowsToUse[indexPath.row] {
		case .image:
			let defaultImage = getDefaultImageForEventCategory()
			let cell = tableView.dequeue(EventDetailsImageTableViewCell.self, for: indexPath)
			cell.configure(withImageURL: event!.imageURL ?? event?.artist?.imageURL, fallbackImage: defaultImage)
			return cell
		case .action:
			let cell = tableView.dequeue(EventDetailsActionTableViewCell.self, for: indexPath)
			let goingStatus = authProfile?.events?.going?[event!.identifier]?.goingStatus() ?? .none
			let isBookmarked = authProfile?.events?.favorite?[event!.identifier] != nil
			cell.delegate = self
			cell.configure(withGoingStatus: goingStatus, isBookmarked: isBookmarked, ticketURLString: event!.ticketPurchaseUrl, infoURLString: event!.url)
			return cell
		case .info:
			let cell = tableView.dequeue(EventDetailsInfoTableViewCell.self, for: indexPath)
			let dateString = longDateFormatter.string(from: getAdjustedStartDate(date: event!.startDateTime as Date))
			var distanceString = "-"
			
			if let location = locationService.currentLocation {
				let distance = CLLocation(latitude: event!.venue.location.latitude, longitude: event!.venue.location.longitude).distance(from: location)
				distanceString = String(format: "%.1f Miles", (distance / 1609.34))
			}
			cell.delegate = self
			cell.configure(withEventTitle: event!.title, dateString: dateString, venueName: event!.venue.name, aboutInfo: event!.about, andDistanceString: distanceString, tableWidth: tableView.bounds.width, shouldShowMore: shouldShowMoreAbout)
			return cell
		case .source:
			let cell = tableView.dequeue(EventDetailsSourceLogoTableViewCell.self, for: indexPath)
			cell.configure(forEventSource: EventSource(rawValue: Int(event!.source))!)
			return cell
		case .attendees:
			let cell = tableView.dequeue(EventDetailsAttendeesTableViewCell.self, for: indexPath)
			cell.configure(withProfileIDs: firebaseEvent?.goingIDs() ?? [], goingCount: firebaseEvent?.goingCount ?? 0, interestedCount: firebaseEvent?.interestedCount ?? 0)
			return cell
		case .community:
			let cell = tableView.dequeue(EventDetailsCommunityTableViewCell.self, for: indexPath)
			cell.configure(withPostsCount: communityOverview?.messageCount ?? 0, imagesCount: communityOverview?.imageCount ?? 0, andCommentsCount: communityOverview?.commentCount ?? 0)
			return cell
		case .artist:
			let cell = tableView.dequeue(EventDetailsArtistTableViewCell.self, for: indexPath)
			let upcomingCount = event?.artist?.events?.filter({ (event) -> Bool in
				return (event as! PortlEvent).startDateTime as Date > Date()
			}).count ?? 0
			let recentCount = event?.artist?.events?.filter({ (event) -> Bool in
				return Date() > (event as! PortlEvent).startDateTime as Date
			}).count ?? 0
			let defaultImage = getDefaultImageForEventCategory()
			cell.configure(withArtistImageURL: event?.artist?.imageURL ?? event!.imageURL, fallbackImage: defaultImage, artistName: event?.artist?.name ?? "", upcomingEventCount: upcomingCount, recentEventCount: recentCount)
			return cell
		case .venue:
			let cell = tableView.dequeue(EventDetailsVenueTableViewCell.self, for: indexPath)
			let address = "\(event!.venue.address?.getStreetsString() ?? "") \(event!.venue.address?.getCityStateString() ?? "")"
			cell.configure(withVenueName: event!.venue.name ?? "", andVenueAddress: address)
			return cell
		case .map:
			let cell = tableView.dequeue(MapTableViewCell.self, for: indexPath)
			cell.configure(forLocation: event!.venue.location.toLocation())
			cell.delegate = self
			return cell
		}
	}
	
	// MARK: UICollectionViewDelegate

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
		
		switch rowsToUse[indexPath.row] {
		case .attendees:
			performSegue(withIdentifier: EventDetailsViewController.attendeesSegueIdentifier, sender: self)
		case .artist:
			if event?.artist == nil {
				performSegue(withIdentifier: EventDetailsViewController.venueSegueIdentifier, sender: self)
			} else {
				performSegue(withIdentifier: EventDetailsViewController.artistSegueIdentifier, sender: self)
			}
		case .venue:
			performSegue(withIdentifier: EventDetailsViewController.venueSegueIdentifier, sender: self)
		case .community:
			performSegue(withIdentifier: EventDetailsViewController.communitySegueIdentifier, sender: self)
		default:
			return
		}
	}

	// MARK: Private
	
	private func getDirections() {
		if let eventLocation = event?.venue.location {
			let coordinate = CLLocationCoordinate2DMake(eventLocation.latitude, eventLocation.longitude)
			let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
			mapItem.name = event?.venue.name
			mapItem.url = event?.venue.url.flatMap {URL(string: $0)}
			mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
		}
	}
	
	@IBAction private func onSwipeLeft(_ sender: UIGestureRecognizer) {
		guard let events = events, currentEventIndex >= 0, currentEventIndex < events.count - 1 else {
			return
		}
		
		let transition = CATransition()
		transition.duration = 0.5
		transition.type = .push
		transition.subtype = .fromRight
		transition.fillMode = .forwards
		transition.timingFunction = CAMediaTimingFunction(name: .default)
		view.layer.add(transition, forKey: nil)
		
		currentEventIndex += 1
		event = events[currentEventIndex]
		createDisposables()
	}
	
	@IBAction private func onSwipeRight(_ sender: UIGestureRecognizer) {
		guard let events = events, currentEventIndex > 0 else {
			return
		}
		
		let transition = CATransition()
		transition.duration = 0.5
		transition.type = .push
		transition.subtype = .fromLeft
		transition.fillMode = .backwards
		transition.timingFunction = CAMediaTimingFunction(name: .default)
		view.layer.add(transition, forKey: nil)
		
		currentEventIndex -= 1
		event = events[currentEventIndex]
		createDisposables()
	}
	
	private func presentAuthAlert(forActionName actionName: String) {
		guard presentedViewController == nil else {
			return
		}
		
		let alert = UIAlertController(title: nil, message: "You must sign in to \(actionName).", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Sign In", style: .default, handler: {[unowned self] (_) in
			self.tabBarController?.performSegue(withIdentifier: "signUpSegue", sender: nil)
		}))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		present(alert, animated: true, completion: nil)
	}

	private func getDefaultImageForEventCategory() -> UIImage {
		return UIService.defaultImageForEvent(event: event!)
	}
	
	private func getAdjustedStartDate(date: Date) -> Date {
		do {
			guard let params = try paramsService.currentSearchParams.value() else {
				return date
			}
			
			return Calendar.current.date(byAdding: .hour, value: -(params.hoursOffsetFromLocation ?? 0), to: date)!
		} catch {
			return date
		}
	}
	
	private func presetSafariViewController(withURL URL: URL) {
		let svc = SFSafariViewController(url: URL)
		svc.preferredBarTintColor = PaletteColor.dark2.uiColor
		svc.preferredControlTintColor = PaletteColor.light1.uiColor
		svc.delegate = self
		tabBarController?.present(svc, animated: true, completion: nil)
	}
	
	private func createDisposables() {
		if let unwrapped = event {
			eventService.clearEvent()
			eventDisposable = eventService.event
				.observeOn(MainScheduler.instance)
				.subscribe(onNext: {[weak self] firebaseEvent in
					self?.firebaseEvent = firebaseEvent
				})
			eventService.loadEvent(withEventID: unwrapped.identifier)
			
			let conversationID = ConversationService.getCommunityConversationID(fromEventID: unwrapped.identifier)

			conversationService.clearConversationOverviews()
			conversationService.createOverviewObservables(forIDs: [conversationID])
			
			conversationService.clearConversation()
			conversationOverviewDisposable = conversationService.conversationOverviews[conversationID]?
				.observeOn(MainScheduler.instance)
				.subscribe(onNext: {[weak self] firebaseConversationOverview in
					self?.communityOverview = firebaseConversationOverview
				})
			
			conversationService.loadConversationOverviews(forIDs: [conversationID])
		}
		
		profileDisposable = profileService.authenticatedProfile
			.observeOn(MainScheduler.instance)
			.subscribe(onNext: {[weak self] firebaseProfile in
				self?.authProfile = firebaseProfile
			})
		
		if let artistID = event?.artist?.identifier {
			artistDisposable = portlService.getArtist(forIdentifier: artistID)
				.observeOn(MainScheduler.instance)
				.subscribe(onNext: {[weak self] _ in
					if self?.isViewLoaded == true, let indexRow = self?.rowsToUse.firstIndex(of: .artist) {
						self?.tableView.reloadRows(at: [IndexPath(row: indexRow, section: 0)], with: .none)
					}
				})
		}
	}
	
	private func disposeDisposables() {
		eventDisposable?.dispose()
		profileDisposable?.dispose()
		conversationOverviewDisposable?.dispose()
		artistDisposable?.dispose()
	}
	
	@IBAction private func onShare(_ sender: Any) {
		guard authProfile != nil else {
			presentAuthAlert(forActionName: "share events")
			return
		}

		let alert = UIAlertController(title: nil, message: "Share Event", preferredStyle: .actionSheet)
		alert.addAction(UIAlertAction(title: "Livefeed", style: .default, handler: {[unowned self] (_) in
			guard self.authProfile?.showJoined ?? true else {
				self.presentErrorAlert(withMessage: "You can't share to the Livefeed with a private account.", completion: nil)
				return
			}
			
			if let event = self.event {
				let nav = UIStoryboard(name: "share", bundle: nil).instantiateViewController(withIdentifier: "ShareScene") as! UINavigationController
				let controller = nav.viewControllers[0] as! ShareViewController
				controller.event = event
				nav.modalPresentationStyle = .overFullScreen
				self.tabBarController?.present(nav, animated: true, completion: nil)
			}
		}))
		alert.addAction(UIAlertAction(title: "With a Friend", style: .default, handler: {[unowned self] (_) in
			if let event = self.event {
				let nav = UIStoryboard(name: "share", bundle: nil).instantiateViewController(withIdentifier: "ShareFriendSelectScene") as! UINavigationController
				let controller = nav.viewControllers[0] as! ShareFriendSelectViewController
				controller.eventForShare = event
				nav.modalPresentationStyle = .overFullScreen
				self.tabBarController?.present(nav, animated: true, completion: nil)
			}
		}))
		if let urlString = event?.url, let url = URL(string: urlString) {
			alert.addAction(UIAlertAction(title: "Other", style: .default, handler: {[unowned self] (_) in
				let controller = UIActivityViewController(activityItems: ["Check out this event I found using the PORTL Social Discovery mobile app. Find out more, and install PORTL for free at: https://portl.com\n\n", url], applicationActivities: nil)
				self.present(controller, animated: true, completion: nil)
			}))
		}
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		present(alert, animated: true, completion: nil)
	}
		
	// MARK: Navigation
	
	@IBAction private func onBack() {
		self.navigationController?.popViewController(animated: true)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == EventDetailsViewController.artistSegueIdentifier {
			let controller = segue.destination as! ArtistDetailsViewController
			controller.artist = event?.artist
		} else  if segue.identifier == EventDetailsViewController.venueSegueIdentifier {
			let controller = segue.destination as! VenueDetailsViewController
			controller.venue = event?.venue
		} else if segue.identifier == EventDetailsViewController.attendeesSegueIdentifier {
			let controller = segue.destination as! AttendeesViewController
			controller.eventID = event?.identifier
		} else if segue.identifier == EventDetailsViewController.communitySegueIdentifier {
			let controller = segue.destination as! CommunityViewController
			controller.eventID = event?.identifier
			controller.eventDate = event?.startDateTime as Date?
		}
	}
	
	// MARK: View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.navigationItem.title = "Event Details"
		let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: .plain, target: self, action: #selector(onBack))
		backItem.tintColor = PaletteColor.light1.uiColor
		self.navigationItem.leftBarButtonItem = backItem

		
		let shareItem = UIBarButtonItem(image: UIImage(named: "icon_action_share"), style: .plain, target: self, action: #selector(onShare))
		shareItem.tintColor = PaletteColor.light1.uiColor
		self.navigationItem.rightBarButtonItem = shareItem
		
		tableView.registerNib(EventDetailsImageTableViewCell.self)
		tableView.registerNib(EventDetailsActionTableViewCell.self)
		tableView.registerNib(EventDetailsInfoTableViewCell.self)
		tableView.registerNib(EventDetailsSourceLogoTableViewCell.self)
		tableView.registerNib(EventDetailsAttendeesTableViewCell.self)
		tableView.registerNib(EventDetailsCommunityTableViewCell.self)
		tableView.registerNib(EventDetailsArtistTableViewCell.self)
		tableView.registerNib(EventDetailsVenueTableViewCell.self)
		tableView.registerNib(MapTableViewCell.self)
		
		let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeRight))
		swipeRight.direction = .right
		view.addGestureRecognizer(swipeRight)
		
		let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeLeft))
		swipeLeft.direction = .left
		view.addGestureRecognizer(swipeLeft)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		createDisposables()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		disposeDisposables()
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		Injector.root!.inject(into: inject)
	}
	
	func inject(profileService: UserProfileService, uiService: AppearanceConfiguring, paramsService: HomeParametersService, longDateFormatter: LongDateFormatterQualifier, locationService: LocationProviding, eventService: EventService, firebaseDateFormatter: FirebaseDateFormatter, conversationService: ConversationService, portlService: PortlDataProviding) {
		self.profileService = profileService
		self.uiService = uiService
		self.paramsService = paramsService
		self.longDateFormatter = longDateFormatter.value
		self.locationService = locationService
		self.eventService = eventService
		self.firebaseDateFormatter = firebaseDateFormatter.value
		self.conversationService = conversationService
		self.portlService = portlService
	}
	
	// MARK: Properties
	
	@objc var event: PortlEvent? {
		willSet {
			if event != nil {
				disposeDisposables()
				shouldShowMoreAbout = false
			}
		}
		didSet {
			if isViewLoaded {
				UIView.performWithoutAnimation {
					tableView.reloadData()
				}
			}
		}
	}
	
	@objc var events: [PortlEvent]?
	@objc var currentEventIndex = -1
	
	private var firebaseEvent: FirebaseEvent? {
		didSet {
			if isViewLoaded {
				UIView.performWithoutAnimation {

				if firebaseEvent != nil {
					tableView.reloadRows(at: [IndexPath(row: EventRow.attendees.rawValue, section: 0)], with: .none)
				}
				}
			}
		}
	}
	
	private var authProfile: FirebaseProfile? {
		didSet {
			UIView.performWithoutAnimation {

			if isViewLoaded {
				tableView.reloadRows(at: [IndexPath(row: EventRow.action.rawValue, section: 0)], with: .none)
			}
			}
		}
	}
	
	private var communityOverview: FirebaseConversation.Overview? {
		didSet {
			UIView.performWithoutAnimation {

			if isViewLoaded {
				if communityOverview != nil {
					tableView.reloadRows(at: [IndexPath(row: EventRow.community.rawValue, section: 0)], with: .none)
				}
			}
			}
		}
	}
	
	private var rowsToUse: [EventRow] {
		guard event != nil else {
			return []
		}
		
		return event?.artist != nil ? EventDetailsViewController.rowsWithArtist : EventDetailsViewController.rowsWithoutArtist
	}
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var tableView: UITableView!
	
	private var uiService: AppearanceConfiguring!
	private var paramsService: HomeParametersService!
	private var locationService: LocationProviding!
	private var longDateFormatter: DateFormatter!
	private var firebaseDateFormatter: DateFormatter!

	private var profileService: UserProfileService!
	private var profileDisposable: Disposable?
	
	private var eventService: EventService!
	private var eventDisposable: Disposable?
	
	private var conversationService: ConversationService!
	private var conversationOverviewDisposable: Disposable?
	
	private var communityImageCountDisposable: Disposable?
	
	private var portlService: PortlDataProviding!
	
	private var artistDisposable: Disposable?
	
	private var shouldShowMoreAbout = false
	
	// MARK: Properties (Private Static)
	
	private static let artistSegueIdentifier = "artistSegue"
	private static let venueSegueIdentifier = "venueSegue"
	private static let attendeesSegueIdentifier = "attendeesSegue"
	private static let communitySegueIdentifier = "communitySegue"
	
	// MARK: Enum
	
	enum EventRow: Int {
		case image = 0
		case action
		case info
		case attendees
		case community
		case artist
		case venue
		case map
		case source
	}
	
	private static let rowsWithArtist: [EventRow] = [.image, .action, .info, .attendees, .community, .artist, .venue, .map, .source]
	private static let rowsWithoutArtist: [EventRow] = [.image, .action, .info, .attendees, .community, .venue, .map, .source]
	
	// MARK: Properties (Named)
	
	static let name = "EventDetailsViewController"
}
