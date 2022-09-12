//
//  MKMapView+PORTL.swift
//  Portl
//
//  Created by Jeff Creed on 2/18/20.
//  Copyright © 2020 Portl. All rights reserved.
//

import Foundation
import MapKit

extension MKMapView {
	func centerOnLocation(_ location: CLLocation, withRadiusInMeters radiusInMeters: Double = 1000) {
		let regionRadius: CLLocationDistance = radiusInMeters
		let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
												  latitudinalMeters: regionRadius * 2.0,
												  longitudinalMeters: regionRadius * 2.0)
		setRegion(coordinateRegion, animated: true)
	}
	
	func centerOnAnnotations(shouldIncludeUser: Bool = false, animated: Bool = true) {
		var zoomRect = MKMapRect.null
        for annotation in annotations {
            if !(annotation is MKUserLocation) || shouldIncludeUser {
				let annotationPoint = MKMapPoint(annotation.coordinate)
				let pointRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 20.0, height: 20.000)
				zoomRect = zoomRect.union(pointRect)
            }
        }
				
        setVisibleMapRect(zoomRect, edgePadding: UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60), animated: animated)
	}
}
