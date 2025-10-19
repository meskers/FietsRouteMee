//
//  MapView.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var routes: [BikeRoute]
    @Binding var selectedRoute: BikeRoute?
    var pendingStartLocation: CLLocationCoordinate2D? = nil
    var pendingEndLocation: CLLocationCoordinate2D? = nil
    @ObservedObject private var settingsManager = AppSettingsManager.shared
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
        // Set a minimum frame to prevent CAMetalLayer errors
        mapView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        // Apply settings
        applySettings(to: mapView)
        
        // Ensure valid region to prevent CAMetalLayer errors
        let validRegion = createValidRegion()
        
        // Set region immediately to prevent CAMetalLayer warnings
        mapView.setRegion(validRegion, animated: false)
        
        return mapView
    }
    
    private func createValidRegion() -> MKCoordinateRegion {
        // Validate and create a safe region
        let center: CLLocationCoordinate2D
        let span: MKCoordinateSpan
        
        if region.center.latitude.isFinite && region.center.longitude.isFinite &&
           region.center.latitude >= -90 && region.center.latitude <= 90 &&
           region.center.longitude >= -180 && region.center.longitude <= 180 {
            center = region.center
        } else {
            // Default to Amsterdam
            center = CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)
        }
        
        if region.span.latitudeDelta > 0 && region.span.latitudeDelta <= 180 &&
           region.span.longitudeDelta > 0 && region.span.longitudeDelta <= 360 {
            span = region.span
        } else {
            // Default span
            span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        }
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Apply settings changes
        applySettings(to: mapView)
        
        // Update region only if valid and different from current
        let validRegion = createValidRegion()
        let currentRegion = mapView.region
        
        // Check if region has changed significantly
        let centerDistance = validRegion.center.distanceTo(currentRegion.center)
        let spanChanged = abs(validRegion.span.latitudeDelta - currentRegion.span.latitudeDelta) > 0.001 ||
                         abs(validRegion.span.longitudeDelta - currentRegion.span.longitudeDelta) > 0.001
        
        if centerDistance > 100 || spanChanged {
            mapView.setRegion(validRegion, animated: true)
        }
        
        // Update routes
        updateRoutes(mapView: mapView)
    }
    
    private func applySettings(to mapView: MKMapView) {
        mapView.mapType = settingsManager.mapType.mapKitType
        mapView.showsTraffic = settingsManager.showsTraffic
        mapView.showsBuildings = settingsManager.showsBuildings
        mapView.showsCompass = settingsManager.showsCompass
        mapView.showsScale = settingsManager.showsScale
    }
    
    private func updateRoutes(mapView: MKMapView) {
        // Remove existing overlays and annotations (except user location)
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        // Add pending location annotations FIRST (so they're visible even without a route)
        if let startLoc = pendingStartLocation {
            let startAnnotation = RouteAnnotation(
                coordinate: startLoc,
                title: "Startlocatie",
                subtitle: "Huidige selectie",
                type: .start
            )
            mapView.addAnnotation(startAnnotation)
            print("📍 MapView: Added pending START annotation at \(startLoc)")
        }
        
        if let endLoc = pendingEndLocation {
            let endAnnotation = RouteAnnotation(
                coordinate: endLoc,
                title: "Bestemming",
                subtitle: "Huidige selectie",
                type: .end
            )
            mapView.addAnnotation(endAnnotation)
            print("📍 MapView: Added pending END annotation at \(endLoc)")
        }
        
        // Now add routes if available
        guard !routes.isEmpty else {
            return
        }
        
        // Add route overlays
        for route in routes {
            // Only add polyline if coordinates are valid
            let validCoordinates = route.polyline.filter { coord in
                coord.latitude.isFinite && coord.longitude.isFinite &&
                coord.latitude >= -90 && coord.latitude <= 90 &&
                coord.longitude >= -180 && coord.longitude <= 180
            }
            
            if !validCoordinates.isEmpty {
                let polyline = MKPolyline(coordinates: validCoordinates, count: validCoordinates.count)
                polyline.title = route.id.uuidString
                mapView.addOverlay(polyline)
            }
            
            // Add start and end annotations
            let startAnnotation = RouteAnnotation(
                coordinate: route.startLocation,
                title: "Start",
                subtitle: nil,
                type: .start
            )
            let endAnnotation = RouteAnnotation(
                coordinate: route.endLocation,
                title: "Bestemming",
                subtitle: route.formattedDistance,
                type: .end
            )
            
            mapView.addAnnotation(startAnnotation)
            mapView.addAnnotation(endAnnotation)
        }
        
        // Zoom to fit all routes
        if !routes.isEmpty {
            var minLat = 90.0
            var maxLat = -90.0
            var minLon = 180.0
            var maxLon = -180.0
            
            for route in routes {
                for coord in route.polyline {
                    minLat = min(minLat, coord.latitude)
                    maxLat = max(maxLat, coord.latitude)
                    minLon = min(minLon, coord.longitude)
                    maxLon = max(maxLon, coord.longitude)
                }
            }
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            let span = MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.3, 0.01), // Minimum span
                longitudeDelta: max((maxLon - minLon) * 1.3, 0.01) // Minimum span
            )
            
            let region = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 4
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let routeAnnotation = annotation as? RouteAnnotation else { return nil }
            
            let identifier = "RouteAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false // Disable callout to prevent context menu issues
                annotationView?.isEnabled = true
                annotationView?.isUserInteractionEnabled = false // Disable interaction to prevent context menu
            } else {
                annotationView?.annotation = annotation
            }
            
            // Configure appearance based on type
            switch routeAnnotation.type {
            case .start:
                annotationView?.image = UIImage(systemName: "bicycle.circle.fill")
                annotationView?.tintColor = .systemGreen
            case .end:
                annotationView?.image = UIImage(systemName: "flag.circle.fill")
                annotationView?.tintColor = .systemRed
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            // Handle annotation selection if needed
        }
    }
}

