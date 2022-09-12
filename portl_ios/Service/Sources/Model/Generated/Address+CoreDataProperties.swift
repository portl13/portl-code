//
//  Address+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 5/16/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension Address {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Address> {
        return NSFetchRequest<Address>(entityName: "Address")
    }
    
    @NSManaged public var street2: String?
    @NSManaged public var street: String?
    @NSManaged public var city: String?
    @NSManaged public var state: String?
    @NSManaged public var zipcode: String?
    @NSManaged public var country: String?
    @NSManaged public var venue: PortlVenue
    
    @objc
    public func getStreetsString() -> String {
        return CSVString(optionalStrings: [street, street2])
    }
    
    @objc
    public func getCityStateString() -> String {
        return CSVString(optionalStrings: [city, state ?? country])
    }
	
    private func CSVString(optionalStrings: [String?]) -> String {
        var format = ""
        var values = Array<String>()
        for s in optionalStrings.compactMap({ $0 }) {
            if s.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                if values.count > 0 {
                    format += ", "
                }
                format += "%@"
                values.append(s)
            }
        }
        
        return String(format: format, arguments: values)
    }
}
