import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    
    var body: some View {
        Form {
            Section(header: Text(settings.language.language)) {
                Picker(settings.language.appLanguage, selection: $settings.language) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .navigationTitle(settings.language.settings)
    }
}
