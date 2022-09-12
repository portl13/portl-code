//
//  EventSearchItem+MKAnnotation.swift
//  Service
//
//  Created by Jeff Creed on 4/16/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import MapKit

extension EventSearchItem: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(event.venue.location.latitude, event.venue.location.longitude)
    }
    
    public var title: String? {
        return event.title
    }
    
    public var subtitle: String? {
        return event.venue.name
    }
}
