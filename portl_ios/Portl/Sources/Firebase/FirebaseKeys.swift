//
//  FirebaseKeys.swift
//  Portl
//
//  Created by Jeff Creed on 6/5/18.
//  Copyright © 2018 Portl. All rights reserved.
//

class FirebaseKeys {
    public static let profileKey = "profile"
	public static let profilePrivateKey = "profile_private"
    public static let friendsKey = "friend"
	public static let schemaKey = "schema"
	public static let eventsKey = "event"
	public static let conversationsKey = "conversation"
	public static let livefeedsKey = "livefeed"
	public static let device = "device"
	public static let experiencesKey = "experience"
	
    class ProfileKeys {
        public static let firstNameKey = "first_name"
        public static let lastNameKey = "last_name"
        public static let avatarKey = "avatar"
        public static let sharedKey = "shared"
        public static let eventsKey = "events"
        public static let interestsKey = "interests"
		public static let genderKey = "gender"
		public static let zipcodeKey = "zipcode"
		public static let birthDateKey = "birth_date"
		public static let usernameKey = "username"
		public static let uidKey = "uid"
		public static let usernameDKey = "username_d"
		public static let firstLastKey = "first_last"
		public static let bioKey = "bio"
		public static let websiteKey = "website"
		public static let unseenLivefeedKey = "unseen_livefeed"
		public static let unreadMessagesKey = "unread_messages"
		public static let conversationKey = "conversation"
		public static let followingKey = "following"
		
		class EventKeys {
			public static let favoritesKey = "favorite"
			public static let goingKey = "going"
			public static let shareKey = "share"
		}
		
		class ConversationKeys {
			public static let hasNewKey = "has_new"
			public static let isArchivedKey = "is_archived"
			public static let archivedMessagesKey = "archived_messages"
		}
		
		class FollowingKeys {
			public static let artistKey = "artist"
			public static let venueKey = "venue"
		}
    }
	
	class ProfilePrivateKeys {
		public static let votesKey = "votes"
		
		class VotesKeys {
			public static let conversationKey = "conversation"
			public static let experienceKey = "experience"
		}
	}
    
    class NotificationKeys {
        public static let fromKey = "from"
        public static let eventKey = "event"
    }
	
	class FriendsKeys {
		public static let userOneKey = "user1"
		public static let userTwoKey = "user2"
		public static let acceptedKey = "accepted"
		public static let invitedKey = "invited"
		public static let statusKey = "status"
	}
	
	class SchemaKeys {
		public static let versionKey = "version"
		public static let deprecationDateKey = "deprecation_date"
	}
	
	class ConversationKeys {
		public static let messagesKey = "messages"
		public static let overviewKey = "overview"
		public static let sendersKey = "senders"
		
		class OverviewKeys {
			public static let firstMessageKey = "first_message"
		}
	}
	
	class LivefeedKeys {
		public static let profileIDKey = "profile_id"
	}
}
