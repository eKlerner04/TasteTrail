import Foundation
import MapKit
import CoreLocation
import UIKit

class RestaurantSearchService {
    
    /// Sucht Restaurants in einem erweiterten Radius durch Aufteilung in 4 Quadranten
    static func searchRestaurants(
        around coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        completion: @escaping ([RestaurantLocation]) -> Void
    ) {
        // Für größere Radien (über 1km) teilen wir in 4 Quadranten auf
        let shouldSplitSearch = radius > 1000
        
        if shouldSplitSearch {
            searchInQuadrants(around: coordinate, radius: radius, completion: completion)
        } else {
            // Für kleinere Radien eine normale Suche
            searchInSingleRegion(around: coordinate, radius: radius, completion: completion)
        }
    }
    
    /// Sucht in 4 Quadranten und kombiniert die Ergebnisse
    private static func searchInQuadrants(
        around coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        completion: @escaping ([RestaurantLocation]) -> Void
    ) {
        // Berechne die Offset-Distanz für jeden Quadranten (ca. 35% des Radius)
        let offsetDistance = radius * 0.35
        
        // Erstelle 4 Quadranten-Zentren (Nord-Ost, Nord-West, Süd-Ost, Süd-West)
        let quadrants = [
            createOffsetCoordinate(from: coordinate, latOffset: offsetDistance, lonOffset: offsetDistance),   // Nord-Ost
            createOffsetCoordinate(from: coordinate, latOffset: offsetDistance, lonOffset: -offsetDistance),  // Nord-West
            createOffsetCoordinate(from: coordinate, latOffset: -offsetDistance, lonOffset: offsetDistance),  // Süd-Ost
            createOffsetCoordinate(from: coordinate, latOffset: -offsetDistance, lonOffset: -offsetDistance)  // Süd-West
        ]
        
        var allResults: [RestaurantLocation] = []
        let group = DispatchGroup()
        let lock = NSLock()
        
        // Führe Suche in jedem Quadranten aus
        for quadrantCenter in quadrants {
            group.enter()
            searchInSingleRegion(around: quadrantCenter, radius: radius * 0.6) { restaurants in
                lock.lock()
                allResults.append(contentsOf: restaurants)
                lock.unlock()
                group.leave()
            }
        }
        
        // Warte bis alle Suchen abgeschlossen sind
        group.notify(queue: .main) {
            // Entferne Duplikate basierend auf Namen und ungefährer Position
            let uniqueRestaurants = removeDuplicates(from: allResults)
            completion(uniqueRestaurants)
        }
    }
    
