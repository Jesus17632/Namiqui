//
//  MapPinAlertVie.swift
//  ResiApp
//
//  Created by Dev Jr.23 on 5/5/26.
//
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

    @Query private var compradores: [BuyerProfile]

    @AppStorage("userRole") private var userRole: String = ""
    @State private var capturaSeleccionada: SimulatedCapture? = nil
    @State private var mostrarContacto: Bool = false
    @State private var mostrarChat: Bool = false

    // COMBINAMOS LOS DATOS DE SWIFTDATA CON LOS DATOS HARDCODEADOS
    private var todasLasCapturas: [SimulatedCapture] {
        capturas + HardcodedData.capturasMock
    }
    
    private var todosLosCompradores: [BuyerProfile] {
        compradores + HardcodedData.compradoresMock
    }

    var body: some View {
        ZStack {
            MapaConPins(
                capturas: todasLasCapturas,       // Pasamos el arreglo combinado
                compradores: todosLosCompradores, // Pasamos el arreglo combinado
                onSelectCaptura: { captura in
                    withAnimation(AppAnimation.spring) { capturaSeleccionada = captura }
                }
            )
            .ignoresSafeArea()

            // 💬 CHATBOT FAB — esquina superior izquierda
            VStack {
                HStack {
                    ChatBotButton(mostrarChat: $mostrarChat)
                        .padding(.leading, 16)
                        .padding(.top, 65)
                    Spacer()
                }
                Spacer()
            }

            if capturaSeleccionada != nil {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(AppAnimation.spring) { capturaSeleccionada = nil }
                    }
                    .transition(.opacity)
            }

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
        .sheet(isPresented: $mostrarChat) {
            // Conecta aquí tu ChatBotView
            Text("Chat Bot")
        }
    }
}

// MARK: - ChatBot FAB

struct ChatBotButton: View {
    @Binding var mostrarChat: Bool

    var body: some View {
        Button(action: { mostrarChat = true }) {
            ZStack {
                // Círculo principal sólido verde
                Circle()
                    .fill(Color.appGreen)
                    .frame(width: 56, height: 56) // Tamaño ajustado para buen área táctil
                    .shadow(
                        color: Color.appGreen.opacity(0.4),
                        radius: 6, y: 3
                    )

                Image(systemName: "message.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Mapa UIKit con pins (capturas + compradores)

struct MapaConPins: UIViewRepresentable {
    let capturas: [SimulatedCapture]
    let compradores: [BuyerProfile]
    var onSelectCaptura: (SimulatedCapture) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelectCaptura, capturas: capturas)
    }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.register(CapturaAnnotationView.self,
                     forAnnotationViewWithReuseIdentifier: CapturaAnnotationView.reuseID)
        map.register(BuyerAnnotationView.self,
                     forAnnotationViewWithReuseIdentifier: BuyerAnnotationView.reuseID)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        let viejas = map.annotations.filter {
            $0 is CapturaAnnotation || $0 is BuyerAnnotation
        }
        map.removeAnnotations(viejas)

        let pinsCaptura = capturas.map {
            CapturaAnnotation(
                coordinate: CLLocationCoordinate2D(latitude: $0.coordLatitud, longitude: $0.coordLongitud),
                capturaId: $0.id
            )
        }
        map.addAnnotations(pinsCaptura)

        let pinsBuyer = compradores.map {
            BuyerAnnotation(
                coordinate: CLLocationCoordinate2D(latitude: $0.latitud, longitude: $0.longitud),
                nombre: $0.nombre,
                direccion: $0.direccion
            )
        }
        map.addAnnotations(pinsBuyer)

        context.coordinator.capturas = capturas
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var onSelect: (SimulatedCapture) -> Void
        var capturas: [SimulatedCapture]

        init(onSelect: @escaping (SimulatedCapture) -> Void, capturas: [SimulatedCapture]) {
            self.onSelect = onSelect; self.capturas = capturas
        }

        func mapView(_ map: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let ann = annotation as? CapturaAnnotation {
                let v = map.dequeueReusableAnnotationView(
                    withIdentifier: CapturaAnnotationView.reuseID, for: ann) as? CapturaAnnotationView
                v?.configure()
                return v
            }
            if let ann = annotation as? BuyerAnnotation {
                let v = map.dequeueReusableAnnotationView(
                    withIdentifier: BuyerAnnotationView.reuseID, for: ann) as? BuyerAnnotationView
                v?.configure()
                v?.canShowCallout = true
                return v
            }
            return nil
        }

        func mapView(_ map: MKMapView, didSelect view: MKAnnotationView) {
            guard let ann = view.annotation as? CapturaAnnotation,
                  let cap = capturas.first(where: { $0.id == ann.capturaId }) else { return }
            map.deselectAnnotation(ann, animated: false)
            onSelect(cap)
        }
    }
}

// MARK: - Annotations

final class CapturaAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let capturaId: UUID
    init(coordinate: CLLocationCoordinate2D, capturaId: UUID) {
        self.coordinate = coordinate; self.capturaId = capturaId
    }
}

final class BuyerAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?

