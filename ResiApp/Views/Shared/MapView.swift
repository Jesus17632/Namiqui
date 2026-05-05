//
//  MapView.swift
//  ResiApp
//
//  Created by Dev Jr.23 on 5/5/26.
//

import SwiftUI
internal import MapKit

struct MapView: View {
    @Environment(LocationManager.self) private var locationManager

    var body: some View {
        ZStack(alignment: .bottom) {
            // Mapa con pins de capturas simuladas (overlay)
            MapCapturaOverlay()
                .ignoresSafeArea()

            // Banner de ubicación denegada (igual que antes)
            if locationManager.authorizationStatus == .denied ||
               locationManager.authorizationStatus == .restricted {
                VStack(spacing: 8) {
                    Image(systemName: "location.slash.fill")
                        .font(.title2)
                    Text("Activa la ubicación en Ajustes para ver tu posición.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding()
            }
        }
        .onAppear {
            locationManager.requestPermission()
        }
    }
}

#Preview {
    MapView()
}
