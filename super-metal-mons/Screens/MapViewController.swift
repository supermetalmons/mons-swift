// ∅ 2024 super-metal-mons

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    private let radius: Double = 2300
    private let centerCoordinate = CLLocationCoordinate2D(latitude: 39.78196866145232, longitude: -104.97050021587202)
    private var locationManager: CLLocationManager?
    private var locationStatus: CLAuthorizationStatus?
    
    private var isOkLocation = false
    private var claimInProgress = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.cancel, style: .plain, target: self, action: #selector(dismissAnimated))
        setupMapView()
        // TODO: stop updating location when app is not active, when screen closes, when there is no need anymore
    }
    
    private func setupMapView() {
        mapView.delegate = self
        let region = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: radius * 6.9, longitudinalMeters: radius * 6.9)
        mapView.setRegion(region, animated: true)
        let circle = MKCircle(center: centerCoordinate, radius: radius)
        mapView.addOverlay(circle)
    }
    
    @IBAction func actionButtonTapped(_ sender: Any) {
        if isOkLocation && mapView.showsUserLocation {
            actionButton.configuration?.title = nil
            actionButton.configuration?.showsActivityIndicator = true
            actionButton.isUserInteractionEnabled = false
            claim()
        } else {
            showCurrentLocation()
        }
    }
    
    private func showCurrentLocation() {
        if locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways {
            locationManager?.startUpdatingLocation()
        } else {
            locationManager?.requestWhenInUseAuthorization()
        }
        mapView.showsUserLocation = true
    }
    
    private func claim() {
#if !targetEnvironment(macCatalyst)
        guard !claimInProgress else { return }
        claimInProgress = true
        Firebase.claim { [weak self] result in
            self?.claimInProgress = false
            if let code = result, let url = URL(string: "https://claim.linkdrop.io/#/redeem/\(code)?src=d") {
                UIApplication.shared.open(url)
                self?.dismissAnimated()
            } else {
                // TODO: retry
                // TODO: show error
                // TODO: update button depending on isOkLocation
            }
        }
#endif
    }
    
    private func handleOkLocation() {
        isOkLocation = true
        if !claimInProgress {
            actionButton.configuration?.title = Strings.claim
            statusLabel.text = Strings.thereIsSomethingThere
        }
    }
    
    private func handleFarAwayLocation() {
        isOkLocation = false
        if !claimInProgress {
            actionButton.configuration?.title = Strings.search
            statusLabel.text = Strings.lookWithinTheCircle
        }
    }
    
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let userLocation = location.coordinate
            let center = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
            let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
            let distance = userCLLocation.distance(from: center)
            if distance <= radius {
                handleOkLocation()
            } else {
                handleFarAwayLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.locationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager?.startUpdatingLocation()
        } else if status == .restricted || status == .denied {
            statusLabel.text = Strings.allowLocationAccess
        } else if status == .notDetermined {
            statusLabel.text = Strings.monsRocksGems
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
    
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circleOverlay = overlay as? MKCircle {
            let circleRenderer = MKCircleRenderer(circle: circleOverlay)
            circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.1)
            circleRenderer.strokeColor = UIColor.blue
            circleRenderer.lineWidth = 1
            return circleRenderer
        }
        return MKOverlayRenderer()
    }
    
}
