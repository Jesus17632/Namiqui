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

    @AppStorage("userRole") private var userRole: String = ""
    @State private var capturaSeleccionada: SimulatedCapture? = nil
    @State private var mostrarContacto: Bool = false

    var body: some View {
        ZStack {
            MapaConPins(capturas: capturas) { captura in
                withAnimation(AppAnimation.spring) { capturaSeleccionada = captura }
            }
            .ignoresSafeArea()

            // Backdrop oscuro al abrir popup
            if capturaSeleccionada != nil {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(AppAnimation.spring) { capturaSeleccionada = nil }
                    }
                    .transition(.opacity)
            }

            // Popup CENTRADO
            if let captura = capturaSeleccionada {
                CapturaPopupCentrado(
                    captura: captura,
                    esComprador: userRole == "comprador",
                    onClose: {
                        withAnimation(AppAnimation.spring) { capturaSeleccionada = nil }
                    },
                    onContactar: {
                        capturaSeleccionada = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            mostrarContacto = true
                        }
                    }
                )
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .fullScreenCover(isPresented: $mostrarContacto) {
            ContactoSimuladoView(
                nombreContacto: "Productor",
                telefono: "+52 55 1234 5678",
                onClose: { mostrarContacto = false }
            )
        }
    }
}

// MARK: - Mapa UIKit con pins

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

        let pulse = CALayer()
        pulse.frame = bounds
        pulse.cornerRadius = size / 2
        pulse.backgroundColor = UIColor(red: 0.92, green: 0.18, blue: 0.18, alpha: 0.25).cgColor
        layer.insertSublayer(pulse, at: 0)
        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.fromValue = 0.8; anim.toValue = 1.4
        anim.duration = 1.1; anim.autoreverses = true; anim.repeatCount = .infinity
        pulse.add(anim, forKey: "pulse")

        let circle = UIView(frame: CGRect(x: 7, y: 7, width: size - 14, height: size - 14))
        circle.backgroundColor = UIColor(red: 0.92, green: 0.18, blue: 0.18, alpha: 1)
        circle.layer.cornerRadius = (size - 14) / 2
        addSubview(circle)

        let icon = UIImageView(image: UIImage(systemName: "exclamationmark"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.frame = CGRect(x: 12, y: 10, width: size - 24, height: size - 20)
        addSubview(icon)
    }
}

// MARK: - Popup centrado gris claro con transparencia

struct CapturaPopupCentrado: View {
    let captura: SimulatedCapture
    let esComprador: Bool
    let onClose: () -> Void
    let onContactar: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header con badge alerta y botón cerrar
            HStack(alignment: .top) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text("ALERTA")
                        .font(.caption.weight(.black))
                        .tracking(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.appRed, in: Capsule())

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary.opacity(0.6))
                        .frame(width: 30, height: 30)
                        .background(Color.primary.opacity(0.08), in: Circle())
                }
            }
            .padding(.horizontal, 20).padding(.top, 18)

            // Título
            VStack(alignment: .leading, spacing: 4) {
                Text("Captura de estiércol")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                Text(captura.fecha, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20).padding(.top, 12)

            // Imagen placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.primary.opacity(0.06))
                    .frame(height: 130)
                VStack(spacing: 8) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("Imagen no disponible aún")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20).padding(.top, 14)

            // Grid de datos
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                datoCard(emoji: emojiAnimal(captura.animal), titulo: "Animal",   valor: captura.animal)
                datoCard(emoji: "💧", titulo: "Humedad",  valor: String(format: "%.0f%%", captura.humedadPct))
                datoCard(emoji: "📦", titulo: "Volumen",  valor: String(format: "%.0f m³", captura.volumenM3))
                datoCard(emoji: "🌾", titulo: "Alimento", valor: captura.alimento)
            }
            .padding(.horizontal, 20).padding(.top, 14)

            // Botón Simular contacto (solo comprador)
            if esComprador {
                Button(action: onContactar) {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                        Text("Simular contacto").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appBlue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }

            // Coordenadas
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.caption2).foregroundStyle(.appRed)
                Text(String(format: "%.5f, %.5f", captura.coordLatitud, captura.coordLongitud))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 14).padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 30, y: 12)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func datoCard(emoji: String, titulo: String, valor: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Text(emoji).font(.body)
                Text(titulo)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            Text(valor)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
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
