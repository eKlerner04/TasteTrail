import Foundation

enum AppLanguage: String, CaseIterable {
    case german = "de"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .german: return "Deutsch"
        case .english: return "English"
        }
    }
    
    // MARK: - Main View Strings
    var findRestaurantsNearby: String {
        switch self {
        case .german: return "Finde Restaurants in der Nähe"
        case .english: return "Find Restaurants Nearby"
        }
    }
    
    var liveLocation: String {
        switch self {
        case .german: return "Mein Standort nutzen"
        case .english: return "Use my location"
        }
    }
    
    var enterAddress: String {
        switch self {
        case .german: return "Adresse eingeben ..."
        case .english: return "Enter address ..."
        }
    }
    
    var radius: String {
        switch self {
        case .german: return "Radius"
        case .english: return "Radius"
        }
    }
    
    var searchingAddress: String {
        switch self {
        case .german: return "Suche Adresse ..."
        case .english: return "Searching address ..."
        }
    }
    
    var foundLocation: String {
        switch self {
        case .german: return "Gefundener Ort:"
        case .english: return "Found Location:"
        }
    }
    
    var restaurantsInRadius: String {
        switch self {
        case .german: return "Restaurants im Radius:"
        case .english: return "Restaurants in Radius:"
        }
    }
    
    var noRestaurantsFound: String {
        switch self {
        case .german: return "Keine Restaurants im Radius gefunden."
        case .english: return "No restaurants found in radius."
        }
    }
    
    var search: String {
        switch self {
        case .german: return "Suchen"
        case .english: return "Search"
        }
    }
    
    var addressNotFound: String {
        switch self {
        case .german: return "Adresse konnte nicht gefunden werden:"
        case .english: return "Address could not be found:"
        }
    }
    
    var noValidCoordinates: String {
        switch self {
        case .german: return "Keine gültigen Koordinaten gefunden."
        case .english: return "No valid coordinates found."
        }
    }
    
    var searchError: String {
        switch self {
        case .german: return "Fehler bei der Suche:"
        case .english: return "Search error:"
        }
    }
    
    var noRestaurantsFoundError: String {
        switch self {
        case .german: return "Keine Restaurants gefunden."
        case .english: return "No restaurants found."
        }
    }
    
    // MARK: - Search Results View Strings
    var searchResultsFor: String {
        switch self {
        case .german: return "Suchergebnisse für:"
        case .english: return "Search Results for:"
        }
    }
    
    var searchResultsForRestaurants: String {
        switch self{
        case .german: return "Gefundene Restaurants:"
        case .english: return "Found restaurants:"
        }
    }
    
    var searchResultsForRadius: String{
        switch self{
        case .german: return "Radius:"
        case .english: return "Radius"
        }
    }
    
    var results: String {
        switch self {
        case .german: return "Ergebnisse"
        case .english: return "Results"
        }
    }
    
    // MARK: - Settings View Strings
    var settings: String {
        switch self {
        case .german: return "Einstellungen"
        case .english: return "Settings"
        }
    }
    
    var language: String {
        switch self {
        case .german: return "Sprache"
        case .english: return "Language"
        }
    }
    
    var appLanguage: String {
        switch self {
        case .german: return "App-Sprache"
        case .english: return "App Language"
        }
    }
    
    // MARK: - Filter Strings
    var filter: String {
        switch self {
        case .german: return "Filter"
        case .english: return "Filter"
        }
    }
    
    var allCategories: String {
        switch self {
        case .german: return "Alle"
        case .english: return "All"
        }
    }
    
    var categoryRestaurant: String {
        switch self {
        case .german: return "Restaurant"
        case .english: return "Restaurant"
        }
    }
    
    var categoryCafe: String {
        switch self {
        case .german: return "Café"
        case .english: return "Café"
        }
    }
    
    var categoryBakery: String {
        switch self {
        case .german: return "Bäckerei"
        case .english: return "Bakery"
        }
    }
    
    var categoryFastFood: String {
        switch self {
        case .german: return "Fast Food"
        case .english: return "Fast Food"
        }
    }
    
    var categoryBar: String {
        switch self {
        case .german: return "Bar"
        case .english: return "Bar"
        }
    }
    
    var categoryPizza: String {
        switch self {
        case .german: return "Pizza"
        case .english: return "Pizza"
        }
    }
    
    var categoryIceCream: String {
        switch self {
        case .german: return "Eis"
        case .english: return "Ice Cream"
        }
    }
    
    var categoryBistro: String {
        switch self {
        case .german: return "Bistro"
        case .english: return "Bistro"
        }
    }
    
    var categoryPub: String {
        switch self {
        case .german: return "Pub"
        case .english: return "Pub"
        }
    }
    
    var categoryBrasserie: String {
        switch self {
        case .german: return "Brasserie"
        case .english: return "Brasserie"
        }
    }
    
    var categoryWinery: String {
        switch self {
        case .german: return "Weinstube"
        case .english: return "Winery"
        }
    }
    
    var categoryFastCasual: String {
        switch self {
        case .german: return "Fast Casual"
        case .english: return "Fast Casual"
        }
    }
    
    var categoryFineDining: String {
        switch self {
        case .german: return "Fine Dining"
        case .english: return "Fine Dining"
        }
    }
    
    var categoryFoodCourt: String {
        switch self {
        case .german: return "Food Court"
        case .english: return "Food Court"
        }
    }
    
    var browseRestaurants: String {
        switch self {
        case .german: return "Restaurants durchsuchen"
        case .english: return "Browse Restaurants"
        }
    }
    
    var noRestaurantsInCategory: String {
        switch self {
        case .german: return "Keine Restaurants in dieser Kategorie gefunden"
        case .english: return "No restaurants found in this category"
        }
    }
    
    // MARK: - LeftRightView Strings
    var openRoute: String {
        switch self {
        case .german: return "Route öffnen"
        case .english: return "Open Route"
        }
    }
    
    var openWebsite: String {
        switch self {
        case .german: return "Website öffnen"
        case .english: return "Open Website"
        }
    }
    
    var postalCode: String {
        switch self {
        case .german: return "PLZ"
        case .english: return "Postal Code"
        }
    }
    
    var menu: String {
        switch self {
        case .german: return "Menü"
        case .english: return "Menu"
        }
    }
    
    var reviews: String {
        switch self {
        case .german: return "Bewertungen"
        case .english: return "Reviews"
        }
    }
}

