//
//  HomeListViewController.swift
//  Portl
//
//  Copyright © 2018 Portl. All rights reserved.
//


import UIKit
import CoreData
import Service
import CSkyUtil
import RxSwift
import Firebase

class HomeListViewController: HomeBaseContentViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, EventCategoryCollectionViewCellDelegate {
	
    // MARK: EventCollectionViewTableViewCellDelegate

    func eventCategoryCollectionViewCell(_ eventCategoryCollectionViewCell: EventCategoryCollectionViewCell, didSelectShowAllForCategory category: PortlCategory) {
        guard let id = searchIds[category.name] else {
            return
        }

        let viewController = EventListViewController.instance(from: UIStoryboard(name: "event", bundle: nil))
        viewController.searchID = id
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func eventCategoryCollectionViewCell(_ eventCategoryCollectionViewCell: EventCategoryCollectionViewCell, didSelectEvent event: PortlEvent, inCategory category: PortlCategory) {
        guard let eventCategoryController = eventCategoryControllers[category.name], let events = eventCategoryController.items?.map({ (item) -> PortlEvent in return item.event}), let idx = events.firstIndex(of: event) else {
            return
        }

        let viewController = UIStoryboard(name: "event", bundle: nil).instantiate(EventDetailsViewController.self)
        viewController.event = event
        viewController.events = events
        viewController.currentEventIndex = idx
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if emptyCategories.isEmpty {
			return populatedCategories.count
		} else {
			return populatedCategories.count + 1
		}
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if !emptyCategories.isEmpty && indexPath.row == populatedCategories.count {
			let cell = collectionView.dequeue(EmptyCategoriesCollectionViewCell.self, for: indexPath)
			
			cell.config(forCategoryNames: sortCategories(emptyCategories).map({$0.display}))
			cell.delegate = (parent as? HomeContainerViewController)
			
			return cell
		} else {
			let category = sortCategories(populatedCategories)[indexPath.row]
		
        	let cell = collectionView.dequeue(EventCategoryCollectionViewCell.self, for: indexPath)
        	cell.updateWith(category: category, eventCategoryController: eventCategoryControllers[category.name])
        	cell.delegate = self
        
        	return cell
		}
    }
  
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = CGSize()
		
		size = CGSize(width: self.view.frame.size.width, height: 255.0)
		
		if !emptyCategories.isEmpty && indexPath.row == populatedCategories.count {
			size = EmptyCategoriesCollectionViewCell.getSizeForCell(usingWidth: collectionView.bounds.width, andCategoryNames: sortCategories(emptyCategories).map({$0.display}))
		}
		
        return size
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.registerNib(EventCategoryCollectionViewCell.self)
        collectionView.registerNib(EmptyCategoriesCollectionViewCell.self)
		
		collectionView.contentInset = UIEdgeInsets(top: cityLabel.frame.height + contentInsetCityLabelMargin, left: 0.0, bottom: 0.0, right: 0.0)
        
        paramsService.currentSearchParams.subscribe(onNext: {[unowned self] params in
            if self.searchParams != params {
                self.searchParams = params
                
                if self.isVisible {
					if self.collectionView.numberOfItems(inSection: 0) > 0 {
						self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
					}
                    self.collectionView.reloadData()
					self.cityLabel.attributedText = NSAttributedString(string: params?.locationName ?? "", textStyle: .h3Bold)
					self.intiateCategoryRequests()
                } else {
                    self.needsReload = true
                }
            }
        }).disposed(by: disposeBag)
	}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
        if needsReload {
			cityLabel.attributedText = NSAttributedString(string: searchParams?.locationName ?? "", textStyle: .h3Bold)
			intiateCategoryRequests()
            needsReload = false
        }
        isVisible = true
		Analytics.setScreenName(nil, screenClass: "HomeListViewController")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isVisible = false
    }
    
    // MARK: Private
	
	@IBAction private func openSettingsOnParent(_ sender: Any) {
		(parent as! HomeContainerViewController).toggleSettings(self)
	}
	
	private func sortCategories(_ categories: Set<PortlCategory>) -> [PortlCategory] {
		let paramsCategories = searchParams!.categories!
		
		return categories.sorted(by: { (cat, other) -> Bool in
			return paramsCategories.firstIndex(of: cat)! < paramsCategories.firstIndex(of: other)!
		})
	}
    
    private func refresh(key: String) {
		collectionView.reloadData()
    }
	
    private func intiateCategoryRequests() {
		guard let categories = searchParams?.categories, let location = searchParams?.location, let startDate = searchParams?.adjustedDate, let distance = searchParams?.distance else {
            return
        }
		
        eventCategoryControllers.removeAll()
        searchIds.removeAll()
		populatedCategories = Set(categories)
		emptyCategories.removeAll()
		
        for category in categories {
			let key = category.name
			
			self.portlService.getEvents(forCategory: key, location: location, distance: distance, startDate: startDate, withinDays: nil, page: 0).subscribe(onNext: { [weak self] (searchId) in
				guard let strongSelf = self else {
					return
				}
                strongSelf.searchIds[key] = searchId
                
                // todo: want to create the searchController first to create the results controller with it as delegate directly
                let categoryController = EventCategoryController()
                if let resultsController = strongSelf.portlService.fetchedResultsController(forEventSearchObjectId: searchId, delegate: categoryController) {
                    categoryController.fetchedResultsController = resultsController
                    strongSelf.eventCategoryControllers[key] = categoryController
					if resultsController.fetchedObjects?.count ?? 0 == 0 {
						strongSelf.emptyCategories.insert(category)
						strongSelf.populatedCategories.remove(category)
					}
                }
				
                strongSelf.refresh(key: key)
			}, onError: { [weak self] error in
				guard let strongSelf = self else {
					return
				}
				print("Request for events by category failed for category \"\(key)\" : \(error)")
				strongSelf.presentErrorAlert(withMessage: nil, completion: {
					strongSelf.eventCategoryControllers[key] = EventCategoryController()
					strongSelf.refresh(key: key)
				})
            }).disposed(by: disposeBag)
        }
    }
    
    // MARK: Properties (Private)
    
    private var eventCategoryControllers = Dictionary<String, EventCategoryController>()
    private var searchIds = Dictionary<String, NSManagedObjectID>()
    private var isVisible = false
	
	private var populatedCategories = Set<PortlCategory>()
	private var emptyCategories = Set<PortlCategory>()
	
    // MARK: Properties (Private Constant)
    
    private let disposeBag = DisposeBag()
    private let contentInsetCityLabelMargin: CGFloat = 35.0
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var cityLabel: UILabel!
}