    init(coordinate: CLLocationCoordinate2D, nombre: String, direccion: String) {
        self.coordinate = coordinate
        self.title = nombre
        self.subtitle = direccion
    }
}

// MARK: - Pin verde pulsante (capturas = oportunidad)

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

        // Anillo pulsante verde oportunidad (USANDO EL THEME)
        let pulse = CALayer()
        pulse.frame = bounds
        pulse.cornerRadius = size / 2
        pulse.backgroundColor = UIColor(Color.appGreen).withAlphaComponent(0.25).cgColor
        layer.insertSublayer(pulse, at: 0)
        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.fromValue = 0.8; anim.toValue = 1.4
        anim.duration = 1.1; anim.autoreverses = true; anim.repeatCount = .infinity
        pulse.add(anim, forKey: "pulse")

        // Círculo verde esmeralda (USANDO EL THEME)
        let circle = UIView(frame: CGRect(x: 7, y: 7, width: size - 14, height: size - 14))
        circle.backgroundColor = UIColor(Color.appGreen)
        circle.layer.cornerRadius = (size - 14) / 2
        addSubview(circle)

        let icon = UIImageView(image: UIImage(systemName: "exclamationmark"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.frame = CGRect(x: 12, y: 10, width: size - 24, height: size - 20)
        addSubview(icon)
    }
}

// MARK: - Pin azul tienda (comprador)

final class BuyerAnnotationView: MKAnnotationView {
    static let reuseID = "BuyerAnnotationView"
    private let size: CGFloat = 44

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

        // Anillo blanco con sombra
        let ring = UIView(frame: bounds)
        ring.backgroundColor = .white
        ring.layer.cornerRadius = size / 2
        ring.layer.shadowColor = UIColor.black.cgColor
        ring.layer.shadowOpacity = 0.3
        ring.layer.shadowRadius = 6
        ring.layer.shadowOffset = CGSize(width: 0, height: 3)
        addSubview(ring)

        // Círculo azul interior (USANDO EL THEME)
        let inset: CGFloat = 4
        let circle = UIView(frame: CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2))
        circle.backgroundColor = UIColor(Color.appBlue)
        circle.layer.cornerRadius = (size - inset * 2) / 2
        addSubview(circle)

        // Ícono de tienda (storefront)
        let icon = UIImageView(image: UIImage(systemName: "storefront.fill"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        let iconSize: CGFloat = 20
        icon.frame = CGRect(
            x: (size - iconSize) / 2,
            y: (size - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )
        addSubview(icon)
    }
}

// MARK: - Popup centrado

struct CapturaPopupCentrado: View {
    let captura: SimulatedCapture
    let esComprador: Bool
    let onClose: () -> Void
    let onContactar: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill").font(.caption)
                    Text("OPORTUNIDAD").font(.caption.weight(.black)).tracking(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.appGreen, in: Capsule()) // USANDO EL THEME

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

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                datoCard(emoji: "🐄", titulo: "Animal",   valor: "Bovino 🐄")
                datoCard(emoji: "💧", titulo: "Humedad",  valor: String(format: "%.0f%%", captura.humedadPct))
                datoCard(emoji: "📦", titulo: "Volumen",  valor: String(format: "%.0f m³", captura.volumenM3))
                datoCard(emoji: "🌾", titulo: "Alimento", valor: captura.alimento)
            }
            .padding(.horizontal, 20).padding(.top, 14)

            if esComprador {
                Button(action: onContactar) {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                        Text("Simular contacto").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appBlue) // USANDO EL THEME
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }

            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.appGreen) // USANDO EL THEME
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
}

