//
//  ProfileEventsController.swift
//  Portl
//
//  Created by Jeff Creed on 5/31/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CoreData
import CSkyUtil
import Service
import CoreLocation

class ProfileEventsController: CollectionController<PortlEvent> {
    // MARK: UICollectionViewDatasource
   
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(EventCollectionViewCell.self, for: indexPath)
        let event = fetchedResultsController!.object(at: indexPath)
        let meters = locationService.currentLocation!.distance(from: CLLocation(latitude: event.venue.location.latitude, longitude: event.venue.location.longitude))
        cell.configureForEvent(event, withMeters: meters)
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.initiateEventDetailTransition(withEvent: fetchedResultsController!.object(at: indexPath))
    }
    
    override func configureCollectionView() {
        collectionView!.registerNib(EventCollectionViewCell.self)
        collectionView!.dataSource = self
        collectionView!.delegate = self
    }
    
    // MARK: Init
    
    init(locationService: LocationProviding) {
        self.locationService = locationService
        super.init()
    }
    
    weak var delegate: ProfileEventControllerDelegate?
    
    // MARK: Properties (Private)
    
    private let locationService: LocationProviding!
}
