//
//  PortlServiceProviderContainer.swift
//  Service
//
//  Created by Jeff Creed on 3/29/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import Alamofire
import CoreData
import APIEngine

public class PortlServiceProviderContainer: ProviderContainer {
    override public init() {
        super.init()
		
        self.provide(type: URLComponents.self).with {
            var urlComponents = URLComponents()
            urlComponents.scheme = "https"

			#if STAGING
            urlComponents.host = "api.staging.portl.com"
            #else
            urlComponents.host = "api.portl.com"
            #endif
            
            return urlComponents
        }
		
        self.provide(type: ResponseValidating.self).asSingleton().with {
            PortlResponseValidator.init()
        }
        
        self.provide(type: URLSessionConfiguration.self).asSingleton().with {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            
            var headers = SessionManager.defaultHTTPHeaders
            headers["Accept"] = "application/json; charset=UTF8"
            headers["Content-Type"] = "application/json"
            
            configuration.httpAdditionalHeaders = headers
            
            return configuration
        }
        
        self.provide(type: RequestAdapter.self).asSingleton().with { () -> RequestAdapter in
            return AuthRequestAdapter()
        }
		
		self.provide(type: DateFormatter.self).asSingleton().qualified(by: APIDeprecationDateFormatterQualifier.self).with {
			let dateFormatter = DateFormatter()
			dateFormatter.locale = Locale(identifier: "en_US")
			dateFormatter.dateStyle = .medium
			return dateFormatter
		}
		
		self.provide(type: SessionDelegate.self).asSingleton().with { (deprecationDateFormatter: APIDeprecationDateFormatterQualifier) -> SessionDelegate in
			return APISessionDelegate(deprecationDateFormatter: deprecationDateFormatter)
		}
		
		self.provide(type: SessionManager.self).asSingleton().with { (configuration: URLSessionConfiguration, requestAdapter: RequestAdapter, sessionDelegate: SessionDelegate) -> SessionManager in
            let sessionManager = SessionManager(configuration: configuration, delegate: sessionDelegate, serverTrustPolicyManager: nil)
            sessionManager.adapter = requestAdapter
            return sessionManager
        }
        
        self.provide(type: APIEngine.self).asSingleton().with{ (sessionManager: SessionManager, responseValidator: ResponseValidating) in
            return AlamofireAPIEngine(sessionManager: sessionManager, responseValidator: responseValidator)
        }
        
        self.provide(type: PortlAPI.self).asSingleton().with { (apiEngine: APIEngine, baseURLComponents: URLComponents) in
            return PortlAPI(apiEngine: apiEngine, baseURLComponents: baseURLComponents)
        }
        
        self.provide(type: NSPersistentContainer.self).asSingleton().with {
            let bundle = Bundle(for: PortlService.self)
            guard let modelURL = bundle.url(forResource: "Model", withExtension: "momd") else {
                fatalError("Error loading model from bundle")
            }
            
            let model = NSManagedObjectModel(contentsOf: modelURL)
			let container = NSPersistentContainer(name: "Model", managedObjectModel: model!)
			
            return container
        }
				
        self.provide(type: DateFormatter.self).asSingleton().qualified(by: LocalStartDateFormatterQualifier.self).with {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US")
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter
        }
		
		self.provide(type: DateFormatter.self).asSingleton().qualified(by: FirebaseDateFormatterQualifier.self).with {
			let dateFormatter = DateFormatter()
			dateFormatter.locale = Locale(identifier: "en_US")
			dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
			return dateFormatter
		}
		
		self.provide(type: PortlDataProviding.self).asSingleton().with {(persistentContainer: NSPersistentContainer, sessionManager: SessionManager, apiEngine: PortlAPI, localStartDateFormatter: LocalStartDateFormatterQualifier, firebaseDateFormatter: FirebaseDateFormatterQualifier) in
			return PortlService(persistentContainer: persistentContainer, sessionManager: sessionManager, portlAPI: apiEngine, localStartDateFormatter: localStartDateFormatter.value)
        }
				
		self.provide(type: URLComponents.self).qualified(by: GoogleMapsBaseURLQualifier.self).with {
			var urlComponents = URLComponents()
			urlComponents.scheme = "https"
			urlComponents.host = "maps.googleapis.com"
			urlComponents.path = "/maps/api"
			return urlComponents
		}
		
		self.provide(type: String.self).qualified(by: GoogleMapsAPIKeyQualifier.self).with(value: "AIzaSyB3XlIO6pA1mspKMkc5TFNyJ9FT4jEUpUM")

		self.provide(type: GeocodeAPI.self).with { (apiEngine: APIEngine, baseURLComponents: GoogleMapsBaseURLQualifier, apiKey: GoogleMapsAPIKeyQualifier) in
			return GoogleGeocodeAPI(apiKey: apiKey.value, apiEngine: apiEngine, baseURLComponents: baseURLComponents.value)
		}
		
		self.provide(type: Geocoding.self).with {(geocodeAPI: GeocodeAPI) in
			return GeocodeService(geocodeAPI: geocodeAPI)
		}
	}
}
