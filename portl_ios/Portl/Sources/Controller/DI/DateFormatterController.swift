//
//  DateFormatterController.swift
//  Portl
//
//  Created by Jeff Creed on 4/30/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation
import CSkyUtil

@objc public class DateFormatterController: NSObject {
    
    // MARK: Public
    
    @objc public func getLongDateStringForDate(_ date: Date) -> String {
        return longFormatter.string(from: date)
    }
    
    @objc public func getMedDateStringForDate(_ date: Date) -> String {
        return medFormatter.string(from: date)
    }
    
    @objc public func getMedNoTimeDateStringForDate(_ date: Date) -> String {
        return medNoTimeFormatter.string(from: date)
    }
    
    // MARK: Init
    
    public override init() {
        super.init()
        Injector.root!.inject(into: inject)
    }
    
    private func inject(longFormatter: LongDateFormatterQualifier, medFormatter: DateFormatterQualifier, medNoTimeFormatter: NoTimeDateFormatterQualifier ) {
        self.longFormatter = longFormatter.value
        self.medFormatter = medFormatter.value
        self.medNoTimeFormatter = medNoTimeFormatter.value
    }
    
    // MARK: Properties
    
    var longFormatter: DateFormatter!
    var medFormatter: DateFormatter!
    var medNoTimeFormatter: DateFormatter!
}
