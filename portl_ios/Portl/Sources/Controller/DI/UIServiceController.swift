//
//  UIServiceController.swift
//  Portl
//
//  Created by Jeff Creed on 4/29/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation
import CSkyUtil

@objc public class UIServiceController: NSObject {
    // MARK: Public
        
    @objc public func getDefaultImage(forEvent event: PortlEvent) -> UIImage {
        return UIService.defaultImageForEvent(event: event)
    }
	
    // MARK: Init
    
    public override init() {
        super.init()
        Injector.root!.inject(into: inject)
    }
    
    private func inject(uiService: AppearanceConfiguring) {
        self.uiService = uiService
    }
    
    // MARK: Properties
    
    var uiService: AppearanceConfiguring!
}
