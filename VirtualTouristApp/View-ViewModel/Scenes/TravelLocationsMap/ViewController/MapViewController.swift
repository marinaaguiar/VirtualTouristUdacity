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

    func setupTapGestureRecognizer() {
        let holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleHold))
        holdGesture.delegate = self
        holdGesture.minimumPressDuration = 0.25
        holdGesture.delaysTouchesBegan = true
        mapView.addGestureRecognizer(holdGesture)
    }

    @objc func handleHold(gestureRecognizer: UILongPressGestureRecognizer) {
//        guard let pinSelectedID = getPinSelectedID() else { return }
        let locationInView = gestureRecognizer.location(in: view)
        let locationInMap = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(locationInMap,toCoordinateFrom: mapView)
        let pinsSelected = mapView.selectedAnnotations.compactMap { $0 as? MapAnnotation }

        switch gestureRecognizer.state {
        case .began where pinsSelected.isEmpty:
            print("create a new pin")
            vibration.feedbackVibration(.light)
            createNewPin(coordinate: coordinate)
        case .began:
            vibration.feedbackVibration(.soft)
            trashImageView.isHidden = false
            trashImageView.isUserInteractionEnabled = true
        case .changed where isItemDraggedToTrash(locationInView):
            trashImageView.image = UIImage(named: "TrashOpenIcon")
        case .ended:
            guard let selectedPinID = pinsSelected.first?.id else { break }
            vibration.feedbackVibration(.light)
            if isItemDraggedToTrash(locationInView) {
                print(selectedPinID)
                viewModel.deletePin(id: selectedPinID)
                vibration.feedbackVibration(.heavy)
//                let newPinsArray = pinsArray.filter { $0.subtitle != pinsSelected.first?.subtitle }
                mapView.removeAnnotations(pinsSelected)
//                refreshMap(newPinsArray: newPinsArray)
            }
            trashImageView.isHidden = true
            trashImageView.image = UIImage(named: "TrashIcon")
        default:
            break
        }
    }

    // Remove all the pins showing in the map
    // And display all the new pins
    func refreshMap(newPinsArray: [MKPointAnnotation] ) {
//        pinsArray.removeAll()
//        pinsArray = newPinsArray
//        mapView.addAnnotations(pinsArray)
    }

    func populateMap() {
        let annotations = viewModel.getPins()?.map { pin -> MapAnnotation in
            // convert to annotation
            let coordinate = CLLocationCoordinate2D(
                latitude: pin.latitude,
                longitude: pin.longitude
            )

            let existingPin = MapAnnotation(
                id: pin.id ?? UUID().uuidString,
                coordinate: coordinate
            )
//            existingPin.coordinate.latitude = pin.latitude
//            existingPin.coordinate.longitude = pin.longitude
//            existingPin.subtitle = pin.id
            return existingPin
        }
        mapView.addAnnotations(annotations ?? [])
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

    func deletePin(pinAnnotation: MKAnnotationView) {

    }

    func handleSelectedPin(pinAnnotation: MKAnnotationView) {
        let holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(handlePinHold))
        pinAnnotation.addGestureRecognizer(holdGesture)
        pinAnnotation.dragState = .dragging
        pinAnnotation.isDraggable = true
    }

    @objc func handlePinHold(gestureRecognizer: UILongPressGestureRecognizer) {
        let locationInView = gestureRecognizer.location(in: view)
        let locationInMap = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(locationInMap,toCoordinateFrom: mapView)
        let pinsSelected = mapView.selectedAnnotations.compactMap { $0 as? MapAnnotation }

        switch gestureRecognizer.state {
        case .began:
            vibration.feedbackVibration(.soft)
            trashImageView.isHidden = false
            trashImageView.isUserInteractionEnabled = true
        case .changed where isItemDraggedToTrash(locationInView):
            trashImageView.image = UIImage(named: "TrashOpenIcon")
        case .ended:
            guard let selectedPinID = pinsSelected.first?.id else { break }
            vibration.feedbackVibration(.light)
            if isItemDraggedToTrash(locationInView) {
                print(selectedPinID)
                viewModel.deletePin(id: selectedPinID)
                vibration.feedbackVibration(.heavy)
//                let newPinsArray = pinsArray.filter { $0.subtitle != pinsSelected.first?.subtitle }
                mapView.removeAnnotations(pinsSelected)
//                refreshMap(newPinsArray: newPinsArray)
            }
            trashImageView.isHidden = true
            trashImageView.image = UIImage(named: "TrashIcon")
        default:
            break
        }

    }

    func presentPhotoAlbumViewController(pinAnnotation: MapAnnotation) {
        let latitude = pinAnnotation.coordinate.latitude
        let longitude = pinAnnotation.coordinate.longitude
        let id = pinAnnotation.id

        let photoAlbumViewController = self.storyboard?.instantiateViewController(withIdentifier: Constants.PhotoAlbumViewControllerID) as! PhotoAlbumViewController
        photoAlbumViewController.viewModel = PhotoAlbumViewModel(delegate: photoAlbumViewController, latitude: latitude, longitude: longitude)
        photoAlbumViewController.viewModel.getObjectID(for: id)
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
