//
//  ArtistDetailsServiceController.swift
//  Portl
//
//  Created by Jeff Creed on 5/3/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import Service
import RxSwift
import CoreData

@objc public class ArtistDetailsServiceController: NSObject {
	
	// MARK: Public
	
	@objc func requestArtistEventsFromService(withIdentifier identifier: String, completion: (() -> Void)? = nil) -> Void {
		portlService.getArtist(forIdentifier: identifier)
			.observeOn(MainScheduler.instance)
			.subscribe(onNext: {(objectId: NSManagedObjectID) in
				if let delegate = self.fetchedResultsControllerDelegate {
					self.upcomingEventsResultsController = self.portlService.fetchedResultsController(forArtistByIdObjectId: objectId, delegate: delegate, past: false)
					self.pastEventsResultsController = self.portlService.fetchedResultsController(forArtistByIdObjectId: objectId, delegate: delegate, past: true)
				}
				if let completion = completion {
					completion()
				}
			}, onError: { _ in
				print("Request for artist events failed for artist with identifier:\(identifier)")
			}).disposed(by: disposeBag)
	}
	
	@objc func upcomingEventAtIndex(_ idx: Int) -> PortlEvent {
		return upcomingEventsResultsController!.fetchedObjects![idx]
	}
	
	@objc func pastEventAtIndex(_ idx: Int) -> PortlEvent {
		return pastEventsResultsController!.fetchedObjects![idx]
	}
	
	@objc func dateStringForDate(_ date: Date) -> String {
		return dateFormatter.string(from: date)
	}
	
	// MARK: Init
	
	public override init() {
		super.init()
		Injector.root!.inject(into: inject)
	}
	
	private func inject(portlService: PortlDataProviding, dateFormatter: LongDateFormatterQualifier, uiService: AppearanceConfiguring) {
		self.portlService = portlService
		self.dateFormatter = dateFormatter.value
		self.uiService = uiService
	}
	
	// MARK: Properties (private)
	
	private var portlService: PortlDataProviding!
	private var dateFormatter: DateFormatter!
	private var uiService: AppearanceConfiguring!
	private var disposeBag = DisposeBag()
	
	// MARK: Properties
	
	@objc weak var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?
	
	@objc var upcomingEventsResultsController: NSFetchedResultsController<PortlEvent>?
	@objc var upcomingCount: Int  {
		get {
			return upcomingEventsResultsController?.fetchedObjects?.count ?? 0
		}
	}
	@objc var upcomingEvents: [PortlEvent] {
		get {
			return upcomingEventsResultsController?.fetchedObjects ?? []
		}
	}
	@objc var pastEventsResultsController: NSFetchedResultsController<PortlEvent>?
	@objc var pastCount: Int {
		get {
			return pastEventsResultsController?.fetchedObjects?.count ?? 0
		}
	}
	@objc var pastEvents: [PortlEvent] {
		get {
			return pastEventsResultsController?.fetchedObjects ?? []
		}
	}
}

