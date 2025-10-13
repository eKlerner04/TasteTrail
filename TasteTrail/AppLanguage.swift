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
}

