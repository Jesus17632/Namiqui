//
//  BuyerProfile.swift
//  ResiApp
//
//  Created by Dev Jr.23 on 5/5/26.
//

import Foundation
import SwiftData

@Model
final class BuyerProfile {
    @Attribute(.unique) var id: UUID
    var nombre: String
    var telefono: String
    var direccion: String       // Texto libre de la dirección
    var latitud: Double
    var longitud: Double
    @Attribute(.externalStorage) var fotoPerfilData: Data?
    var fechaRegistro: Date

    init(
        id: UUID = UUID(),
        nombre: String,
        telefono: String,
        direccion: String,
        latitud: Double = 0,
        longitud: Double = 0,
        fotoPerfilData: Data? = nil,
        fechaRegistro: Date = .now
    ) {
        self.id = id
        self.nombre = nombre
        self.telefono = telefono
        self.direccion = direccion
        self.latitud = latitud
        self.longitud = longitud
        self.fotoPerfilData = fotoPerfilData
        self.fechaRegistro = fechaRegistro
    }
}
