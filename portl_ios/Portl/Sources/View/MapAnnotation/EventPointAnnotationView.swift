//
//  EventPointAnnotationView.swift
//  Portl
//
//  Created by Jeff Creed on 4/16/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import MapKit
import Service
import CSkyUtil

class EventPointAnnotationView: MKAnnotationView, EventCalloutViewDelegate, Named {
    // MARK: EventCalloutViewDelegate
    
    func calloutViewButtonPressed() {
        delegate?.pointAnnotationViewRequestsEventDetail((annotation as? EventSearchItem)!.event)
    }
    
    // MARK: Point
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // allows calloutview to capture touch events for it's button
        
        let rect = self.bounds
        var isInside = rect.contains(point)
        if !isInside {
            for view in self.subviews {
                isInside = view.frame.contains(point)
                if isInside { break }
            }
        }
        return isInside
    }
    
    // MARK: Init
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.canShowCallout = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.canShowCallout = false
    }
    
    // MARK: View Management
    
    private func addCalloutView(eventSearchItem: EventSearchItem) {
        let calloutView = UINib(nibName: EventCalloutView.name, bundle: nil).instantiate(EventCalloutView.self)
        calloutView.setEventSearchItem(eventSearchItem: eventSearchItem)
        calloutView.center = CGPoint(x: self.bounds.width / 2, y: -calloutView.bounds.height * 0.52)
        calloutView.delegate = self
        addSubview(calloutView)
        customCalloutView = calloutView
    }
    
    // MARK: Properties
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            addCalloutView(eventSearchItem: annotation as! EventSearchItem)
        } else {
            customCalloutView?.removeFromSuperview()
            customCalloutView = nil
        }
    }
    
    override var annotation: MKAnnotation? {
        willSet {
            customCalloutView?.setEventSearchItem(eventSearchItem: annotation as? EventSearchItem)
        }
    }
    
    // MARK: Properties
    
    weak var delegate: EventPointAnnotationViewDelegate?
    
    // MARK: Properties (Named)

    static var name = "EventPointAnnotationView"

    // MARK: Properties (Private)
    
    private var customCalloutView: EventCalloutView?
}
