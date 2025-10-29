import Foundation
import CoreLocation

struct YelpRestaurantData {
    let rating: Double?
    let reviewCount: Int?
    let imageURL: String?
    let menuItems: [String]
    let yelpURL: String? // Link zur Yelp-Seite
}

class YelpAPIService {
    // Yelp API Ke    
    /// Sucht Restaurant-Daten von Yelp API
    static func fetchRestaurantData(
        name: String,
        coordinate: CLLocationCoordinate2D,
        completion: @escaping (YelpRestaurantData?) -> Void
    ) {
        print("🍽️ Suche Yelp-Daten für: \(name)")
        
        // Suche nach Restaurant mit Name und Koordinaten
        let searchURL = "\(baseURL)/businesses/search"
        let parameters = [
            "term": name,
            "latitude": String(coordinate.latitude),
            "longitude": String(coordinate.longitude),
            "radius": "200", // Kleiner Radius für genaue Treffer
            "limit": "1",
            "categories": "restaurants,food" // Suche nur nach Restaurants
        ]
        
        var urlComponents = URLComponents(string: searchURL)
        urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = urlComponents?.url else {
            print("❌ Yelp API: Konnte URL nicht erstellen für \(name)")
            completion(nil)
            return
        }
        
        print("   Yelp URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("   Yelp API Response erhalten für \(name)")
            if let error = error {
                print("❌ Yelp API Fehler für \(name): \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("❌ Yelp API: Keine Daten erhalten für \(name)")
                completion(nil)
                return
            }
            
            // Debug: Zeige HTTP Response Status
            if let httpResponse = response as? HTTPURLResponse {
                print("   HTTP Status: \(httpResponse.statusCode)")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let businesses = json?["businesses"] as? [[String: Any]]
                
                print("   Gefundene Businesses: \(businesses?.count ?? 0)")
                
                if let business = businesses?.first {
                    let rating = business["rating"] as? Double
                    let reviewCount = business["review_count"] as? Int
                    let imageURL = business["image_url"] as? String
                    let yelpURL = business["url"] as? String
                    
                    // Hole Kategorien für Menü-Hinweise
                    let categories = business["categories"] as? [[String: Any]]
                    var menuItems: [String] = []
                    
                    if let categories = categories {
                        // Verwende Yelp-Kategorien als Menü-Hinweise
                        menuItems = categories.compactMap { $0["title"] as? String }
                        
                        // Erweitere mit typischen Gerichten basierend auf Kategorien
                        let categoryTitles = menuItems.map { $0.lowercased() }
                        if categoryTitles.contains(where: { $0.contains("pizza") }) {
                            menuItems.append(contentsOf: ["Margherita", "Pepperoni", "Hawaii"])
                        } else if categoryTitles.contains(where: { $0.contains("burger") }) {
                            menuItems.append(contentsOf: ["Cheeseburger", "Chicken Burger", "Pommes"])
                        } else if categoryTitles.contains(where: { $0.contains("sushi") || $0.contains("japanese") }) {
                            menuItems.append(contentsOf: ["Maki", "Nigiri", "Sashimi"])
                        } else if categoryTitles.contains(where: { $0.contains("chinese") }) {
                            menuItems.append(contentsOf: ["Gong Bao", "Frühlingsrollen", "Reisgericht"])
                        } else if categoryTitles.contains(where: { $0.contains("italian") }) {
                            menuItems.append(contentsOf: ["Pasta", "Pizza", "Risotto"])
                        }
                    }
                    
                    let yelpData = YelpRestaurantData(
                        rating: rating,
                        reviewCount: reviewCount,
                        imageURL: imageURL,
                        menuItems: menuItems,
                        yelpURL: yelpURL
                    )
                    
                    print("✅ Yelp Daten gefunden für \(name): Rating \(rating ?? 0), Reviews \(reviewCount ?? 0)")
                    completion(yelpData)
                } else {
                    print("⚠️ Keine Yelp Daten für \(name)")
                    completion(nil)
                }
            } catch {
                print("❌ Yelp JSON Parse Fehler für \(name): \(error.localizedDescription)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("   JSON Response: \(jsonString.prefix(500))")
                }
                completion(nil)
            }
        }.resume()
    }
}

