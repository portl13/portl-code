# Target Model

## Event

- title
- date/time
- image
- description (seen on Eventbrite events)
- artist
-- name
-- description
-- image
- venue
-- name
-- address
-- location
- categories
- affiliate links
-- lyft
-- expedia
-- opentable
-- original event source(s) / ticket purchase links


## Artist

- name
- image
- description
- affiliate links
-- link to artist detail on original source(s) (songkick, ticketmaster, etc)

- upcoming events
- recent events


## Venue

- name
- image
- address
-- location

- upcoming events
- recent events


# iOS Model

PortlEvent
@property (strong, nonatomic) PortlIdentifier   *eventId;
@property (strong, nonatomic) NSString          *eventTitle;
@property (strong, nonatomic) PortlDescription  *eventDescription;
@property (strong, nonatomic) PortlImage        *eventImage;
@property (strong, nonatomic) PortlWebsiteUrl   *eventUrl;
@property (strong, nonatomic) PortlArtist       *eventArtist;
@property (strong, nonatomic) PortlVenue        *eventVenue;
@property (strong, nonatomic) NSDate            *eventStartDateTime;
@property (strong, nonatomic) NSDate            *eventEndDateTime;
@property (strong, nonatomic) NSDate            *eventCreated;
@property (strong, nonatomic) NSDate            *eventModified;
@property (strong, nonatomic) NSString          *ticketBuyUrl;
@property (strong, nonatomic) NSString          *eventStatus;
@property (strong, nonatomic) NSString          *eventVenueId;
@property (strong, nonatomic) NSString          *eventArtistId;
@property (strong, nonatomic) NSString          *eventArtistKeyForFIR;
@property (strong, nonatomic) NSString          *eventVenueKeyForFIR;
@property (strong, nonatomic) NSArray           *categories;
@property (strong, nonatomic) NSString          *tempStartTimeString;
@property (readwrite, nonatomic) BOOL           timeUnspecifiedOrAllDay;
@property (strong, nonatomic) NSString          *facebookEventUrl;
@property (strong, nonatomic) NSArray           *eventAdminIdentifiers;
- (EventSourceType) sourceType;
- (BOOL) isUpcomingEvent;
- (BOOL) isPastEvent;
- (UIColor *)pinColor;
- (BOOL)categoryIncludedFor:(NSString *)category;
- (NSString *)eventPicturePath;

PortlIdentifier
@property (nonatomic, readwrite) EventSourceType    eventSourceType;
@property (strong, nonatomic) NSString              *eventIdentifierOnSource;

PortlDescription
@property (strong, nonatomic) NSString *descriptionText;
@property (strong, nonatomic) NSString *descriptionHtml;

PortlImage
@property (strong, nonatomic) NSString          *imageThumbUrl;
@property (strong, nonatomic) NSString          *mainCoverImageUrl;
@property (strong, nonatomic) NSDictionary      *imageExtraInformationData;
@property (readwrite, nonatomic) BOOL           usingDefaultImage;
@property (strong, nonatomic) NSString          *defaultCoverImage;

PortlWebsiteUrl
@property (strong, nonatomic) NSString *fullUrl;

PortlArtist
@property (strong, nonatomic) NSString          *artistName;
@property (strong, nonatomic) PortlIdentifier   *artistId;
@property (strong, nonatomic) NSDictionary      *artistfullDataDict;
@property (strong, nonatomic) PortlDescription  *artistDescription;
@property (strong, nonatomic) NSString          *artistPhoneNumber;
@property (strong, nonatomic) NSString          *artistSpotify;
@property (strong, nonatomic) NSString          *artistYoutube;
@property (strong, nonatomic) NSString          *artistiTunes;
@property (strong, nonatomic) NSString          *artistFacebook;
@property (strong, nonatomic) NSString          *artistTwitter;
@property (strong, nonatomic) NSString          *artistInstagram;
@property (strong, nonatomic) NSString          *artistUrl;
@property (strong, nonatomic) PortlImage        *artistLogo;
@property (strong, nonatomic) NSArray           *adminIdentifiers;
@property (strong, nonatomic) NSDate            *artistCreatedAt;
@property (strong, nonatomic) NSDate            *artistModifiedAt;
@property (readwrite, nonatomic) int            upcomingEventsCount;
@property (readwrite, nonatomic) int            pastEventsCount;

PortlVenue
@property (strong, nonatomic) PortlIdentifier   *venueId;
@property (strong, nonatomic) NSString          *venueName;
@property (strong, nonatomic) PortlAddress      *venueAddress;
@property (strong, nonatomic) NSString          *venueDescription;
@property (strong, nonatomic) PortlImage        *venueLogo;
@property (strong, nonatomic) NSString          *venuePhoneNumber;
@property (strong, nonatomic) NSString          *venueWebsiteAddress;
@property (strong, nonatomic) NSArray           *venueAdminIdentifiers;
@property (strong, nonatomic) NSString          *venueFacebook;
@property (strong, nonatomic) NSString          *venueTwitter;
@property (strong, nonatomic) NSString          *venueInstagram;
@property (strong, nonatomic) NSDate            *venueCratedAt;
@property (strong, nonatomic) NSDate            *venueModifiedAt;
@property (strong, nonatomic) NSArray           *adminIds;

PortlAddress
@property (strong, nonatomic) NSString      *fullAddress;
@property (strong, nonatomic) CLLocation    *addressLocation;
@property (strong, nonatomic) NSString      *city;
@property (strong, nonatomic) NSString      *state;
@property (strong, nonatomic) NSString      *postalCode;
@property (strong, nonatomic) NSString      *country;
@property (strong, nonatomic) NSString      *shortenAddress;
@property (strong, nonatomic) NSString      *countryCode;       // For Eventful


typedef enum {
    sourcePortlServer = 0,
    sourceTicketMaster,
    sourceFacebook,
    sourceEventBrite,
    sourceTicketFly,
    sourceEventful,
    sourceSongKick
    }EventSourceType;
