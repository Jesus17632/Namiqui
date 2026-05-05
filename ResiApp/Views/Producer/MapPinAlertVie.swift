//
//  MapPinAlertVie.swift
//  ResiApp
//
//  Created by Dev Jr.23 on 5/5/26.
//


import SwiftUI
import SwiftData
internal import MapKit

// MARK: - Overlay principal

struct MapCapturaOverlay: View {
    @Query(sort: \SimulatedCapture.fecha, order: .reverse)
    private var capturas: [SimulatedCapture]

    @State private var capturaSeleccionada: SimulatedCapture? = nil

    var body: some View {
        ZStack {
            MapaConPins(capturas: capturas) { captura in
                withAnimation(AppAnimation.spring) { capturaSeleccionada = captura }
            }
            .ignoresSafeArea()

            // Fondo oscuro al abrir popup
            if capturaSeleccionada != nil {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(AppAnimation.spring) { capturaSeleccionada = nil }
                    }
                    .transition(.opacity)
            }

            // Popup grande desde abajo
            if let captura = capturaSeleccionada {
                VStack {
                    Spacer()
                    CapturaPopup(captura: captura) {
                        withAnimation(AppAnimation.spring) { capturaSeleccionada = nil }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

// MARK: - Mapa UIKit con pins personalizados

struct MapaConPins: UIViewRepresentable {
    let capturas: [SimulatedCapture]
    var onSelect: (SimulatedCapture) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onSelect: onSelect, capturas: capturas) }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.register(CapturaAnnotationView.self,
                     forAnnotationViewWithReuseIdentifier: CapturaAnnotationView.reuseID)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        let existing = map.annotations.compactMap { $0 as? CapturaAnnotation }
        map.removeAnnotations(existing)
        let nuevas = capturas.map {
            CapturaAnnotation(
                coordinate: CLLocationCoordinate2D(latitude: $0.coordLatitud, longitude: $0.coordLongitud),
                capturaId: $0.id
            )
        }
        map.addAnnotations(nuevas)
        context.coordinator.capturas = capturas
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var onSelect: (SimulatedCapture) -> Void
        var capturas: [SimulatedCapture]

        init(onSelect: @escaping (SimulatedCapture) -> Void, capturas: [SimulatedCapture]) {
            self.onSelect = onSelect; self.capturas = capturas
        }

        func mapView(_ map: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let ann = annotation as? CapturaAnnotation else { return nil }
            let v = map.dequeueReusableAnnotationView(
                withIdentifier: CapturaAnnotationView.reuseID, for: ann) as? CapturaAnnotationView
            v?.configure()
            return v
        }

        func mapView(_ map: MKMapView, didSelect view: MKAnnotationView) {
            guard let ann = view.annotation as? CapturaAnnotation,
                  let cap = capturas.first(where: { $0.id == ann.capturaId }) else { return }
            map.deselectAnnotation(ann, animated: false)
            onSelect(cap)
        }
    }
}

// MARK: - Annotation

final class CapturaAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let capturaId: UUID
    init(coordinate: CLLocationCoordinate2D, capturaId: UUID) {
        self.coordinate = coordinate; self.capturaId = capturaId
    }
}

// MARK: - Pin rojo pulsante

final class CapturaAnnotationView: MKAnnotationView {
    static let reuseID = "CapturaAnnotationView"
    private let size: CGFloat = 40

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        centerOffset = CGPoint(x: 0, y: -size / 2)
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure() {
        subviews.forEach { $0.removeFromSuperview() }
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        // Anillo pulsante rojo
        let pulse = CALayer()
        pulse.frame = bounds
        pulse.cornerRadius = size / 2
        pulse.backgroundColor = UIColor(red: 0.92, green: 0.18, blue: 0.18, alpha: 0.25).cgColor
        layer.insertSublayer(pulse, at: 0)

        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.fromValue = 0.8; anim.toValue = 1.4
        anim.duration = 1.1; anim.autoreverses = true; anim.repeatCount = .infinity
        pulse.add(anim, forKey: "pulse")

        // Círculo rojo sólido
        let circle = UIView(frame: CGRect(x: 7, y: 7, width: size - 14, height: size - 14))
        circle.backgroundColor = UIColor(red: 0.92, green: 0.18, blue: 0.18, alpha: 1)
        circle.layer.cornerRadius = (size - 14) / 2
        addSubview(circle)

        // Ícono
        let icon = UIImageView(image: UIImage(systemName: "exclamationmark"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.frame = CGRect(x: 12, y: 10, width: size - 24, height: size - 20)
        addSubview(icon)
    }
}

// MARK: - Popup grande con transparencia

struct CapturaPopup: View {
    let captura: SimulatedCapture
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Handle drag indicator
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        // Badge de alerta rojo
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                            Text("ALERTA")
                                .font(.caption.weight(.black))
                                .tracking(1)
                        }
                        .foregroundStyle(.appRed)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.appRedSoft, in: Capsule())
                    }

                    Text("Captura de estiércol")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    Text(captura.fecha, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider().background(Color.white.opacity(0.15))

            // Imagen placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 160)

                VStack(spacing: 10) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.25))
                    Text("Imagen no disponible aún")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Grid de datos
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                datoCard(emoji: emojiAnimal(captura.animal), titulo: "Animal",   valor: captura.animal)
                datoCard(emoji: "💧",                        titulo: "Humedad",  valor: String(format: "%.0f%%",    captura.humedadPct))
                datoCard(emoji: "📦",                        titulo: "Volumen",  valor: String(format: "%.0f m³",   captura.volumenM3))
                datoCard(emoji: "🌾",                        titulo: "Alimento", valor: captura.alimento)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Coordenadas
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.caption).foregroundStyle(.appRed)
                Text(String(format: "%.5f, %.5f", captura.coordLatitud, captura.coordLongitud))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.top, 16)
            .padding(.bottom, 36)
        }
        .background(
            RoundedRectangle(cornerRadius: AppPopup.cornerRadius, style: .continuous)
                .fill(AppPopup.material)
                .overlay(
                    RoundedRectangle(cornerRadius: AppPopup.cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: AppPopup.shadowColor, radius: AppPopup.shadowRadius, y: AppPopup.shadowY)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func datoCard(emoji: String, titulo: String, valor: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(emoji).font(.title3)
                Text(titulo)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            Text(valor)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
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
