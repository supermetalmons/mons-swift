// ∅ 2024 super-metal-mons

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    private let radius: Double = 2300
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.cancel, style: .plain, target: self, action: #selector(dismissAnimated))
        setupMapView()
    }
    
    private func setupMapView() {
        mapView.delegate = self
        let centerCoordinate = CLLocationCoordinate2D(latitude: 39.78196866145232, longitude: -104.97050021587202)
        let region = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: radius * 6.9, longitudinalMeters: radius * 6.9)
        mapView.setRegion(region, animated: true)
        let circle = MKCircle(center: centerCoordinate, radius: radius)
        mapView.addOverlay(circle)
    }
    
    
    @IBAction func actionButtonTapped(_ sender: Any) {
        actionButton.configuration?.title = nil
        actionButton.configuration?.showsActivityIndicator = true
        actionButton.isUserInteractionEnabled = false
        claim()
    }
    
    private func claim() {
#if !targetEnvironment(macCatalyst)
        Firebase.claim { [weak self] result in
            if let code = result, let url = URL(string: "https://claim.linkdrop.io/#/redeem/\(code)?src=d") {
                UIApplication.shared.open(url)
                self?.dismissAnimated()
            } else {
                // TODO: show error
            }
        }
#endif
    }
    
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
