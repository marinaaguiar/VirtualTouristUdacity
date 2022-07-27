import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {

    private lazy var viewModel: MapViewModelProtocol = MapViewModel(delegate: self)
    private var vibration = Vibration()

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
        let region = viewModel.setupRegion(in: mapView)
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
            vibration.feedbackVibration(.light)
            createNewPin(coordinate: coordinate)
            mapView.addAnnotations(pinsArray)
        case .changed where isItemDraggedToTrash(locationInView):
            trashImageView.image = UIImage(named: "TrashOpenIcon")
        case .ended:
            if isItemDraggedToTrash(locationInView) {
                print("pinSelected \(pinSelected)")
                let newPinsArray = pinsArray.filter { $0.subtitle != pinSelected.first?.subtitle }
                mapView.removeAnnotations(pinSelected)
                vibration.feedbackVibration(.heavy)
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
        newPin.subtitle = uuid
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
        vibration.feedbackVibration(.medium)
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

        annotationView?.subtitleVisibility = .hidden
        return annotationView
    }
}

// MARK: - MapViewModelDelegate

extension MapViewController: MapViewModelDelegate {
    func didLoad() {
        //
    }
}
