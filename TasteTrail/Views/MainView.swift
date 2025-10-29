import SwiftUI
import MapKit
import CoreLocation

struct MapPinLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct RestaurantLocation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String?
    let phoneNumber: String?
    let category: String?
    let distance: CLLocationDistance?
    let imageURL: String?
    let cuisineTypes: [String]
    let websiteURL: String?
    let timeZone: TimeZone?
    let postalCode: String?
    let country: String?
    let locality: String?
    let rating: Double? // 0.0 - 5.0
    let reviewCount: Int?
    let menuItems: [String] // Beispiel-Menüpunkte
    let yelpURL: String? // Link zur Yelp-Seite
    
    init(name: String, coordinate: CLLocationCoordinate2D, address: String? = nil, phoneNumber: String? = nil, category: String? = nil, distance: CLLocationDistance? = nil, imageURL: String? = nil, cuisineTypes: [String] = [], websiteURL: String? = nil, timeZone: TimeZone? = nil, postalCode: String? = nil, country: String? = nil, locality: String? = nil, rating: Double? = nil, reviewCount: Int? = nil, menuItems: [String] = [], yelpURL: String? = nil) {
        self.name = name
        self.coordinate = coordinate
        self.address = address
        self.phoneNumber = phoneNumber
        self.category = category
        self.distance = distance
        self.imageURL = imageURL
        self.cuisineTypes = cuisineTypes
        self.websiteURL = websiteURL
        self.timeZone = timeZone
        self.postalCode = postalCode
        self.country = country
        self.locality = locality
        self.rating = rating
        self.reviewCount = reviewCount
        self.menuItems = menuItems
        self.yelpURL = yelpURL
    }
}

