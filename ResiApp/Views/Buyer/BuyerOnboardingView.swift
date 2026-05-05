//
//  BuyerOnboardingView.swift
//  ResiApp
//
//  Created by Dev Jr.23 on 5/5/26.
//

import SwiftUI
import SwiftData
import CoreLocation
internal import MapKit

struct BuyerOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager

    var onComplete: () -> Void

    @State private var nombre: String   = ""
    @State private var telefono: String = ""

    // Mapa interactivo
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    )
    @State private var direccionResuelta: String = ""
    @State private var ubicacionLista = false

    @State private var aparecer = false
    @State private var paso: Int = 1   // 1 = datos, 2 = mapa

    private var datosCompletos: Bool {
        !nombre.trimmingCharacters(in: .whitespaces).isEmpty &&
        telefono.count >= 8
    }

    var body: some View {
        ZStack {
            AppGradients.buyerBG.ignoresSafeArea()

            GeometryReader { geo in
                ForEach(0..<5) { i in
                    Circle().fill(Color.white.opacity(0.03))
                        .frame(width: CGFloat(80 + i * 40))
                        .offset(x: geo.size.width - CGFloat(i * 50) - 60,
                                y: CGFloat(i * 70) + 20)
                }
            }.ignoresSafeArea()

            if paso == 1 {
                pasoDatos
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            } else {
                pasoMapa
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .onAppear {
            aparecer = true
            // Centra el mapa en la ubicación actual si hay
            if locationManager.authorizationStatus == .authorizedWhenInUse ||
               locationManager.authorizationStatus == .authorizedAlways {
                let c = locationManager.region.center
                region = MKCoordinateRegion(
                    center: c,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Paso 1: datos

    private var pasoDatos: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Text("🏭")
                        .font(.system(size: 64))
                        .scaleEffect(aparecer ? 1 : 0.3)
                        .animation(AppAnimation.popIn, value: aparecer)

                    Text("Tu perfil\nde comprador")
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Paso 1 de 2 · Tus datos")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .padding(.top, 52)

                VStack(spacing: 14) {
                    campoTexto(icono: "person.fill", placeholder: "Nombre completo", texto: $nombre, teclado: .default)
                    campoTexto(icono: "phone.fill",  placeholder: "Teléfono",        texto: $telefono, teclado: .phonePad)
                }
                .padding(.horizontal, 24)

                Button {
                    withAnimation(AppAnimation.spring) { paso = 2 }
                } label: {
                    HStack(spacing: 8) {
                        Text("Continuar").fontWeight(.bold)
                        Image(systemName: "arrow.right")
                    }
                    .appPrimaryButton(color: .appBlue, enabled: datosCompletos)
                }
                .disabled(!datosCompletos)
                .padding(.horizontal, 24)

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Paso 2: mapa

    private var pasoMapa: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 6) {
                HStack {
                    Button { withAnimation(AppAnimation.spring) { paso = 1 } } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }
                    Spacer()
                    Text("Paso 2 de 2")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Text("Elige tu ubicación")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.top, 8)

                Text("Mueve el mapa para que el pin apunte a tu dirección")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 12)
            }

            // Mapa interactivo con pin fijo al centro
            ZStack {
                Map(coordinateRegion: $region, showsUserLocation: true)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )

                // Pin centrado fijo
                VStack(spacing: 0) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white, .appBlue)
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.appBlue)
                        .offset(y: -8)
                }
                .offset(y: -22) // sube el pin para que la punta apunte al centro real

                // Coordenadas overlay
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.caption2).foregroundStyle(.appBlue)
                        Text(String(format: "%.5f, %.5f", region.center.latitude, region.center.longitude))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(16)
                }
            }
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity)

            // Botón confirmar
            Button(action: crearPerfil) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Confirmar ubicación").fontWeight(.bold)
                }
                .appPrimaryButton(color: .appBlue, enabled: true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    @ViewBuilder
    private func campoTexto(icono: String, placeholder: String, texto: Binding<String>, teclado: UIKeyboardType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icono).foregroundStyle(.white.opacity(0.5)).frame(width: 20)
            TextField("", text: texto, prompt: Text(placeholder).foregroundColor(.white.opacity(0.35)))
                .foregroundStyle(.white)
                .keyboardType(teclado)
                .autocorrectionDisabled()
        }
        .appFieldStyle()
    }

    // MARK: - Lógica

    private func crearPerfil() {
        let coord = region.center
        // Reverse geocoding opcional para guardar la dirección como texto
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            let direccion = construirDireccion(placemarks?.first)
            let perfil = BuyerProfile(
                nombre: nombre.trimmingCharacters(in: .whitespaces),
                telefono: telefono.trimmingCharacters(in: .whitespaces),
                direccion: direccion,
                latitud: coord.latitude,
                longitud: coord.longitude
            )
            modelContext.insert(perfil)
            try? modelContext.save()
            onComplete()
        }
    }

    private func construirDireccion(_ place: CLPlacemark?) -> String {
        guard let place else {
            return String(format: "%.4f, %.4f", region.center.latitude, region.center.longitude)
        }
        var partes: [String] = []
        if let calle = place.thoroughfare      { partes.append(calle) }
        if let num   = place.subThoroughfare   { partes.append(num) }
        if let col   = place.subLocality       { partes.append(col) }
        if let ciudad = place.locality         { partes.append(ciudad) }
        return partes.isEmpty
            ? String(format: "%.4f, %.4f", region.center.latitude, region.center.longitude)
            : partes.joined(separator: ", ")
    }
}
