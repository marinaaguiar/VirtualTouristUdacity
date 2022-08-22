import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {

    private lazy var viewModel: MapViewModelProtocol = MapViewModel(delegate: self)
    private var vibration = Vibration()
//    var pinsArray: [MKPointAnnotation] = []

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var trashImageView: UIImageView!
    @IBOutlet weak var pinDeletedLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        handleHoldRecognizer()
        mapView.delegate = self
        pinDeletedLabel.isHidden = true
        populateMap()
    }

    override func viewWillAppear(_ animated: Bool) {
        trashImageView.isHidden = true
        setupSavedZoomRegion()
    }

    // Display initial map zoom region or the previous saved region
    func setupSavedZoomRegion() {
        let region = viewModel.setupRegion(in: mapView)
    }

    func handleHoldRecognizer() {
        let holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleHold))
        holdGesture.delegate = self
        holdGesture.minimumPressDuration = 0.25
        mapView.addGestureRecognizer(holdGesture)
    }

    @objc func handleHold(gestureRecognizer: UILongPressGestureRecognizer) {
        let locationInView = gestureRecognizer.location(in: view)
        let locationInMap = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(locationInMap,toCoordinateFrom: mapView)
        let pinsSelected = mapView.selectedAnnotations.compactMap { $0 as? MapAnnotation }

        switch gestureRecognizer.state {
        case .began where pinsSelected.isEmpty:
            print("create a new pin")
            vibration.feedbackVibration(.light)
            createNewPin(coordinate: coordinate)
        case .changed:
            isItemDraggedToTrash(locationInView)
        default:
            break
        }
    }

    func populateMap() {
        let annotations = viewModel.getPins()?.map { pin -> MapAnnotation in
            // convert to annotation
            let coordinate = CLLocationCoordinate2D(
                latitude: pin.latitude,
                longitude: pin.longitude
            )
            let annotationFromExistingPin = MapAnnotation(
                id: pin.id ?? UUID().uuidString,
                coordinate: coordinate
            )
            return annotationFromExistingPin
        }
        mapView.addAnnotations(annotations ?? [])
    }

    func isItemDraggedToTrash(_ locationInView: CGPoint) {
        // as it's necessary to check if the gesture is on the
        // trash icon so the user can see a visual feedback
        // that the pin might be deleted when is released

        if trashImageView.frame.contains(locationInView) {
            trashImageView.image = UIImage(named: "TrashOpenIcon")
        } else {
            trashImageView.image = UIImage(named: "TrashIcon")
        }
    }

    func isViewOverTrash(_ view: UIView) -> Bool {
        // as our views do not share a superview, it's necessary to convert the
        // frame to a common reference point and use trashImageView as
        // the common reference.
        let convertedFrame = view.convert(view.frame, to: trashImageView)

        if convertedFrame.intersects(trashImageView.frame) {
            trashImageView.image = UIImage(named: "TrashOpenIcon")
            return true
        } else {
            trashImageView.image = UIImage(named: "TrashIcon")
            return false
        }
    }

    func createNewPin(coordinate: CLLocationCoordinate2D) {
        let uuid = UUID().uuidString
        let newPin = MapAnnotation(
            id: uuid,
            coordinate: CLLocationCoordinate2D(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        )
        viewModel.saveNewPin(id: uuid, location: coordinate)
        mapView.addAnnotation(newPin)
    }

    func showDeletedPinMessage() {
        pinDeletedLabel.isHidden = false
        view.layer.masksToBounds = true
        pinDeletedLabel.layer.cornerRadius = 20
        Timer.scheduledTimer(timeInterval: 0.60, target: self, selector: #selector(self.hideDeletedPinMessage), userInfo: nil, repeats: false)
    }

    @objc func hideDeletedPinMessage() {
        pinDeletedLabel.isHidden = true
    }

    func presentPhotoAlbumViewController(pinAnnotation: MKPointAnnotation) {
        let latitude = pinAnnotation.coordinate.latitude
        let longitude = pinAnnotation.coordinate.longitude
//        let id = pinAnnotation.id

        let photoAlbumViewController = self.storyboard?.instantiateViewController(withIdentifier: Constants.PhotoAlbumViewControllerID) as! PhotoAlbumViewController
        photoAlbumViewController.viewModel = PhotoAlbumViewModel(delegate: photoAlbumViewController, latitude: latitude, longitude: longitude)
//        photoAlbumViewController.viewModel.getObjectID(for: id)
//        photoAlbumViewController.viewModel.displayPhotos(for: pinAnnotation.id)
        self.show(photoAlbumViewController, sender: self)
    }
}

//MARK: - UIGestureRecognizerDelegate

extension MapViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

    //MARK: - MapViewDelegate

extension MapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let mapCenter = mapView.region.center
        let mapSpan = mapView.region.span
        viewModel.saveUserZoomRegion(center: mapCenter, span: mapSpan)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        vibration.feedbackVibration(.medium)
        presentPhotoAlbumViewController(pinAnnotation: view.annotation as! MapAnnotation)
        view.isDraggable = true
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        guard let annotation = view.annotation as? MapAnnotation else { return }
        print("old state \(oldState.rawValue)")
        print("new state \(newState.rawValue)")
        switch newState {
        case .starting:
            vibration.feedbackVibration(.soft)
            viewModel.setPin(with: annotation.id)
        case .dragging:
            trashImageView.isHidden = false
            trashImageView.isUserInteractionEnabled = true
        case .ending:
            if isViewOverTrash(view) {
                viewModel.deletePin(with: annotation.id)
                showDeletedPinMessage()
                vibration.feedbackVibration(.heavy)
                mapView.removeAnnotation(annotation)
                viewModel.refreshItems()
            }
            vibration.feedbackVibration(.rigid)
            trashImageView.image = UIImage(named: "TrashIcon")
            trashImageView.isHidden = true
        default:
            break
        }
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.mapView.reloadInputViews()
        }
    }
}
