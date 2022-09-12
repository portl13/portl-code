//
//  FirebaseUtilsController.swift
//  Portl
//
//  Created by Jeff Creed on 2/8/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CSkyUtil

@objc public class FirebaseUtilsController: NSObject {
	@objc func isFirebaseSchemaDeprecated(completion: @escaping (String?) -> Void) {
		firebaseUtils.isSchemaDeprecated(completion: completion)
	}
	
	// MARK: Init
	
	override public init() {
		super.init()
		Injector.root!.inject(into: inject)
	}
	
	private func inject(firebaseUtils: FirebaseUtils) {
		self.firebaseUtils = firebaseUtils
	}
	
	// MARK: Properties (Private)
	
	private var firebaseUtils: FirebaseUtils!
}
