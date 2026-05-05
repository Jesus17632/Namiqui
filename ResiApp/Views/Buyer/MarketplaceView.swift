//
//  MarketplaceView.swift
//  EcoVinculo
//

import SwiftUI
import SwiftData
import CoreLocation
internal import MapKit

struct MarketplaceView: View {

    @State private var filtroEspecie: String = "Todos"
    
    // Lista de especies para el filtro superior
    let opcionesFiltro = ["Todos", "Bovino", "Porcino", "Aviar", "Ovino"]

    // Propiedad calculada que filtra los datos hardcodeados según la selección
    var capturasFiltradas: [SimulatedCapture] {
        if filtroEspecie == "Todos" {
            return HardcodedData.capturasMock
        } else {
            return HardcodedData.capturasMock.filter { $0.animal.contains(filtroEspecie) }
        }
    }

    // Configuración de la cuadrícula: 2 columnas flexibles
    let columnasGrid = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filtros

                if capturasFiltradas.isEmpty {
                    estadoVacio
                } else {
                    ScrollView {
                        LazyVGrid(columns: columnasGrid, spacing: 16) {
                            ForEach(capturasFiltradas) { captura in
                                CapturaCard(captura: captura)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Marketplace")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    // MARK: - Filtros por Especie

    private var filtros: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(opcionesFiltro, id: \.self) { especie in
                    filtroChip(especie)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private func filtroChip(_ especie: String) -> some View {
        let activo = (filtroEspecie == especie)
        Button {
            withAnimation {
                filtroEspecie = especie
            }
        } label: {
            Text(especie)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(activo ? Color.green : Color(.secondarySystemBackground))
                .foregroundStyle(activo ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Estado vacío

    private var estadoVacio: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.arrow.triangle.circlepath")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No hay resultados")
                .font(.headline)
            Text("Actualmente no hay capturas disponibles para la especie seleccionada.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tarjeta en Cuadrícula (CapturaCard)

struct CapturaCard: View {
    let captura: SimulatedCapture

    @Environment(LocationManager.self) private var locationManager

    /// Distancia en kilómetros entre la captura y el comprador.
    private var distanciaKm: Double {
        let buyerCoord = locationManager.region.center
        let buyerLocation = CLLocation(
            latitude: buyerCoord.latitude,
            longitude: buyerCoord.longitude
        )
        let pileLocation = CLLocation(
            latitude: captura.latitud,
            longitude: captura.longitud
        )
        return pileLocation.distance(from: buyerLocation) / 1000.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Espacio para la imagen (Placeholder)
            ZStack {
                Color(.secondarySystemBackground)
                Image(systemName: "photo.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.tertiary)
            }
            .frame(height: 110)
            .clipped()

            // 2. Información de la tarjeta
            VStack(alignment: .leading, spacing: 6) {
                // Especie y volumen
                HStack(alignment: .top) {
                    Text(captura.animal)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text("\(captura.volumenM3, specifier: "%.0f") m³")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }
                
                // Humedad y alimento
                Text("💧 \(captura.humedadPct, specifier: "%.0f")% • \(captura.alimento)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Divider().padding(.vertical, 2)

                // Distancia
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.green)
                        .font(.caption2)
                    Text("A \(distanciaKm, specifier: "%.1f") km")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 3)
    }
}

// MARK: - HARDCODED DATA (Tus datos)

struct HardcodedDatas {
    // +20 Zonas Ganaderas (Alejadas de las ciudades principales)
    static let capturasMock: [SimulatedCapture] = [
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Bovino", humedadPct: 45.0, volumenM3: 150.0, alimento: "Forraje", latitud: 28.4053, longitud: -106.8671),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Porcino", humedadPct: 60.0, volumenM3: 80.5, alimento: "Grano", latitud: 20.8144, longitud: -102.7686),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Bovino", humedadPct: 50.0, volumenM3: 120.0, alimento: "Pasto mixto", latitud: 16.9056, longitud: -92.0931),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Ovino", humedadPct: 35.0, volumenM3: 40.0, alimento: "Pasto seco", latitud: 19.3142, longitud: -97.9255),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Porcino", humedadPct: 55.0, volumenM3: 90.0, alimento: "Concentrado", latitud: 18.8858, longitud: -97.7275),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Bovino", humedadPct: 48.0, volumenM3: 110.0, alimento: "Alfalfa", latitud: 18.9030, longitud: -98.4380),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Aviar", humedadPct: 30.0, volumenM3: 200.0, alimento: "Maíz", latitud: 18.4611, longitud: -97.3931),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Bovino", humedadPct: 40.0, volumenM3: 95.0, alimento: "Paja", latitud: 30.5606, longitud: -115.9422),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Porcino", humedadPct: 58.0, volumenM3: 130.0, alimento: "Soya", latitud: 27.0722, longitud: -109.4439),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Bovino", humedadPct: 46.0, volumenM3: 180.0, alimento: "Sorgo", latitud: 25.5744, longitud: -108.3667),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Bovino", humedadPct: 52.0, volumenM3: 300.0, alimento: "Silo de maíz", latitud: 25.5611, longitud: -103.4961),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Bovino", humedadPct: 50.0, volumenM3: 280.0, alimento: "Silo de maíz", latitud: 25.5833, longitud: -103.4958),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Porcino", humedadPct: 62.0, volumenM3: 150.0, alimento: "Alimento balanceado", latitud: 20.3411, longitud: -102.0225),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Bovino", humedadPct: 47.0, volumenM3: 85.0, alimento: "Pasto tropical", latitud: 22.2150, longitud: -98.3842),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Bovino", humedadPct: 44.0, volumenM3: 105.0, alimento: "Estrella de África", latitud: 21.3508, longitud: -98.2250),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Bovino", humedadPct: 55.0, volumenM3: 75.0, alimento: "Guinea", latitud: 21.1425, longitud: -88.1522),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Bovino", humedadPct: 53.0, volumenM3: 60.0, alimento: "Pasto natural", latitud: 18.1833, longitud: -90.6833),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Ovino", humedadPct: 38.0, volumenM3: 45.0, alimento: "Zacate", latitud: 16.6975, longitud: -93.7214),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Bovino", humedadPct: 49.0, volumenM3: 110.0, alimento: "Caña de azúcar", latitud: 19.7717, longitud: -104.3642),
        SimulatedCapture(id: UUID(), producerProfileId: UUID(), fecha: Date(), animal: "Porcino", humedadPct: 57.0, volumenM3: 140.0, alimento: "Mezcla comercial", latitud: 25.9222, longitud: -109.1731)
    ]

    // 5 Plantas procesadoras de fertilizante
    static let compradoresMock: [BuyerProfile] = [
        BuyerProfile(id: UUID(), nombre: "BioFertilizantes del Bajío", telefono: "+52 461 555 0101", direccion: "Celaya, GTO", latitud: 20.5281, longitud: -100.8122),
        BuyerProfile(id: UUID(), nombre: "Agroquímicos e Insumos", telefono: "+52 462 555 0102", direccion: "Irapuato, GTO", latitud: 20.6736, longitud: -101.3500),
        BuyerProfile(id: UUID(), nombre: "Planta Industrial Norte", telefono: "+52 81 555 0103", direccion: "Pesquería, NL", latitud: 25.7836, longitud: -100.0519),
        BuyerProfile(id: UUID(), nombre: "Procesadora Agro", telefono: "+52 33 555 0104", direccion: "Zapopan Norte, JAL", latitud: 20.7300, longitud: -103.4350),
        BuyerProfile(id: UUID(), nombre: "Fertilizantes del Golfo", telefono: "+52 921 555 0105", direccion: "Coatzacoalcos, VER", latitud: 18.1342, longitud: -94.4447)
    ]
}
