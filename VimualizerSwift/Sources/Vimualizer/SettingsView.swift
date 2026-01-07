import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var logic: VimLogic
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
            
            // Add more tabs as needed
        }
        .padding()
        .frame(width: 450, height: 500)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var logic: VimLogic
    
    var body: some View {
        Form {
            Section(header: Text("Features").font(.headline)) {
                Toggle("Enable Vimualizer", isOn: $logic.isMasterEnabled)
                Toggle("Show Key Hints", isOn: $logic.isHudEnabled)
            }
            .padding()
        }
    }
}

struct AppearanceSettingsView: View {
    @EnvironmentObject var logic: VimLogic
    
    var body: some View {
        Form {
            Section(header: Text("Layout").font(.headline)) {
                HStack {
                    Text("HUD Position")
                    Spacer()
                    Picker("", selection: .constant(0)) {
                        Text("Top Right").tag(0)
                        Text("Center").tag(1)
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
            }
            .padding()
        }
    }
}