struct MainView: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var address: String = ""
    @StateObject private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var marker: MapPinLocation? = nil
    @State private var radius: CLLocationDistance = 1000
    @State private var restaurants: [RestaurantLocation] = []
    @State private var allRestaurants: [RestaurantLocation] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var showResults = false
    @State private var showSettings = false
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var isRequestingLocation = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(settings.language.findRestaurantsNearby)
                    .font(.subheadline)
                    .padding(2)

                Button(action: {
                    isRequestingLocation = true
                    locationManager.requestLocation()
                }) {
                    HStack(spacing: 8) {
                        if isRequestingLocation {
                            Image(systemName: "gearshape")
                                .foregroundColor(.blue)
                                .rotationEffect(.degrees(isRequestingLocation ? 360 : 0))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRequestingLocation)
                        } else {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                        }
                        
                        Text(isRequestingLocation ? "Getting Location..." : "Use my Location")
                            .foregroundColor(.blue)
                            .font(.system(.body, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
                .disabled(isRequestingLocation)
                .opacity(isRequestingLocation ? 0.7 : 1.0)
                
                HStack(spacing: 12) {
                    TextField(settings.language.enterAddress, text: $address)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        searchForAddress()
                    }) {
                        Text(settings.language.search)
                            .font(.system(.body, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .disabled(address.isEmpty)
                    .opacity(address.isEmpty ? 0.5 : 1.0)
                    .scaleEffect(address.isEmpty ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: address.isEmpty)
                }
                .padding(.horizontal)

                MapReader { proxy in
                    Map(position: $position) {
                        if let marker {
                            Marker(" ", coordinate: marker.coordinate)
                                .tint(.red)
                            
                            MapCircle(center: marker.coordinate, radius: radius)
                                .foregroundStyle(Color.blue.opacity(0.2))
                                .stroke(.blue.opacity(0.6), lineWidth: 2)
                            
                            ForEach(restaurants){ restaurant in
                                Marker(restaurant.name, coordinate: restaurant.coordinate)
                                    .tint(.orange)
                            }
                        }
                    }
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                let tapLocation = value.location
                                if let coordinate = proxy.convert(tapLocation, from: .local) {
                                    marker = MapPinLocation(coordinate: coordinate)
                                }
                            }
                    )
                }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .onChange(of: locationManager.locationUpdateTrigger) { oldValue, newValue in
                    if let coordinate = locationManager.location {
                        isRequestingLocation = false // Loading-State beenden
                        
                        marker = MapPinLocation(coordinate: coordinate)
                        
                        withAnimation {
                            position = .region(MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                            ))
                        }
                        
                        searchRestaurants(around: coordinate, radius: radius)
                        reverseGeocode(coordinate: coordinate)
                    }
                }
                .onChange(of: locationManager.authorizationStatus) { oldValue, newValue in
                    // Loading-State beenden wenn Berechtigung verweigert wurde
                    if newValue == .denied || newValue == .restricted {
                        isRequestingLocation = false
                    }
                }
                
                
                VStack(spacing: 8){
                    Text("\(settings.language.radius): \(Int(radius)) m")
                        .font(.headline)
                    Slider(value: $radius, in: 100...5000, step: 100)
                        .padding()
                        .onChange(of: radius) { oldValue, newValue in
                            // Debounce: Warte 1.5 Sekunden bevor Suche ausgeführt wird
                            searchTask?.cancel()
                            searchTask = Task {
                                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 Sekunden
                                
                                if !Task.isCancelled, let coordinate = marker?.coordinate {
                                    await MainActor.run {
                                        searchRestaurants(around: coordinate, radius: newValue)
                                    }
                                }
                            }
                        }
                }

                if isSearching {
                    ProgressView(settings.language.searchingAddress)
                } else if let coordinate = marker?.coordinate {
                    VStack(spacing: 4) {
                        Text(settings.language.foundLocation)
                            .font(.headline)
                        Text("Latitude: \(coordinate.latitude, specifier: "%.5f") Longitude: \(coordinate.longitude, specifier: "%.5f")")
                        
                        if !restaurants.isEmpty{
                            Text("\(settings.language.restaurantsInRadius) \(restaurants.count)")
                                .font(.subheadline)
                        } else {
                            Text(settings.language.noRestaurantsFound)
                                .font(.subheadline)
                        }
                    }
                }

                

                Spacer()
            }
            .navigationDestination(isPresented: $showResults) {
                SearchResultsView(address: address, restaurants: restaurants, radius: radius)
            }
            .navigationTitle("TasteTrail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing){
                    Button{
                        showSettings = true
                    }label: {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                    }
                }
            }
            .toolbar{
                ToolbarItem(placement: .bottomBar){
                    Button{
                        showResults = true
                    }label: {
                        HStack(spacing: 12) {
                            Text("TasteTrail")
                                .foregroundColor(.primary)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(.body, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    .disabled(address.isEmpty)
                    .opacity(address.isEmpty ? 0.5 : 1.0)
                    .scaleEffect(address.isEmpty ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: address.isEmpty)
                }
            }
            .navigationDestination(isPresented: $showSettings){
                SettingsView()
            }
            .onDisappear {
                // Cleanup: Cancle alle laufenden Search-Tasks
                searchTask?.cancel()
            }
            
        }
    }

    private func searchForAddress() {
        guard !address.isEmpty else { return }
        isSearching = true
        searchError = nil

        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            isSearching = false

            if let error = error {
                searchError = "\(settings.language.addressNotFound) \(error.localizedDescription)"
                return
            }

            if let location = placemarks?.first?.location {
                let coordinate = location.coordinate
                marker = MapPinLocation(coordinate: coordinate)

                withAnimation {
                    position = .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                    ))
                }

                searchRestaurants(around: coordinate, radius: radius)
            } else {
                searchError = settings.language.noValidCoordinates
            }
        }
    }
    

    
    private func searchRestaurants(around coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) {
        isSearching = true
        searchError = nil
        restaurants.removeAll()
        
        RestaurantSearchService.searchRestaurants(around: coordinate, radius: radius) { foundRestaurants in
            isSearching = false
            
            // Speichere alle gefundenen Restaurants
            allRestaurants = foundRestaurants
            
            // Filtere nach dem tatsächlichen Radius
            restaurants = RestaurantSearchService.filterRestaurantsByRadius(
                restaurants: allRestaurants,
                center: coordinate,
                radius: radius
            )
            
            if restaurants.isEmpty {
                searchError = settings.language.noRestaurantsFoundError
            }
        }
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                let address = [
                    placemark.thoroughfare,
                    placemark.subThoroughfare,
                    placemark.locality,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
                
                self.address = address
            }
        }
    }
}

#Preview {
    MainView()
}
