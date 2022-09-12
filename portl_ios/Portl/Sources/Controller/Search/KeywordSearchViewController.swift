//
//  KeywordSearchViewController.swift
//  Portl
//
//  Created by Jeff Creed on 5/11/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CoreData
import Service
import CSkyUtil
import RxSwift
import CoreLocation

enum SearchMode: String {
	case artist = "artist"
	case venue = "venue"
}

class KeywordSearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UITextFieldDelegate, UIScrollViewDelegate {
	// MARK: UIScrollViewDelegate
	
	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let offsetY = scrollView.contentOffset.y
		let contentHeight = scrollView.contentSize.height
		let resultCount = searchMode == .artist ? (artistFetchedResultsController?.fetchedObjects?.count ?? 0) : (venueFetchedResultsController?.fetchedObjects?.count ?? 0)
		let requestInProgress = loading.contains(searchMode.rawValue)
		let page = searchMode == .artist ? artistPage : venuePage
		
		if offsetY > contentHeight - scrollView.frame.size.height && !requestInProgress &&  resultCount == page * pageSize {
			if searchMode == .artist {
				artistPage = (resultCount / pageSize) + 1
			} else {
				venuePage = (resultCount / pageSize) + 1
			}
			requestMoreForSelectedSearch()
		}
	}
	
	// MARK: UITextFieldDelegate
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		closeKeyboardButton.isHidden = false
		if !textEntered {
			textField.textColor = PaletteColor.light1.uiColor
			textField.attributedText = nil
		}
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		closeKeyboardButton.isHidden = true
		if !textEntered {
			setTextFieldPlaceholder()
		}
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		performSearch()
		return true
	}
		
	@IBAction func textFieldDidChange(_ textField: UITextField) {
		textEntered = textField.text?.count ?? 0 > 0
		clearButton.isHidden = !textEntered
	}
	
	// MARK: NSFetchedResultsControllerDelegate
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		// check which controller, if current then refresh table
		tableView.reloadData()
	}
	
	// MARK: UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch searchMode {
		case .artist:
			return artistFetchedResultsController?.fetchedObjects?.count ?? 0
		case .venue:
			return venueFetchedResultsController?.fetchedObjects?.count ?? 0
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch searchMode {
		case .artist:
			let artistItem = artistFetchedResultsController!.object(at: indexPath)
			let cell = tableView.dequeue(ArtistSearchItemTableViewCell.self, for: indexPath)
			let defaultImage = UIService.defaultImageForArtist(artist: artistItem.artist)
			let shouldShowHR = indexPath.row < (artistFetchedResultsController?.fetchedObjects?.count ?? 0) - 1
			cell.configure(withArtistItem: artistItem, defaultImage: defaultImage, source: UIService.stringForEventSource(source: EventSource(rawValue: Int(artistItem.artist.source))!), shouldShowHR: shouldShowHR)
			return cell
		case .venue:
			let venueItem = venueFetchedResultsController!.object(at: indexPath)
			let cell = tableView.dequeue(VenueSearchItemTableViewCell.self, for: indexPath)
			let venueLocation = CLLocation(latitude: venueItem.venue.location.latitude, longitude: venueItem.venue.location.longitude)
			let distance = venueLocation.distance(from: localParams!.location!) / METERS_ONE_MILE
			let defaultImage = UIService.defaultImageForVenue(venue: venueItem.venue)
			let shouldShowHR = indexPath.row < (venueFetchedResultsController?.fetchedObjects?.count ?? 0) - 1
			cell.configure(withVenueItem: venueItem, defaultImage: defaultImage, source: UIService.stringForEventSource(source: EventSource(rawValue: Int(venueItem.venue.source))!), distanceString: String(format:"%.1f", distance), shouldShowHR: shouldShowHR)
			return cell
		}
	}
	
	// MARK: UITableViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
		
		// segue based on mode
		switch searchMode {
		case .artist:
			artistForDetailSegue = artistFetchedResultsController!.object(at: indexPath).artist
			performSegue(withIdentifier: artistDetailsSegue, sender: self)
		case .venue:
			venueForDetailSegue = venueFetchedResultsController!.object(at: indexPath).venue
			performSegue(withIdentifier: venueDetailsSegue, sender: self)
		}
	}
	
	// MARK: View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(onBack))
		backItem.tintColor = .white
		navigationItem.leftBarButtonItem = backItem
		navigationItem.title = "Search"

		tableView.registerNib(ArtistSearchItemTableViewCell.self)
		tableView.registerNib(VenueSearchItemTableViewCell.self)
		
		searchField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		textEntered = false
		setTextFieldPlaceholder()
		locationLabel.text = localParams?.locationName
		if let distanceValue = localParams?.distance {
			setDistanceLabel(distanceValue
			)
		}
	}
	
	// MARK: Navigation
	
	@objc private func onBack() {
		navigationController?.popViewController(animated: true)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == artistDetailsSegue {
			let viewController = segue.destination as! ArtistDetailsViewController
			viewController.artist = artistForDetailSegue!
		} else if segue.identifier == venueDetailsSegue {
			let viewController = segue.destination as! VenueDetailsViewController
			viewController.venue = venueForDetailSegue!
		}
	}
	
	// MARK: Private
	
	private func requestArtistsForKeyword() {
		guard let keyword = searchField.text else {
			return
		}
		
		configureViewForRequestBegin()
		
		portlService.getArtists(forKeyword: keyword).subscribe(onNext: { [unowned self] (artistByKeywordID: NSManagedObjectID) -> Void in
			self.artistFetchedResultsController = self.portlService.fetchedResultsController(forArtistByKeywordObjectID: artistByKeywordID, delegate: self)
			self.searchIDs[self.searchMode.rawValue] = artistByKeywordID
			self.configureViewForRequestComplete(.artist)
			}, onError: { _ in
				print("Request for artists failed for keyword:\(keyword)")
				self.artistFetchedResultsController = nil
				self.searchIDs.removeValue(forKey: SearchMode.artist.rawValue)
				self.configureViewForRequestComplete(.artist)
		}).disposed(by: disposeBag)
	}
	
	private func requestVenuesForKeyword() {
		guard let keyword = searchField.text else {
			return
		}
		
		if let location = localParams?.location, let withinDistance = localParams?.distance {
			configureViewForRequestBegin()
			
			portlService.getVenues(forKeyword: keyword, location: location, withinDistance: withinDistance).subscribe(onNext: { [unowned self] (venueByKeywordID: NSManagedObjectID) -> Void in
				self.venueFetchedResultsController = self.portlService.fetchedResultsController(forVenueByKeywordObjectID: venueByKeywordID, delegate: self)
				self.searchIDs[self.searchMode.rawValue] = venueByKeywordID
				self.configureViewForRequestComplete(.venue)
				}, onError: {_ in
					print("Request for venues failed for keyword:\(keyword)")
					self.venueFetchedResultsController = nil
					self.searchIDs.removeValue(forKey: SearchMode.venue.rawValue)
					self.configureViewForRequestComplete(.venue)
			}).disposed(by: disposeBag)
		} else {
			presentErrorAlert(withMessage: "Unable to determine search location", completion: nil)
		}
	}
	
	private func requestMoreForSelectedSearch() {
		guard let searchID = searchIDs[searchMode.rawValue] else {
			return
		}
		
		configureViewForRequestBegin()
		
		switch (searchMode) {
		case .artist:
			portlService.getNextPageOfArtistKeywordSearch(forArtistKeywordSearchObjectID: searchID)?.subscribe(onError: { _ in
				print("Request for more artists failed")
			}, onCompleted: { [unowned self] in
				self.configureViewForRequestComplete(.artist)
			}).disposed(by: disposeBag)
		case .venue:
			portlService.getNextPageOfVenueKeywordSearch(forVenueKeywordSearchObjectID: searchID)?.subscribe(onError: { _ in
				print("Request for more venues failed")
			}, onCompleted: { [unowned self] in
				self.configureViewForRequestComplete(.venue)
			}).disposed(by: disposeBag)
		}
	}
	
	private func configureViewForRequestBegin() {
		activityIndicatorView.isHidden = false
		loading.insert(searchMode.rawValue)
		noResultsLabel.isHidden = true
	}
	
	private func configureViewForRequestComplete(_ mode: SearchMode) {
		self.tableView.reloadData()
		loading.remove(mode.rawValue)
		configureLoadingViewForCurrentMode()
		
		switch searchMode {
		case .artist:
			noResultsLabel.isHidden = artistFetchedResultsController?.fetchedObjects?.count ?? 0 != 0
			artistPage = (artistFetchedResultsController?.fetchedObjects?.count ?? 0) / pageSize
		case .venue:
			noResultsLabel.isHidden = venueFetchedResultsController?.fetchedObjects?.count ?? 0 != 0
			venuePage = (artistFetchedResultsController?.fetchedObjects?.count ?? 0) / pageSize
		}
	}
	
	private func configureLoadingViewForCurrentMode() {
		activityIndicatorView.isHidden = !loading.contains(searchMode.rawValue)
	}
	
	private func setArtistMode() {
		if searchMode != .artist {
			searchMode = .artist
			configureLoadingViewForCurrentMode()
			tableView.reloadData()
			if !noResultsLabel.isHidden {
				noResultsLabel.isHidden = artistFetchedResultsController?.fetchedObjects?.count ?? 0 > 0
			}
			UIView.animate(withDuration: 0.2) {
				self.paramsHeightConstraint.constant = 0.0
				self.view.layoutIfNeeded()
			}
		}
	}
	
	private func setVenueMode() {
		if searchMode != .venue {
			searchMode = .venue
			configureLoadingViewForCurrentMode()
			tableView.reloadData()
			if !noResultsLabel.isHidden {
				noResultsLabel.isHidden = venueFetchedResultsController?.fetchedObjects?.count ?? 0 > 0
			}
			
			UIView.animate(withDuration: 0.2) {
				self.paramsHeightConstraint.constant = self.paramsOpenConstant
				self.view.layoutIfNeeded()
			}
		}
	}
	
	private func performSearch() {
		switch searchMode {
		case .artist:
			requestArtistsForKeyword()
			return
		case .venue:
			requestVenuesForKeyword()
			return
		}
	}
	
	@IBAction private func changeSearchMode(_ sender: UISegmentedControl) {
		sender.selectedSegmentIndex == 0 ? setArtistMode() : setVenueMode()
	}
	
	@IBAction private func clearSearch(_ sender: Any) {
		searchField.text = nil
		clearButton.isHidden = true
		textEntered = false
		if !searchField.isFirstResponder {
			setTextFieldPlaceholder()
		}
	}
	
	private func setTextFieldPlaceholder() {
		searchField.attributedText = NSAttributedString(string: hintText, textStyle: .h3, overrideColor: PaletteColor.dark3, overrideAlignment: nil)
	}
	
	@IBAction private func closeKeyboard(_ sender: Any) {
		searchField.resignFirstResponder()
	}
	
	@IBAction private func setLocation(_ sender: Any) {
        let alertController = UIAlertController(title: nil, message: "Please choose location to search events.", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Use my location", style: .default, handler: {[unowned self] (action) in
			self.locationService.performAuthorizedLocationAccess { (authorized) in
				self.toggleLocationLoad(loading: true)

				guard authorized == true, let location = self.locationService.currentLocation else {
					return
				}
				
				self.geocodeService.getCityName(forLatitude: location.coordinate.latitude, andLongitude: location.coordinate.longitude).subscribe(onNext: {[unowned self] (cityName) in
					self.locationLabel.text = "Use my location"
					self.localParams!.location = location
					self.localParams!.hoursOffsetFromLocation = 0
					self.localParams!.locationName = cityName
					self.toggleLocationLoad(loading: false)

				}).disposed(by: self.disposeBag)
			}
        }))
        
        alertController.addAction(UIAlertAction(title: "Enter address", style: .default, handler: {[unowned self] (action) in
            let addressController = UIAlertController(title: nil, message: "Enter address (city, street, or postal code)", preferredStyle: .alert)
            addressController.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "\"Portland\" or \"97209\" or \"6th Ave\""
            })
            addressController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                // get location for string and then string for location
                if let textField = addressController.textFields?[0], let text = textField.text, !text.isEmpty {
					self.toggleLocationLoad(loading: true)
					self.geocodeService.getLocation(forAddress: text).subscribe(onNext: {[unowned self] (result) in
						guard let address = result?.formattedAddress, address != "", let location = result?.location  else {
							self.toggleLocationLoad(loading: false)
							self.presentErrorAlert(withMessage: "Error getting map coordinates for \"\(text)\"", completion: nil)
							return
						}
						let newLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
						let myLocation = self.locationService.currentLocation!
						
						self.localParams!.location = newLocation
						
						let coder = CLGeocoder();
						coder.reverseGeocodeLocation(newLocation, completionHandler: { (placemarks, error) in
							guard error == nil else {
								self.presentErrorAlert(withMessage: "Error getting time zone information for \"\(text)\"", completion: nil)
								return
							}
							coder.reverseGeocodeLocation(myLocation, completionHandler: { (myPlacemarks, error) in
								guard error == nil else {
									self.presentErrorAlert(withMessage: "Error getting time zone information for current location", completion: nil)
									return
								}
								
								let myPlace = myPlacemarks?.last
								let myOffset = myPlace?.timeZone?.secondsFromGMT()
								let place = placemarks?.last
								let searchOffset = place?.timeZone?.secondsFromGMT()
								let offsetHours = ((myOffset ?? 0) - (searchOffset ?? 0)) / 60 / 60
								self.localParams!.hoursOffsetFromLocation = offsetHours
							})
						})
						
						self.localParams!.locationName = address
						self.locationLabel.text = address
						self.toggleLocationLoad(loading: false)
					}).disposed(by: self.disposeBag)
                }
                
                // todo: handle error of location not found??
            }))
            addressController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(addressController, animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

	private func toggleLocationLoad(loading: Bool) {
		locationLabel.isHidden = loading
		if (loading) {
			locationLoadingIndicator.startAnimating()
		} else {
			locationLoadingIndicator.stopAnimating()
		}
	}

	@IBAction private func setDistance(_ sender: Any) {
        let alertController = UIAlertController(title: nil, message: "Distance in miles", preferredStyle: .actionSheet)
        let createHandler = { [unowned self] (value: Double) in
            return { (action: UIAlertAction) in
                self.localParams!.distance = value
                self.setDistanceLabel(value)
            }
        }
        
        alertController.addAction(UIAlertAction(title: "1 mile", style: .default, handler: createHandler(1)))
        alertController.addAction(UIAlertAction(title: "2 miles", style: .default, handler: createHandler(2)))
        alertController.addAction(UIAlertAction(title: "5 miles", style: .default, handler: createHandler(5)))
        alertController.addAction(UIAlertAction(title: "10 miles", style: .default, handler: createHandler(10)))
        alertController.addAction(UIAlertAction(title: "50 miles", style: .default, handler: createHandler(50)))
        alertController.addAction(UIAlertAction(title: "100 miles", style: .default, handler: createHandler(100)))
        alertController.addAction(UIAlertAction(title: "Other", style: .default, handler: {[unowned self] (action) in
            let distanceController = UIAlertController(title: "Enter distance", message: nil, preferredStyle: .alert)
            
            distanceController.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "Enter distance"
                textField.keyboardType = .numbersAndPunctuation
            })
            distanceController.addAction(UIAlertAction(title: "Ok", style: .default, handler: {(action) in
                if let textField = distanceController.textFields?[0], let text = textField.text, let value = Double(text)  {
                    self.localParams!.distance = value
                    self.withinLabel.text = "\(Int(value)) mile" + (value > 1 ? "s" : "")
                }
            }))
            distanceController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            self.present(distanceController, animated: true)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true)
    }
	
	private func setDistanceLabel(_ value: Double) {
		withinLabel.text = "\(Int(value)) mile" + (value > 1 ? "s" : "")
	}

	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		searchMode = .artist
		
		super.init(coder: aDecoder)
		
		Injector.root!.inject(into: inject)
	}
	
	private func inject(portlService: PortlDataProviding, paramsService: HomeParametersService, locationService: LocationProviding, geocodeService: Geocoding) {
		self.portlService = portlService
		self.locationService = locationService
		self.geocodeService = geocodeService
	}
	
	// MARK: Properties
	
	var localParams: SearchParameters?

	// MARK: Properties (Private)
	
	private var portlService: PortlDataProviding!	
	private var artistFetchedResultsController: NSFetchedResultsController<ArtistKeywordSearchItem>?
	private var artistForDetailSegue: PortlArtist?
	private var venueFetchedResultsController: NSFetchedResultsController<VenueKeywordSearchItem>?
	private var venueForDetailSegue: PortlVenue?
	
	private var disposeBag = DisposeBag()
	private var searchMode: SearchMode
	private var loading = Set<String>()
	private var searchIDs = Dictionary<String, NSManagedObjectID>()
	private var textEntered = false
	
    // MARK: Properties (Private, Params)
    
	private var locationService: LocationProviding!
	private var geocodeService: Geocoding!

    private var dateFormatter: DateFormatter!

	// MARK: Properties (Private, IBOutlet)
	
	@IBOutlet private weak var tableView: UITableView!
	@IBOutlet private weak var activityIndicatorView: UIView!
	@IBOutlet private weak var noResultsLabel: UILabel!
	@IBOutlet private weak var searchField: UITextField!
	@IBOutlet private weak var segmentedControl: UISegmentedControl!
	@IBOutlet private weak var clearButton: UIButton!
	@IBOutlet private weak var locationLabel: UILabel!
	@IBOutlet private weak var withinLabel: UILabel!
	@IBOutlet private weak var paramsHeightConstraint: NSLayoutConstraint!
	@IBOutlet private weak var closeKeyboardButton: UIButton!
	@IBOutlet private weak var locationLoadingIndicator: UIActivityIndicatorView!
	
	private let paramsOpenConstant: CGFloat = 112.0
	private let hintText = "Search..."
	private let pageSize = 50
	private var venuePage = 1
	private var artistPage = 1
	
	// MARK: Properties (Private Constant)
	
	private let artistDetailsSegue = "artistDetailsSegue"
	private let venueDetailsSegue = "venueDetailsSegue"
}
