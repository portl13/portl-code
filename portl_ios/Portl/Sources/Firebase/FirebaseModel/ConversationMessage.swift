//
//  ConversationMessage.swift
//  Service
//
//  Created by Jeff Creed on 4/29/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CoreData

public class ConversationMessage: NSManagedObject {
	public var imageHeight: Int? {
		get {
			return imageHeightValue?.intValue
		}
		set {
			imageHeightValue = newValue as NSNumber?
		}
	}
	
	public var imageWidth: Int? {
		get {
			return imageWidthValue?.intValue
		}
		set {
			imageWidthValue = newValue as NSNumber?
		}
	}
}
