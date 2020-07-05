//
//  ViewController.swift
//  MapSample
//
//  Created by Kap's on 18/06/20.
//  Copyright © 2020 Kapil. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    
    let locationManager =  CLLocationManager()
    var previousLocation : CLLocation?
    
    var directionsArray : [MKDirections] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        checkLocationServices()
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorizations()
        } else {
            let alertTitle = "Hey!"
            let alertMessage = "You have not enabled location services for the device. Please enable and try again."
            
            let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    func setupLocationManager() {
        print("Location Manger was setup successfully")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
        
    func checkLocationAuthorizations() {
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            trackUserLocation()
        case .denied:
            //show an alert to enable for the app
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            //show an alert what to do
            break
        case .authorizedAlways:
            break
            
        @unknown default:
        fatalError()
        }
    }
    
    func trackUserLocation() {
        mapView.showsUserLocation = true
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapView)
        centerViewOnUserLocation()
    }
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let longitute = mapView.centerCoordinate.longitude
        let latitute = mapView.centerCoordinate.latitude
        
        return CLLocation(latitude: longitute, longitude: latitute)
    }
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: 10000, longitudinalMeters: 10000)
            mapView.setRegion(region, animated: true)
        }
    }
    
    @IBAction func goButtonTapped(_ sender: Any) {
        getDirections()
    }
    
    func resetMapView(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map{ $0.cancel() }
    }
    
    func getDirections() {
        guard let location = locationManager.location?.coordinate else {
            return
        }
        
        let request = createDirectionRequest(from: location)
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions)
        
        directions.calculate { [unowned self] (response, error) in
            
            guard let response = response else { return }
            
            for route in response.routes {
                let steps = route.steps
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func createDirectionRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        
        let startingLocation      = MKPlacemark(coordinate: coordinate)
        let distinationCoordinate = getCenterLocation(for: mapView).coordinate
        let destinationLocation   = MKPlacemark(coordinate: distinationCoordinate)
        
        let request               = MKDirections.Request()
        request.source            = MKMapItem(placemark: startingLocation)
        request.destination       = MKMapItem(placemark: destinationLocation)
        request.transportType     = .automobile
        request.requestsAlternateRoutes = true
        
        return request
    }
}

extension MapViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapView)
        let geoCoder = CLGeocoder()
        
        guard let previousLocation = self.previousLocation else { return }
        
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        
        geoCoder.cancelGeocode()
        
        geoCoder.reverseGeocodeLocation(center) { [weak self] (palcemarks,error) in
            guard let self = self else { return }
            
            if let _ = error {
                
                let alertTitle = "Alert"
                let alertMessage = "Some error happened"
                
                let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                
                return
            }
            
            guard let placemark = palcemarks?.first else {
                return
            }
            
            let locality = placemark.country ?? ""
            let subLocality = placemark.postalCode ?? ""
            
            DispatchQueue.main.async {
                self.addressLabel.text = "\(locality),\(subLocality)"
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        
        return renderer
    }
}

extension MapViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("The location manager error is \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorizations()
    }
    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.last else { return }
//        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
//        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: 10000, longitudinalMeters: 10000)
//        mapView.setRegion(region, animated: true)
//    }
}


