//
//  PerfilCompradorView.swift
//  ResiApp
//
//  Created by Dev Jr.23 on 5/5/26.
//


import SwiftUI
import SwiftData
import PhotosUI
internal import MapKit

struct PerfilCompradorView: View {
    @AppStorage("userRole") private var userRole: String = ""
    @Environment(\.modelContext) private var modelContext

    @Query private var perfiles: [BuyerProfile]
    @Query private var matches: [Match]

    @State private var mostrarOnboarding    = false
    @State private var mostrarConfirmacion  = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var aparecer             = false

    private var perfil: BuyerProfile? { perfiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                if let perfil {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            headerPerfil(perfil)
                            statsSection
                            mapaSection(perfil)
                            accionesSection
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                } else {
                    ProgressView("Cargando perfil…")
                }
            }
            .onAppear {
                aparecer = true
                if perfil == nil { mostrarOnboarding = true }
            }
            .sheet(isPresented: $mostrarOnboarding) {
                BuyerOnboardingView { mostrarOnboarding = false }
                    .interactiveDismissDisabled()
            }
            .alert("¿Cambiar rol?", isPresented: $mostrarConfirmacion) {
                Button("Cancelar", role: .cancel) {}
                Button("Cambiar", role: .destructive) { userRole = "" }
            } message: {
                Text("Volverás a la pantalla de selección de rol.")
            }
            .onChange(of: pickerItem) { _, newItem in
                Task { await cargarFoto(newItem) }
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func headerPerfil(_ perfil: BuyerProfile) -> some View {
        ZStack(alignment: .bottom) {
            AppGradients.buyerHeader
                .frame(height: 280)

            // Círculos decorativos
            GeometryReader { geo in
                ForEach(0..<5) { i in
                    Circle()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: CGFloat(50 + i * 35))
                        .offset(x: CGFloat(i * 60) - 30,
                                y: CGFloat(i % 2 == 0 ? 30 : 70))
                }
            }.frame(height: 280)

            VStack(spacing: 12) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        avatarView(perfil).frame(width: 110, height: 110)
                        ZStack {
                            Circle().fill(Color.appBlue).frame(width: 32, height: 32)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14)).foregroundStyle(.white)
                        }.offset(x: 4, y: 4)
                    }
                }.buttonStyle(.plain)

                VStack(spacing: 4) {
                    Text(perfil.nombre)
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.white)
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill").font(.caption2)
                        Text(perfil.telefono).font(.subheadline)
                    }.foregroundStyle(.white.opacity(0.75))

                    HStack(spacing: 4) {
                        Image(systemName: "mappin.fill").font(.caption2)
                        Text(perfil.direccion).font(.caption).lineLimit(1)
                    }.foregroundStyle(.white.opacity(0.55))
                }
                Spacer(minLength: 24)
            }
            .padding(.top, 60)
            .opacity(aparecer ? 1 : 0)
            .animation(AppAnimation.easeSnap.delay(0.1), value: aparecer)
        }
    }

    @ViewBuilder
    private func avatarView(_ perfil: BuyerProfile) -> some View {
        Group {
            if let data = perfil.fotoPerfilData, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                ZStack {
                    Circle().fill(AppGradients.buyerHeader)
                    Text("🏭").font(.system(size: 50))
                }
            }
        }
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 0) {
            statItem(valor: "\(matches.count)", etiqueta: "Matches")
            Divider().frame(height: 40)
            statItem(valor: "\(matches.filter { $0.estado == .confirmado }.count)", etiqueta: "Confirmados")
            Divider().frame(height: 40)
            statItem(valor: "\(matches.filter { $0.estado == .propuesto }.count)", etiqueta: "Pendientes")
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
    }

    @ViewBuilder
    private func statItem(valor: String, etiqueta: String) -> some View {
        VStack(spacing: 2) {
            Text(valor).font(.system(size: 18, weight: .black))
            Text(etiqueta).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity)
    }

    // MARK: - Mapa de ubicación

    @ViewBuilder
    private func mapaSection(_ perfil: BuyerProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mi ubicación")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            let coord = CLLocationCoordinate2D(latitude: perfil.latitud, longitude: perfil.longitud)
            let region = MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )

            ZStack(alignment: .bottomLeading) {
                Map(coordinateRegion: .constant(region),
                    annotationItems: [BuyerMapPin(coordinate: coord)]) { pin in
                    MapMarker(coordinate: pin.coordinate, tint: .appBlue)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.appBlue.opacity(0.25), lineWidth: 1)
                )

                // Badge dirección
                Text(perfil.direccion)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(12)
            }
            .padding(.horizontal, 16)
            .shadow(color: AppPopup.shadowColor.opacity(0.2), radius: 12, y: 4)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Acciones

    private var accionesSection: some View {
        VStack(spacing: 0) {
            Divider().padding(.horizontal, 20)
            Button(role: .destructive) {
                mostrarConfirmacion = true
            } label: {
                Label("Cambiar rol", systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity)
                    .padding(14)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Foto

    private func cargarFoto(_ item: PhotosPickerItem?) async {
        guard let item, let perfil else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        if let jpg = UIImage(data: data)?.jpegData(compressionQuality: 0.8) {
            perfil.fotoPerfilData = jpg
            try? modelContext.save()
        }
    }
}

private struct BuyerMapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
