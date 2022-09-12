//
//  HomeContainerViewController.swift
//  Portl
//
//  Copyright © 2018 Portl. All rights reserved.
//


import UIKit
import CSkyUtil
import Service
import CoreData
import RxSwift

class HomeContainerViewController: UIViewController, HomeSettingsViewControllerDelegate, NSFetchedResultsControllerDelegate, DatePickerViewControllerDelegate, InterestsSelectViewControllerDelegate, EmptyCategoriesCollectionViewCellDelegate {
	
	// MARK: EmptyCategoriesCollectionViewCellDelegate
	
	func emptyCategoriesCollectionViewCellDidSelectManageCategories(_ emptyCategoriesCollectionViewCell: EmptyCategoriesCollectionViewCell) {
		selectCategories(emptyCategoriesCollectionViewCell)
	}
	
	// MARK: NSFetchedResultsControllerDelegate
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		updateCategories()
	}
	
	// MARK: InterestsSelectViewControllerDelegate
	
	func interestsUpdated(to updated: Array<Dictionary<PortlCategory, Bool>>) {
		if Auth.auth().currentUser == nil || FIRPortlAuthenticator.shared().isGuestLogin() {
			currentCategories = updated.compactMap({ (dict) -> PortlCategory? in
				return dict.first!.value ? dict.first!.key : nil
			})
			userInterests = updated
			updateSearchParams()
			self.navigationController?.popViewController(animated: true)
		} else {
			interests.updateUserInterests(with: updated.map({ (pcDict) -> [String: Bool] in
				return [pcDict.first!.key.name: pcDict.first!.value]
			})) {[unowned self] (error) in
				self.updateCategories()
				self.navigationController?.popViewController(animated: true)
			}
		}
	}
	
	// MARK: DatePickerViewControllerDelegate
	
	func datePickerViewController(_ datePickerViewController: DatePickerViewController, didSelectDate date: Date) {
		let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
		let dateMinusTime = Calendar.current.date(from: components)!
		
		homeSettingsViewController.setDateFromSettingsDateView(date: dateMinusTime)
		datePickerViewController.dismiss(animated: true, completion: nil)
	}
	
	func datePickerViewControllerDidCancel(_ datePickerViewController: DatePickerViewController) {
		datePickerViewController.dismiss(animated: true, completion: nil)
	}
		
	// MARK: HomeSettingsViewControllerDelegate
	
	func settingsViewControllerRequestsDismissal() {
		toggleSettings(self)
	}
	
	func settingsViewControllerRequestsDatePicker() {
		self.performSegue(withIdentifier: "settingsDateSegue", sender: self)
	}
	
	// MARK: IBAction
	
	@IBAction private func showProfile(_ sender: Any) {
		if FIRPortlAuthenticator.shared().isGuestLogin() {
			initiatedSignup = true
			self.tabBarController?.performSegue(withIdentifier: "signUpSegue", sender: self)
		} else {
			let profileController = UIStoryboard(name: "profile", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
			if let userID = FIRPortlAuthenticator.shared().authorizedProfile?["uid"] as? String {
				profileController.profileID = userID
				self.navigationController?.pushViewController(profileController, animated: true)
			}
		}
	}
	
	@IBAction private func selectCategories(_ sender: Any) {
		let interestsViewController = UIStoryboard(name: "common", bundle: nil).instantiateViewController(withIdentifier: "InterestsSelectViewController") as! InterestsSelectViewController
		interestsViewController.initialInterests = userInterests
		interestsViewController.delegate = self
		self.navigationController?.pushViewController(interestsViewController, animated: true)
	}
	
	@IBAction private func toggleContentMode(_ sender: Any) {
		let newContentController: HomeBaseContentViewController
		if currentContentViewController === homeListViewController {
			// Switch to map
			
			toggleContentBarButtonItem.image = #imageLiteral(resourceName: "icon_listing")
			if let homeMapViewController = homeMapViewController {
				newContentController = homeMapViewController
			}
			else {
				let homeMapViewController = storyboard!.instantiateViewController(withIdentifier: "HomeMapViewController") as! HomeMapViewController
				self.homeMapViewController = homeMapViewController
				
				newContentController = homeMapViewController
			}
		}
		else {
			// Switch to list
			
			toggleContentBarButtonItem.image = #imageLiteral(resourceName: "icon_map_view")
			newContentController = homeListViewController
		}
		
		setContentViewController(newContentController)
	}
	
	@IBAction func toggleSettings(_ sender: Any) {
		UIView.animate(withDuration: 0.25, animations: {
			if self.contentTopSpaceConstraint.constant == 0 {
				self.contentTopSpaceConstraint.constant = self.settingsContainerView.frame.height
				self.contentDimmingView.isHidden = false
				self.contentDimmingView.alpha = 0.6
			}
			else {
				self.contentTopSpaceConstraint.constant = 0
				self.contentDimmingView.alpha = 0.0
				if self.datePickerTopConstraint.constant < 3 {
					self.datePickerTopConstraint.constant = 3
				}
			}
			
			self.view.layoutIfNeeded()
		}, completion: { (isComplete) in
			if self.contentDimmingView.alpha < 0.6 {
				self.contentDimmingView.isHidden = true
			}
		})
	}
	
	// MARK: Private
	
	private func setContentViewController(_ viewController: HomeBaseContentViewController) {
		guard viewController !== currentContentViewController else {
			return
		}
		
		currentContentViewController?.willMove(toParent: nil)
		addChild(viewController)
		
		viewController.view.frame = contentContainerView.frame
		viewController.view.translatesAutoresizingMaskIntoConstraints = false
		currentContentViewController?.view.removeFromSuperview()
		
		contentContainerView.addSubview(viewController.view)
		contentContainerView.addConstraint(viewController.view.topAnchor.constraint(equalTo: contentContainerView.topAnchor))
		contentContainerView.addConstraint(viewController.view.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor))
		contentContainerView.addConstraint(viewController.view.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor))
		contentContainerView.addConstraint(viewController.view.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor))
		
		currentContentViewController?.removeFromParent()
		viewController.didMove(toParent: self)
		
		currentContentViewController = viewController
	}
	
	private func updateCategories() {
		let defaultCategories = categoriesResultsController?.fetchedObjects ?? []
		if Auth.auth().currentUser == nil || FIRPortlAuthenticator.shared().isGuestLogin() {
			currentCategories = defaultCategories.filter { $0.defaultSelected }
			self.updateSearchParams()
		} else {
			interests.getCurrentUserInterests {[unowned self] (userInterests) in
				if userInterests.count > 0 {
					self.currentCategories = userInterests.compactMap({(userInterest) -> PortlCategory? in
						if let portlCatIdx = defaultCategories.firstIndex(where: { (pc) -> Bool in
							return pc.name == userInterest.first!.key && userInterest.first!.value as! Bool
						}), let portlCat = self.categoriesResultsController?.fetchedObjects?[portlCatIdx] {
							return portlCat
						} else {
							return nil
						}
					})
					self.userInterests = userInterests.compactMap({(userInterest) -> [PortlCategory: Bool]? in
						if let portlCatIdx = defaultCategories.firstIndex(where: { (pc) -> Bool in
							return pc.name == userInterest.first!.key
						}), let portlCat = self.categoriesResultsController?.fetchedObjects?[portlCatIdx] {
							return [portlCat: userInterest.first!.value as! Bool]
						} else {
							return nil
						}
					})
					// check if there are portl categories that user interests doesn't have
					// if so, add to user interests and update user interests on firebase
					if defaultCategories.count > self.userInterests.count {
						let interestsNames = Set(self.userInterests.flatMap { $0.keys })
						let missingFromInterests = defaultCategories.filter { !interestsNames.contains($0) }
						missingFromInterests.forEach {
							self.userInterests.append([$0: true])
						}
						self.interests.updateUserInterests(with: self.userInterests.map { return [$0.keys.first!.name: true] }) { (error) in
							self.updateCategories()
						}
					} else {
						self.updateSearchParams()
					}
				} else {
					self.currentCategories = defaultCategories.filter { $0.defaultSelected }
					self.updateSearchParams()
				}
			}
		}
	}
	
	private func updateSearchParams() {
		if initialRequest {
			let calendar = Calendar.current
			locationService.performAuthorizedLocationAccess {[unowned self] (authorized) in
				if authorized {					
					self.locationAlert?.dismiss(animated: true, completion: nil)
					self.locationAlert = nil
					
					if let location = self.locationService.currentLocation {
						self.geocodeService.getCityName(forLatitude: location.coordinate.latitude, andLongitude: location.coordinate.longitude).subscribe(onNext: {[unowned self] (cityName) in
							self.paramsService.updateSearchParameters(SearchParameters(location: location,
																					   distance: self.paramsService.distanceForSearch,
																					   startingDate: calendar.date(from: calendar.dateComponents([.year, .month, .day], from: Date())),
																					   categories: self.currentCategories,
																					   hoursOffsetFromLocation: 0,
																					   locationName: cityName
							))
							self.initialRequest = false
						}).disposed(by: self.disposeBag)
					}
				} else if self.locationAlert == nil {
					// not authorized for location
					
					let alert = UIAlertController(title: "Unauthorized", message: "This application requires access to your device's location to function properly.", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { [unowned self] _ in
						UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
						self.locationAlert = nil
					}))
					alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [unowned self] _ in
						self.locationAlert = nil
						self.paramsService.updateSearchParameters(SearchParameters(location: nil,
																				   distance: self.paramsService.distanceForSearch,
																				   startingDate: calendar.date(from: calendar.dateComponents([.year, .month, .day], from: Date())),
																				   categories: self.currentCategories,
																				   hoursOffsetFromLocation: 0,
																				   locationName: nil
						))
					}))
					self.locationAlert = alert
					self.present(alert, animated: true, completion: nil)
				}
			}
		} else {
			self.paramsService.updateSearchParameters(
				SearchParameters(location: nil,
								 distance: nil,
								 startingDate: nil,
								 categories: self.currentCategories,
								 hoursOffsetFromLocation: nil,
								 locationName: nil
				)
			)
		}
	}
	
	// MARK: View Management
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "HomeSettingsEmbedSegue" {
			homeSettingsViewController = segue.destination as? HomeSettingsViewController
			homeSettingsViewController.delegate = self
			homeSettingsViewController.view.translatesAutoresizingMaskIntoConstraints = false
		}
		else if segue.identifier == "HomeListEmbedSegue" {
			homeListViewController = segue.destination as? HomeListViewController
			currentContentViewController = homeListViewController
		}
		else if segue.identifier == "settingsDateSegue" {
			let controller = segue.destination as! DatePickerViewController
			controller.maxDate = nil
			controller.delegate = self
		}
		else {
			super.prepare(for: segue, sender: sender)
		}
	}
	
	// MARK: View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let titleImageView = UIImageView(image: #imageLiteral(resourceName: "navbar_logo"))
		titleImageView.contentMode = .center
		navigationItem.titleView = titleImageView
		
		let showProfileBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "icon_profile"), style: .plain, target: self, action: #selector(showProfile(_:)))
		showProfileBarButtonItem.tintColor = .white
		
		let selectCategoriesBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "icon_category"), style: .plain, target: self, action: #selector(selectCategories(_:)))
		selectCategoriesBarButtonItem.tintColor = .white
		
		navigationItem.leftBarButtonItems = [showProfileBarButtonItem, selectCategoriesBarButtonItem]
		
		let toggleContentBarButtonItem = UIBarButtonItem(image:#imageLiteral(resourceName: "icon_map_view"), style: .plain, target: self, action: #selector(toggleContentMode(_:)))
		toggleContentBarButtonItem.tintColor = .white
		
		let settingsBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "icon_search"), style: .plain, target: self, action: #selector(toggleSettings(_:)))
		settingsBarButtonItem.tintColor = .white
		
		navigationItem.rightBarButtonItems = [settingsBarButtonItem, toggleContentBarButtonItem]
		self.toggleContentBarButtonItem = toggleContentBarButtonItem
		
		NotificationCenter.default.addObserver(forName: .locationUpdateNotification, object: nil, queue: nil) { (_) in
			self.updateSearchParams()
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: gNotificationHomeButtonPressed), object: nil, queue: nil) { (_) in
			if self.currentContentViewController != self.homeListViewController {
				self.setContentViewController(self.homeListViewController)
				toggleContentBarButtonItem.image = #imageLiteral(resourceName: "icon_map_view")
			}
		}
		
		updateCategories()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if initiatedSignup && !FIRPortlAuthenticator.shared().isGuestLogin() {
			initiatedSignup = false
			let profileController = UIStoryboard(name: "profile", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
			profileController.profileID = Auth.auth().currentUser?.uid
			self.navigationController?.pushViewController(profileController, animated: true)
		}
	}
	
	// MARK: Initialization
	
	func inject(paramsService: HomeParametersService, locationService: LocationProviding, portlService: PortlDataProviding, interests: Interests, geocodeService: Geocoding, profileService: UserProfileService) {
		self.portlService = portlService
		self.paramsService = paramsService
		self.locationService = locationService
		self.interests = interests
		self.geocodeService = geocodeService
		self.profileService = profileService
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		Injector.root!.inject(into: inject)
		categoriesResultsController = portlService.fetchedResultsControllerForPortlCategories(delegate: self)
	}
	
	// MARK: Properties (Private - Injected)
	
	private var portlService: PortlDataProviding!
	private var paramsService: HomeParametersService!
	private var locationService: LocationProviding!
	private var interests: Interests!
	private var geocodeService: Geocoding!
	private var profileService: UserProfileService!
	
	// MARK: Properties (Private)
	
	private var homeSettingsViewController: HomeSettingsViewController!
	private var initiatedSignup = false
	private var homeListViewController: HomeListViewController!
	private var homeMapViewController: HomeMapViewController?
	private weak var currentContentViewController: HomeBaseContentViewController?
	private weak var toggleContentBarButtonItem: UIBarButtonItem!
	private var locationAlert: UIAlertController?
	private var currentCategories = Array<PortlCategory>()
	private var categoriesResultsController: NSFetchedResultsController<PortlCategory>?
	private var userInterests = Array<Dictionary<PortlCategory, Bool>>()
	private var initialRequest = true
	private var disposeBag = DisposeBag()
	
	// MARK: Properties (IBOutlet)
	
	@IBOutlet private weak var settingsContainerView: UIView!
	@IBOutlet private weak var contentTopSpaceConstraint: NSLayoutConstraint!
	@IBOutlet private weak var contentContainerView: UIView!
	@IBOutlet private weak var contentDimmingView: UIView!
	@IBOutlet private weak var datePickerContainerView: UIView!
	@IBOutlet private weak var datePickerTopConstraint: NSLayoutConstraint!
}
