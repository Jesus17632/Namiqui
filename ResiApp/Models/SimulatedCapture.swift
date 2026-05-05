//
//  SimulatedCapture.swift
//  ResiApp
//
//  Created by Dev Jr.23 on 5/5/26.
//


import Foundation
import SwiftData

/// Tipo de animal fuente del estiércol
enum AnimalFuente: String, Codable, CaseIterable {
    case bovino   = "Bovino 🐄"
    case porcino  = "Porcino 🐷"
    case aviar    = "Aviar 🐔"
    case equino   = "Equino 🐴"
    case ovino    = "Ovino 🐑"
}

@Model
final class SimulatedCapture {
    @Attribute(.unique) var id: UUID

    /// Referencia al productor dueño de esta captura
    var producerProfileId: UUID

    var fecha: Date
    var animal: String          // AnimalFuente.rawValue
    var humedadPct: Double      // 0–100
    var volumenM3: Double       // metros cúbicos
    var alimento: String        // qué come el animal

    /// Coordenadas donde se generó el pin en el mapa
    var latitud: Double
    var longitud: Double

    /// Pequeño offset aleatorio para que los pins no se superpongan
    var latOffset: Double
    var lonOffset: Double

    init(
        id: UUID = UUID(),
        producerProfileId: UUID,
        fecha: Date = .now,
        animal: String,
        humedadPct: Double,
        volumenM3: Double,
        alimento: String,
        latitud: Double,
        longitud: Double,
        latOffset: Double = Double.random(in: -0.002...0.002),
        lonOffset: Double = Double.random(in: -0.002...0.002)
    ) {
        self.id = id
        self.producerProfileId = producerProfileId
        self.fecha = fecha
        self.animal = animal
        self.humedadPct = humedadPct
        self.volumenM3 = volumenM3
        self.alimento = alimento
        self.latitud = latitud
        self.longitud = longitud
        self.latOffset = latOffset
        self.lonOffset = lonOffset
    }

    /// Coordenada efectiva en el mapa (con offset para no solapar)
    var coordLatitud: Double { latitud + latOffset }
    var coordLongitud: Double { longitud + lonOffset }
}

// MARK: - Factory de datos aleatorios

extension SimulatedCapture {
    static func aleatorio(profileId: UUID, lat: Double, lon: Double) -> SimulatedCapture {
        let animal = AnimalFuente.allCases.randomElement()!
        let alimentos: [String] = ["Maíz y sorgo", "Pasto estrella", "Alfalfa", "Rastrojo de trigo", "Concentrado balanceado", "Caña de azúcar"]
        return SimulatedCapture(
            producerProfileId: profileId,
            animal: animal.rawValue,
            humedadPct: Double.random(in: 55...85).rounded(),
            volumenM3: Double(Int.random(in: 2...30)),
            alimento: alimentos.randomElement()!,
            latitud: lat,
            longitud: lon
        )
    }
}
