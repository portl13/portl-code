//
//  UIService.swift
//  Service
//
//  Created by Jeff Creed on 3/28/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import UIKit

enum EventSource: Int {
    case portl = 0
    case ticketmaster
    case facebook
    case eventbrite
    case ticketfly
    case eventful
    case songkick
	case meetup
	case bandsintown
}

protocol AppearanceConfiguring {
    func configureAppearance()
	static func defaultImageForCategory(category: String?, identifier: String?) -> UIImage
	static func defaultImageForVenue(venue: PortlVenue) -> UIImage 
    static func stringForEventSource(source: EventSource) -> String
	static func defaultConcertImage(identifier: String) -> UIImage
}

class UIService: NSObject, AppearanceConfiguring {
    func configureAppearance() {
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self, UIToolbar.self]).tintColor = UIColor.white
        UINavigationBar.appearance().isOpaque = true
        UINavigationBar.appearance().barStyle = .blackOpaque
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().setBackgroundImage(UIImage(named: "img_navbar_background"), for: .default)
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
	@objc static func defaultImageForCategory(category: String?, identifier: String?) -> UIImage {
        var maxIndex: Int = 1
        var imageNameFormat = ""
        switch category {
        case "Business":
            maxIndex = 6
            imageNameFormat = "img_business_%d"
		case "Comedy":
			maxIndex = 7
			imageNameFormat = "img_comedy_%d"
		case "Community":
			maxIndex = 5
			imageNameFormat = "img_community_%d"
		case "Family":
			maxIndex = 5
			imageNameFormat = "img_family_%d"
		case "Fashion":
			maxIndex = 4
			imageNameFormat = "img_fashion_%d"
		case "Film":
			maxIndex = 6
			imageNameFormat = "img_film_%d"
		case "Food":
			maxIndex = 6
			imageNameFormat = "img_food_%d"
        case "Music":
            maxIndex = 10
            imageNameFormat = "img_music_%d"
		case "Other":
			maxIndex = 5
			imageNameFormat = "img_other_%d"
		case "Science":
			maxIndex = 6
			imageNameFormat = "img_science_%d"
        case "Sports":
            maxIndex = 7
            imageNameFormat = "img_sports_%d"
        case "Theater":
            maxIndex = 7
            imageNameFormat = "img_theatre_%d"
		case "Travel":
			maxIndex = 5
			imageNameFormat = "img_travel_%d"
		case "Yoga":
			maxIndex = 5
			imageNameFormat = "img_yoga_%d"
        default:
            // todo: all categories not represented in default image assets. what to put here??
			maxIndex = 10
			imageNameFormat = "img_portl_concert_no_image_%d"
        }
		
		let imageNumber = abs((identifier ?? "").hashValue % maxIndex) + 1
        return UIImage(named: String(format: imageNameFormat, imageNumber))!
    }
	
	@objc static func defaultImageForVenue(venue: PortlVenue) -> UIImage {
		let imageNumber = abs((venue.identifier).hashValue % 7) + 1
		return UIImage(named: String(format: "img_theatre_%d", imageNumber))!
	}
	
	@objc static func defaultConcertImage(identifier: String) -> UIImage {
        return defaultImageForCategory(category: "Music", identifier: identifier)
    }
    
    static func stringForEventSource(source: EventSource) -> String {
        switch source {
        case .portl:
            return "portl"
        case.ticketmaster:
            return "ticketmaster"
        case .facebook:
            return "facebook"
        case .eventbrite:
            return "eventbrite"
        case .ticketfly:
            return "ticketfly"
        case .eventful:
            return "eventful"
        case .songkick:
            return "songkick"
		case .meetup:
			return "meetup"
		case .bandsintown:
			return "bandsintown"
        }
    }
    
    static func iconNameForCategory(category: PortlCategory) -> String {
        return "icon_cat_\(category.name == "Business" ? "workshop" : category.name.lowercased())_circle85"
    }
	
	static func categoryPinIcon(forKey key: String) -> String? {
		return categoryPinIcons[key]
	}
	
	static let categoryPinIcons = [
		"music":"icon_cat_music_mappin",
		"sports":"icon_cat_sports_mappin",
		"business":"icon_cat_workshop_mappin",
		"theatre":"icon_cat_theatre_mappin",
		"family":"icon_cat_family_mappin",
		"yoga":"icon_cat_yoga_mappin",
		"food":"icon_cat_food_mappin",
		"fashion":"icon_cat_fashion_mappin",
		"science":"icon_cat_science_mappin",
		"travel":"icon_cat_travel_mappin",
		"other":"icon_cat_other_mappin",
		"museum":"icon_cat_government_mappin",
		"film":"icon_cat_film_mappin",
		"community":"icon_cat_community_mappin",
	]
}
