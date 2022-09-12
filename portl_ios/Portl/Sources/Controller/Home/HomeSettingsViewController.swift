//
//  HomeSettingsViewController.swift
//  Portl
//
//  Copyright © 2018 Portl. All rights reserved.
//


import UIKit
import CSkyUtil
import Service
import RxSwift
import CoreLocation

class HomeSettingsViewController: UIViewController {
    
    // MARK: IBAction
    
    @IBAction private func cancel() {
        placeholderParams = backupParams
        configureViewFromServiceParams()
        delegate?.settingsViewControllerRequestsDismissal()
    }
    
    @IBAction private func applySettings() {
        if let params = placeholderParams {
            paramsService.updateSearchParameters(params)
        }
        delegate?.settingsViewControllerRequestsDismissal()
    }
    
    @IBAction private func setLocation() {
        let alertController = UIAlertController(title: nil, message: "Please choose location to search events.", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Use my location", style: .default, handler: {[unowned self] (action) in
			self.locationService.performAuthorizedLocationAccess(with: { (authorized) in
				self.toggleLocationLoad(loading: true)
				
				guard authorized == true, let location = self.locationService.currentLocation else {
					return
				}
				
				self.geocodeService.getCityName(forLatitude: location.coordinate.latitude, andLongitude: location.coordinate.longitude).subscribe(onNext: {[unowned self] (cityName) in
					self.locationLabel.text = "Use my location"
					self.placeholderParams!.location = location
					self.placeholderParams!.hoursOffsetFromLocation = 0
					self.placeholderParams!.locationName = cityName
					self.toggleLocationLoad(loading: false)

				}).disposed(by: self.disposeBag)
			})
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
						
						self.placeholderParams!.location = newLocation
						
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
								self.placeholderParams!.hoursOffsetFromLocation = offsetHours
							})
						})
						
						self.placeholderParams!.locationName = address
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
    
    @IBAction private func setDistance() {
        let alertController = UIAlertController(title: nil, message: "Distance in miles", preferredStyle: .actionSheet)
        let createHandler = { [unowned self] (value: Double) in
            return { (action: UIAlertAction) in
                self.placeholderParams!.distance = value
                self.distanceLabel.text = "\(Int(value)) mile" + (value > 1 ? "s" : "")
            }
        }
        
        alertController.addAction(UIAlertAction(title: "1 mile", style: .default, handler: createHandler(1)))
        alertController.addAction(UIAlertAction(title: "2 miles", style: .default, handler: createHandler(2)))
        alertController.addAction(UIAlertAction(title: "5 miles", style: .default, handler: createHandler(5)))
        alertController.addAction(UIAlertAction(title: "10 miles", style: .default, handler: createHandler(10)))
		alertController.addAction(UIAlertAction(title: "25 miles", style: .default, handler: createHandler(25)))
        alertController.addAction(UIAlertAction(title: "50 miles", style: .default, handler: createHandler(50)))
        alertController.addAction(UIAlertAction(title: "100 miles", style: .default, handler: createHandler(100)))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true)
    }
    
    @IBAction private func setStartingDate() {
        delegate?.settingsViewControllerRequestsDatePicker()
    }
    
    @IBAction private func segueToAdvancedSearch() {
        performSegue(withIdentifier: HomeSettingsViewController.keywordSearchSegueIdentifier, sender: self)
    }
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if (segue.identifier == HomeSettingsViewController.keywordSearchSegueIdentifier) {
			let advancedSearchViewController = segue.destination as! KeywordSearchViewController
			advancedSearchViewController.localParams = placeholderParams ?? backupParams
		}
	}
    
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewFromServiceParams()
		applyButton.layer.cornerRadius = 4
    }
    
    // MARK: Private
    
    private func configureViewFromServiceParams() {
        if let location = placeholderParams?.location {
			if location == locationService.currentLocation {
                locationLabel.text = "Use my location"
            } else {
				self.locationLabel.text = placeholderParams?.locationName
            }
        }
        
        if let within = placeholderParams?.distance {
            distanceLabel.text = "\(Int(within)) miles"
        }
        
        if let start = placeholderParams?.startingDate {
            dateLabel.text = dateFormatter.string(from: start)
        }
    }
	
	private func toggleLocationLoad(loading: Bool) {
		locationLabel.isHidden = loading
		if (loading) {
			locationSpinner.startAnimating()
		} else {
			locationSpinner.stopAnimating()
		}
	}
	
    // MARK: Init
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        Injector.root!.inject(into: inject)
        
        paramsService.currentSearchParams.subscribe(onNext: { [unowned self] params in
            self.placeholderParams = params
            self.backupParams = params
            if self.isViewLoaded {
                self.configureViewFromServiceParams()
            }
        }).disposed(by: disposeBag)
	}
    
	private func inject(paramsService: HomeParametersService, formatter: NoTimeDateFormatterQualifier, locationService: LocationProviding, geocodeService: Geocoding) {
        self.paramsService = paramsService
        dateFormatter = formatter.value
		self.locationService = locationService
		self.geocodeService = geocodeService
    }
    
    // MARK: Properties
    
    func setDateFromSettingsDateView(date: Date) {
        placeholderParams?.startingDate = date
        configureViewFromServiceParams()
    }
    
	weak var delegate: HomeSettingsViewControllerDelegate?
    
    // MARK: Properties (Private)
    
    private var paramsService: HomeParametersService!
	private var locationService: LocationProviding!
	private var geocodeService: Geocoding!
	
    private var placeholderParams: SearchParameters?
    private var backupParams: SearchParameters?
    private var dateFormatter: DateFormatter!
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var advancedButton: UIButton!
	@IBOutlet weak var locationSpinner: UIActivityIndicatorView!
	@IBOutlet weak var applyButton: UIButton!
	
	private static let keywordSearchSegueIdentifier = "AdvancedSearchSegue"
}