// MARK: - Navigation Map View
struct NavigationMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var routes: [BikeRoute]
    @Binding var selectedRoute: BikeRoute?
    @ObservedObject private var settingsManager = AppSettingsManager.shared
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading // Follow user with heading for navigation
        
        // Set a minimum frame to prevent CAMetalLayer errors
        mapView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        // Apply settings
        applySettings(to: mapView)
        
        // Set stable region for navigation
        let stableRegion = createStableRegion()
        mapView.setRegion(stableRegion, animated: false)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Apply settings changes
        applySettings(to: mapView)
        
        // Update region more conservatively for navigation
        let stableRegion = createStableRegion()
        let currentRegion = mapView.region
        
        // Only update if region has changed significantly (larger threshold for navigation)
        let centerDistance = stableRegion.center.distanceTo(currentRegion.center)
        let spanChanged = abs(stableRegion.span.latitudeDelta - currentRegion.span.latitudeDelta) > 0.01 ||
                         abs(stableRegion.span.longitudeDelta - currentRegion.span.longitudeDelta) > 0.01
        
        if centerDistance > 500 || spanChanged { // Larger threshold for navigation
            mapView.setRegion(stableRegion, animated: true)
        }
        
        // Update routes
        updateRoutes(mapView: mapView)
    }
    
    private func createStableRegion() -> MKCoordinateRegion {
        // Create a more stable region for navigation
        let center: CLLocationCoordinate2D
        let span: MKCoordinateSpan
        
        if region.center.latitude.isFinite && region.center.longitude.isFinite &&
           region.center.latitude >= -90 && region.center.latitude <= 90 &&
           region.center.longitude >= -180 && region.center.longitude <= 180 {
            center = region.center
        } else {
            // Default to Amsterdam
            center = CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)
        }
        
        // Use larger, more stable span for navigation
        if region.span.latitudeDelta > 0 && region.span.latitudeDelta <= 180 &&
           region.span.longitudeDelta > 0 && region.span.longitudeDelta <= 360 {
            span = MKCoordinateSpan(
                latitudeDelta: max(region.span.latitudeDelta, 0.01),
                longitudeDelta: max(region.span.longitudeDelta, 0.01)
            )
        } else {
            // Default span for navigation
            span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        }
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    private func applySettings(to mapView: MKMapView) {
        mapView.mapType = settingsManager.mapType.mapKitType
        mapView.showsTraffic = settingsManager.showsTraffic
        mapView.showsBuildings = settingsManager.showsBuildings
        mapView.showsCompass = settingsManager.showsCompass
        mapView.showsScale = settingsManager.showsScale
    }
    
    private func updateRoutes(mapView: MKMapView) {
        // Only update if routes have actually changed
        guard !routes.isEmpty else {
            // Clear existing routes if no routes
            if !mapView.overlays.isEmpty || !mapView.annotations.isEmpty {
                mapView.removeOverlays(mapView.overlays)
                mapView.removeAnnotations(mapView.annotations)
            }
            return
        }
        
        // Remove existing overlays
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        // Add route overlays
        for route in routes {
            // Only add polyline if coordinates are valid
            let validCoordinates = route.polyline.filter { coord in
                coord.latitude.isFinite && coord.longitude.isFinite &&
                coord.latitude >= -90 && coord.latitude <= 90 &&
                coord.longitude >= -180 && coord.longitude <= 180
            }
            
            if !validCoordinates.isEmpty {
                let polyline = MKPolyline(coordinates: validCoordinates, count: validCoordinates.count)
                polyline.title = route.id.uuidString
                mapView.addOverlay(polyline)
            }
            
            // Add start and end annotations
            let startAnnotation = RouteAnnotation(
                coordinate: route.startLocation,
                title: "Start",
                subtitle: nil,
                type: .start
            )
            let endAnnotation = RouteAnnotation(
                coordinate: route.endLocation,
                title: "Bestemming",
                subtitle: route.formattedDistance,
                type: .end
            )
            
            mapView.addAnnotation(startAnnotation)
            mapView.addAnnotation(endAnnotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: NavigationMapView
        
        init(_ parent: NavigationMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 4
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let routeAnnotation = annotation as? RouteAnnotation else { return nil }
            
            let identifier = "RouteAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
                annotationView?.isEnabled = true
                annotationView?.isUserInteractionEnabled = false
            } else {
                annotationView?.annotation = annotation
            }
            
            // Configure appearance based on type
            switch routeAnnotation.type {
            case .start:
                annotationView?.image = UIImage(systemName: "bicycle.circle.fill")
                annotationView?.tintColor = .systemGreen
            case .end:
                annotationView?.image = UIImage(systemName: "flag.circle.fill")
                annotationView?.tintColor = .systemRed
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            // Handle annotation selection if needed
        }
    }
}

// MARK: - Route Annotation
class RouteAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let type: AnnotationType
    
    enum AnnotationType {
        case start
        case end
    }
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, type: AnnotationType) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.type = type
    }
}
