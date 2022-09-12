
Each event has a list of category tags describing what type of event it is. The categories differ by event source. The
iOS application offers category-based filtering and a pre-built list of categories for the user to choose from.

The app hard-codes these category keys:

music, family, sports, business, theatre, food, film, yoga, fashion, community, science, travel, museum

For each key, it stores:

- display color
- title
- some icons
- a list of categories (excerpt):

    else if ([key isEqualToString:@"business"]) {
        return @[@"business", @"workshop", @"work", @"shopping"];
    } else if ([key isEqualToString:@"film"]) {
        return @[@"film", @"movie", @"entertainment"];
    }

The categories are


> db.events.distinct('categories', {'id.sourceType': 1})  // TicketMaster
[
	"Arts & Theatre",
	"Music",
	"Undefined",
	"Hip-Hop/Rap",
	"Urban",
	"Pop",
	"Rock",
	"Club Dance",
	"Dance/Electronic",
	"Sports",
	"College",
	"Football",
	"Comedy",
	"R&B",
	"Alternative Rock",
	"Folk",
	"Other",
	"Jazz",
	"Musical",
	"Theatre",
	"Miscellaneous Theatre",
	"Family",
	"Miscellaneous",
	"Volleyball",
	"Baseball",
	"MLB",
	"Hockey",
	"NHL",
	"Soccer",
	"Martial Arts",
	"Mixed Martial Arts",
	"Boxing",
	"NFL",
	"Classical",
	"Symphonic",
	"Basketball",
	"NBA",
	"Wrestling",
	"Bullriding",
	"Rodeo",
	"Golf",
	"PGA Tour"
]
> db.events.distinct('categories', {'id.sourceType': 2})  // Facebook
[
	"THEATER_EVENT",
	"EVENT_NETWORKING",
	"EVENT_SHOPPING",
	"EVENT_HOME",
	"EVENT_THEATER",
	"EVENT_COMEDY_PERFORMANCE",
	"COMEDY_EVENT"
]
> db.events.distinct('categories', {'id.sourceType': 6})  // SongKick
[ "concert", "music", "festival" ]




