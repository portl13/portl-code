//
//  HomeMapViewController.swift
//  Portl
//
//  Copyright © 2018 Portl. All rights reserved.
//


import UIKit
import Service
import RxSwift
import CSkyUtil
import CoreData
import MapKit
import Firebase

class HomeMapViewController: HomeBaseContentViewController, NSFetchedResultsControllerDelegate, MKMapViewDelegate, HomeMapFilterViewControllerDelegate, EventPointAnnotationViewDelegate {
    
    // MARK: EventPointAnnotationViewDelegate
    
    func pointAnnotationViewRequestsEventDetail(_ event: PortlEvent) {
        let viewController = UIStoryboard(name: "event", bundle: nil).instantiateViewController(withIdentifier: "EventDetailsViewController") as! EventDetailsViewController
        viewController.event = event
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: HomeMapFilterViewControllerDelegate
    
    func mapFilterViewControllerUpdatedCategory(_ category: String, shouldDisplay: Bool) {
        if !shouldDisplay {
            hiddenCategories.insert(category)
        } else {
            hiddenCategories.remove(category)
        }
        
        refresh(category)
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is EventSearchItem else {
            return nil
        }
        
        let view: EventPointAnnotationView
        
        if let dequeuedView = mapView.dequeue(EventPointAnnotationView.self) {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = EventPointAnnotationView(annotation: annotation)
        }
        
        if let catKey = ((annotation as! EventSearchItem).event.categories.sortedArray(using: [NSSortDescriptor(key: "orderIndex", ascending: true)]).first as? EventCategory) {
            view.image = UIService.getMapPinImage(forCategory: catKey)
        }
        
        view.centerOffset = CGPoint(x: 0, y: -view.image!.size.height / 2)
        view.delegate = self
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.setCenter(view.annotation!.coordinate, animated: true)
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let key = categoryResultsControllers.filter({ (key, value) -> Bool in
            return value == controller
        }).first?.key {
            refresh(key)
        }
    }
    
    // MARK: IBAction
    
    @IBAction private func showMapSettings(_ sender: UIView) {
        UIView.animate(withDuration: 0.25, animations: {
            if sender === self.showMapFilterButton {
                self.showMapFilterButtonBottomSpaceConstraint.constant = self.mapFilterContainerView.frame.height + 16.0
            }
            else {
                self.showMapFilterButtonBottomSpaceConstraint.constant = 16.0
            }
            
            self.view.layoutIfNeeded()
        }, completion: { (isComplete) in
            if sender === self.showMapFilterButton {
                self.showMapFilterButton.isHidden = true
                self.hideMapFilterButton.isHidden = false
            }
            else {
                self.showMapFilterButton.isHidden = false
                self.hideMapFilterButton.isHidden = true
            }
        })
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showMapFilterButton.layer.cornerRadius = 16
        hideMapFilterButton.layer.cornerRadius = 16
        mapTypeButtonView.layer.cornerRadius = 16
        mapTypeImageView.layer.cornerRadius = 11
        
        paramsService.currentSearchParams.subscribe(onNext:{[unowned self] params in
            if self.searchParams != params {
                self.searchParams = params
                
                if self.isVisible {
                    self.reload()
                } else {
                    self.needsReload = true
                }
            }
        }).disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if needsReload {
            reload()
            needsReload = false
        }
        isVisible = true
		Analytics.setScreenName(nil, screenClass: "HomeMapViewController")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isVisible = false
    }
    
    // MARK: View Management
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "HomeMapFilterEmbedSegue" {
            segue.destination.view.translatesAutoresizingMaskIntoConstraints = false
            (segue.destination as! HomeMapFilterViewController).delegate = self
        }
        else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    // MARK: Private
    
    @IBAction private func toggleMapBackgroundType() {
        if mapView.mapType == .standard {
            mapView.mapType = .satellite
            mapTypeImageView.image = #imageLiteral(resourceName: "icon_type_map")
        } else {
            mapView.mapType = .standard
            mapTypeImageView.image = #imageLiteral(resourceName: "icon_type_earth")
        }
    }
    
    private func addMapAnnotations(_ key: String) {
        guard let items = categoryResultsControllers[key]?.fetchedObjects else {
            return
        }
        mapView.addAnnotations(items)
    }
    
    private func refresh(_ key: String) {
        if let items = categoryResultsControllers[key]?.fetchedObjects {
            mapView.removeAnnotations(items)
        }
        
        if !hiddenCategories.contains(key) {
            addMapAnnotations(key)
        }
        
		mapView.centerOnAnnotations()
    }
    
    private func reload() {
        guard let keys = searchParams?.categories?.map({$0.name}), let location = searchParams?.location, let startDate = searchParams?.adjustedDate, let distance = searchParams?.distance  else {
            return
        }
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.categoryResultsControllers.removeAll()
        self.searchIds.removeAll()
        
        for key in keys {
			self.portlService.getEvents(forCategory: key, location: location, distance: distance, startDate: startDate, withinDays: 1, page: 0).subscribe(onNext: { [unowned self, key] (searchId) in
                self.categoryResultsControllers[key] = self.portlService.fetchedResultsController(forEventSearchObjectId: searchId, delegate: self)
                self.searchIds[key] = searchId
                self.refresh(key)
                }, onError: { [unowned self] error in
                    print("Request for events by category failed for category \"\(key)\" : \(error)")
					self.presentErrorAlert(withMessage: nil, completion: {
						self.refresh(key)
					})
            }).disposed(by: disposeBag)
        }
    }
    
    // MARK: Properties (Private)
    
    private var homeMapFilterViewController: HomeMapFilterViewController!
    private var categoryResultsControllers = Dictionary<String, NSFetchedResultsController<EventSearchItem>>()
    private var searchIds = Dictionary<String, NSManagedObjectID>()
    private var selectedAnnotationView: MKAnnotationView?
    private var hiddenCategories = Set<String>()
    private var isVisible = false
    private let disposeBag = DisposeBag()
    
    // MARK: Properties (IBOutlet)
    
    @IBOutlet private weak var showMapFilterButton: UIButton!
    @IBOutlet private weak var hideMapFilterButton: UIButton!
    @IBOutlet private weak var mapTypeButtonView: UIView!
    @IBOutlet private weak var mapTypeImageView: UIImageView!
    @IBOutlet private weak var showMapFilterButtonBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mapFilterContainerView: UIView!
    @IBOutlet private weak var mapView: MKMapView!
}
