// ∅ 2024 super-metal-mons

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    // TODO: get from remote config
    private let radius: Double = 2300
    private let centerCoordinate = CLLocationCoordinate2D(latitude: 39.78196866145232, longitude: -104.97050021587202)
    private var locationManager: CLLocationManager?
    private var locationStatus: CLAuthorizationStatus?
    
    private var isOkLocation = false
    private var claimInProgress = false
    
    // TODO: get current code from remote config
    private let initialCode = Keychain.shared.denverCode
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.cancel, style: .plain, target: self, action: #selector(dismissAnimated))
        getCurrentDrop()
        setupMapView()
        if initialCode == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
            actionButton.configuration?.title = Strings.search
        } else {
            statusLabel.text = Strings.youGotTheRock
            actionButton.configuration?.title = Strings.show
        }
    }
    
    private func getCurrentDrop() {
        Firebase.getCurrentDrop { [weak self] currentDrop in
            if let drop = currentDrop {
                self?.setupWithCurrentDrop(drop)
            } else {
                self?.failedToGetCurrentDrop()
            }
        }
    }
    
    private func failedToGetCurrentDrop() {
        // TODO: should be able to retry
        print("meh")
    }
    
    private func setupWithCurrentDrop(_ currentDrop: CurrentDrop) {
        // TODO: setup
        print(currentDrop.id)
    }
    
    private func setupMapView() {
        mapView.delegate = self
        let region = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: radius * 6.9, longitudinalMeters: radius * 6.9)
        mapView.setRegion(region, animated: true)
        let circle = MKCircle(center: centerCoordinate, radius: radius)
        mapView.addOverlay(circle)
    }
    
    @IBAction func actionButtonTapped(_ sender: Any) {
        if let code = initialCode {
            openLinkdrop(code: code)
        } else if isOkLocation && mapView.showsUserLocation {
            startClaiming()
        } else {
            showCurrentLocation()
        }
    }
    
    private func openLinkdrop(code: String) {
        guard let url = URL(string: "https://claim.linkdrop.io/#/redeem/\(code)?src=d") else { return }
        UIApplication.shared.open(url)
        dismiss(animated: false)
    }
    
    private func startClaiming() {
        actionButton.configuration?.title = nil
        actionButton.configuration?.showsActivityIndicator = true
        actionButton.isUserInteractionEnabled = false
        claim()
    }
    
    @IBAction func fcButtonTapped(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://warpcast.com/mons")!)
    }
    
    @IBAction func xButtonTapped(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://twitter.com/supermetalx")!)
    }
    
    @IBAction func githubButtonTapped(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://github.com/supermetalmons/mons-swift")!)
    }
    
    private func showCurrentLocation() {
        if locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways {
            locationManager?.startUpdatingLocation()
        } else {
            locationManager?.requestWhenInUseAuthorization()
        }
        mapView.showsUserLocation = true
    }
    
    private func claim(retryCount: Int = 0) {
#if !targetEnvironment(macCatalyst)
        guard !claimInProgress else { return }
        claimInProgress = true
        Firebase.claim { [weak self] result in
            self?.claimInProgress = false
            if let code = result {
                Keychain.shared.save(denverCode: code)
                self?.openLinkdrop(code: code)
            } else {
                if retryCount < 3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        self?.claim(retryCount: retryCount + 1)
                    }
                } else {
                    self?.updateActionButtonAfterUnsuccessfulClaim()
                    self?.showDidNotClaimAlert()
                }
            }
        }
#endif
    }
    
    private func showDidNotClaimAlert() {
        let alert = UIAlertController(title: Strings.couldNotClaim, message: Strings.itMightBeOver, preferredStyle: .alert)
        let retryAction = UIAlertAction(title: Strings.retry, style: .default) { [weak self] _ in
            self?.startClaiming()
        }
        let okAction = UIAlertAction(title: Strings.ok, style: .cancel)
        alert.addAction(okAction)
        alert.addAction(retryAction)
        present(alert, animated: true)
    }
    
    private func updateActionButtonAfterUnsuccessfulClaim() {
        actionButton.configuration?.showsActivityIndicator = false
        actionButton.isUserInteractionEnabled = true
        if isOkLocation {
            handleOkLocation()
        } else {
            handleFarAwayLocation()
        }
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
    
    deinit {
        locationManager?.stopUpdatingLocation()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func appDidBecomeActive() {
        locationManager?.startUpdatingLocation()
    }
    
    @objc private func appWillResignActive() {
        locationManager?.stopUpdatingLocation()
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
