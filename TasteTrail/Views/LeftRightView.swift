import SwiftUI
import CoreLocation
import MapKit

struct LeftRightView: View {
    @ObservedObject var settings = AppSettings.shared
    let restaurants: [RestaurantLocation]
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0
    @State private var isLoadingImages = true
    @State private var loadedImageCount = 0
    @State private var likedRestaurants: [UUID: LikedRestaurant] = [:] // Speichert gelikte Restaurants
    @State private var showResults = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Hintergrund
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if restaurants.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text(settings.language.noRestaurantsFound)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else if isLoadingImages {
                    // Loading Screen: Lade alle Bilder vor
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.blue)
                        Text("Lade Restaurant-Bilder...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("\(loadedImageCount) / \(restaurants.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .onAppear {
                        preloadImages()
                    }
                } else if currentIndex < restaurants.count {
                    ZStack {
                        // Restaurant-Karte (volle Größe)
                        restaurantCard(restaurant: restaurants[currentIndex], geometry: geometry)
                            .offset(dragOffset)
                            .rotationEffect(.degrees(dragRotation))
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation
                                        dragRotation = Double(value.translation.width / 20)
                                    }
                                    .onEnded { value in
                                        let swipeThreshold: CGFloat = 100
                                        
                                        if abs(value.translation.width) > swipeThreshold {
                                            // Swipe nach links oder rechts
                                            if value.translation.width > 0 {
                                                // Rechts swipen - Restaurant speichern/bevorzugen
                                                likeRestaurant() // Liken beim Rechts-Swipe
                                            } else {
                                                // Links swipen - Restaurant überspringen
                                                skipRestaurant() // Überspringen beim Links-Swipe
                                            }
                                        } else {
                                            // Zurück zur Mitte springen
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                dragOffset = .zero
                                                dragRotation = 0
                                            }
                                        }
                                    }
                            )
                        
