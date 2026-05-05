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

    var onComplete: () -> Void

    @State private var nombre: String    = ""
    @State private var telefono: String  = ""
    @State private var direccion: String = ""

    @State private var geocodificando    = false
    @State private var coordenadas: CLLocationCoordinate2D? = nil
    @State private var errorGeo          = false
    @State private var region            = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    )

    @State private var aparecer          = false
    @State private var mapaVisible       = false

    private var formularioCompleto: Bool {
        !nombre.trimmingCharacters(in: .whitespaces).isEmpty &&
        telefono.count >= 8 &&
        coordenadas != nil
    }

    var body: some View {
        ZStack {
            AppGradients.buyerBG.ignoresSafeArea()

            // Patrón decorativo
            GeometryReader { geo in
                ForEach(0..<5) { i in
                    Circle()
                        .fill(Color.white.opacity(0.03))
                        .frame(width: CGFloat(80 + i * 40))
                        .offset(x: geo.size.width - CGFloat(i * 50) - 60,
                                y: CGFloat(i * 70) + 20)
                }
            }.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // ── Header ───────────────────────────────────────
                    VStack(spacing: 10) {
                        Text("🏭")
                            .font(.system(size: 64))
                            .scaleEffect(aparecer ? 1 : 0.3)
                            .animation(AppAnimation.popIn, value: aparecer)

                        Text("Tu perfil\nde comprador")
                            .font(.system(size: 30, weight: .black))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .opacity(aparecer ? 1 : 0)
                            .offset(y: aparecer ? 0 : 24)
                            .animation(AppAnimation.easeSnap.delay(0.18), value: aparecer)

                        Text("Cuéntanos dónde operas")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.55))
                            .opacity(aparecer ? 1 : 0)
                            .animation(AppAnimation.easeSnap.delay(0.28), value: aparecer)
                    }
                    .padding(.top, 52)

                    // ── Campos ───────────────────────────────────────
                    VStack(spacing: 14) {
                        campoTexto(icono: "person.fill",    placeholder: "Nombre completo",   texto: $nombre,    teclado: .default)
                        campoTexto(icono: "phone.fill",     placeholder: "Teléfono",          texto: $telefono,  teclado: .phonePad)
                        campoTexto(icono: "mappin.fill",    placeholder: "Dirección o colonia", texto: $direccion, teclado: .default)

                        // Botón geocodificar
                        Button(action: geocodificar) {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(coordenadas != nil ? Color.appBlue.opacity(0.3) : Color.white.opacity(0.1))
                                        .frame(width: 38, height: 38)
                                    if geocodificando {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: coordenadas != nil ? "checkmark.circle.fill" : "location.magnifyingglass")
                                            .foregroundStyle(coordenadas != nil ? .appBlue : .white.opacity(0.7))
                                    }
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(coordenadas != nil ? "Dirección localizada ✓" : "Buscar dirección en el mapa")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(coordenadas != nil ? .appBlue : .white)
                                    if errorGeo {
                                        Text("No se encontró. Intenta ser más específico.")
                                            .font(.caption2).foregroundStyle(.appRed)
                                    }
                                }
                                Spacer()
                            }
                            .appFieldStyle()
                        }
                        .buttonStyle(.plain)
                        .disabled(geocodificando || direccion.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 24)
                    .opacity(aparecer ? 1 : 0)
                    .animation(AppAnimation.easeSnap.delay(0.38), value: aparecer)

                    // ── Mini mapa ────────────────────────────────────
                    if mapaVisible, let coord = coordenadas {
                        mapaPreview(coord: coord)
                            .padding(.horizontal, 24)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    // ── Botón confirmar ──────────────────────────────
                    Button(action: crearPerfil) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Empezar como Comprador").fontWeight(.bold)
                        }
                        .appPrimaryButton(color: .appBlue, enabled: formularioCompleto)
                    }
                    .disabled(!formularioCompleto)
                    .padding(.horizontal, 24)
                    .opacity(aparecer ? 1 : 0)
                    .animation(AppAnimation.easeSnap.delay(0.48), value: aparecer)

                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear { aparecer = true }
        .interactiveDismissDisabled()
    }

    // MARK: - Mini mapa preview

    @ViewBuilder
    private func mapaPreview(coord: CLLocationCoordinate2D) -> some View {
        ZStack(alignment: .topTrailing) {
            Map(coordinateRegion: .constant(region), annotationItems: [MapPin(coordinate: coord)]) { pin in
                MapMarker(coordinate: pin.coordinate, tint: .appBlue)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: AppPopup.shadowColor, radius: 16, y: 6)

            // Badge de coordenadas
            Text(String(format: "%.4f, %.4f", coord.latitude, coord.longitude))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(10)
        }
    }

    // MARK: - Campo de texto

    @ViewBuilder
    private func campoTexto(
        icono: String,
        placeholder: String,
        texto: Binding<String>,
        teclado: UIKeyboardType
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icono)
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 20)
            TextField("", text: texto,
                      prompt: Text(placeholder).foregroundColor(.white.opacity(0.35)))
                .foregroundStyle(.white)
                .keyboardType(teclado)
                .autocorrectionDisabled()
        }
        .appFieldStyle()
    }

    // MARK: - Lógica

    private func geocodificar() {
        let query = direccion.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        geocodificando = true
        errorGeo = false

        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(query) { placemarks, error in
            geocodificando = false
            guard let place = placemarks?.first,
                  let loc = place.location else {
                errorGeo = true
                return
            }
            coordenadas = loc.coordinate
            region = MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            )
            withAnimation(AppAnimation.spring) { mapaVisible = true }
        }
    }

    private func crearPerfil() {
        guard let coord = coordenadas else { return }
        let perfil = BuyerProfile(
            nombre: nombre.trimmingCharacters(in: .whitespaces),
            telefono: telefono.trimmingCharacters(in: .whitespaces),
            direccion: direccion.trimmingCharacters(in: .whitespaces),
            latitud: coord.latitude,
            longitud: coord.longitude
        )
        modelContext.insert(perfil)
        try? modelContext.save()
        onComplete()
    }
}

// Helper para MapAnnotation
private struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
