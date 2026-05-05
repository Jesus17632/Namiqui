//
//  ContactoSimuladoView.swift.swift
//  ResiApp
//
//  Created by Dev Jr.23 on 5/5/26.
//

import SwiftUI
import Combine

enum EstadoLlamada {
    case marcando
    case llamando
    case conectado
}

struct MensajeChat: Identifiable {
    let id = UUID()
    let texto: String
    let esMio: Bool
    let hora: Date
}

struct ContactoSimuladoView: View {
    let nombreContacto: String
    let telefono: String
    let onClose: () -> Void

    @State private var estado: EstadoLlamada = .marcando
    @State private var segundosLlamada = 0
    @State private var mensajes: [MensajeChat] = []
    @State private var mensajeNuevo = ""
    @State private var aparecer = false
    @State private var pulsoAvatar = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            AppGradients.producerBG.ignoresSafeArea()

            // Patrón decorativo
            GeometryReader { geo in
                ForEach(0..<5) { i in
                    Circle()
                        .fill(Color.white.opacity(0.03))
                        .frame(width: CGFloat(60 + i * 40))
                        .offset(x: CGFloat(i * 60) - 30,
                                y: CGFloat(i % 2 == 0 ? 30 : 90))
                }
            }.ignoresSafeArea()

            VStack(spacing: 0) {
                headerLlamada
                Spacer()
                if estado == .conectado {
                    chatView
                } else {
                    llamandoView
                }
            }
        }
        .onAppear {
            aparecer = true
            // Marcando → llamando
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(AppAnimation.spring) { estado = .llamando }
            }
            // Llamando → conectado (luego de 3 seg)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                withAnimation(AppAnimation.spring) {
                    estado = .conectado
                    cargarMensajesIniciales()
                }
            }
        }
        .onReceive(timer) { _ in
            if estado == .conectado { segundosLlamada += 1 }
        }
    }

    // MARK: - Header

    private var headerLlamada: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "chevron.down")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.12), in: Circle())
                }
                Spacer()
                if estado == .conectado {
                    HStack(spacing: 6) {
                        Circle().fill(Color.appGreen).frame(width: 8, height: 8)
                        Text(formatearTiempo(segundosLlamada))
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "phone.down.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.appRed, in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // Avatar grande con pulso
            ZStack {
                if pulsoAvatar && estado != .conectado {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 130, height: 130)
                        .scaleEffect(pulsoAvatar ? 1.3 : 1.0)
                        .opacity(pulsoAvatar ? 0 : 1)
                        .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulsoAvatar)
                }
                ZStack {
                    Circle().fill(LinearGradient(
                        colors: [Color(red: 1, green: 0.87, blue: 0.2), Color(red: 0.95, green: 0.7, blue: 0.1)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 110, height: 110)
                    Text("🍌").font(.system(size: 56))
                }
                .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
            }
            .onAppear { pulsoAvatar = true }

            // Nombre + estado
            VStack(spacing: 4) {
                Text(nombreContacto)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text(estado == .conectado ? telefono : textoEstado)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .animation(.easeInOut, value: estado)
            }
        }
        .opacity(aparecer ? 1 : 0)
        .offset(y: aparecer ? 0 : -20)
        .animation(AppAnimation.easeSnap, value: aparecer)
    }

    private var textoEstado: String {
        switch estado {
        case .marcando: return "Marcando…"
        case .llamando: return "Llamando…"
        case .conectado: return ""
        }
    }

    // MARK: - Llamando view

    private var llamandoView: some View {
        VStack(spacing: 24) {
            // Onda de sonido animada
            HStack(spacing: 6) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 4, height: estado == .llamando ? CGFloat.random(in: 14...32) : 14)
                        .animation(
                            .easeInOut(duration: 0.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.1),
                            value: estado
                        )
                }
            }
            .frame(height: 40)

            Text("Conectando con el productor")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxHeight: .infinity)
        .padding(.bottom, 80)
    }

    // MARK: - Chat view

    private var chatView: some View {
        VStack(spacing: 0) {
            // Mensajes
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(mensajes) { msg in
                            burbuja(msg).id(msg.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .onChange(of: mensajes.count) { _, _ in
                    if let last = mensajes.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            // Input
            HStack(spacing: 10) {
                TextField("", text: $mensajeNuevo,
                          prompt: Text("Mensaje…").foregroundColor(.white.opacity(0.4)))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Color.white.opacity(0.1), in: Capsule())

                Button(action: enviarMensaje) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            mensajeNuevo.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.white.opacity(0.15)
                                : Color.appGreen,
                            in: Circle()
                        )
                }
                .disabled(mensajeNuevo.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
            .padding(.top, 8)
            .background(.ultraThinMaterial)
        }
        .frame(maxHeight: 380)
    }

    @ViewBuilder
    private func burbuja(_ msg: MensajeChat) -> some View {
        HStack {
            if msg.esMio { Spacer(minLength: 50) }
            Text(msg.texto)
                .font(.subheadline)
                .foregroundStyle(msg.esMio ? .white : .white)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    msg.esMio
                        ? AnyShapeStyle(Color.appBlue)
                        : AnyShapeStyle(Color.white.opacity(0.12))
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            if !msg.esMio { Spacer(minLength: 50) }
        }
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    // MARK: - Lógica

    private func cargarMensajesIniciales() {
        mensajes.append(MensajeChat(
            texto: "¡Hola! Vi tu interés en mi captura de estiércol. ¿En qué te puedo ayudar?",
            esMio: false, hora: .now))
    }

    private func enviarMensaje() {
        let texto = mensajeNuevo.trimmingCharacters(in: .whitespaces)
        guard !texto.isEmpty else { return }
        withAnimation(AppAnimation.spring) {
            mensajes.append(MensajeChat(texto: texto, esMio: true, hora: .now))
        }
        mensajeNuevo = ""

        // Respuesta automática simulada
        let respuestas = [
            "Sí, claro. ¿Cuándo lo necesitas?",
            "Perfecto, podemos coordinar la entrega.",
            "El estiércol está fresco, máximo 3 días.",
            "Te paso mi ubicación exacta cuando confirmes.",
            "Ese precio me parece justo. ¿Cerramos trato?"
        ]
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(AppAnimation.spring) {
                mensajes.append(MensajeChat(
                    texto: respuestas.randomElement() ?? "Ok",
                    esMio: false, hora: .now))
            }
        }
    }

    private func formatearTiempo(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}
