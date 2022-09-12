//
//  EventListViewController.swift
//  Portl
//
//  Created by Jeff Creed on 4/27/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation
import CoreData
import Service
import CSkyUtil
import RxSwift

public class EventListViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, Named, StoryboardInstantiable, UICollectionViewDelegateFlowLayout {
    
    // MARK: NSFetchedResultsControllerDelegate
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.reloadData()
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return headerFormatter.string(from: sectionNameFormatter.date(from: sectionName)!)
    }
    
    // MARK: UICollectionViewDataSource
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return resultsController?.sections?.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultsController!.sections![section].numberOfObjects
    }
    
    // MARK: UICollectionViewDelegate
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(EventCollectionViewCell.self, for: indexPath)
        if let eventItem = resultsController?.object(at: indexPath) {
            cell.setEventItem(eventItem)
        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		let header = collectionView.dequeueReusableSupplementaryNamedView(EventListHeaderView.self, ofKind: UICollectionView.elementKindSectionHeader, for: indexPath)
        
        let section = resultsController!.sections![indexPath.section]
        header.setDateLabelText(text: section.indexTitle!)
    
        return header
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            eventForDetailSegue = resultsController!.object(at: indexPath).event
            performSegue(withIdentifier: "sid_event_details", sender: nil)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.size.width - 5) / 2, height: (collectionView.frame.size.width - 5) / 2 * 4 / 3)
    }
    
    // MARK: View Management
    
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sid_event_details", let event = eventForDetailSegue, let events = resultsController?.fetchedObjects?.compactMap({ (item) in return item.event}) {
            let controller = segue.destination as! EventDetailsViewController
            controller.event = event
            controller.events = events
			controller.currentEventIndex = events.firstIndex(of: event)!
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
        if bottomEdge > scrollView.contentSize.height {
            if !loadingMore {
                getNextPageOfResults()
            }
        }
    }
    
    // MARK: View Life Cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
		let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(onBack))
        backItem.tintColor = .white
        self.navigationItem.leftBarButtonItem = backItem
        
        collectionView.registerNib(EventCollectionViewCell.self)
        
        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.sectionHeadersPinToVisibleBounds = true
        
        getResultsController()
    }
    
    // MARK: Private
    
    private func getResultsController() {
        resultsController = portlService.fetchedResultsControllerWithDateSections(forEventSearchObjectId: searchID, delegate: self)
        collectionView.reloadData()
    }
    
    private func getNextPageOfResults() {
        loadingMore = true
        portlService.getNextPageOfEventCategorySearch(forEventSearchObjectId: searchID)?.subscribe(onNext: {[weak self] _ in
            self?.loadingMore = false
			self?.getResultsController()
        }, onError: {[weak self] _ in
            self?.loadingMore = false
			print("Request for more events failed for search with objectID: \(String(describing: self?.searchID))")
        }).disposed(by: disposeBag)
    }
    
    @objc private func onBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: Init
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        Injector.root!.inject(into: inject)
    }
    
    private func inject(dataProvider: PortlDataProviding, formatter: NoTimeDateFormatterQualifier, nameFormatter: ResultsControllerSectionFormatterQualifier) {
        portlService = dataProvider
        headerFormatter = formatter.value
        sectionNameFormatter = nameFormatter.value
    }
    
    // MARK: Properties
    
    var searchID: NSManagedObjectID!
    
    // MARK: Properties (Named)
    
    public static let name: String = "EventListViewController"
    
    // MARK: Properties (Private)
    
    private var resultsController: NSFetchedResultsController<EventSearchItem>?
    private var portlService: PortlDataProviding!
    private var headerFormatter: DateFormatter!
    private var sectionNameFormatter: DateFormatter!
    private var loadingMore = false {
        didSet {
            guard isViewLoaded else { return }
            
            if loadingMore {
                activityIndicator.startAnimating()
                UIApplication.shared.beginIgnoringInteractionEvents()
            } else {
                activityIndicator.stopAnimating()
                UIApplication.shared.endIgnoringInteractionEvents()
            }
        }
    }
    private var eventForDetailSegue: PortlEvent?
    
    // MARK: Properties (Private Constant)
    
    private let disposeBag = DisposeBag()
    
    // MARK: Properties (Private IBOutlet)
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
}
