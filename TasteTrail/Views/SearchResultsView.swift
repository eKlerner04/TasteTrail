import SwiftUI
import CoreLocation

enum RestaurantCategory: CaseIterable {
    case all
    case restaurant
    case cafe
    case bakery
    case fastFood
    case bar
    case pizza
    case iceCream
    case bistro
    case pub
    case brasserie
    case winery
    case fastCasual
    case fineDining
    case foodCourt
    
    var filterKey: String {
        switch self {
        case .all: return ""
        case .restaurant: return "restaurant"
        case .cafe: return "cafe"
        case .bakery: return "bakery"
        case .fastFood: return "fastFood"
        case .bar: return "bar"
        case .pizza: return "pizza"
        case .iceCream: return "iceCream"
        case .bistro: return "bistro"
        case .pub: return "pub"
        case .brasserie: return "brasserie"
        case .winery: return "winery"
        case .fastCasual: return "fastCasual"
        case .fineDining: return "fineDining"
        case .foodCourt: return "foodCourt"
        }
    }
    
    func displayName(using language: AppLanguage) -> String {
        switch self {
        case .all: return language.allCategories
        case .restaurant: return language.categoryRestaurant
        case .cafe: return language.categoryCafe
        case .bakery: return language.categoryBakery
        case .fastFood: return language.categoryFastFood
        case .bar: return language.categoryBar
        case .pizza: return language.categoryPizza
        case .iceCream: return language.categoryIceCream
        case .bistro: return language.categoryBistro
        case .pub: return language.categoryPub
        case .brasserie: return language.categoryBrasserie
        case .winery: return language.categoryWinery
        case .fastCasual: return language.categoryFastCasual
        case .fineDining: return language.categoryFineDining
        case .foodCourt: return language.categoryFoodCourt
        }
    }
}

struct SearchResultsView: View{
    @ObservedObject var settings = AppSettings.shared
    let address: String
    let restaurants: [RestaurantLocation]
    let radius: CLLocationDistance
    @State private var showLeftRightView = false
    @State private var selectedCategory: RestaurantCategory = .all
    
    // Verfügbare Kategorien aus den Restaurants extrahieren
    private var availableCategories: [RestaurantCategory] {
        var available: [RestaurantCategory] = [.all]
        
        // Prüfe, welche Kategorien in den Restaurants vorhanden sind
        for category in RestaurantCategory.allCases where category != .all {
            let hasCategory = restaurants.contains { restaurant in
                // Prüfe sowohl Kategorie als auch Name
                let categoryMatch = restaurant.category?.lowercased().contains(category.filterKey.lowercased()) ?? false
                let nameMatch = restaurant.name.lowercased().contains(category.filterKey.lowercased())
                
                // Spezielle Prüfungen für verschiedene Kategorien
                switch category {
                case .bar:
                    return categoryMatch || nameMatch || 
                           restaurant.name.lowercased().contains("bar") ||
                           restaurant.name.lowercased().contains("tavern")
                case .pub:
                    return categoryMatch || nameMatch ||
                           restaurant.name.lowercased().contains("pub") ||
                           restaurant.name.lowercased().contains("biergarten")
                case .bistro:
                    return categoryMatch || nameMatch ||
                           restaurant.name.lowercased().contains("bistro")
                case .brasserie:
                    return categoryMatch || nameMatch ||
                           restaurant.name.lowercased().contains("brasserie")
                case .winery:
                    return categoryMatch || nameMatch ||
                           restaurant.name.lowercased().contains("winery") ||
                           restaurant.name.lowercased().contains("weinstube") ||
                           restaurant.name.lowercased().contains("weingut")
                case .fineDining:
                    return categoryMatch || nameMatch ||
                           restaurant.name.lowercased().contains("gourmet") ||
                           restaurant.name.lowercased().contains("fine dining")
                case .foodCourt:
                    return categoryMatch || nameMatch ||
                           restaurant.name.lowercased().contains("food court") ||
                           restaurant.name.lowercased().contains("food hall")
                default:
                    return categoryMatch || nameMatch
                }
            }
            if hasCategory {
                available.append(category)
            }
        }
        
        // Debug: Zeige gefundene Kategorien
        print("🔍 Verfügbare Kategorien: \(available.map { $0.displayName(using: settings.language) })")
        
        return available
    }
    
    // Gefilterte Restaurants
    private var filteredRestaurants: [RestaurantLocation] {
        if selectedCategory == .all {
            return restaurants
        }
        
        let filterKey = selectedCategory.filterKey.lowercased()
        let filtered = restaurants.filter { restaurant in
            restaurantMatchesCategory(restaurant, filterKey: filterKey)
        }
        
        print("🔍 Filter '\(selectedCategory.displayName(using: settings.language))': \(filtered.count) von \(restaurants.count) Restaurants")
        
        return filtered
    }
    
    // Gibt das passende Icon für eine Kategorie zurück
    private func iconForCategory(_ category: RestaurantCategory) -> String {
        switch category {
        case .all: return "list.bullet"
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer"
        case .bakery: return "birthday.cake"
        case .fastFood: return "takeoutbag.and.cup.and.straw"
        case .bar: return "wineglass"
        case .pizza: return "circle.grid.2x2"
        case .iceCream: return "snowflake"
        case .bistro: return "cup.and.saucer.fill"
        case .pub: return "mug.fill"
        case .brasserie: return "wineglass.fill"
        case .winery: return "wineglass.2.fill"
        case .fastCasual: return "takeoutbag.and.cup.and.straw.fill"
        case .fineDining: return "fork.knife.circle.fill"
        case .foodCourt: return "tray.2.fill"
        }
    }
    
