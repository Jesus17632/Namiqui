//
//  PerfilProductorView.swift
//  ResiApp
//
//  Created by Dev Jr.23 on 5/5/26.
//

import SwiftUI
import SwiftData
import PhotosUI
internal import MapKit

struct PerfilProductorView: View {
    @AppStorage("userRole") private var userRole: String = ""
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager

    @Query private var perfiles: [ProducerProfile]
    @State private var mostrarConfirmacionRol = false
    @State private var simulandoCaptura = false
    @State private var mostrarExito = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var aparecer = false

    private var perfil: ProducerProfile? { perfiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                if let perfil {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            headerPerfil(perfil)
                            datosSection(perfil)
                            publicacionesSection(perfil)
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                } else {
                    ProgressView("Cargando perfil…")
                }

                // Toast éxito
                if mostrarExito {
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.appGreen)
                            Text("Captura publicada y pin añadido al mapa 📍")
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .onAppear { aparecer = true }
            .alert("¿Cambiar rol?", isPresented: $mostrarConfirmacionRol) {
                Button("Cancelar", role: .cancel) {}
                Button("Cambiar", role: .destructive) { userRole = "" }
            } message: {
                Text("Volverás a la pantalla de selección de rol.")
            }
            .onChange(of: pickerItem) { _, newItem in
                Task { await cargarFotoPerfil(newItem) }
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func headerPerfil(_ perfil: ProducerProfile) -> some View {
        ZStack(alignment: .bottom) {
            AppGradients.producerHeader.frame(height: 270)

            // Círculos decorativos
            GeometryReader { _ in
                ForEach(0..<6) { i in
                    Circle()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: CGFloat(60 + i * 30))
                        .offset(x: CGFloat(i * 55) - 40,
                                y: CGFloat(i % 2 == 0 ? 20 : 65))
                }
            }.frame(height: 270)

            VStack(spacing: 12) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        avatarView(perfil).frame(width: 110, height: 110)
                        ZStack {
                            Circle().fill(Color.appGreen).frame(width: 32, height: 32)
                            Image(systemName: "camera.fill").font(.system(size: 14)).foregroundStyle(.white)
                        }.offset(x: 4, y: 4)
                    }
                }.buttonStyle(.plain)

                VStack(spacing: 4) {
                    Text(perfil.nombre)
                        .font(.system(size: 22, weight: .black)).foregroundStyle(.white)
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill").font(.caption2)
                        Text(perfil.telefono).font(.subheadline)
                    }.foregroundStyle(.white.opacity(0.75))
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill").font(.caption2)
                        Text(String(format: "%.4f, %.4f", perfil.latitud, perfil.longitud)).font(.caption)
                    }.foregroundStyle(.white.opacity(0.5))
                }
                Spacer(minLength: 24)
            }
            .padding(.top, 60)
            .opacity(aparecer ? 1 : 0)
            .animation(AppAnimation.easeSnap.delay(0.1), value: aparecer)
        }
    }

    @ViewBuilder
    private func avatarView(_ perfil: ProducerProfile) -> some View {
        Group {
            if let data = perfil.fotoPerfilData, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                ZStack {
                    Circle().fill(LinearGradient(
                        colors: [Color(red: 1, green: 0.87, blue: 0.2), Color(red: 0.95, green: 0.7, blue: 0.1)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text("🍌").font(.system(size: 52))
                }
            }
        }
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
    }

    // MARK: - Datos / Stats

    @ViewBuilder
    private func datosSection(_ perfil: ProducerProfile) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                statItem(valor: "\(capturasDePerfil(perfil).count)",
                         etiqueta: "Capturas")
                Divider().frame(height: 40)
                statItem(valor: String(format: "%.0f m³", volumenTotal(perfil)),
                         etiqueta: "Volumen total")
                Divider().frame(height: 40)
                statItem(valor: diasRegistrado(perfil), etiqueta: "Días activo")
            }
            .padding(.vertical, 16)
            .background(Color(.secondarySystemBackground))

            Divider()

            Button(action: simularCaptura) {
                HStack(spacing: 10) {
                    if simulandoCaptura {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    Text("Simular captura").fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.appGreen.opacity(0.85))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(simulandoCaptura)
            .padding(.horizontal, 20).padding(.vertical, 16)

            Divider()
        }
    }

    @ViewBuilder
    private func statItem(valor: String, etiqueta: String) -> some View {
        VStack(spacing: 2) {
            Text(valor).font(.system(size: 18, weight: .black))
            Text(etiqueta).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity)
    }

    // MARK: - Feed publicaciones

    @ViewBuilder
    private func publicacionesSection(_ perfil: ProducerProfile) -> some View {
        let capturas = capturasDePerfil(perfil)
        VStack(alignment: .leading, spacing: 0) {
            Text("Mis publicaciones").font(.headline)
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 12)

            if capturas.isEmpty {
                VStack(spacing: 12) {
                    Text("🌾").font(.system(size: 48))
                    Text("Aún no tienes capturas").font(.subheadline).foregroundStyle(.secondary)
                    Text("Usa el botón \"Simular captura\" para empezar.")
                        .font(.caption).foregroundStyle(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center).padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 48)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(capturas) { capturaCard($0) }
                }
                .padding(.horizontal, 16).padding(.bottom, 24)
            }

            Divider().padding(.horizontal, 20)
            Button(role: .destructive) { mostrarConfirmacionRol = true } label: {
                Label("Cambiar rol", systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity).padding(14)
            }
            .padding(.horizontal, 20).padding(.vertical, 8).padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private func capturaCard(_ captura: SimulatedCapture) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appRed.opacity(0.10))
                    .frame(width: 52, height: 52)
                Text(emojiAnimal(captura.animal)).font(.system(size: 26))
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(captura.animal).font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(captura.fecha, style: .date).font(.caption2).foregroundStyle(.secondary)
                }
                HStack(spacing: 12) {
                    Label(String(format: "%.0f%%", captura.humedadPct), systemImage: "drop.fill")
                        .font(.caption).foregroundStyle(.blue)
                    Label(String(format: "%.0f m³", captura.volumenM3), systemImage: "cube.fill")
                        .font(.caption).foregroundStyle(.orange)
                }
                Text("🌾 \(captura.alimento)").font(.caption2).foregroundStyle(.secondary)
            }
            Image(systemName: "mappin.circle.fill").foregroundStyle(.appRed).font(.title3)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
    }

    // MARK: - Lógica

    private func capturasDePerfil(_ perfil: ProducerProfile) -> [SimulatedCapture] {
        let id = perfil.id
        let desc = FetchDescriptor<SimulatedCapture>(
            predicate: #Predicate { $0.producerProfileId == id },
            sortBy: [SortDescriptor(\.fecha, order: .reverse)]
        )
        return (try? modelContext.fetch(desc)) ?? []
    }

    private func volumenTotal(_ perfil: ProducerProfile) -> Double {
        capturasDePerfil(perfil).reduce(0) { $0 + $1.volumenM3 }
    }

    private func diasRegistrado(_ perfil: ProducerProfile) -> String {
        let d = Calendar.current.dateComponents([.day], from: perfil.fechaRegistro, to: .now).day ?? 0
        return "\(max(1, d))"
    }

    private func simularCaptura() {
        guard let perfil else { return }
        simulandoCaptura = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let coord = locationManager.region.center
            let cap = SimulatedCapture.aleatorio(profileId: perfil.id, lat: coord.latitude, lon: coord.longitude)
            modelContext.insert(cap)
            try? modelContext.save()
            simulandoCaptura = false
            withAnimation(AppAnimation.spring) { mostrarExito = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { mostrarExito = false }
            }
        }
    }

    private func cargarFotoPerfil(_ item: PhotosPickerItem?) async {
        guard let item, let perfil else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        if let jpg = UIImage(data: data)?.jpegData(compressionQuality: 0.8) {
            perfil.fotoPerfilData = jpg; try? modelContext.save()
        }
    }

    private func emojiAnimal(_ raw: String) -> String {
        if raw.contains("Bovino")  { return "🐄" }
        if raw.contains("Porcino") { return "🐷" }
        if raw.contains("Aviar")   { return "🐔" }
        if raw.contains("Equino")  { return "🐴" }
        if raw.contains("Ovino")   { return "🐑" }
        return "🐾"
    }
}
