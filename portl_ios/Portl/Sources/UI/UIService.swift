//
//  UIService.swift
//  Service
//
//  Created by Jeff Creed on 3/28/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import UIKit
import CSkyUtil
import MapKit

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

enum LivefeedActionFormat: String {
	case going = "%@ %@ going"
	case interested = "%@ %@ interested"
	case shared = "%@ shared an event"
	case community = "%@ commented in %@"
	case communityPhoto = "%@ posted a photo in %@"
	case communityReply = "%@ replied to a post in %@"
	case experience = "%@ posted a comment"
	case experiencePhoto = "%@ posted a photo"
	case experienceReply = "%@ replied to a post"
	case communityVideo = "%@ posted a video in %@"
	case experienceVideo = "%@ posted a video"
}

enum PostActionFormat: String {
	case comment = "%@ commented"
	case photo = "%@ posted a photo"
	case video = "%@ posted a video"
}

protocol AppearanceConfiguring {
    func configureAppearance()
	static func defaultImageForEvent(event: PortlEvent) -> UIImage
	static func defaultImageForVenue(venue: PortlVenue) -> UIImage
	static func defaultImageForArtist(artist: PortlArtist) -> UIImage
    static func stringForEventSource(source: EventSource) -> String
}

class UIService: NSObject, AppearanceConfiguring {
    func configureAppearance() {
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self, UIToolbar.self]).tintColor = UIColor.white
        UINavigationBar.appearance().isOpaque = true
        UINavigationBar.appearance().barStyle = .blackOpaque
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = PaletteColor.dark2.uiColor
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
		
		if #available(iOS 13.0, *) {
			// TODO: Remove as part of Dark Mode work
			UISegmentedControl.appearance().overrideUserInterfaceStyle = .dark
			UITableViewCell.appearance().overrideUserInterfaceStyle = .dark
			UISegmentedControl.appearance().overrideUserInterfaceStyle = .dark
			UIRefreshControl.appearance().overrideUserInterfaceStyle = .dark
			MKMapView.appearance().overrideUserInterfaceStyle = .dark
		}
    }
	
	static func getImageURL(forEvent event: PortlEvent) -> URL? {
		guard let urlString = event.imageURL ?? event.artist?.imageURL else {
			return nil
		}
		
		return URL(string: urlString)
	}
	
	private static func defaultImage(forCategoryName categoryName:String, identifier: String?) -> UIImage {
		
		let imageCount: Int
		switch categoryName {
		case "comedy", "music", "theatre":
			imageCount = 8
		case "family", "travel", "yoga":
			imageCount = 6
		case "fashion":
			imageCount = 5
		case "film", "food", "science", "workshops", "business":
			imageCount = 7
		case "sports", "museum":
			imageCount = 9
		default:
			imageCount = 10
		}
		
		let imageNumber = abs((identifier ?? "").hashValue % imageCount) + 1
		let imageName: String
		if categoryName == "business" {
			imageName = "workshops\(imageNumber)"
		} else if categoryName == "other" || categoryName == "community" {
			imageName = "portl\(imageNumber)"
		} else {
			imageName = "\(categoryName)\(imageNumber)"
		}
		
        return UIImage(named: imageName)!
    }
	
	@objc static func defaultImageForEvent(event: PortlEvent) -> UIImage {
		return defaultImage(forCategoryName: event.getPrimaryEventCategory().name.lowercased(), identifier: event.identifier)
	}
	
	@objc static func defaultImageForVenue(venue: PortlVenue) -> UIImage {
		let imageNumber = abs((venue.identifier).hashValue % 7) + 1
		return UIImage(named: "theatre\(imageNumber)")!
	}
	
	@objc static func defaultImageForArtist(artist: PortlArtist) -> UIImage {
		let imageNumber = abs((artist.identifier).hashValue % 10) + 1
		return UIImage(named: "portl\(imageNumber)")!
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
	
	static func smallLogoForEventSource(source: EventSource) -> UIImage {
		return UIImage(named: "img_logo_\(stringForEventSource(source: source))15")!
	}
    
    static func iconNameForCategory(category: PortlCategory) -> String {
        return iconNameForLowercaseCategoryName(categoryName: category.name.lowercased())
    }
	
	static func iconNameForCategory(category: EventCategory) -> String {
		return iconNameForLowercaseCategoryName(categoryName: category.name.lowercased())
	}
	
	static func getMapPinImage(forCategory category: EventCategory) -> UIImage {
		let pinBackground = UIImage(named: "icon_cat_pin_bg")!
		let pinImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: pinBackground.size.width, height: pinBackground.size.height))
		pinImageView.image = pinBackground
		
		let iconImage = UIImage(named: mapIconName(forCategoryName: category.name.lowercased())) ?? UIImage(named: "map_other")!
		let iconImageView = UIImageView(frame: CGRect(x: pinImageView.frame.width / 2.0 - iconImage.size.width / 2.0, y: 2.0, width: iconImage.size.width, height: iconImage.size.height))
		iconImageView.image = iconImage
		pinImageView.addSubview(iconImageView)
		
		let renderer = UIGraphicsImageRenderer(size: pinImageView.bounds.size)
		let combinedImage = renderer.image { context in
			pinImageView.drawHierarchy(in: pinImageView.bounds, afterScreenUpdates: true)
		}
		return combinedImage
	}

	
	static func iconNameForLowercaseCategoryName(categoryName: String) -> String {
		return "icon_cat_\(categoryName == "business" ? "workshop" : categoryName)_25"
	}
	
	static func mapIconName(forCategoryName categoryName: String) -> String {
		return "map_\(categoryName == "business" ? "workshop" : categoryName)"
	}
	
	static let defaultProfileImage = UIImage(named: "img_profile_placeholder")!
	
	static func getActionStringForLivefeed(withProfileName nameToUse: String, isSelf: Bool, eventTitle: String?, andLivefeedActionFormat actionFormat: LivefeedActionFormat) -> NSAttributedString? {
		var formatVars = [String]()
		formatVars.append(nameToUse)
		
		if actionFormat == .going || actionFormat == .interested {
			formatVars.append(isSelf ? "are" : "is")
		}
		
		if actionFormat == .community || actionFormat == .communityPhoto || actionFormat == .communityReply || actionFormat == .communityVideo {
			guard let eventTitle = eventTitle else {
				return nil
			}
			
			formatVars.append(eventTitle)
		}
		
		let string = String(format: actionFormat.rawValue, arguments: formatVars)
		let attributed = NSMutableAttributedString(string: string, textStyle: .body, overrideColor: .light2, overrideAlignment: nil)
		
		let nameRange = (string as NSString).range(of: nameToUse)
		attributed.addAttributes([.font: TextStyle.bodyBold.font, .foregroundColor: PaletteColor.light1.uiColor], range: nameRange)
		
		if actionFormat == .community || actionFormat == .communityPhoto || actionFormat == .communityReply || actionFormat == .communityVideo {
			let eventRange = (string as NSString).range(of: eventTitle!)
			attributed.addAttributes([.font: TextStyle.bodyBold.font, .foregroundColor: PaletteColor.light1.uiColor], range: eventRange)
		}
		
		return attributed
	}
	
	static func getActionStringForPost(withProfileName nameToUse: String, andCommunityActionFormat actionFormat: PostActionFormat) -> NSAttributedString {
		let string = String(format: actionFormat.rawValue, nameToUse)
		let attributed = NSMutableAttributedString(string: string, textStyle: .small, overrideColor: .light2, overrideAlignment: nil)
		
		let nameRange = (string as NSString).range(of: nameToUse)
		attributed.addAttributes([.font: TextStyle.smallBold.font, .foregroundColor: PaletteColor.light1.uiColor], range: nameRange)
		
		return attributed
	}
		
	static func getInlineProfileNameAndMessage(withProfileName nameToUse: String, andMessageText messageText: String?) -> NSAttributedString {
		var string = nameToUse
		if let text = messageText {
			string += " " + text
		}
		let attributed = NSMutableAttributedString(string: string, textStyle: .body, overrideColor: .light1, overrideAlignment: nil)

		let nameRange = (string as NSString).range(of: nameToUse)
		attributed.addAttributes([.font: TextStyle.bodyBold.font, .foregroundColor: PaletteColor.light1.uiColor], range: nameRange)
		
		return attributed
	}
	
	static func getTableViewHeaderString(forText text: String) -> NSAttributedString {
		let attributed = NSMutableAttributedString(string: text, textStyle: .bodyBold, overrideColor: .dark4)
		attributed.addAttribute(.kern, value: 2, range: NSMakeRange(0, attributed.length))
		return attributed
	}
	
	static func getMapFiltersTitleString(forLocationText locationText: String) -> NSAttributedString {
		let string = String(format: "Events near %@ starting today:", locationText)
		let attributed = NSMutableAttributedString(string: string, textStyle: .body, overrideColor: .light2, overrideAlignment: nil)
		
		let locationRange = (string as NSString).range(of: locationText)
		attributed.addAttributes([.font: TextStyle.bodyBold.font, .foregroundColor: PaletteColor.light1.uiColor], range: locationRange)
		
		return attributed
	}
	
	static func getLocationMapMarker() -> UIImage {
		return UIImage(named: "venue_location_pin")!
	}
}
