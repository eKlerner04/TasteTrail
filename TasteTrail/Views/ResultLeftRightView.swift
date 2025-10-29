import SwiftUI
import CoreLocation

struct LikedRestaurant: Identifiable {
    let id: UUID
    let restaurant: RestaurantLocation
    var likeCount: Int
    
    init(restaurant: RestaurantLocation, likeCount: Int = 1) {
        self.id = restaurant.id
        self.restaurant = restaurant
        self.likeCount = likeCount
    }
}

struct ResultLeftRightView: View {
    @ObservedObject var settings = AppSettings.shared
    let likedRestaurants: [LikedRestaurant]
    
    // Sortiere nach Likes (höchste zuerst)
    private var sortedRestaurants: [LikedRestaurant] {
        likedRestaurants.sorted { $0.likeCount > $1.likeCount }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if sortedRestaurants.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "heart.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("Keine interessanten Restaurants")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Swipe nach rechts, um Restaurants zu speichern")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        // Übersicht mit Rangliste
                        ForEach(Array(sortedRestaurants.enumerated()), id: \.element.id) { index, likedRestaurant in
                            RestaurantResultCard(
                                restaurant: likedRestaurant.restaurant,
                                rank: index + 1,
                                likeCount: likedRestaurant.likeCount
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Ergebnisse")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct RestaurantResultCard: View {
    let restaurant: RestaurantLocation
    let rank: Int
    let likeCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Rang-Platzierung
            ZStack {
                Circle()
                    .fill(rankColor(for: rank))
                    .frame(width: 50, height: 50)
                
                Text("\(rank)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Restaurant Bild (klein)
            if let imageURL = restaurant.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "fork.knife")
                                    .foregroundColor(.white)
                            )
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(.white)
                    )
            }
            
            // Restaurant Info
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let address = restaurant.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if let distance = restaurant.distance {
                    Text(String(format: "%.0f m entfernt", distance))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Like-Count
            VStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                Text("\(likeCount)")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow // Gold
        case 2: return .gray.opacity(0.7) // Silber
        case 3: return Color.brown.opacity(0.8) // Bronze
        default: return .blue
        }
    }
}

#Preview {
    ResultLeftRightView(likedRestaurants: [
        LikedRestaurant(
            restaurant: RestaurantLocation(
                name: "Beispiel Restaurant 1",
                coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
                address: "Musterstraße 123",
                distance: 500
            ),
            likeCount: 5
        ),
        LikedRestaurant(
            restaurant: RestaurantLocation(
                name: "Beispiel Restaurant 2",
                coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
                address: "Beispielweg 45",
                distance: 250
            ),
            likeCount: 3
        )
    ])
}

