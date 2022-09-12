//
//  ParamsServiceProviderContainer.swift
//  Service
//
//  Created by Jeff Creed on 4/12/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation
import CSkyUtil

public class SearchParamsProviderContainer: ProviderContainer {
    override public init() {
        super.init()
        
        self.provide(type: HomeParametersService.self).asSingleton().with {
            HomeParametersService()
        }
    }
}
