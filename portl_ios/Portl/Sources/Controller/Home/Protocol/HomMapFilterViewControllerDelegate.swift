//
//  HomMapFilterViewControllerDelegate.swift
//  Portl
//
//  Created by Jeff Creed on 4/17/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation

protocol HomeMapFilterViewControllerDelegate: class {
    func mapFilterViewControllerUpdatedCategory(_ category: String, shouldDisplay: Bool)
}
