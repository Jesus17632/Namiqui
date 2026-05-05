//
//  RolSelectorView.swift
//  EcoVinculo
//
//  Pantalla de bienvenida del primer lanzamiento. El usuario debe elegir
//  un rol antes de continuar; no hay forma de cerrarla sin elegir.
//

import SwiftUI

struct RolSelectorView: View {
    @AppStorage("userRole") private var userRole: String = ""
    
    // Nueva variable para controlar la vista emergente
    @State private var mostrarOnboardingProductor = false

    var body: some View {
        VStack(spacing: 32) {
            // Encabezado / branding
            VStack(spacing: 12) {
                Image(systemName: "leaf.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.green)

                Text("EcoVínculo Ganadero")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("Elige tu rol para empezar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 60)

            Spacer()

            // Dos botones grandes con ícono y descripción
            VStack(spacing: 20) {
                rolButton(
                    icono: "leaf.fill",
                    titulo: "Soy Productor",
                    descripcion: "Tengo estiércol que quiero aprovechar"
                ) {
                    // Abrimos la pantalla emergente en lugar de asignar el rol de golpe
                    mostrarOnboardingProductor = true
                }

                rolButton(
                    icono: "building.2.fill",
                    titulo: "Soy Comprador",
                    descripcion: "Proceso material para biogás o compostaje"
                ) {
                    userRole = "comprador"
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        // Aquí conectamos el Onboarding del Productor como una vista independiente
        .fullScreenCover(isPresented: $mostrarOnboardingProductor) {
            ProducerOnboardingView(
                onComplete: {
                    // Al terminar, asignamos el rol y cerramos el modal
                    userRole = "productor"
                    mostrarOnboardingProductor = false
                },
                onBack: {
                    // Si le da a la flechita de regreso, solo cerramos el modal
                    mostrarOnboardingProductor = false
                }
            )
        }
    }

    /// Card-button reutilizable para cada rol.
    @ViewBuilder
    private func rolButton(
        icono: String,
        titulo: String,
        descripcion: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icono)
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
                    .frame(width: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(titulo)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text(descripcion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RolSelectorView()
}