// MARK: - HARDCODED DATA

struct HardcodedData {
    static let capturasMock: [SimulatedCapture] = [
        SimulatedCapture(producerProfileId: UUID(), humedadPct: 45.0, volumenM3: 150.0, alimento: "Silo de maíz",      latitud: 28.4053, longitud: -106.8671),
        SimulatedCapture(producerProfileId: UUID(), humedadPct: 50.0, volumenM3: 120.0, alimento: "Pasto estrella",    latitud: 16.9056, longitud: -92.0931),
        SimulatedCapture(producerProfileId: UUID(), humedadPct: 48.0, volumenM3: 110.0, alimento: "Alfalfa",           latitud: 18.9030, longitud: -98.4380),
        SimulatedCapture(producerProfileId: UUID(), humedadPct: 40.0, volumenM3: 95.0,  alimento: "Rastrojo de maíz",  latitud: 30.5606, longitud: -115.9422),
        SimulatedCapture(producerProfileId: UUID(), humedadPct: 46.0, volumenM3: 180.0, alimento: "Sorgo forrajero",   latitud: 25.5744, longitud: -108.3667),
        SimulatedCapture(producerProfileId: UUID(), humedadPct: 52.0, volumenM3: 300.0, alimento: "Silo de maíz",      latitud: 25.5611, longitud: -103.4961),
        SimulatedCapture(producerProfileId: UUID(), humedadPct: 50.0, volumenM3: 280.0, alimento: "Silo de maíz",      latitud: 25.5833, longitud: -103.4958),
        SimulatedCapture(producerProfileId: UUID(), humedadPct: 47.0, volumenM3: 85.0,  alimento: "Pasto estrella",    latitud: 22.2150, longitud: -98.3842),
        SimulatedCapture(producerProfileId: UUID(), humedadPct: 44.0, volumenM3: 105.0, alimento: "Alfalfa",           latitud: 21.3508, longitud: -98.2250),
        SimulatedCapture(producerProfileId: UUID(), humedadPct: 55.0, volumenM3: 75.0,  alimento: "Pasto estrella",    latitud: 21.1425, longitud: -88.1522),
        SimulatedCapture(producerProfileId: UUID(), humedadPct: 53.0, volumenM3: 60.0,  alimento: "Sorgo forrajero",   latitud: 18.1833, longitud: -90.6833),
        SimulatedCapture(producerProfileId: UUID(), humedadPct: 49.0, volumenM3: 110.0, alimento: "Rastrojo de maíz",  latitud: 19.7717, longitud: -104.3642)
    ]

    static let compradoresMock: [BuyerProfile] = [
        BuyerProfile(id: UUID(), nombre: "BioFertilizantes del Bajío", telefono: "+52 461 555 0101", direccion: "Celaya, GTO", latitud: 20.5281, longitud: -100.8122),
        BuyerProfile(id: UUID(), nombre: "Agroquímicos e Insumos", telefono: "+52 462 555 0102", direccion: "Irapuato, GTO", latitud: 20.6736, longitud: -101.3500),
        BuyerProfile(id: UUID(), nombre: "Planta Industrial Norte", telefono: "+52 81 555 0103", direccion: "Pesquería, NL", latitud: 25.7836, longitud: -100.0519),
        BuyerProfile(id: UUID(), nombre: "Procesadora Agro", telefono: "+52 33 555 0104", direccion: "Zapopan Norte, JAL", latitud: 20.7300, longitud: -103.4350),
        BuyerProfile(id: UUID(), nombre: "Fertilizantes del Golfo", telefono: "+52 921 555 0105", direccion: "Coatzacoalcos, VER", latitud: 18.1342, longitud: -94.4447)
    ]
}

