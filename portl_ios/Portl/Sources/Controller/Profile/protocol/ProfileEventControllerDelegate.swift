//
//  ProfileEventControllerDelegate.swift
//  Portl
//
//  Created by Jeff Creed on 5/31/18.
//  Copyright © 2018 Portl. All rights reserved.
//

protocol ProfileEventControllerDelegate: class {
    func initiateEventDetailTransition(withEvent event:PortlEvent)
}