    // Prüft, ob eine Kategorie mit dem Filter übereinstimmt
    private func matchesCategory(_ category: String, filterKey: String) -> Bool {
        if filterKey.isEmpty { return true }
        
        // Spezielle Mappings für verschiedene Kategorien-Bezeichnungen
        let mappings: [String: [String]] = [
            "restaurant": ["restaurant", "dining", "eating"],
            "cafe": ["cafe", "coffee", "café"],
            "bakery": ["bakery", "baker", "bäckerei"],
            "fastfood": ["fastfood", "fast.food", "quick.service"],
            "bar": ["bar", "tavern"],
            "pizza": ["pizza", "pizzeria"],
            "icecream": ["ice.cream", "icecream", "gelato"],
            "bistro": ["bistro"],
            "pub": ["pub", "biergarten"],
            "brasserie": ["brasserie", "brassiere"],
            "winery": ["winery", "weinstube", "weingut", "wine"],
            "fastcasual": ["fast.casual", "casual.dining"],
            "finedining": ["fine.dining", "upscale", "gourmet"],
            "foodcourt": ["food.court", "food.hall", "market"]
        ]
        
        // Prüfe direkte Übereinstimmung
        if category.contains(filterKey) {
            return true
        }
        
        // Prüfe Mappings
        if let synonyms = mappings[filterKey] {
            return synonyms.contains(where: { category.contains($0) })
        }
        
        return false
    }
    
    // Prüft Restaurant-Name UND Kategorie für Filter-Matching
    private func restaurantMatchesCategory(_ restaurant: RestaurantLocation, filterKey: String) -> Bool {
        if filterKey.isEmpty { return true }
        
        let nameLower = restaurant.name.lowercased()
        let categoryLower = restaurant.category?.lowercased() ?? ""
        
        // Spezielle Prüfungen für verschiedene Filter
        switch filterKey {
        case "bar":
            return categoryLower.contains("bar") || nameLower.contains("bar") || nameLower.contains("tavern")
        case "pub":
            return categoryLower.contains("pub") || nameLower.contains("pub") || nameLower.contains("biergarten")
        case "bistro":
            return categoryLower.contains("bistro") || nameLower.contains("bistro")
        case "brasserie":
            return categoryLower.contains("brasserie") || nameLower.contains("brasserie")
        case "winery":
            return categoryLower.contains("winery") || nameLower.contains("winery") || 
                   nameLower.contains("weinstube") || nameLower.contains("weingut")
        case "finedining":
            return categoryLower.contains("fine.dining") || nameLower.contains("gourmet") || 
                   nameLower.contains("fine dining") || nameLower.contains("upscale")
        case "foodcourt":
            return categoryLower.contains("food.court") || nameLower.contains("food court") || 
                   nameLower.contains("food hall")
        default:
            return matchesCategory(categoryLower, filterKey: filterKey) || 
                   nameLower.contains(filterKey)
        }
    }
    
    var body: some View{
        VStack(spacing: 30) {
            if restaurants.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text(settings.language.noRestaurantsFound)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Filter-Sektion
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                    .foregroundColor(.blue)
                                Text(settings.language.filter)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(availableCategories, id: \.self) { category in
                                        Button(action: {
                                            selectedCategory = category
                                        }) {
                                            HStack(spacing: 6) {
                                                // Icon basierend auf Kategorie
                                                Image(systemName: iconForCategory(category))
                                                
                                                Text(category.displayName(using: settings.language))
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                            }
                                            .foregroundColor(selectedCategory == category ? .white : .primary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(selectedCategory == category ? Color.blue : Color(.systemGray5))
                                            .cornerRadius(20)
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Übersichts-Informationen
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("\(settings.language.searchResultsFor) \(address)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                HStack(spacing: 16) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "fork.knife.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.orange)
                                        Text("\(filteredRestaurants.count)")
                                            .font(.title)
                                            .fontWeight(.bold)
                                        Text(settings.language.searchResultsForRestaurants.replacingOccurrences(of: ":", with: ""))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack(spacing: 8) {
                                        Image(systemName: "location.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.blue)
                                        Text("\(Int(radius)) m")
                                            .font(.title)
                                            .fontWeight(.bold)
                                        Text(settings.language.radius)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 20)
                            
                            // Button zur Swipe-Ansicht
                            Button(action: {
                                showLeftRightView = true
                            }) {
                                HStack(spacing: 12) {
                                    Text(settings.language.browseRestaurants)
                                        .font(.system(.body, weight: .semibold))
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title3)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(filteredRestaurants.isEmpty ? Color.gray : Color.blue)
                                .cornerRadius(12)
                            }
                            .disabled(filteredRestaurants.isEmpty)
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                            
                            if selectedCategory != .all && filteredRestaurants.isEmpty {
                                Text(settings.language.noRestaurantsInCategory)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle(settings.language.results)
        .navigationDestination(isPresented: $showLeftRightView) {
            LeftRightView(restaurants: filteredRestaurants)
        }
    }
}
