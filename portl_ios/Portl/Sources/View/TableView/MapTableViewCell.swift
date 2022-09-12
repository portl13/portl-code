//
//  MapTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 2/17/20.
//  Copyright © 2020 Portl. All rights reserved.
//

import Foundation
import MapKit
import CSkyUtil

protocol MapTableViewCellDelegate: class {
	func mapTableViewCellRequestsDirections(_ mapTableViewCell: MapTableViewCell)
}

class MapTableViewCell: UITableViewCell, Named, MKMapViewDelegate {
	
	func configure(forLocation location: CLLocation) {
	
		let locationAnnotation = MKPointAnnotation()
		locationAnnotation.coordinate = location.coordinate
		mapView.addAnnotation(locationAnnotation)

		mapView.centerOnAnnotations(shouldIncludeUser: true, animated: false)
	}
		
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		guard !(annotation is MKUserLocation) else {
			return nil
		}
		
		let annotationView = MKAnnotationView()
		annotationView.image = UIService.getLocationMapMarker()
		annotationView.centerOffset = CGPoint(x: 0, y: -annotationView.image!.size.height / 2)
		annotationView.annotation = annotation
		return annotationView
	}
	
	// MARK: Private
	
	@IBAction private func requestDirections(_ sender: Any) {
		delegate?.mapTableViewCellRequestsDirections(self)
	}
	
	// MARK: Properties
	
	@IBOutlet var mapView: MKMapView!
	
	weak var delegate: MapTableViewCellDelegate?
	
	// MARK: Properties (Named)
	
	class var name: String {
		return "MapTableViewCell"
	}
}
