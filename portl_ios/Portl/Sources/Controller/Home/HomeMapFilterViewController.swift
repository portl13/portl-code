//
//  HomeMapFilterViewController.swift
//  Portl
//
//  Copyright © 2018 Portl. All rights reserved.
//


import UIKit
import Service
import CSkyUtil
import RxSwift

class HomeMapFilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedKeys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(MapCategoryTableViewCell.self, for: indexPath)
        let key = sortedKeys[indexPath.row]
		let displayName = sortedDisplayKeys[indexPath.row]
		
		cell.configureWithCategory(key, displayName: displayName, showOnMap: !hiddenCategories.contains(key))
        cell.shouldShowHR(indexPath.row < sortedKeys.count - 1)
		
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)

        let cell = tableView.cellForRow(at: indexPath) as! MapCategoryTableViewCell
        
        let key = sortedKeys[indexPath.row]
		let displayName = sortedDisplayKeys[indexPath.row]

        let show = hiddenCategories.contains(key)
        
        if show {
            hiddenCategories.remove(key)
        } else {
            hiddenCategories.insert(key)
        }
        
		cell.configureWithCategory(key, displayName: displayName, showOnMap: show)
        delegate?.mapFilterViewControllerUpdatedCategory(key, shouldDisplay: !hiddenCategories.contains(key))
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        filtersTableView.registerNib(MapCategoryTableViewCell.self)
        
        serviceParams.subscribe(onNext: {[unowned self] params in
            if let categories = params?.categories {
				self.sortedKeys = categories.map({$0.name})
                self.sortedDisplayKeys = categories.map({$0.display})
            }
            
            if let location = params?.location {
				self.geocodeService.getCityName(forLatitude: location.coordinate.latitude, andLongitude: location.coordinate.longitude).subscribe(onNext: {[unowned self] (cityName) in
					if let cityName = cityName {
						self.tableLabel.attributedText = UIService.getMapFiltersTitleString(forLocationText: cityName)
					}
				}).disposed(by: self.disposeBag)
            } else {
                self.tableLabel.text = "Events"
            }
            
            self.filtersTableView.reloadData()
        }).disposed(by: disposeBag)
    }
    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        Injector.root!.inject(into: inject)
    }
    
	private func inject(paramsService: HomeParametersService, formatter: NoTimeDateFormatterQualifier, geocodeService: Geocoding) {
        serviceParams = paramsService.currentSearchParams
        dateFormatter = formatter.value
		self.geocodeService = geocodeService
    }
    
    // MARK: Properties
    
    weak var delegate: HomeMapFilterViewControllerDelegate?
    
    // MARK: Properties (Private Static Const)
    
    private static let verticalSpacing: CGFloat = 10.0
    private static let verticalMargins = 3
    
    // MARK: Properties (Private)
    
    private var hiddenCategories = Set<String>()
    private var sortedKeys = Array<String>()
	private var sortedDisplayKeys = Array<String>()
    private let disposeBag = DisposeBag()
    
    private var dateFormatter: DateFormatter!
    private var serviceParams: BehaviorSubject<SearchParameters?>!
	private var geocodeService: Geocoding!
	
    @IBOutlet private weak var filtersTableView: UITableView!
    @IBOutlet private weak var tableLabel: UILabel!
    @IBOutlet private weak var heightConstraint: NSLayoutConstraint!
}
