//
//  ContentView.swift
//  ResiApp
//
//  Created by Dev Jr.23 on 5/4/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Mapa", systemImage: "map.fill", value: AppTab.home) {
                NavigationStack { MapView() }
            }
            Tab("Escanear", systemImage: "camera.fill", value: AppTab.scan) {
                NavigationStack {
                    ScanView(selectedTab: $selectedTab)
                }
            }
            Tab("Perfil", systemImage: "person.fill", value: AppTab.profile) {
                NavigationStack { ProfileView() }
            }
        }
        .tint(Color.tlaneGreen)
    }
}

#Preview {
    ContentView()
}
