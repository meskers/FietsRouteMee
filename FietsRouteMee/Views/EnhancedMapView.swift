//
//  EnhancedMapView.swift
//  FietsRouteMee
//
//  Enhanced MapView with MapLibre integration for superior cycling maps
//

import SwiftUI
import MapKit
import CoreLocation

struct EnhancedMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var routes: [BikeRoute]
    @Binding var selectedRoute: BikeRoute?
    @Binding var knooppunten: [Fietsknooppunt]
    @Binding var cyclingPOIs: [CyclingPOI]
    
    var pendingStartLocation: CLLocationCoordinate2D? = nil
    var pendingEndLocation: CLLocationCoordinate2D? = nil
    var showKnooppunten: Bool = true
    var showCyclingPOIs: Bool = true
    
    @ObservedObject private var settingsManager = AppSettingsManager.shared
    @ObservedObject private var mapLibreService = MapLibreService.shared
    @ObservedObject private var fietsknooppuntenService = FietsknooppuntenService.shared
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
        // Set a minimum frame to prevent CAMetalLayer errors
        mapView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        // Apply enhanced settings
        applyEnhancedSettings(to: mapView)
        
        // Ensure valid region to prevent CAMetalLayer errors
        let validRegion = createValidRegion()
        mapView.setRegion(validRegion, animated: false)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region if needed
        if !regionsAreEqual(mapView.region, region) {
            mapView.setRegion(region, animated: true)
        }
        
        // Update routes
        updateRoutes(on: mapView)
        
        // Update knooppunten
        if showKnooppunten {
            updateKnooppunten(on: mapView)
        }
        
        // Update cycling POIs
        if showCyclingPOIs {
            updateCyclingPOIs(on: mapView)
        }
        
        // Update pending locations
        updatePendingLocations(on: mapView)
        
        // Apply settings
        applyEnhancedSettings(to: mapView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Private Methods
    
    private func applyEnhancedSettings(to mapView: MKMapView) {
        // Enhanced cycling-optimized settings
        mapView.mapType = .standard
        
        // Show cycling-relevant features
        mapView.showsTraffic = false // Disable traffic for cycling routes
        mapView.showsBuildings = true
        // Use modern pointOfInterestFilter instead of deprecated showsPointsOfInterest
        if #available(iOS 13.0, *) {
            mapView.pointOfInterestFilter = .includingAll
        } else {
            mapView.showsPointsOfInterest = true
        }
        mapView.showsCompass = true
        mapView.showsScale = true
        
        // Cycling-specific map styling
        if #available(iOS 13.0, *) {
            mapView.preferredConfiguration = MKStandardMapConfiguration()
        }
        
        // Enable user interaction
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = false // Disable 3D for cycling
    }
    
    private func createValidRegion() -> MKCoordinateRegion {
        let center = region.center
        let span = region.span
        
        // Ensure valid coordinates
        let validLatitude = max(-90, min(90, center.latitude))
        let validLongitude = max(-180, min(180, center.longitude))
        
        let validSpanLat = max(0.001, min(180, span.latitudeDelta))
        let validSpanLon = max(0.001, min(360, span.longitudeDelta))
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: validLatitude, longitude: validLongitude),
            span: MKCoordinateSpan(latitudeDelta: validSpanLat, longitudeDelta: validSpanLon)
        )
    }
    
    private func regionsAreEqual(_ region1: MKCoordinateRegion, _ region2: MKCoordinateRegion) -> Bool {
        let tolerance = 0.0001
        return abs(region1.center.latitude - region2.center.latitude) < tolerance &&
               abs(region1.center.longitude - region2.center.longitude) < tolerance &&
               abs(region1.span.latitudeDelta - region2.span.latitudeDelta) < tolerance &&
               abs(region1.span.longitudeDelta - region2.span.longitudeDelta) < tolerance
    }
    
    private func updateRoutes(on mapView: MKMapView) {
        // Remove existing route overlays
        let existingOverlays = mapView.overlays.filter { $0 is MKPolyline }
        mapView.removeOverlays(existingOverlays)
        
        // Add new routes
        for route in routes {
            let polyline = MKPolyline(coordinates: route.polyline, count: route.polyline.count)
            polyline.title = "Route"
            mapView.addOverlay(polyline)
        }
        
        // Highlight selected route
        if let selectedRoute = selectedRoute {
            let selectedPolyline = MKPolyline(coordinates: selectedRoute.polyline, count: selectedRoute.polyline.count)
            selectedPolyline.title = "SelectedRoute"
            mapView.addOverlay(selectedPolyline)
        }
    }
    
    private func updateKnooppunten(on mapView: MKMapView) {
        // Remove existing knooppunt annotations
        let existingKnooppunten = mapView.annotations.filter { $0 is FietsknooppuntAnnotation }
        mapView.removeAnnotations(existingKnooppunten)
        
        // Add new knooppunten
        for knooppunt in knooppunten {
            let annotation = FietsknooppuntAnnotation(knooppunt: knooppunt)
            mapView.addAnnotation(annotation)
        }
    }
    
    private func updateCyclingPOIs(on mapView: MKMapView) {
        // Remove existing POI annotations
        let existingPOIs = mapView.annotations.filter { $0 is CyclingPOIAnnotation }
        mapView.removeAnnotations(existingPOIs)
        
        // Add new cycling POIs
        for poi in cyclingPOIs {
            let annotation = CyclingPOIAnnotation(poi: poi)
            mapView.addAnnotation(annotation)
        }
    }
    
    private func updatePendingLocations(on mapView: MKMapView) {
        // Remove existing pending location annotations
        let existingPending = mapView.annotations.filter { $0 is PendingLocationAnnotation }
        mapView.removeAnnotations(existingPending)
        
        // Add start location
        if let startLocation = pendingStartLocation {
            let startAnnotation = PendingLocationAnnotation(
                coordinate: startLocation,
                type: .start,
                title: "Start Locatie"
            )
            mapView.addAnnotation(startAnnotation)
        }
        
        // Add end location
        if let endLocation = pendingEndLocation {
            let endAnnotation = PendingLocationAnnotation(
                coordinate: endLocation,
                type: .end,
                title: "Eind Locatie"
            )
            mapView.addAnnotation(endAnnotation)
        }
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: EnhancedMapView
        
        init(_ parent: EnhancedMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
                
                // Load knooppunten for new region
                Task {
                    await self.parent.fietsknooppuntenService.loadKnooppunten(in: mapView.region)
                }
                
                // Load cycling POIs for new region
                Task {
                    await self.parent.mapLibreService.loadCyclingPOIs(
                        near: mapView.region.center,
                        radius: max(mapView.region.span.latitudeDelta, mapView.region.span.longitudeDelta) * 111000
                    )
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                
                if polyline.title == "SelectedRoute" {
                    renderer.strokeColor = .systemBlue
                    renderer.lineWidth = 6
                    renderer.lineDashPattern = [10, 5]
                } else {
                    renderer.strokeColor = .systemGreen
                    renderer.lineWidth = 4
                }
                
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let knooppuntAnnotation = annotation as? FietsknooppuntAnnotation {
                return createKnooppuntView(for: knooppuntAnnotation, on: mapView)
            } else if let poiAnnotation = annotation as? CyclingPOIAnnotation {
                return createPOIView(for: poiAnnotation, on: mapView)
            } else if let pendingAnnotation = annotation as? PendingLocationAnnotation {
                return createPendingLocationView(for: pendingAnnotation, on: mapView)
            }
            
            return nil
        }
        
        private func createKnooppuntView(for annotation: FietsknooppuntAnnotation, on mapView: MKMapView) -> MKAnnotationView {
            let identifier = "FietsknooppuntAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Create custom view for knooppunt
            _ = annotation.knooppunt
            let view = UIView()
            view.backgroundColor = .blue
            view.layer.cornerRadius = 15
            view.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            
            annotationView?.addSubview(view)
            annotationView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            
            return annotationView!
        }
        
        private func createPOIView(for annotation: CyclingPOIAnnotation, on mapView: MKMapView) -> MKAnnotationView {
            let identifier = "CyclingPOIAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Create custom view for POI
            _ = annotation.poi
            let view = UIView()
            view.backgroundColor = .green
            view.layer.cornerRadius = 10
            view.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            
            annotationView?.addSubview(view)
            annotationView?.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
            
            return annotationView!
        }
        
        private func createPendingLocationView(for annotation: PendingLocationAnnotation, on mapView: MKMapView) -> MKAnnotationView {
            let identifier = "PendingLocationAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Create custom view for pending location
            let view = UIView()
            view.backgroundColor = annotation.type == .start ? .green : .red
            view.layer.cornerRadius = 15
            view.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            
            annotationView?.addSubview(view)
            annotationView?.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            
            return annotationView!
        }
    }
}