    /// Einzelne Suchregion
    private static func searchInSingleRegion(
        around coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        completion: @escaping ([RestaurantLocation]) -> Void
    ) {
        print("🔍 Starte Restaurant-Suche...")
        print("   Koordinaten: \(coordinate.latitude), \(coordinate.longitude)")
        print("   Radius: \(radius) m")
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "Restaurant"
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            print("🔍 MapKit Suche abgeschlossen")
            if let error = error {
                print("Suchfehler: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let mapItems = response?.mapItems else {
                print("⚠️ Keine MapItems gefunden")
                completion([])
                return
            }
            
            print("✅ \(mapItems.count) Restaurants von MapKit gefunden")
            
            // Verwende DispatchGroup um Yelp-Daten parallel zu holen
            let group = DispatchGroup()
            var restaurants: [RestaurantLocation] = []
            let lock = NSLock()
            
            // Begrenze auf max 20 Restaurants um Rate Limits zu respektieren
            let limitedItems = Array(mapItems.prefix(20))
            print("📊 Verarbeite \(limitedItems.count) Restaurants mit Yelp API...")
            
            for (index, item) in limitedItems.enumerated() {
                guard let name = item.name, let location = item.placemark.location else { continue }
                
                group.enter()
                
                // Kleiner Delay zwischen Requests (Rate Limit Schutz)
                let delay = Double(index) * 0.1 // 100ms zwischen Requests
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    // Hole Yelp-Daten für dieses Restaurant
                    YelpAPIService.fetchRestaurantData(name: name, coordinate: location.coordinate) { yelpData in
                        defer { group.leave() }
                        
                        // Debug: Zeige alle verfügbaren Daten
                        print("📍 Restaurant gefunden: \(name)")
                        print("   - Phone: \(item.phoneNumber ?? "keine")")
                        print("   - Category: \(item.pointOfInterestCategory?.rawValue ?? "keine")")
                        
                        // Formatiere Adresse
                        let addressComponents = [
                            item.placemark.thoroughfare,
                            item.placemark.subThoroughfare,
                            item.placemark.locality
                        ].compactMap { $0 }
                        let address = addressComponents.isEmpty ? nil : addressComponents.joined(separator: ", ")
                        
                        // Kategorie/Typ
                        let category = item.pointOfInterestCategory?.rawValue
                        
                        // Küchentypen basierend auf Kategorie bestimmen
                        let cuisineTypes = determineCuisineTypes(from: category, name: name)
                        
                        // Verwende NUR Yelp-Bilder, kein Fallback
                        // Wenn kein Yelp-Bild vorhanden ist, imageURL = nil für Fallback-Anzeige
                        let imageURL = yelpData?.imageURL
                        
                        // Website URL (falls vorhanden)
                        let websiteURL = item.url?.absoluteString
                        
                        // Verwende NUR echte Yelp-Daten, keine Platzhalter
                        // Wenn keine Yelp-Daten vorhanden sind, werden Rating/Menü einfach nil/leer sein
                        let rating = yelpData?.rating
                        let reviewCount = yelpData?.reviewCount
                        let menuItems = yelpData?.menuItems ?? []
                        let yelpURL = yelpData?.yelpURL
                        
                        print("   - Rating: \(rating != nil ? String(format: "%.1f", rating!) : "keine")")
                        print("   - Review Count: \(reviewCount ?? 0)")
                        print("   - Menu Items: \(menuItems.count)")
                        print("---")
                        
                        let restaurant = RestaurantLocation(
                            name: name,
                            coordinate: location.coordinate,
                            address: address,
                            phoneNumber: item.phoneNumber,
                            category: category,
                            imageURL: imageURL,
                            cuisineTypes: cuisineTypes,
                            websiteURL: websiteURL,
                            timeZone: item.placemark.timeZone,
                            postalCode: item.placemark.postalCode,
                            country: item.placemark.country,
                            locality: item.placemark.locality,
                            rating: rating,
                            reviewCount: reviewCount,
                            menuItems: menuItems,
                            yelpURL: yelpURL
                        )
                        
                        lock.lock()
                        restaurants.append(restaurant)
                        lock.unlock()
                    }
                }
            }
            
            // Warte bis alle Yelp-Requests abgeschlossen sind
            group.notify(queue: .main) {
                completion(restaurants)
            }
        }
    }
    
    /// Erstellt eine neue Koordinate mit Offset
    private static func createOffsetCoordinate(
        from coordinate: CLLocationCoordinate2D,
        latOffset: CLLocationDistance,
        lonOffset: CLLocationDistance
    ) -> CLLocationCoordinate2D {
        // Konvertiere Meter in Grad (ungefähre Berechnung)
        let latDelta = latOffset / 111000.0  // ~111km pro Breitengrad
        let lonDelta = lonOffset / (111000.0 * cos(coordinate.latitude * .pi / 180.0))  // Angepasst für Längengrad
        
        return CLLocationCoordinate2D(
            latitude: coordinate.latitude + latDelta,
            longitude: coordinate.longitude + lonDelta
        )
    }
    
    /// Entfernt Duplikate aus der Restaurant-Liste
    private static func removeDuplicates(from restaurants: [RestaurantLocation]) -> [RestaurantLocation] {
        var uniqueRestaurants: [RestaurantLocation] = []
        var seenNames: Set<String> = []
        
        for restaurant in restaurants {
            // Erstelle einen eindeutigen Key aus Name und gerundeten Koordinaten
            let roundedLat = round(restaurant.coordinate.latitude * 10000) / 10000
            let roundedLon = round(restaurant.coordinate.longitude * 10000) / 10000
            let key = "\(restaurant.name)_\(roundedLat)_\(roundedLon)"
            
            if !seenNames.contains(key) {
                seenNames.insert(key)
                uniqueRestaurants.append(restaurant)
            }
        }
        
        return uniqueRestaurants
    }
    
    /// Versucht Bild-URL von MapKit/Apple Maps zu bekommen
    private static func getImageURL(from mapItem: MKMapItem, name: String, cuisineTypes: [String]) -> String? {
        // Debug: Zeige alle verfügbaren Properties
        print("   → Prüfe verfügbare Bild-Daten...")
        
        // Option 1: Prüfe ob MapItem URL vorhanden ist
        if let url = mapItem.url {
            print("   → MapItem URL: \(url.absoluteString)")
        }
        
        // Option 2: Look Around für iOS 16+ (komplex, aber möglich)
        // Das Problem: Look Around gibt kein direktes Bild zurück, sondern nur UI-Komponenten
        // Für echte Bilder müssen wir einen Screenshot machen oder einen externen Service nutzen
        
        // Leider stellt MapKit keine direkten Bild-URLs bereit
        // Apple Maps zeigt Bilder nur in der App an, nicht über API
        
        print("   → Keine direkten Bilder von MapKit verfügbar")
        print("   → Verwende Fallback-Service")
        
        // Verwende Fallback mit Foodish/Picsum
        return generateImageURL(for: name, cuisineTypes: cuisineTypes)
    }
    
    /// Generiert eine Bild-URL für das Restaurant (Fallback)
    private static func generateImageURL(for name: String, cuisineTypes: [String]) -> String {
        // Verwende Foodish API für echte Restaurant/Food-Bilder
        // Foodish API Random-Endpoint: https://foodish-api.herokuapp.com/
        
        // Bestimme Bildtyp basierend auf Küchentyp
        let imageCategory: String
        
        if let primaryCuisine = cuisineTypes.first?.lowercased() {
            if primaryCuisine.contains("pizza") {
                imageCategory = "pizza"
            } else if primaryCuisine.contains("burger") || primaryCuisine.contains("fast food") {
                imageCategory = "burger"
            } else if primaryCuisine.contains("sushi") || primaryCuisine.contains("japanisch") {
                imageCategory = "sushi"
            } else if primaryCuisine.contains("chinesisch") {
                imageCategory = "chinese"
            } else if primaryCuisine.contains("italienisch") {
                imageCategory = "pasta"
            } else if primaryCuisine.contains("bäckerei") || primaryCuisine.contains("bakery") {
                imageCategory = "dessert"
            } else {
                imageCategory = "biryani" // Fallback
            }
        } else {
            imageCategory = "biryani" // Fallback
        }
        
        // Verwende Hash des Restaurant-Namens für konsistente Bilder
        let seed = abs(name.hashValue)
        
        // Option 1: Picsum Photos (kein API-Key, zuverlässig, aber keine echten Restaurant-Bilder)
        // return "https://picsum.photos/seed/\(name)\(seed)/400/300"
        
        // Option 2: Foodish API (kein API-Key, echte Food-Bilder)
        // Verwende den Random-Endpoint für zuverlässige Bilder
        // Beachte: Die API könnte gelegentlich langsamer sein oder ausfallen
        return "https://foodish-api.herokuapp.com/images/\(imageCategory)/\(imageCategory)\(seed % 30 + 1).jpg"
        
        // Option 3: Unsplash API (benötigt kostenlosen API-Key für bessere Qualität)
        // Müsste zuerst registriert werden auf unsplash.com/developers
    }
    
    /// Bestimmt Küchentypen basierend auf Kategorie und Name
    private static func determineCuisineTypes(from category: String?, name: String) -> [String] {
        var cuisines: [String] = []
        let categoryLower = category?.lowercased() ?? ""
        let nameLower = name.lowercased()
        
        // Küchentypen basierend auf Kategorie
        if categoryLower.contains("restaurant") || categoryLower.contains("dining") {
            cuisines.append("Restaurant")
        }
        if categoryLower.contains("cafe") || categoryLower.contains("coffee") {
            cuisines.append("Café")
        }
        if categoryLower.contains("bakery") {
            cuisines.append("Bäckerei")
        }
        if categoryLower.contains("fastfood") || categoryLower.contains("fast.food") {
            cuisines.append("Fast Food")
        }
        if categoryLower.contains("bar") || categoryLower.contains("pub") {
            cuisines.append("Bar")
        }
        if categoryLower.contains("pizza") {
            cuisines.append("Pizza")
        }
        if categoryLower.contains("icecream") || categoryLower.contains("gelato") {
            cuisines.append("Eis")
        }
        if categoryLower.contains("bistro") {
            cuisines.append("Bistro")
        }
        if categoryLower.contains("pub") || categoryLower.contains("biergarten") {
            cuisines.append("Pub")
        }
        if categoryLower.contains("brasserie") {
            cuisines.append("Brasserie")
        }
        if categoryLower.contains("winery") || categoryLower.contains("weinstube") || categoryLower.contains("weingut") {
            cuisines.append("Weinstube")
        }
        if categoryLower.contains("food.court") || categoryLower.contains("food.hall") {
            cuisines.append("Food Court")
        }
        
        // Küchentypen basierend auf Restaurant-Name
        let cuisineKeywords: [String: String] = [
            "pizza": "Pizza",
            "italian": "Italienisch",
            "chinese": "Chinesisch",
            "japanese": "Japanisch",
            "sushi": "Sushi",
            "mexican": "Mexikanisch",
            "indian": "Indisch",
            "thai": "Thailändisch",
            "burger": "Burger",
            "steak": "Steak",
            "seafood": "Meeresfrüchte",
            "vegetarian": "Vegetarisch",
            "vegan": "Vegan",
            "bakery": "Bäckerei",
            "cafe": "Café",
            "coffee": "Kaffee",
            "bar": "Bar",
            "bistro": "Bistro",
            "brasserie": "Brasserie",
            "pub": "Pub",
            "winery": "Weinstube",
            "weinstube": "Weinstube",
            "fine.dining": "Fine Dining",
            "gourmet": "Fine Dining",
            "upscale": "Fine Dining"
        ]
        
        for (keyword, cuisine) in cuisineKeywords {
            if nameLower.contains(keyword) && !cuisines.contains(cuisine) {
                cuisines.append(cuisine)
            }
        }
        
        // Fallback: Wenn keine spezifische Küche gefunden wurde
        if cuisines.isEmpty {
            cuisines.append("Verschiedenes")
        }
        
        return cuisines
    }
    
    /// Generiert beispielhafte Rating-Daten basierend auf Restaurant-Name
    /// Hinweis: MapKit stellt keine echten Rating-Daten bereit, daher verwenden wir Platzhalter
    private static func generateRatingData(for category: String, name: String) -> (rating: Double?, reviewCount: Int?) {
        // Generiere konsistente aber verschiedene Ratings basierend auf Name-Hash
        let hash = abs(name.hashValue)
        let baseRating = 3.5 + Double(hash % 15) / 10.0 // Zwischen 3.5 und 5.0
        let reviewCount = 10 + (hash % 500) // Zwischen 10 und 510
        
        return (rating: baseRating, reviewCount: reviewCount)
    }
    
    /// Generiert beispielhafte Menüpunkte basierend auf Küchentyp
    private static func generateMenuItems(for cuisineTypes: [String]) -> [String] {
        var items: [String] = []
        
        let cuisineLower = cuisineTypes.first?.lowercased() ?? ""
        
        // Generiere Menüpunkte basierend auf Küchentyp
        if cuisineLower.contains("pizza") {
            items = ["Margherita", "Pepperoni", "Hawaii", "Quattro Stagioni", "Vegetariana"]
        } else if cuisineLower.contains("burger") || cuisineLower.contains("fast food") {
            items = ["Cheeseburger", "Chicken Burger", "Veggie Burger", "Pommes", "Nachos"]
        } else if cuisineLower.contains("sushi") || cuisineLower.contains("japanisch") {
            items = ["Maki", "Nigiri", "Sashimi", "Temaki", "Tempura"]
        } else if cuisineLower.contains("italienisch") {
            items = ["Spaghetti Carbonara", "Penne Arrabbiata", "Lasagne", "Risotto", "Tiramisu"]
        } else if cuisineLower.contains("chinesisch") {
            items = ["Gong Bao Huhn", "Frühlingsrollen", "Reisgericht", "Süß-sauer", "Chow Mein"]
        } else if cuisineLower.contains("bäckerei") || cuisineLower.contains("bakery") {
            items = ["Croissant", "Baguette", "Kuchen", "Brezel", "Donut"]
        } else if cuisineLower.contains("café") || cuisineLower.contains("kaffee") {
            items = ["Cappuccino", "Latte Macchiato", "Espresso", "Kuchen", "Croissant"]
        } else if cuisineLower.contains("bar") || cuisineLower.contains("pub") {
            items = ["Cocktails", "Bier", "Wein", "Snacks", "Nachos"]
        } else {
            // Standard-Menü
            items = ["Tagesgericht", "Vorspeise", "Hauptgericht", "Dessert", "Getränke"]
        }
        
        return items
    }
    
    /// Filtert Restaurants nach tatsächlichem Radius vom Zentrum
    static func filterRestaurantsByRadius(
        restaurants: [RestaurantLocation],
        center: CLLocationCoordinate2D,
        radius: CLLocationDistance
    ) -> [RestaurantLocation] {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        
        return restaurants.compactMap { restaurant in
            let restaurantLocation = CLLocation(
                latitude: restaurant.coordinate.latitude,
                longitude: restaurant.coordinate.longitude
            )
            let distance = restaurantLocation.distance(from: centerLocation)
            
            guard distance <= radius else { return nil }
            
            // Erstelle neues Restaurant mit Distanz-Information
            return RestaurantLocation(
                name: restaurant.name,
                coordinate: restaurant.coordinate,
                address: restaurant.address,
                phoneNumber: restaurant.phoneNumber,
                category: restaurant.category,
                distance: distance,
                imageURL: restaurant.imageURL,
                cuisineTypes: restaurant.cuisineTypes,
                websiteURL: restaurant.websiteURL,
                timeZone: restaurant.timeZone,
                postalCode: restaurant.postalCode,
                country: restaurant.country,
                locality: restaurant.locality,
                rating: restaurant.rating,
                reviewCount: restaurant.reviewCount,
                menuItems: restaurant.menuItems,
                yelpURL: restaurant.yelpURL
            )
        }
    }
}


