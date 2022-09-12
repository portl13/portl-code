package com.portl.test.integration

import com.portl.commons.models.Location
import javax.inject.Inject

import scala.concurrent.{ExecutionContext, Future}

case class City(
    name: String,
    state: String,
    lat: Double,
    lng: Double
)

class LocalDataService @Inject()(implicit val ec: ExecutionContext) {
  def usCityLocations(): Future[List[Location]] = Future {
    LocalDataService.cities.map(c => Location(c.lng, c.lat)).toList
  }
}

object LocalDataService {
  val cities = Seq(
    City("New York", "New York", 40.6635, -73.9387),
    City("Los Angeles", "California", 34.0194, -118.4108),
    City("Chicago", "Illinois", 41.8376, -87.6818),
    City("Houston", "Texas", 29.7866, -95.3909),
    City("Phoenix", "Arizona", 33.5722, -112.0901),
    City("Philadelphia", "Pennsylvania", 40.0094, -75.1333),
    City("San Antonio", "Texas", 29.4724, -98.5251),
    City("San Diego", "California", 32.8153, -117.135),
    City("Dallas", "Texas", 32.7933, -96.7665),
    City("San Jose", "California", 37.2967, -121.8189),
    City("Austin", "Texas", 30.3039, -97.7544),
    City("Jacksonville", "Florida", 30.3369, -81.6616),
    City("San Francisco", "California", 37.7272, -123.0322),
    City("Columbus", "Ohio", 39.9852, -82.9848),
    City("Indianapolis", "Indiana", 39.7767, -86.1459),
    City("Fort Worth", "Texas", 32.7815, -97.3467),
    City("Charlotte", "North Carolina", 35.2078, -80.831),
    City("Seattle", "Washington", 47.6205, -122.3509),
    City("Denver", "Colorado", 39.7619, -104.8811),
    City("El Paso", "Texas", 31.8484, -106.427),
    City("Washington", "District of Columbia", 38.9041, -77.0172),
    City("Boston", "Massachusetts", 42.332, -71.0202),
    City("Detroit", "Michigan", 42.383, -83.1022),
    City("Nashville", "Tennessee", 36.1718, -86.785),
    City("Memphis", "Tennessee", 35.1028, -89.9774),
    City("Portland", "Oregon", 45.537, -122.65),
    City("Oklahoma City", "Oklahoma", 35.4671, -97.5137),
    City("Las Vegas", "Nevada", 36.2292, -115.2601),
    City("Louisville", "Kentucky", 38.1654, -85.6474),
    City("Baltimore", "Maryland", 39.3, -76.6105),
    City("Milwaukee", "Wisconsin", 43.0633, -87.9667),
    City("Albuquerque", "New Mexico", 35.1056, -106.6474),
    City("Tucson", "Arizona", 32.1531, -110.8706),
    City("Fresno", "California", 36.7836, -119.7934),
    City("Sacramento", "California", 38.5666, -121.4686),
    City("Mesa", "Arizona", 33.4019, -111.7174),
    City("Kansas City", "Missouri", 39.1251, -94.551),
    City("Atlanta", "Georgia", 33.7629, -84.4227),
    City("Long Beach", "California", 33.8092, -118.1553),
    City("Colorado Springs", "Colorado", 38.8673, -104.7607),
    City("Raleigh", "North Carolina", 35.8306, -78.6418),
    City("Miami", "Florida", 25.7752, -80.2086),
    City("Virginia Beach", "Virginia", 36.78, -76.0252),
    City("Omaha", "Nebraska", 41.2644, -96.0451),
    City("Oakland", "California", 37.7698, -122.2257),
    City("Minneapolis", "Minnesota", 44.9633, -93.2683),
    City("Tulsa", "Oklahoma", 36.1279, -95.9023),
    City("Arlington", "Texas", 32.7007, -97.1247),
    City("New Orleans", "Louisiana", 30.0534, -89.9345),
    City("Wichita", "Kansas", 37.6907, -97.3459),
    City("Cleveland", "Ohio", 41.4785, -81.6794),
    City("Tampa", "Florida", 27.9701, -82.4797),
    City("Bakersfield", "California", 35.3212, -119.0183),
    City("Aurora", "Colorado", 39.688, -104.6897),
    City("Honolulu", "Hawaii", 21.3243, -157.8476),
    City("Anaheim", "California", 33.8555, -117.7601),
    City("Santa Ana", "California", 33.7363, -117.883),
    City("Corpus Christi", "Texas", 27.7543, -97.1734),
    City("Riverside", "California", 33.9381, -117.3932),
    City("Lexington", "Kentucky", 38.0407, -84.4583),
    City("St. Louis", "Missouri", 38.6357, -90.2446),
    City("Stockton", "California", 37.9763, -121.3133),
    City("Pittsburgh", "Pennsylvania", 40.4398, -79.9766),
    City("Saint Paul", "Minnesota", 44.9489, -93.1041),
    City("Cincinnati", "Ohio", 39.1402, -84.5058),
    City("Anchorage", "Alaska", 61.1743, -149.2843),
    City("Henderson", "Nevada", 36.0097, -115.0357),
    City("Greensboro", "North Carolina", 36.0951, -79.827),
    City("Plano", "Texas", 33.0508, -96.7479),
    City("Newark", "New Jersey", 40.7242, -74.1726),
    City("Lincoln", "Nebraska", 40.8105, -96.6803),
    City("Toledo", "Ohio", 41.6641, -83.5819),
    City("Orlando", "Florida", 28.4166, -81.2736),
    City("Chula Vista", "California", 32.6277, -117.0152),
    City("Irvine", "California", 33.6784, -117.7713),
    City("Fort Wayne", "Indiana", 41.0882, -85.1439),
    City("Jersey City", "New Jersey", 40.7114, -74.0648),
    City("Durham", "North Carolina", 35.9811, -78.9029),
    City("St. Petersburg", "Florida", 27.762, -82.6441),
    City("Laredo", "Texas", 27.5604, -99.4892),
    City("Buffalo", "New York", 42.8925, -78.8597),
    City("Madison", "Wisconsin", 43.0878, -89.4299),
    City("Lubbock", "Texas", 33.5656, -101.8867),
    City("Chandler", "Arizona", 33.2829, -111.8549),
    City("Scottsdale", "Arizona", 33.6843, -111.8611),
    City("Glendale", "Arizona", 33.5331, -112.1899),
    City("Reno", "Nevada", 39.5491, -119.8499),
    City("Norfolk", "Virginia", 36.923, -76.2446),
    City("Winston–Salem", "North Carolina", 36.1027, -80.261),
    City("North Las Vegas", "Nevada", 36.2857, -115.0939),
    City("Irving", "Texas", 32.8577, -96.97),
    City("Chesapeake", "Virginia", 36.6794, -76.3018),
    City("Gilbert", "Arizona", 33.3103, -111.7431),
    City("Hialeah", "Florida", 25.8699, -80.3029),
    City("Garland", "Texas", 32.9098, -96.6303),
    City("Fremont", "California", 37.4945, -121.9412),
    City("Baton Rouge", "Louisiana", 30.4422, -91.1309),
    City("Richmond", "Virginia", 37.5314, -77.476),
    City("Boise", "Idaho", 43.6002, -116.2317),
    City("San Bernardino", "California", 34.1416, -117.2936),
    City("Spokane", "Washington", 47.6669, -117.4333),
    City("Des Moines", "Iowa", 41.5726, -93.6102),
    City("Modesto", "California", 37.6375, -121.003),
    City("Birmingham", "Alabama", 33.5274, -86.799),
    City("Tacoma", "Washington", 47.2522, -122.4598),
    City("Fontana", "California", 34.109, -117.4629),
    City("Rochester", "New York", 43.1699, -77.6169),
    City("Oxnard", "California", 34.2023, -119.2046),
    City("Moreno Valley", "California", 33.9233, -117.2057),
    City("Fayetteville", "North Carolina", 35.0828, -78.9735),
    City("Aurora", "Illinois", 41.7635, -88.2901),
    City("Glendale", "California", 34.1814, -118.2458),
    City("Yonkers", "New York", 40.9459, -73.8674),
    City("Huntington Beach", "California", 33.6906, -118.0093),
    City("Montgomery", "Alabama", 32.3472, -86.2661),
    City("Amarillo", "Texas", 35.1999, -101.8302),
    City("Little Rock", "Arkansas", 34.7254, -92.3586),
    City("Akron", "Ohio", 41.0805, -81.5214),
    City("Columbus", "Georgia", 32.5102, -84.8749),
    City("Augusta", "Georgia", 33.3655, -82.0734),
    City("Grand Rapids", "Michigan", 42.9612, -85.6556),
    City("Shreveport", "Louisiana", 32.4669, -93.7922),
    City("Salt Lake City", "Utah", 40.7769, -111.931),
    City("Huntsville", "Alabama", 34.699, -86.673),
    City("Mobile", "Alabama", 30.6684, -88.1002),
    City("Tallahassee", "Florida", 30.4551, -84.2534),
    City("Grand Prairie", "Texas", 32.6869, -97.0211),
    City("Overland Park", "Kansas", 38.889, -94.6906),
    City("Knoxville", "Tennessee", 35.9707, -83.9493),
    City("Port St. Lucie", "Florida", 27.2806, -80.3883),
    City("Worcester", "Massachusetts", 42.2695, -71.8078),
    City("Brownsville", "Texas", 25.9991, -97.455),
    City("Tempe", "Arizona", 33.3884, -111.9318),
    City("Santa Clarita", "California", 34.403, -118.5042),
    City("Newport News", "Virginia", 37.0762, -76.522),
    City("Cape Coral", "Florida", 26.6432, -81.9974),
    City("Providence", "Rhode Island", 41.8231, -71.4188),
    City("Fort Lauderdale", "Florida", 26.1412, -80.1467),
    City("Chattanooga", "Tennessee", 35.066, -85.2484),
    City("Rancho Cucamonga", "California", 34.1233, -117.5642),
    City("Oceanside", "California", 33.2245, -117.3062),
    City("Santa Rosa", "California", 38.4468, -122.7061),
    City("Garden Grove", "California", 33.7788, -117.9605),
    City("Vancouver", "Washington", 45.6349, -122.5957),
    City("Sioux Falls", "South Dakota", 43.5383, -96.732),
    City("Ontario", "California", 34.0394, -117.6042),
    City("McKinney", "Texas", 33.1985, -96.668),
    City("Elk Grove", "California", 38.4146, -121.385),
    City("Jackson", "Mississippi", 32.3158, -90.2128),
    City("Pembroke Pines", "Florida", 26.021, -80.3404),
    City("Salem", "Oregon", 44.9237, -123.0232),
    City("Springfield", "Missouri", 37.1942, -93.2913),
    City("Corona", "California", 33.862, -117.5655),
    City("Eugene", "Oregon", 44.0567, -123.1162),
    City("Fort Collins", "Colorado", 40.5482, -105.0648),
    City("Peoria", "Arizona", 33.7862, -112.308),
    City("Frisco", "Texas", 33.1554, -96.8226),
    City("Cary", "North Carolina", 35.7809, -78.8133),
    City("Lancaster", "California", 34.6936, -118.1753),
    City("Hayward", "California", 37.6287, -122.1024),
    City("Palmdale", "California", 34.591, -118.1054),
    City("Salinas", "California", 36.6902, -121.6337),
    City("Alexandria", "Virginia", 38.8201, -77.0841),
    City("Lakewood", "Colorado", 39.6989, -105.1176),
    City("Springfield", "Massachusetts", 42.1155, -72.54),
    City("Pasadena", "Texas", 29.6586, -95.1506),
    City("Sunnyvale", "California", 37.3858, -122.0263),
    City("Macon", "Georgia", 32.8088, -83.6942),
    City("Pomona", "California", 34.0585, -117.7611),
    City("Hollywood", "Florida", 26.031, -80.1646),
    City("Kansas City", "Kansas", 39.1225, -94.7418),
    City("Escondido", "California", 33.1331, -117.074),
    City("Clarksville", "Tennessee", 36.5664, -87.3452),
    City("Joliet", "Illinois", 41.5177, -88.1488),
    City("Rockford", "Illinois", 42.2588, -89.0646),
    City("Torrance", "California", 33.835, -118.3414),
    City("Naperville", "Illinois", 41.7492, -88.162),
    City("Paterson", "New Jersey", 40.9148, -74.1628),
    City("Savannah", "Georgia", 32.0025, -81.1536),
    City("Bridgeport", "Connecticut", 41.1874, -73.1958),
    City("Mesquite", "Texas", 32.7629, -96.5888),
    City("Killeen", "Texas", 31.0777, -97.732),
    City("Syracuse", "New York", 43.041, -76.1436),
    City("McAllen", "Texas", 26.2322, -98.2464),
    City("Pasadena", "California", 34.1606, -118.1396),
    City("Bellevue", "Washington", 47.5979, -122.1565),
    City("Fullerton", "California", 33.8857, -117.928),
    City("Orange", "California", 33.787, -117.8613),
    City("Dayton", "Ohio", 39.7774, -84.1996),
    City("Miramar", "Florida", 25.977, -80.3358),
    City("Thornton", "Colorado", 39.9194, -104.9428),
    City("West Valley City", "Utah", 40.6885, -112.0118),
    City("Olathe", "Kansas", 38.8843, -94.8195),
    City("Hampton", "Virginia", 37.048, -76.2971),
    City("Warren", "Michigan", 42.4929, -83.025),
    City("Midland", "Texas", 32.0246, -102.1135),
    City("Waco", "Texas", 31.5601, -97.186),
    City("Charleston", "South Carolina", 32.8179, -79.959),
    City("Columbia", "South Carolina", 34.0291, -80.898),
    City("Denton", "Texas", 33.2166, -97.1414),
    City("Carrollton", "Texas", 32.9884, -96.8998),
    City("Surprise", "Arizona", 33.6706, -112.4527),
    City("Roseville", "California", 38.769, -121.3189),
    City("Sterling Heights", "Michigan", 42.5812, -83.0303),
    City("Murfreesboro", "Tennessee", 35.8522, -86.416),
    City("Gainesville", "Florida", 29.6788, -82.3461),
    City("Cedar Rapids", "Iowa", 41.967, -91.6778),
    City("Visalia", "California", 36.3273, -119.3289),
    City("Coral Springs", "Florida", 26.2707, -80.2593),
    City("New Haven", "Connecticut", 41.3108, -72.925),
    City("Stamford", "Connecticut", 41.0799, -73.546),
    City("Thousand Oaks", "California", 34.1933, -118.8742),
    City("Concord", "California", 37.9722, -122.0016),
    City("Elizabeth", "New Jersey", 40.6664, -74.1935),
    City("Lafayette", "Louisiana", 30.2074, -92.0285),
    City("Kent", "Washington", 47.388, -122.2127),
    City("Topeka", "Kansas", 39.0347, -95.6962),
    City("Simi Valley", "California", 34.2669, -118.7485),
    City("Santa Clara", "California", 37.3646, -121.9679),
    City("Athens", "Georgia", 33.9496, -83.3701),
    City("Hartford", "Connecticut", 41.7659, -72.6816),
    City("Victorville", "California", 34.5277, -117.3536),
    City("Abilene", "Texas", 32.4545, -99.7381),
    City("Norman", "Oklahoma", 35.2406, -97.3453),
    City("Vallejo", "California", 38.1079, -122.264),
    City("Berkeley", "California", 37.867, -122.2991),
    City("Round Rock", "Texas", 30.5252, -97.666),
    City("Ann Arbor", "Michigan", 42.2761, -83.7309),
    City("Fargo", "North Dakota", 46.8652, -96.829),
    City("Columbia", "Missouri", 38.9473, -92.3264),
    City("Allentown", "Pennsylvania", 40.5936, -75.4784),
    City("Evansville", "Indiana", 37.9877, -87.5347),
    City("Beaumont", "Texas", 30.0849, -94.1453),
    City("Odessa", "Texas", 31.8838, -102.3411),
    City("Wilmington", "North Carolina", 34.2092, -77.8858),
    City("Arvada", "Colorado", 39.8337, -105.1503),
    City("Independence", "Missouri", 39.0855, -94.3521),
    City("Provo", "Utah", 40.2453, -111.6448),
    City("Lansing", "Michigan", 42.7143, -84.5593),
    City("El Monte", "California", 34.0746, -118.0291),
    City("Springfield", "Illinois", 39.7911, -89.6446),
    City("Fairfield", "California", 38.2593, -122.0321),
    City("Clearwater", "Florida", 27.9789, -82.7666),
    City("Peoria", "Illinois", 40.7515, -89.6174),
    City("Rochester", "Minnesota", 44.0154, -92.4772),
    City("Carlsbad", "California", 33.1239, -117.2828),
    City("Westminster", "Colorado", 39.8822, -105.0644),
    City("West Jordan", "Utah", 40.6024, -112.0008),
    City("Pearland", "Texas", 29.5558, -95.3231),
    City("Richardson", "Texas", 32.9723, -96.7081),
    City("Downey", "California", 33.9382, -118.1309),
    City("Miami Gardens", "Florida", 25.9489, -80.2436),
    City("Temecula", "California", 33.4931, -117.1317),
    City("Costa Mesa", "California", 33.6659, -117.9123),
    City("College Station", "Texas", 30.5852, -96.2964),
    City("Elgin", "Illinois", 42.0396, -88.3217),
    City("Murrieta", "California", 33.5721, -117.1904),
    City("Gresham", "Oregon", 45.5023, -122.4416),
    City("High Point", "North Carolina", 35.99, -79.9905),
    City("Antioch", "California", 37.9791, -121.7962),
    City("Inglewood", "California", 33.9561, -118.3443),
    City("Cambridge", "Massachusetts", 42.376, -71.1187),
    City("Lowell", "Massachusetts", 42.639, -71.3211),
    City("Manchester", "New Hampshire", 42.9849, -71.4441),
    City("Billings", "Montana", 45.7885, -108.5499),
    City("Pueblo", "Colorado", 38.2699, -104.6123),
    City("Palm Bay", "Florida", 27.9856, -80.6626),
    City("Centennial", "Colorado", 39.5906, -104.8691),
    City("Richmond", "California", 37.9523, -122.3606),
    City("Ventura", "California", 34.2678, -119.2542),
    City("Pompano Beach", "Florida", 26.2416, -80.1339),
    City("North Charleston", "South Carolina", 32.9178, -80.065),
    City("Everett", "Washington", 47.9566, -122.1914),
    City("Waterbury", "Connecticut", 41.5585, -73.0367),
    City("West Palm Beach", "Florida", 26.7464, -80.1251),
    City("Boulder", "Colorado", 40.027, -105.2519),
    City("West Covina", "California", 34.0559, -117.9099),
    City("Broken Arrow", "Oklahoma", 36.0365, -95.781),
    City("Clovis", "California", 36.8282, -119.6849),
    City("Daly City", "California", 37.7009, -122.465),
    City("Lakeland", "Florida", 28.0555, -81.9549),
    City("Santa Maria", "California", 34.9332, -120.4438),
    City("Norwalk", "California", 33.9076, -118.0835),
    City("Sandy Springs", "Georgia", 33.9315, -84.3687),
    City("Hillsboro", "Oregon", 45.528, -122.9357),
    City("Green Bay", "Wisconsin", 44.5207, -87.9842),
    City("Tyler", "Texas", 32.3173, -95.3059),
    City("Wichita Falls", "Texas", 33.9067, -98.5259),
    City("Lewisville", "Texas", 33.0466, -96.9818),
    City("Burbank", "California", 34.1901, -118.3264),
    City("Greeley", "Colorado", 40.4153, -104.7697),
    City("San Mateo", "California", 37.5603, -122.3106),
    City("El Cajon", "California", 32.8017, -116.9604),
    City("Jurupa Valley", "California", 34.0026, -117.4676),
    City("Rialto", "California", 34.1118, -117.3883),
    City("Davenport", "Iowa", 41.5541, -90.604),
    City("League City", "Texas", 29.4901, -95.1091),
    City("Edison", "New Jersey", 40.504, -74.3494),
    City("Davie", "Florida", 26.0791, -80.285),
    City("Las Cruces", "New Mexico", 32.3264, -106.7897),
    City("South Bend", "Indiana", 41.6769, -86.269),
    City("Vista", "California", 33.1895, -117.2386),
    City("Woodbridge", "New Jersey", 40.5607, -74.2927),
    City("Renton", "Washington", 47.4761, -122.192),
    City("Lakewood", "New Jersey", 40.0771, -74.2004),
    City("San Angelo", "Texas", 31.4411, -100.4505),
    City("Clinton", "Michigan", 42.5903, -82.917),
  )
}
