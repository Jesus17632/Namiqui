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

    // Closures explícitos para controlar la navegación sin depender del dismiss automático
    var onComplete: () -> Void
    var onBack: () -> Void

    @State private var nombre: String = ""
    @State private var telefono: String = ""
    @State private var buscandoUbicacion = false
    @State private var ubicacionConfirmada = false
    @State private var latitudCapturada: Double = 0
    @State private var longitudCapturada: Double = 0
    @State private var errorUbicacion = false

    private var formularioCompleto: Bool {
        !nombre.trimmingCharacters(in: .whitespaces).isEmpty &&
        telefono.count >= 8 &&
        ubicacionConfirmada
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo estándar de Apple para formularios (gris muy claro en Light, negro en Dark)
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // MARK: - Header Minimalista
                        VStack(spacing: 8) {
                            Image(systemName: "leaf.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(Color.appGreen)
                                .padding(.bottom, 4)

                            Text("Perfil de Productor")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.primary)

                            Text("Ingresa tus datos para comenzar")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 8)

                        // MARK: - Formulario (Estilo iOS Settings)
                        VStack(spacing: 0) {
                            campoTexto(icono: "person.fill", placeholder: "Nombre completo", texto: $nombre, teclado: .default)
                            
                            Divider().padding(.leading, 52)
                            
                            campoTexto(icono: "phone.fill", placeholder: "Teléfono", texto: $telefono, teclado: .phonePad)
                            
                            Divider().padding(.leading, 52)

                            // Botón de Ubicación Integrado
                            Button(action: capturarUbicacion) {
                                HStack(spacing: 16) {
                                    Image(systemName: ubicacionConfirmada ? "location.fill" : "location")
                                        .font(.system(size: 20))
                                        .foregroundStyle(ubicacionConfirmada ? Color.appGreen : Color.accentColor)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(ubicacionConfirmada ? "Ubicación capturada" : "Obtener mi ubicación")
                                            .font(.body)
                                            .foregroundStyle(ubicacionConfirmada ? Color.appGreen : .primary)
                                        
                                        if ubicacionConfirmada {
                                            Text(String(format: "%.4f, %.4f", latitudCapturada, longitudCapturada))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        } else if errorUbicacion {
                                            Text("No se pudo obtener. Activa el GPS.")
                                                .font(.caption)
                                                .foregroundStyle(Color.appRed)
                                        }
                                    }
                                    Spacer()
                                    
                                    if buscandoUbicacion {
                                        ProgressView()
                                    } else if ubicacionConfirmada {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Color.appGreen)
                                    }
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(buscandoUbicacion)
                        }
                        .background(Color(.secondarySystemGroupedBackground)) // Blanco puro en modo claro
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)

                        // MARK: - Botón Confirmar Nativo
                        Button(action: crearPerfil) {
                            Text("Empezar como Productor")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.appGreen)
                        .controlSize(.large)
                        .disabled(!formularioCompleto)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            // MARK: - Custom Back Button
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Volver")
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(AnimatedBackButtonStyle()) // Aplica la animación HIG
                }
            }
            .onAppear {
                if locationManager.authorizationStatus == .authorizedWhenInUse ||
                   locationManager.authorizationStatus == .authorizedAlways {
                    capturarUbicacion()
                }
            }
        }
    }

    // MARK: - Componentes
    
    @ViewBuilder
    private func campoTexto(icono: String, placeholder: String, texto: Binding<String>, teclado: UIKeyboardType) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icono)
                .font(.system(size: 20))
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            
            TextField(placeholder, text: texto)
                .font(.body)
                .keyboardType(teclado)
                .autocorrectionDisabled()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }

    // MARK: - Lógica

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

// MARK: - Animación estilo Apple (Scale)
struct AnimatedBackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Reduce sutilmente el tamaño y la opacidad al tocar, como las apps nativas
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ProducerOnboardingView(
        onComplete: { },
        onBack: { } // <- Solo le agregamos esto vacío para que el preview funcione
    )
}
