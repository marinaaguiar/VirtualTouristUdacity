import UIKit
import MapKit
import CoreData

protocol MapViewModelProtocol: AnyObject {

    func initializeCoreData()
    func saveUserZoomRegion(center: CLLocationCoordinate2D, span: MKCoordinateSpan)
    func getStoredUserRegion() -> Region?
    func setupRegion(in mapView: MKMapView)
}

protocol MapViewModelDelegate: AnyObject {
    func didLoad()
}

class MapViewModel: MapViewModelProtocol {

    private weak var delegate: MapViewModelDelegate?
    private let storageService = DataController.shared
    private let defaults = UserDefaults.standard

    private var pins: [Pin]?

    init(delegate: MapViewModelDelegate?) {
        self.delegate = delegate
    }

    func initializeCoreData() {
        storageService.loadPersistentStores { result in
            switch result {
            case .success:
                print("Loaded successfully")
                self.refreshItems()
            case .failure:
                print("Failed to load")
            }
        }
    }

    func refreshItems() {
        let request: NSFetchRequest<Pin> = Pin.fetchRequest()

        let sort = NSSortDescriptor(key: "location", ascending: true)
        request.sortDescriptors = [sort]

        do {
            try storageService.performContainerAction { container in
                let context = container.viewContext
                let objects = try context.fetch(request)
                self.pins = objects
                self.delegate?.didLoad()
            }
        } catch {
            print("Error fetching data from context \(error)")
        }
    }

    // MARK: - Map Region

    func setupRegion(in mapView: MKMapView) {
        getInitialUserRegion { region in
            mapView.setRegion(region.toMapRegion(), animated: true)
        }
    }

    func getInitialUserRegion(completion: (Region) -> Void) {
        if let storedRegion = getStoredUserRegion() {
            completion(storedRegion)
        } else {
            completion(Region.default)
        }
    }

    func saveUserZoomRegion(center: CLLocationCoordinate2D, span: MKCoordinateSpan) {

        let region = Region(center: center, span: span)
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(region) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "LastZoomRegion")
        }
    }

    func getStoredUserRegion() -> Region? {
        let decoder = JSONDecoder()

        guard
            let regionData = defaults.object(forKey: "LastZoomRegion") as? Data,
            let loadedRegion = try?
                decoder.decode(Region.self, from: regionData)
        else { return nil}

        return loadedRegion
    }
}