// MARK: - Custom Annotations

class FietsknooppuntAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let knooppunt: Fietsknooppunt
    
    init(knooppunt: Fietsknooppunt) {
        self.knooppunt = knooppunt
        self.coordinate = knooppunt.coordinate
        self.title = knooppunt.displayName
        self.subtitle = knooppunt.network.displayName
        super.init()
    }
}

class CyclingPOIAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let poi: CyclingPOI
    
    init(poi: CyclingPOI) {
        self.poi = poi
        self.coordinate = poi.coordinate
        self.title = poi.name
        self.subtitle = poi.type.displayName
        super.init()
    }
}

class PendingLocationAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let type: PendingLocationType
    
    enum PendingLocationType {
        case start
        case end
        
        var color: UIColor {
            switch self {
            case .start: return .systemGreen
            case .end: return .systemRed
            }
        }
    }
    
    init(coordinate: CLLocationCoordinate2D, type: PendingLocationType, title: String) {
        self.coordinate = coordinate
        self.type = type
        self.title = title
        self.subtitle = nil
        super.init()
    }
}

// MARK: - Custom Annotation Views

struct KnooppuntAnnotationView: UIViewRepresentable {
    let knooppunt: Fietsknooppunt
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(knooppunt.network.color)
        view.layer.cornerRadius = 15
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.white.cgColor
        
        let label = UILabel()
        label.text = knooppunt.number
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 12)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
}

struct CyclingPOIAnnotationView: UIViewRepresentable {
    let poi: CyclingPOI
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(poi.type.color)
        view.layer.cornerRadius = 12.5
        
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: poi.type.icon)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 15),
            imageView.heightAnchor.constraint(equalToConstant: 15)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
}

struct PendingLocationAnnotationView: UIViewRepresentable {
    let type: PendingLocationAnnotation.PendingLocationType
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = type.color
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.white.cgColor
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
}
