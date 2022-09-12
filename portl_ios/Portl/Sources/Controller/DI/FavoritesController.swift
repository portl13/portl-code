//
//  FavoritesController.swift
//  Portl
//
//  Created by Jeff Creed on 6/14/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import Service
import CoreData
import RxSwift
import CoreLocation

@objc public class FavoritesController: NSObject, NSFetchedResultsControllerDelegate {
    @objc func getAuthUserFavoriteEvents(completion: @escaping (Error?) -> Void) {
		if let ids = ((try? profileService.authenticatedProfile.value()?.events?.favorite?.map({ (favorite) -> String in
			favorite.key
		})) as [String]??), let unwrapped = ids {
			self.portlService.getEvents(forIDs: unwrapped).subscribe(onNext: { [unowned self] IDs in
				self.favoriteEventsResultsController = self.portlService.fetchedResultsController(forEventIDs: IDs, delegate: self)
				completion(nil)
				}, onError: { error in
					print("Request for bookmarked events failed: \(error)")
					completion(error)
			}).disposed(by: self.disposeBag)
		} else {
			completion(nil)
		}
    }
    
    @objc func getDistanceInMeters(fromEvent event: PortlEvent) -> Double {
        guard let currentLocation = locationService.currentLocation else {
            return 0.0
        }
        let location = event.venue.location
        let lat = location.latitude
        let lng = location.longitude
        return currentLocation.distance(from: CLLocation(latitude: lat, longitude: lng))
    }
    
    // MARK: Init
    
    public override init() {
        super.init()
        Injector.root!.inject(into: inject)
    }
    
    private func inject(profileService: UserProfileService, portlService: PortlDataProviding, locationService: LocationProviding) {
        self.portlService = portlService
        self.locationService = locationService
		self.profileService = profileService
    }
    
    // MARK: Properties
    
    @objc weak var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?
    
    @objc var favoriteEventsResultsController: NSFetchedResultsController<PortlEvent>?
    @objc var favoritesCount: Int  {
        get {
            return favoriteEventsResultsController?.fetchedObjects?.count ?? 0
        }
    }
    @objc var favoriteEvents: [PortlEvent] {
        get {
            return favoriteEventsResultsController?.fetchedObjects ?? []
        }
    }
    
    // MARK: Properties (Private)
    
    private var profileService: UserProfileService!
    private var portlService: PortlDataProviding!
    private var locationService: LocationProviding!
    private var disposeBag = DisposeBag()
}
