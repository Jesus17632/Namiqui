//
//  ProducerProfile.swift
//  ResiApp
//
//  Created by Dev Jr.23 on 5/5/26.
//

import Foundation
import SwiftData

@Model
final class ProducerProfile {
    @Attribute(.unique) var id: UUID

    var nombre: String
    var telefono: String
    var latitud: Double
    var longitud: Double

    /// Foto de perfil guardada como Data (JPEG comprimido).
    /// nil = usa el avatar de topocho por defecto.
    @Attribute(.externalStorage) var fotoPerfilData: Data?

    /// Fecha de registro
    var fechaRegistro: Date

    init(
        id: UUID = UUID(),
        nombre: String,
        telefono: String,
        latitud: Double = 0,
        longitud: Double = 0,
        fotoPerfilData: Data? = nil,
        fechaRegistro: Date = .now
    ) {
        self.id = id
        self.nombre = nombre
        self.telefono = telefono
        self.latitud = latitud
        self.longitud = longitud
        self.fotoPerfilData = fotoPerfilData
        self.fechaRegistro = fechaRegistro
    }
}
