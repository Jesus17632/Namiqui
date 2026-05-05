//
//  ProducerOnboardingView.swift
//  ResiApp
//
//  Created by Dev Jr.23 on 5/5/26.
//

import SwiftUI
import SwiftData
internal import MapKit

struct ProducerOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager

    var onComplete: () -> Void

    @State private var nombre: String = ""
    @State private var telefono: String = ""
    @State private var buscandoUbicacion = false
    @State private var ubicacionConfirmada = false
    @State private var latitudCapturada: Double = 0
    @State private var longitudCapturada: Double = 0
    @State private var errorUbicacion = false
    @State private var aparecer = false

    private var formularioCompleto: Bool {
        !nombre.trimmingCharacters(in: .whitespaces).isEmpty &&
        telefono.count >= 8 &&
        ubicacionConfirmada
    }

    var body: some View {
        ZStack {
            AppGradients.producerBG.ignoresSafeArea()

            GeometryReader { geo in
                ForEach(0..<5) { i in
                    Circle()
                        .fill(Color.white.opacity(0.03))
                        .frame(width: CGFloat(60 + i * 35))
                        .offset(x: CGFloat(i * 55) - 30, y: CGFloat(i % 2 == 0 ? 20 : 70))
                }
            }.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // Header
                    VStack(spacing: 10) {
                        Text("🌿")
                            .font(.system(size: 64))
                            .scaleEffect(aparecer ? 1 : 0.3)
                            .animation(AppAnimation.popIn, value: aparecer)

                        Text("Cuéntanos\nquién eres")
                            .font(.system(size: 30, weight: .black))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .opacity(aparecer ? 1 : 0)
                            .offset(y: aparecer ? 0 : 24)
                            .animation(AppAnimation.easeSnap.delay(0.18), value: aparecer)

                        Text("Tu perfil de productor")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.55))
                            .opacity(aparecer ? 1 : 0)
                            .animation(AppAnimation.easeSnap.delay(0.28), value: aparecer)
                    }
                    .padding(.top, 52)

                    // Campos
                    VStack(spacing: 14) {
                        campoTexto(icono: "person.fill", placeholder: "Nombre completo", texto: $nombre, teclado: .default)
                        campoTexto(icono: "phone.fill",  placeholder: "Teléfono",        texto: $telefono, teclado: .phonePad)

                        // Botón ubicación
                        Button(action: capturarUbicacion) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(ubicacionConfirmada ? Color.appGreen.opacity(0.25) : Color.surfaceWhite)
                                        .frame(width: 38, height: 38)
                                    if buscandoUbicacion {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: ubicacionConfirmada ? "location.fill" : "location")
                                            .foregroundStyle(ubicacionConfirmada ? .appGreen : .white.opacity(0.7))
                                    }
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ubicacionConfirmada ? "Ubicación capturada ✓" : "Obtener mi ubicación actual")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(ubicacionConfirmada ? .appGreen : .white)
                                    if ubicacionConfirmada {
                                        Text(String(format: "%.4f, %.4f", latitudCapturada, longitudCapturada))
                                            .font(.caption2).foregroundStyle(.white.opacity(0.5))
                                    } else if errorUbicacion {
                                        Text("No se pudo obtener. Activa el GPS.")
                                            .font(.caption2).foregroundStyle(.appRed)
                                    }
                                }
                                Spacer()
                            }
                            .appFieldStyle()
                        }
                        .buttonStyle(.plain)
                        .disabled(buscandoUbicacion)
                    }
                    .padding(.horizontal, 24)
                    .opacity(aparecer ? 1 : 0)
                    .animation(AppAnimation.easeSnap.delay(0.38), value: aparecer)

                    // Botón confirmar
                    Button(action: crearPerfil) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Empezar como Productor").fontWeight(.bold)
                        }
                        .appPrimaryButton(color: .appGreen, enabled: formularioCompleto)
                    }
                    .disabled(!formularioCompleto)
                    .padding(.horizontal, 24)
                    .opacity(aparecer ? 1 : 0)
                    .animation(AppAnimation.easeSnap.delay(0.48), value: aparecer)

                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear {
            aparecer = true
            if locationManager.authorizationStatus == .authorizedWhenInUse ||
               locationManager.authorizationStatus == .authorizedAlways {
                capturarUbicacion()
            }
        }
        .interactiveDismissDisabled()
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

    private func capturarUbicacion() {
        buscandoUbicacion = true
        errorUbicacion = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let coord = locationManager.region.center
            latitudCapturada  = coord.latitude
            longitudCapturada = coord.longitude
            ubicacionConfirmada = true
            buscandoUbicacion = false
        }
    }

    private func crearPerfil() {
        let perfil = ProducerProfile(
            nombre: nombre.trimmingCharacters(in: .whitespaces),
            telefono: telefono.trimmingCharacters(in: .whitespaces),
            latitud: latitudCapturada,
            longitud: longitudCapturada
        )
        modelContext.insert(perfil)
        try? modelContext.save()
        onComplete()
    }
}
