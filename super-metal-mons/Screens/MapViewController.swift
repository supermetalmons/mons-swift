// ∅ 2024 super-metal-mons

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    private enum State {
        case lookingForRocks, failedToGetCurrentDrop, didNotClaimCurrentDrop, didClaimCurrentDrop
    }
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    private var locationManager: CLLocationManager?
    private var locationStatus: CLAuthorizationStatus?
    
    private var isOkLocation = false
    private var claimInProgress = false
    private var claimedCodeInKeychain: String?
    private var currentDrop: CurrentDrop?
    private var centerCoordinate: CLLocationCoordinate2D?
    private var radius: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.cancel, style: .plain, target: self, action: #selector(dismissAnimated))
        updateDisplayedState(.lookingForRocks)
        getCurrentDrop()
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
    
    private func updateDisplayedState(_ state: State) {
        switch state {
        case .lookingForRocks:
            actionButton.configuration?.showsActivityIndicator = true
            actionButton.isEnabled = false
            actionButton.configuration?.title = nil
            statusLabel.text = Strings.monsRocksGems
        case .failedToGetCurrentDrop, .didNotClaimCurrentDrop:
            actionButton.configuration?.showsActivityIndicator = false
            actionButton.isEnabled = true
            actionButton.configuration?.title = Strings.search
            statusLabel.text = Strings.monsRocksGems
        case .didClaimCurrentDrop:
            actionButton.configuration?.showsActivityIndicator = false
            actionButton.isEnabled = true
            statusLabel.text = Strings.youGotTheRock
            actionButton.configuration?.title = Strings.show
        }
    }
    
    private func failedToGetCurrentDrop() {
        updateDisplayedState(.failedToGetCurrentDrop)
    }
    
    private func setupWithCurrentDrop(_ currentDrop: CurrentDrop) {
        guard let radius = Double(currentDrop.radius),
              let latitude = Double(currentDrop.latitude),
              let longitude = Double(currentDrop.longitude) else {
            failedToGetCurrentDrop()
            return
        }
        
        self.currentDrop = currentDrop
        let claimedCodeInKeychain = Keychain.shared.getCode(dropId: currentDrop.id)
        let centerCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.radius = radius
        self.centerCoordinate = centerCoordinate
        
        setupMapView(centerCoordinate: centerCoordinate, radius: radius)

        if claimedCodeInKeychain == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
            updateDisplayedState(.didNotClaimCurrentDrop)
        } else {
            updateDisplayedState(.didClaimCurrentDrop)
        }
    }
    
    private func setupMapView(centerCoordinate: CLLocationCoordinate2D, radius: Double) {
        mapView.delegate = self
        let region = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: radius * 6.9, longitudinalMeters: radius * 6.9)
        mapView.setRegion(region, animated: true)
        let circle = MKCircle(center: centerCoordinate, radius: radius)
        mapView.addOverlay(circle)
    }
    
    @IBAction func actionButtonTapped(_ sender: Any) {
        // TODO: different when there is no current drop
        
        if let code = claimedCodeInKeychain {
            openLinkdrop(code: code)
        } else if let dropId = currentDrop?.id, isOkLocation && mapView.showsUserLocation {
            startClaiming(dropId: dropId)
        } else {
            showCurrentLocation()
        }
    }
    
    private func openLinkdrop(code: String) {
        guard let url = URL(string: "https://claim.linkdrop.io/#/redeem/\(code)?src=d") else { return }
        UIApplication.shared.open(url)
        dismiss(animated: false)
    }
    
    private func startClaiming(dropId: String) {
        actionButton.configuration?.title = nil // TODO: move to updateDisplayedState
        actionButton.configuration?.showsActivityIndicator = true
        actionButton.isUserInteractionEnabled = false
        claim(dropId: dropId)
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
    
    private func claim(dropId: String, retryCount: Int = 0) {
#if !targetEnvironment(macCatalyst)
        guard !claimInProgress else { return }
        claimInProgress = true
        Firebase.claim(dropId: dropId) { [weak self] result in
            self?.claimInProgress = false
            if let code = result {
                Keychain.shared.save(code: code, dropId: dropId)
                self?.openLinkdrop(code: code)
            } else {
                if retryCount < 3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        self?.claim(dropId: dropId, retryCount: retryCount + 1)
                    }
                } else {
                    self?.updateActionButtonAfterUnsuccessfulClaim()
                    self?.showDidNotClaimAlert(dropId: dropId)
                }
            }
        }
#endif
    }
    
    private func showDidNotClaimAlert(dropId: String) {
        let alert = UIAlertController(title: Strings.couldNotClaim, message: Strings.itMightBeOver, preferredStyle: .alert)
        let retryAction = UIAlertAction(title: Strings.retry, style: .default) { [weak self] _ in
            self?.startClaiming(dropId: dropId)
        }
        let okAction = UIAlertAction(title: Strings.ok, style: .cancel)
        alert.addAction(okAction)
        alert.addAction(retryAction)
        present(alert, animated: true)
    }
    
    private func updateActionButtonAfterUnsuccessfulClaim() {
        actionButton.configuration?.showsActivityIndicator = false // TODO: move to updateDisplayedState
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
            actionButton.configuration?.title = Strings.claim // TODO: move to updateDisplayedState
            statusLabel.text = Strings.thereIsSomethingThere
        }
    }
    
    private func handleFarAwayLocation() {
        isOkLocation = false
        if !claimInProgress {
            actionButton.configuration?.title = Strings.search // TODO: move to updateDisplayedState
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
        guard let location = locations.last, let radius = radius, let centerCoordinate = centerCoordinate else { return }
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
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.locationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager?.startUpdatingLocation()
        } else if status == .restricted || status == .denied {
            statusLabel.text = Strings.allowLocationAccess // TODO: move to updateDisplayedState
        } else if status == .notDetermined {
            statusLabel.text = Strings.monsRocksGems // TODO: move to updateDisplayedState
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
