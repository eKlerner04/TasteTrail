import SwiftUI

struct SearchResultsView: View{
    @ObservedObject var settings = AppSettings.shared
    let address: String
    
    var body: some View{
        VStack(spacing :20){
            Text("\(settings.language.searchResultsFor) \(address)")
        }
        .navigationTitle(settings.language.results)
    }
}

