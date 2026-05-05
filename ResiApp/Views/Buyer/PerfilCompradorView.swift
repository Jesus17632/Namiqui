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
    @Environment(\.dismiss) private var dismiss // Flecha emergente

    @Query private var perfiles: [BuyerProfile]
    @Query private var matches: [Match]

    @State private var mostrarConfirmacion = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var aparecer = false

    private var perfil: BuyerProfile? { perfiles.first }

    var body: some View {
        ZStack {
            // Fondo blanco puro
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Barra superior emergente (< en negro)
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.black)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

                if let perfil {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            headerCompacto(perfil)
                            statsRow
                            miniMapa(perfil)
                            matchesList
                            
                            botonCambiarRol
                                .padding(.top, 16)
                                .padding(.bottom, 40)
                        }
                    }
                } else {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Cargando perfil…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { aparecer = true } }
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

    // MARK: - Header

    @ViewBuilder
    private func headerCompacto(_ perfil: BuyerProfile) -> some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    avatarView(perfil)
                        .frame(width: 100, height: 100)
                    
                    // Icono de cámara
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                            .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.appBlue)
                    }
                    .offset(x: 4, y: 4)
                }
            }
            .buttonStyle(.plain)

            VStack(spacing: 4) {
                Text(perfil.nombre)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                Text(perfil.telefono)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity)
        .opacity(aparecer ? 1 : 0)
        .offset(y: aparecer ? 0 : -10)
    }

    @ViewBuilder
    private func avatarView(_ perfil: BuyerProfile) -> some View {
        Group {
            if let data = perfil.fotoPerfilData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle().fill(Color.appBlue.opacity(0.15))
                    Text("🏭").font(.system(size: 48))
                }
            }
        }
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(valor: "\(matches.count)", label: "Matches", color: .appBlue)
            statCard(
                valor: "\(matches.filter { $0.estado == .confirmado }.count)",
                label: "Confirmados", color: .appGreen
            )
            statCard(
                valor: "\(matches.filter { $0.estado == .propuesto }.count)",
                label: "Pendientes", color: .orange
            )
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func statCard(valor: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(valor)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6)) // Gris muy claro para destacar del fondo blanco
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Mini mapa

    @ViewBuilder
    private func miniMapa(_ perfil: BuyerProfile) -> some View {
        let coord = CLLocationCoordinate2D(latitude: perfil.latitud, longitude: perfil.longitud)
        let region = MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        )

        VStack(alignment: .leading, spacing: 8) {
            Text("UBICACIÓN DE PLANTA")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 36)

            ZStack(alignment: .bottomLeading) {
                Map(coordinateRegion: .constant(region),
                    annotationItems: [BuyerMapPinSimple(coordinate: coord)]) { pin in
                    MapMarker(coordinate: pin.coordinate, tint: .appBlue)
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .allowsHitTesting(false)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(Color.appBlue)
                    Text(perfil.direccion)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.9))
                .clipShape(Capsule())
                .padding(12)
            }
            .padding(.horizontal, 20)
            .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        }
    }

    // MARK: - Lista de matches

    private var matchesList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("ACTIVIDAD RECIENTE")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                if !matches.isEmpty {
                    Text("\(matches.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 36)

            if matches.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(matches.enumerated()), id: \.element.id) { idx, match in
                        matchRow(match)
                        if idx < matches.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.tertiary)
            Text("Sin actividad")
                .font(.headline)
            Text("Tus matches aparecerán aquí cuando conectes con un productor.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 32)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func matchRow(_ match: Match) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(colorEstado(match.estado).opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: iconoEstado(match.estado))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(colorEstado(match.estado))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Match registrado")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(match.estado.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(match.fecha, format: .relative(presentation: .numeric))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func iconoEstado(_ estado: MatchEstado) -> String {
        switch estado {
        case .propuesto:  return "clock.fill"
        case .confirmado: return "checkmark"
        case .rechazado:  return "xmark"
        }
    }

    private func colorEstado(_ estado: MatchEstado) -> Color {
        switch estado {
        case .propuesto:  return .orange
        case .confirmado: return .appGreen
        case .rechazado:  return .appRed
        }
    }

    // MARK: - Cambiar rol

    private var botonCambiarRol: some View {
        Button(role: .destructive) {
            mostrarConfirmacion = true
        } label: {
            Text("Cambiar a Productor")
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20)
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

private struct BuyerMapPinSimple: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
