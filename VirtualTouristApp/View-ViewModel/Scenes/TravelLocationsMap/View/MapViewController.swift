import UIKit
import MapKit
import AudioToolbox
import CoreLocation

class MapViewController: UIViewController {

    private lazy var viewModel: MapViewModelProtocol = MapViewModel(delegate: self)

    var pinsArray: [MKPointAnnotation] = []

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var trashImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupTapGestureRecognizer()
    }

    override func viewWillAppear(_ animated: Bool) {
        trashImageView.isHidden = true
        setupSavedZoomRegion()
    }

    func setupSavedZoomRegion() {
        let region = viewModel.setupRegion()
        mapView.setRegion(region, animated: true)
    }

    func centerViewInUserLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {

        
//        let locationManager = CLLocationManager()
//        let regionInMeters: Double = 10000
//
//        let userLocation = CLLocationCoordinate2D(latitude: UserAuthentication.Auth.latitude, longitude: UserAuthentication.Auth.longitude)
//        let region = MKCoordinateRegion.init(center: userLocation, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
//        mapView.setRegion(region, animated: true)
    }

    func setupTapGestureRecognizer() {
        let holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleHold))
        holdGesture.delegate = self
        holdGesture.minimumPressDuration = 0.25
        holdGesture.delaysTouchesBegan = true
        mapView.addGestureRecognizer(holdGesture)
    }

    @objc func handleHold(gestureRecognizer: UILongPressGestureRecognizer) {
        let locationInView = gestureRecognizer.location(in: view)
        let locationInMap = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(locationInMap,toCoordinateFrom: mapView)
        let pinSelected = mapView.selectedAnnotations

        switch gestureRecognizer.state {
        case .began where !pinSelected.isEmpty:
            trashImageView.isHidden = false
            trashImageView.isUserInteractionEnabled = true
        case .began:
            print("create a new pin")
            feedbackVibration(.light)
            createNewPin(coordinate: coordinate)
            mapView.addAnnotations(pinsArray)
        case .changed where isItemDraggedToTrash(locationInView):
            trashImageView.image = UIImage(named: "TrashOpenIcon")
        case .ended:
            if isItemDraggedToTrash(locationInView) {
                print("pinSelected \(pinSelected)")
                let newPinsArray = pinsArray.filter { $0.title != pinSelected.first?.title }
                mapView.removeAnnotations(pinSelected)
                feedbackVibration(.heavy)
                refreshMap(newPinsArray: newPinsArray)
            }
            trashImageView.isHidden = true
            trashImageView.image = UIImage(named: "TrashIcon")
        default:
            break
        }
    }

    func refreshMap(newPinsArray: [MKPointAnnotation] ) {
        pinsArray.removeAll()
        pinsArray = newPinsArray
        mapView.addAnnotations(pinsArray)
    }

    func isItemDraggedToTrash(_ locationInView: CGPoint) -> Bool {
        if trashImageView.frame.contains(locationInView) {
            return true
        }
        trashImageView.image = UIImage(named: "TrashIcon")
        return false
    }

    func handleDragItemToTrash(gestureRecognizer: UILongPressGestureRecognizer) {

        trashImageView.isHidden = false
        trashImageView.isUserInteractionEnabled = true

        let locationInView = gestureRecognizer.location(in: view)
        let locationTrashView = trashImageView.frame.origin

        print(locationTrashView)
        print(locationInView)
        if trashImageView.frame.contains(locationInView) {
            print("intersect")
        }
    }

    func createNewPin(coordinate: CLLocationCoordinate2D) {
        let uuid = UUID().uuidString
        let newPin = MKPointAnnotation()
        newPin.title = uuid
        newPin.coordinate = CLLocationCoordinate2D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        pinsArray.append(newPin)
    }

    func handleSelectedPin(pinAnnotation: MKAnnotationView) {
        let holdGesture = UILongPressGestureRecognizer(target: self, action: nil)

        if holdGesture.minimumPressDuration > 0.15 {
            pinAnnotation.addGestureRecognizer(holdGesture)
            pinAnnotation.isDraggable = true
        }
    }

    func deletePin(pinAnnotation: MKAnnotationView) {

    }

    func presentPhotoAlbumViewController() {
        let photoAlbumViewController = self.storyboard?.instantiateViewController(withIdentifier: Constants.PhotoAlbumViewControllerID) as! PhotoAlbumViewController
        self.show(photoAlbumViewController, sender: self)
    }
}

extension MapViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension MapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let mapCenter = mapView.region.center
        let mapSpan = mapView.region.span
        viewModel.saveUserZoomRegion(center: mapCenter, span: mapSpan)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        feedbackVibration(.medium)
        presentPhotoAlbumViewController()
        handleSelectedPin(pinAnnotation: view)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        let pinIdentifier = "pin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: pinIdentifier) as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: pinIdentifier)
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
}

// MARK: - MapViewModelDelegate

extension MapViewController: MapViewModelDelegate {
    func didLoad() {
        //
    }
}

// MARK: - Feedback Vibrate

extension MapViewController {

    enum FeedbackVibration {
        case light
        case medium
        case heavy
        case soft
        case rigid
    }

    func feedbackVibration(_ type: FeedbackVibration) {
        switch type {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .soft:
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        case .rigid:
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
        }
    }
}
