//
//  EventPointAnnotationViewDelegate.swift
//  Portl
//
//  Created by Jeff Creed on 5/1/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Service

protocol EventPointAnnotationViewDelegate: class {
    func pointAnnotationViewRequestsEventDetail(_ event: PortlEvent)
}
