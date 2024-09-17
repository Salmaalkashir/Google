//
//  HomeViewController.swift
//  Google
//
//  Created by Salma on 14/09/2024.
//

import UIKit
import GoogleMaps
import CoreLocation
import GooglePlaces


class HomeViewController: UIViewController {
    @IBOutlet private weak var mapView: GMSMapView!
    @IBOutlet private weak var searchButton: UIButton!
    @IBOutlet private weak var locationView: UIView!
    @IBOutlet private var myLocationLabel: UILabel!
    var locationManager = CLLocationManager()
    private var userLocationMarker: GMSMarker?
    let geoCoder = CLGeocoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationView.layer.cornerRadius = 20
        
        // Setup location manager
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Enable "My Location" button and set the delegate
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        mapView.delegate = self  // Set the mapView's delegate
        searchButton.titleLabel?.textAlignment = .left
       
        let initialPosition = CLLocationCoordinate2D(latitude: 31.2221154, longitude: 29.9449498)
        let location = CLLocation(latitude: initialPosition.latitude, longitude: initialPosition.longitude)
       
        geoCoder.reverseGeocodeLocation(location) { places, error in
          guard let place = places?.first , error == nil else{return}
        print("location:\("\(place.name ?? "no name"),\(place.subLocality ?? "no subloc") ,\(place.administrativeArea ?? "no admin")")")
          self.myLocationLabel.text = "\(place.name ?? "no name"),\(place.subLocality ?? "no subloc") ,\(place.administrativeArea ?? "no admin")"
        }
        let zoom = GMSCameraPosition.camera(withLatitude: initialPosition.latitude, longitude: initialPosition.longitude, zoom: 6.0)
        mapView.camera = zoom
        mapView.addSubview(locationView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        repositionMyLocationButton()
    }
    
    func showMarker(position: CLLocationCoordinate2D, title: String, snippet: String) -> GMSMarker {
        let marker = GMSMarker()
        marker.position = position
        marker.title = title
        marker.snippet = snippet
        marker.map = mapView
        return marker
    }
    
    func repositionMyLocationButton() {
        // Iterate through the subviews of the mapView to find the "My Location" button
        for view in mapView.subviews {
            // Find the button by class name (it is of type UIButton)
            if let button = view as? UIButton {
                // Set a new frame for the button to change its position (x and y coordinates)
                // Example: move the button to (x: 20, y: 50)
                button.frame = CGRect(x: 100, y: 90, width: button.frame.width, height: button.frame.height)
            }
        }
    }
}

private extension HomeViewController {
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt64(UInt(GMSPlaceField.name.rawValue) |
                                                                   UInt(GMSPlaceField.placeID.rawValue)))
        autocompleteController.placeFields = fields
        let filter = GMSAutocompleteFilter()
        filter.type = .address
        autocompleteController.autocompleteFilter = filter
        present(autocompleteController, animated: true, completion: nil)
    }
}

extension HomeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            print("No location found")
            return
        }
        
        // Remove old user location marker if any
        userLocationMarker?.map = nil
        
        // Add a marker at the user's current location
        userLocationMarker = showMarker(position: location.coordinate, title: "Your Location", snippet: "You are here")
        let zoom = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 15.0)
        mapView.animate(to: zoom)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location access authorized")
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            print("Location access not determined")
        default:
            print("Unexpected authorization status")
        }
    }
}
extension HomeViewController: GMSMapViewDelegate {
    // Handle the "My Location" button tap
    func mapView(_ mapView: GMSMapView, didTapMyLocationButtonFor locationView: UIView) -> Bool {
        if let userLocation = mapView.myLocation?.coordinate {
            // Zoom in to the user's current location

            let zoom = GMSCameraPosition.camera(withTarget: userLocation, zoom: 15.0)
            mapView.animate(to: zoom)
        }
        return true // Return true to indicate that you've handled the event
    }
}

extension HomeViewController: GMSAutocompleteViewControllerDelegate {

    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        myLocationLabel.text = place.name ?? ""
        print("Place name: \(place.name ?? "No name")")
        print("Place ID: \(place.placeID ?? "No place ID")")
        print("Place coordinate: \(place.coordinate.latitude), \(place.coordinate.longitude)")
        
        // Dismiss the autocomplete view controller.
        dismiss(animated: true, completion: nil)
        
        // Clear existing markers on the map (optional)
        mapView.clear()
        
        // Add a marker at the selected place's location
        let marker = GMSMarker()
        marker.position = place.coordinate
        marker.title = place.name
        marker.map = mapView
        
        // Zoom in on the selected location
        let zoomLevel: Float = 15.0 // You can adjust this zoom level if needed
        let camera = GMSCameraPosition.camera(withTarget: place.coordinate, zoom: zoomLevel)
        mapView.animate(to: camera)
    }

    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
    }

    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }

    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
