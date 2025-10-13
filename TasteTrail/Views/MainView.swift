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
}

struct MainView: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var address: String = ""
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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(settings.language.findRestaurantsNearby)
                    .font(.subheadline)

                TextField(settings.language.enterAddress, text: $address)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
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
                
                
                VStack(spacing: 8){
                    Text("\(settings.language.radius): \(Int(radius)) m")
                        .font(.headline)
                    Slider(value: $radius, in: 100...5000, step: 100)
                        .padding()
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

                Button(action: {
                    searchForAddress()
                }) {
                    Text(settings.language.search)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .disabled(address.isEmpty)
                .opacity(address.isEmpty ? 0.6 : 1.0)
                

                Spacer()
            }
            .navigationDestination(isPresented: $showResults) {
                SearchResultsView(address: address)
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
                        Image(systemName: "arrowshape.forward.circle")
                            .imageScale(.large)
                    }
                    .disabled(address.isEmpty)
                    .opacity(address.isEmpty ? 0.6 : 1.0)
                }
            }
            .navigationDestination(isPresented: $showSettings){
                SettingsView()
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
    
    private func filterRestaurantsByRadius() {
        guard let center = marker?.coordinate else { return }
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)

        restaurants = allRestaurants.filter { restaurant in
            let restaurantLocation = CLLocation(latitude: restaurant.coordinate.latitude,
                                                longitude: restaurant.coordinate.longitude)
            return restaurantLocation.distance(from: centerLocation) <= radius
        }
    }

    
    private func searchRestaurants(around coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) {
        isSearching = true
        searchError = nil
        restaurants.removeAll()
        
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
            isSearching = false
            if let error = error {
                searchError = "\(settings.language.searchError) \(error.localizedDescription)"
                return
            }
            
            guard let mapItems = response?.mapItems else {
                searchError = settings.language.noRestaurantsFoundError
                return
            }
            
            let centerLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

            allRestaurants = mapItems.compactMap { item in
                guard let name = item.name, let location = item.placemark.location else { return nil }
                return RestaurantLocation(name: name, coordinate: location.coordinate)
            }

            filterRestaurantsByRadius()
        }
    }
}

#Preview {
    MainView()
}
