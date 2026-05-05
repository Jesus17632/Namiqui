//
//  AppTheme.swift
//  ResiApp
//
//  Created by Dev Jr.23 on 5/5/26.
//

import SwiftUI

// MARK: - Colores base

extension Color {
    // ── Marca ──────────────────────────────────────────────────────
    static let appGreen        = Color(red: 0.13, green: 0.75, blue: 0.37) // #22BF5E
    static let appGreenDark    = Color(red: 0.06, green: 0.40, blue: 0.20)
    static let appGreenDeep    = Color(red: 0.04, green: 0.18, blue: 0.10)

    // ── Alertas / peligro ───────────────────────────────────────────
    static let appRed          = Color(red: 0.92, green: 0.18, blue: 0.18)
    static let appRedSoft      = Color(red: 0.92, green: 0.18, blue: 0.18).opacity(0.18)

    // ── Comprador ───────────────────────────────────────────────────
    static let appBlue         = Color(red: 0.10, green: 0.45, blue: 0.90)
    static let appBlueDark     = Color(red: 0.05, green: 0.18, blue: 0.40)
    static let appBlueDeep     = Color(red: 0.03, green: 0.10, blue: 0.25)

    // ── Superficies ─────────────────────────────────────────────────
    static let surfaceWhite    = Color.white.opacity(0.08)
    static let surfaceBorder   = Color.white.opacity(0.14)
    static let surfaceOverlay  = Color.black.opacity(0.28)

    // Compatibilidad con código existente
    static let tlaneGreen      = Color.appGreen
}

// MARK: - Gradientes

struct AppGradients {
    static let producerBG = LinearGradient(
        colors: [Color.appGreenDeep, Color.appGreenDark],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let producerHeader = LinearGradient(
        colors: [Color.appGreenDeep, Color.appGreen.opacity(0.85)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let buyerBG = LinearGradient(
        colors: [Color.appBlueDeep, Color.appBlueDark],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let buyerHeader = LinearGradient(
        colors: [Color.appBlueDeep, Color.appBlue.opacity(0.85)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let alertPin = LinearGradient(
        colors: [Color.appRed, Color.appRed.opacity(0.7)],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Popup

struct AppPopup {
    static let material: Material        = .ultraThinMaterial
    static let cornerRadius: CGFloat     = 28
    static let shadowColor               = Color.black.opacity(0.40)
    static let shadowRadius: CGFloat     = 32
    static let shadowY: CGFloat          = 12
}

// MARK: - Campo de texto

struct AppField {
    static let background      = Color.white.opacity(0.08)
    static let border          = Color.white.opacity(0.15)
    static let cornerRadius: CGFloat = 14
    static let padding: CGFloat      = 16
}

// MARK: - Animaciones

struct AppAnimation {
    static let spring   = Animation.spring(response: 0.55, dampingFraction: 0.72)
    static let easeSnap = Animation.easeOut(duration: 0.38)
    static let popIn    = Animation.spring(response: 0.45, dampingFraction: 0.58)
}

// MARK: - ViewModifiers

struct AppTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppField.padding)
            .background(
                RoundedRectangle(cornerRadius: AppField.cornerRadius)
                    .fill(AppField.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppField.cornerRadius)
                            .strokeBorder(AppField.border, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func appFieldStyle() -> some View { modifier(AppTextFieldModifier()) }

    func appPrimaryButton(color: Color, enabled: Bool) -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(18)
            .background(enabled ? color : Color.white.opacity(0.12))
            .foregroundStyle(enabled ? .white : .white.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .animation(AppAnimation.easeSnap, value: enabled)
    }
}

// MARK: - ShapeStyle conformance
// Permite usar .appGreen, .appRed, .appBlue directamente en foregroundStyle(), etc.
extension ShapeStyle where Self == Color {
    static var appGreen: Color { .appGreen }
    static var appGreenDark: Color { .appGreenDark }
    static var appRed: Color { .appRed }
    static var appRedSoft: Color { .appRedSoft }
    static var appBlue: Color { .appBlue }
    static var appBlueDark: Color { .appBlueDark }
    static var surfaceWhite: Color { .surfaceWhite }
    static var surfaceBorder: Color { .surfaceBorder }
}
