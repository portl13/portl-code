//
//  HomeBaseContentViewController.swift
//  Portl
//
//  Copyright © 2018 Portl. All rights reserved.
//


import UIKit
import CoreData
import Service
import CSkyUtil

class HomeBaseContentViewController: UIViewController {
    
    // MARK: Init
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        Injector.root!.inject(into: inject)
    }
    
    private func inject(dataProvider: PortlDataProviding, paramsService: HomeParametersService) {
        self.portlService = dataProvider
        self.paramsService = paramsService
    }
    
    var portlService: PortlDataProviding!
    var paramsService: HomeParametersService!
    var searchParams: SearchParameters?
    var needsReload: Bool = false
}

