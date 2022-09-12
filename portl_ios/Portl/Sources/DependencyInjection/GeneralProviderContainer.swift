//
//  GeneralProviderContainer.swift
//  Service
//
//  Created by Jeff Creed on 4/11/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation
import CSkyUtil
import CoreData
import Service

public class GeneralProviderContainer: ProviderContainer {
    override public init() {
        super.init()
        
        self.provide(type: AppearanceConfiguring.self).asSingleton().with { UIService() }
        
        self.provide(type: DateFormatter.self).asSingleton().qualified(by: NoTimeDateFormatterQualifier.self).with {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US")
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            dateFormatter.doesRelativeDateFormatting = true
            return dateFormatter
        }
        
        self.provide(type: DateFormatter.self).asSingleton().qualified(by: DateFormatterQualifier.self).with {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US")
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            dateFormatter.doesRelativeDateFormatting = true
            return dateFormatter
        }
        
        self.provide(type: DateFormatter.self).asSingleton().qualified(by: LongDateFormatterQualifier.self).with {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US")
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            dateFormatter.doesRelativeDateFormatting = true
            return dateFormatter
        }
		
        self.provide(type: DateFormatter.self).asSingleton().qualified(by: ResultsControllerSectionFormatterQualifier.self).with {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US")
            dateFormatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss Z"
            return dateFormatter
        }
        
        self.provide(type: DateFormatter.self).asSingleton().qualified(by: FirebaseDateFormatter.self).with {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US")
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss z"
            return dateFormatter
        }
		
		self.provide(type: DateFormatter.self).asSingleton().qualified(by: BirthdayDateFormatterQualifier.self).with {
			let dateFormatter = DateFormatter()
			dateFormatter.locale = Locale(identifier: "en_US")
			dateFormatter.dateFormat = "yyyy-MM-dd"
			return dateFormatter
		}
		
		self.provide(type: NSPersistentContainer.self).asSingleton().qualified(by: FirebasePersistentContainerQualifier.self).with {
			let bundle = Bundle(for: FirebaseService.self)
			guard let modelURL = bundle.url(forResource: "FirebaseModel", withExtension: "momd") else {
				fatalError("Error loading Firebase model from bundle")
			}
			
			let model = NSManagedObjectModel(contentsOf: modelURL)
			let container = NSPersistentContainer(name: "FirebaseModel", managedObjectModel: model!)
			
			return container
		}
		
		self.provide(type: FirebaseDataProviding.self).asSingleton().with {(persistentContainer: FirebasePersistentContainerQualifier, firebaseDateFormatter: FirebaseDateFormatter) in
			return FirebaseService(persistentContainer: persistentContainer.value, firebaseDateFormatter: firebaseDateFormatter.value)
		}
		
		self.provide(type: DatabaseReference.self).asSingleton().qualified(by: DatabaseRootReferenceQualifier.self).with {
			return Database.database().reference().child("v2")
		}
		
		self.provide(type: FCMTokenManager.self).asSingleton().with { (databaseRootReference: DatabaseRootReferenceQualifier) in
			return FCMTokenManager(databaseRootReference: databaseRootReference)
		}

        self.provide(type: Sharing.self).asSingleton().with { (dateFormatter: FirebaseDateFormatter) in
            return Sharing(dateFormatter: dateFormatter)
        }
        
        self.provide(type: Interests.self).asSingleton().with {
            return Interests()
        }
		
		self.provide(type: Friends.self).asSingleton().with { (dateFormatter: FirebaseDateFormatter) in
			return Friends(dateFormatter: dateFormatter.value)
		}
		
		self.provide(type: OldProfileService.self).asSingleton().with {
			return OldProfileService()
		}
		
		self.provide(type: FirebaseUtils.self).asSingleton().with { (notifcationDateFormatter: FirebaseDateFormatter, dateFormatter: DateFormatterQualifier) in
			return FirebaseUtils(notificationDateFormatter: notifcationDateFormatter.value, dateFormatter: dateFormatter.value)
		}
		
        self.provide(type: BottomSlideInTransitionFactory.self).with { BottomSlideInTransitionFactory() }
		
				
		self.provide(type: UserProfileService.self).asSingleton().with { (databaseRootReference: DatabaseRootReferenceQualifier, dateFormatter: FirebaseDateFormatter, firebaseService: FirebaseDataProviding) in
			return UserProfileService(databaseRootReference: databaseRootReference.value, dateFormatter: dateFormatter.value, firebaseService: firebaseService)
		}
		
		self.provide(type: EventService.self).asSingleton().with { (databaseRootReference: DatabaseRootReferenceQualifier) in
			return EventService(databaseRootReference: databaseRootReference.value)
		}
				
		self.provide(type: ConversationService.self).asSingleton().with { (databaseRootReference: DatabaseRootReferenceQualifier, dateFormatter: FirebaseDateFormatter) in
			return ConversationService(databaseRootReference: databaseRootReference.value, notificationFormatter: dateFormatter.value)
		}
		
		self.provide(type: LivefeedService.self).asSingleton().with { (databaseRootReference: DatabaseRootReferenceQualifier) in
			return LivefeedService(databaseRootReference: databaseRootReference.value)
		}
				
		self.provide(type: PlaybackController.self).asSingleton().with {
			return PlaybackController()
		}
    }
}