                        // Fix positionierte Action-Buttons (unten) - bleiben immer an Position
                        VStack {
                            Spacer()
                            
                            HStack(spacing: 40) {
                                // Überspringen Button
                                Button(action: {
                                    skipRestaurant()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                                
                                Spacer()
                                
                                // Like/Speichern Button
                                Button(action: {
                                    likeRestaurant()
                                }) {
                                    Image(systemName: "heart.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                        .background(Color.green)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.bottom, 30)
                        }
                        .allowsHitTesting(true)
                    }
                } else {
                    // Alle Restaurants durchgesehen
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("Alle Restaurants durchgesehen!")
                            .font(.headline)
                        Button("Von vorne beginnen") {
                            currentIndex = 0
                            dragOffset = .zero
                            dragRotation = 0
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 4) {
                    Text("\(currentIndex + 1) / \(restaurants.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: Double(currentIndex + 1), total: Double(restaurants.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 150)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showResults = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                        if !likedRestaurants.isEmpty {
                            Text("\(likedRestaurants.count)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showResults) {
            ResultLeftRightView(likedRestaurants: Array(likedRestaurants.values))
        }
    }
    
    // Überspringen-Funktion
    // Lade alle Bilder vor, bevor die View angezeigt wird
    private func preloadImages() {
        guard !restaurants.isEmpty else {
            isLoadingImages = false
            return
        }
        
        let imageURLs = restaurants.compactMap { restaurant -> URL? in
            guard let imageURL = restaurant.imageURL else { return nil }
            return URL(string: imageURL)
        }
        
        var loadedCount = 0
        let totalCount = imageURLs.count
        
        // Wenn keine Bilder vorhanden, direkt fortfahren
        if totalCount == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoadingImages = false
            }
            return
        }
        
        // Lade alle Bilder parallel
        for url in imageURLs {
            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    loadedCount += 1
                    loadedImageCount = loadedCount
                    
                    // Wenn alle Bilder geladen sind oder nach max 3 Sekunden
                    if loadedCount >= totalCount {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isLoadingImages = false
                        }
                    }
                }
            }.resume()
        }
        
        // Timeout: Nach 3 Sekunden fortfahren, auch wenn nicht alle Bilder geladen sind
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if isLoadingImages {
                isLoadingImages = false
            }
        }
    }
    
    private func skipRestaurant() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset = CGSize(width: -1000, height: 0)
            dragRotation = -15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            moveToNext()
        }
    }
    
    // Like-Funktion
    private func likeRestaurant() {
        // Speichere das Restaurant als "geliked"
        let restaurant = restaurants[currentIndex]
        if let existing = likedRestaurants[restaurant.id] {
            // Erhöhe Like-Count wenn bereits vorhanden
            likedRestaurants[restaurant.id] = LikedRestaurant(
                restaurant: restaurant,
                likeCount: existing.likeCount + 1
            )
        } else {
            // Neues Like
            likedRestaurants[restaurant.id] = LikedRestaurant(restaurant: restaurant)
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset = CGSize(width: 1000, height: 0)
            dragRotation = 15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            moveToNext()
        }
    }
    
    private func restaurantCard(restaurant: RestaurantLocation, geometry: GeometryProxy) -> some View {
        // Bildgrößen-Einstellungen (hier anpassbar)
        let imageHeight: CGFloat = 250 // Höhe des Restaurant-Bildes
        let fallbackIconSize: CGFloat = 100 // Größe des Fallback-Icons
        
        // Prüfe ob ein echtes Bild vorhanden ist
        let hasRealImage = restaurant.imageURL != nil
        
        return VStack(alignment: .leading, spacing: 0) {
            // Restaurant Bild
            ZStack(alignment: .topTrailing) {
                // Echtes Bild vom Unsplash
                if let imageURL = restaurant.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            // Loading-State: Zeige Farbverlauf während Laden
                            restaurantBackgroundGradient(for: restaurant)
                                .frame(height: imageHeight)
                                .overlay(
                                    ProgressView()
                                        .tint(.white)
                                )
                        case .success(let image):
                            // Erfolgreich geladen: Zeige echtes Bild
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: imageHeight)
                                .clipped()
                        case .failure:
                            // Fehler: Fallback auf Farbverlauf + Icon
                            ZStack {
                                restaurantBackgroundGradient(for: restaurant)
                                    .frame(height: imageHeight)
                                
                                restaurantImage(for: restaurant)
                                    .font(.system(size: fallbackIconSize))
                                    .foregroundColor(.pink.opacity(0.9)) //hier habe ich was geändert

                            }
                        @unknown default:
                            restaurantBackgroundGradient(for: restaurant)
                                .frame(height: imageHeight)
                        }
                    }
                } else {
                    ZStack {
                        restaurantBackgroundGradient(for: restaurant)
                            .frame(height: imageHeight)
                        
                        restaurantImage(for: restaurant)
                            .font(.system(size: fallbackIconSize))
                            .foregroundColor(.white.opacity(0.9)) //hier habe ich was geändert
                        
                        VStack {
                            HStack {
                                Text(restaurant.name)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white) //hier habe ich grün gemachjt
                                    .shadow(color: .black.opacity(0.5), radius: 3)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 200)
                        }
                    }
                }
                
                // Name Overlay - nur bei echten Bildern mit Hintergrund-Balken
                if hasRealImage {
                    VStack {
                        Spacer()
                        HStack {
                            Text(restaurant.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 3)
                            Spacer()
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.6)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
            }
            
            // Inhalt
            VStack(alignment: .leading, spacing: 16) {
                // Küchentypen als Chips
                if !restaurant.cuisineTypes.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(restaurant.cuisineTypes, id: \.self) { cuisine in
                                HStack(spacing: 4) {
                                    Image(systemName: "fork.knife")
                                        .font(.caption2)
                                    Text(cuisine)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                Divider()
                
                // Bewertung & Rezensionen
                if let rating = restaurant.rating, let reviewCount = restaurant.reviewCount {
                    HStack(spacing: 12) {
                        // Sterne-Anzeige
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                let starValue = Double(index) + 1.0
                                if starValue <= rating {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.title3)
                                } else if starValue - 0.5 <= rating {
                                    Image(systemName: "star.lefthalf.fill")
                                        .foregroundColor(.yellow)
                                        .font(.title3)
                                } else {
                                    Image(systemName: "star")
                                        .foregroundColor(.gray)
                                        .font(.title3)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "%.1f", rating))
                                .font(.headline)
                                .foregroundColor(.primary)
                            HStack(spacing: 4) {
                                Text("(\(reviewCount) \(settings.language.reviews))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                // Yelp Link
                                if let yelpURL = restaurant.yelpURL, let url = URL(string: yelpURL) {
                                    Button(action: {
                                        UIApplication.shared.open(url)
                                    }) {
                                        HStack(spacing: 2) {
                                            Image(systemName: "link")
                                                .font(.caption2)
                                            Text("Yelp")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                }
                
                // Menü-Vorschau
                if !restaurant.menuItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.purple)
                                .font(.title3)
                            Text(settings.language.menu)
                                .font(.headline)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(restaurant.menuItems.prefix(5), id: \.self) { item in
                                    Text(item)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                }
                
                // Adresse & Standort
                VStack(alignment: .leading, spacing: 8) {
                    if let address = restaurant.address {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(address)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                if let locality = restaurant.locality, let country = restaurant.country {
                                    Text("\(locality), \(country)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    if let postalCode = restaurant.postalCode {
                                Text("\(settings.language.postalCode): \(postalCode)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 32)
                    }
                }
                
                Divider()
                
                // Distanz & Navigation
                VStack(alignment: .leading, spacing: 8) {
                    if let distance = restaurant.distance {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.orange)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(format: "%.0f m entfernt", distance))
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                // Button zum Öffnen in Apple Maps
                                Button(action: {
                                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: restaurant.coordinate))
                                    mapItem.name = restaurant.name
                                    mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                            .font(.caption)
                                        Text(settings.language.openRoute)
                                            .font(.caption)
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // Kontaktinformationen
                VStack(alignment: .leading, spacing: 8) {
                    if let phone = restaurant.phoneNumber {
                        HStack(spacing: 8) {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                            Button(action: {
                                if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text(phone)
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    if let websiteURL = restaurant.websiteURL, !websiteURL.contains("maps://") {
                        HStack(spacing: 8) {
                            Image(systemName: "safari.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            Button(action: {
                                if let url = URL(string: websiteURL) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text(settings.language.openWebsite)
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .padding(20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
    
    private func restaurantImage(for restaurant: RestaurantLocation) -> Image {
        // Bestimme Bild basierend auf Küchentyp
        if restaurant.cuisineTypes.contains(where: { $0.lowercased().contains("pizza") }) {
            return Image(systemName: "circle.grid.2x2.fill")
        } else if restaurant.cuisineTypes.contains(where: { $0.lowercased().contains("café") || $0.lowercased().contains("kaffee") }) {
            return Image(systemName: "cup.and.saucer.fill")
        } else if restaurant.cuisineTypes.contains(where: { $0.lowercased().contains("bäckerei") || $0.lowercased().contains("bakery") }) {
            return Image(systemName: "birthday.cake.fill")
        } else if restaurant.cuisineTypes.contains(where: { $0.lowercased().contains("bar") }) {
            return Image(systemName: "wineglass.fill")
        } else if restaurant.cuisineTypes.contains(where: { $0.lowercased().contains("burger") || $0.lowercased().contains("fast food") }) {
            return Image(systemName: "takeoutbag.and.cup.and.straw.fill")
        } else if restaurant.cuisineTypes.contains(where: { $0.lowercased().contains("sushi") || $0.lowercased().contains("japanisch") }) {
            return Image(systemName: "fish.fill")
        } else {
            return Image(systemName: "fork.knife.circle.fill")
        }
    }
    
    private func restaurantBackgroundGradient(for restaurant: RestaurantLocation) -> LinearGradient {
        // Bestimme Farbverlauf basierend auf Küchentyp
        let colors: [Color]
        
        if restaurant.cuisineTypes.contains(where: { $0.lowercased().contains("pizza") }) {
            colors = [Color.red.opacity(0.7), Color.orange.opacity(0.8)]
        } else if restaurant.cuisineTypes.contains(where: { $0.lowercased().contains("café") || $0.lowercased().contains("kaffee") }) {
            colors = [Color.brown.opacity(0.7), Color.orange.opacity(0.8)]
        } else if restaurant.cuisineTypes.contains(where: { $0.lowercased().contains("bäckerei") || $0.lowercased().contains("bakery") }) {
            colors = [Color.yellow.opacity(0.7), Color.orange.opacity(0.8)]
        } else if restaurant.cuisineTypes.contains(where: { $0.lowercased().contains("bar") }) {
            colors = [Color.purple.opacity(0.7), Color.pink.opacity(0.8)]
        } else if restaurant.cuisineTypes.contains(where: { $0.lowercased().contains("burger") || $0.lowercased().contains("fast food") }) {
            colors = [Color.orange.opacity(0.7), Color.red.opacity(0.8)]
        } else if restaurant.cuisineTypes.contains(where: { $0.lowercased().contains("sushi") || $0.lowercased().contains("japanisch") }) {
            colors = [Color.blue.opacity(0.7), Color.cyan.opacity(0.8)]
        } else {
            colors = [Color.gray.opacity(0.7), Color.blue.opacity(0.8)]
        }
        
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func moveToNext() {
        if currentIndex < restaurants.count - 1 {
            currentIndex += 1
        } else {
            currentIndex = restaurants.count // Alle durchgesehen
        }
        dragOffset = .zero
        dragRotation = 0
    }
    
    private func formatCategory(_ category: String) -> String {
        let cleaned = category.replacingOccurrences(of: "MKPOICategory", with: "")
        return cleaned.capitalized
    }
}

#Preview {
    NavigationStack {
        LeftRightView(restaurants: [
            RestaurantLocation(
                name: "Beispiel Restaurant",
                coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
                address: "Musterstraße 123, 10115 Berlin",
                phoneNumber: "+49 30 12345678",
                category: "MKPOICategoryRestaurant",
                distance: 500,
                imageURL: nil,
                cuisineTypes: ["Italienisch", "Pizza"],
                websiteURL: "https://example.com",
                rating: 4.5,
                reviewCount: 127,
                menuItems: ["Margherita", "Pepperoni", "Hawaii"],
                yelpURL: "https://www.yelp.com/biz/example"
            ),
            RestaurantLocation(
                name: "Café Muster",
                coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
                address: "Beispielweg 45, 10115 Berlin",
                phoneNumber: "+49 30 87654321",
                category: "MKPOICategoryCafe",
                distance: 250,
                imageURL: "https://picsum.photos/400/300",
                cuisineTypes: ["Café", "Kaffee"],
                websiteURL: "https://example-cafe.com",
                rating: 4.2,
                reviewCount: 89,
                menuItems: ["Cappuccino", "Latte Macchiato", "Espresso"],
                yelpURL: nil
            ),
            RestaurantLocation(
                name: "Sushi Bar Tokyo",
                coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
                address: "Japanstraße 10, 10115 Berlin",
                phoneNumber: "+49 30 11111111",
                category: "MKPOICategoryRestaurant",
                distance: 750,
                imageURL: "https://picsum.photos/400/300",
                cuisineTypes: ["Sushi", "Japanisch"],
                websiteURL: "https://sushi-tokyo.com",
                rating: 4.8,
                reviewCount: 234,
                menuItems: ["Maki", "Nigiri", "Sashimi", "Temaki"],
                yelpURL: "https://www.yelp.com/biz/sushi-tokyo"
            )
        ])
    }
}


