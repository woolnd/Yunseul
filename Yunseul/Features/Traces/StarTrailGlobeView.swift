//
//  StarTrailGlobeView.swift
//  Yunseul
//
//  Created by wodnd on 4/13/26.
//

import SwiftUI
import MapKit

struct StarTrailGlobeView: UIViewRepresentable {
    
    let trailEntries: [StarTrailEntry]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.mapType = .hybridFlyover
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = true
        mapView.showsUserLocation = false
        mapView.delegate = context.coordinator
        
        let camera = MKMapCamera()
        camera.centerCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        camera.altitude = 20_000_000
        camera.pitch = 0
        mapView.setCamera(camera, animated: false)
        
        mapView.cameraZoomRange = MKMapView.CameraZoomRange(
            minCenterCoordinateDistance: 10_000_000,
            maxCenterCoordinateDistance: 30_000_000
        )
        
        if #available(iOS 16.0, *) {
            mapView.preferredConfiguration = MKHybridMapConfiguration()
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        guard !trailEntries.isEmpty else { return }
        
        let sorted = trailEntries.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
        let coordinates = sorted.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        
        if let first = coordinates.first {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = first
            startAnnotation.title = "start"
            mapView.addAnnotation(startAnnotation)
        }
        if let last = coordinates.last {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = last
            endAnnotation.title = "end"
            mapView.addAnnotation(endAnnotation)
        }
        
        let lats = coordinates.map { $0.latitude }
        let lons = coordinates.map { $0.longitude }
        let minLat = lats.min() ?? 0
        let maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0
        let maxLon = lons.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 30),
            longitudeDelta: max((maxLon - minLon) * 1.5, 30)
        )
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let point = annotation as? MKPointAnnotation else { return nil }
            
            let isEnd = point.title == "end"
            
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: point.title)
            view.canShowCallout = false
            
            let size: CGFloat = isEnd ? 10 : 6
            let circle = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
            circle.backgroundColor = UIColor(Color.Yunseul.starBlue).withAlphaComponent(isEnd ? 1.0 : 0.5)
            circle.layer.cornerRadius = size / 2
            view.addSubview(circle)
            view.frame = circle.frame
            
            return view
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(Color.Yunseul.starBlue).withAlphaComponent(0.7)
                renderer.lineWidth = 2
                renderer.lineDashPattern = [6, 4]
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
