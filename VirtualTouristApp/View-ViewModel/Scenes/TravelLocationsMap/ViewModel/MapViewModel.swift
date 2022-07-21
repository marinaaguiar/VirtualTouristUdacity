import UIKit
import MapKit
import CoreData

protocol MapViewModelProtocol: AnyObject {

    func initializeCoreData()
    func saveUserZoomRegion(center: CLLocationCoordinate2D, span: MKCoordinateSpan)
    func setupRegion() -> MKCoordinateRegion
}

protocol MapViewModelDelegate: AnyObject {
    func didLoad()
}

struct Region: Codable {
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let latitudeDelta: CLLocationDegrees
    let longitudeDelta: CLLocationDegrees
}

class MapViewModel: MapViewModelProtocol {

    private weak var delegate: MapViewModelDelegate?
    private let storageService = DataController.shared
    private var pins: [Pin]?

    private let defaults = UserDefaults.standard


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

    func saveUserZoomRegion(center: CLLocationCoordinate2D, span: MKCoordinateSpan) {

        let region = Region(latitude: center.latitude, longitude: center.longitude, latitudeDelta: span.latitudeDelta, longitudeDelta: span.longitudeDelta)
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(region) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "LastZoomRegion")
        }
    }

    func setupRegion() -> MKCoordinateRegion {
        var region = MKCoordinateRegion()
        if let lastZoomRegion = defaults.object(forKey: "LastZoomRegion") as? Data {
            let decoder = JSONDecoder()
            if let loadedRegion = try? decoder.decode(Region.self, from: lastZoomRegion) {
               region = MKCoordinateRegion.init(
                    center: CLLocationCoordinate2D(
                        latitude: loadedRegion.latitude,
                        longitude: loadedRegion.longitude),
                    span: MKCoordinateSpan(
                        latitudeDelta: loadedRegion.latitudeDelta,
                        longitudeDelta: loadedRegion.longitudeDelta)
                )
            }
        }
        return region
    }
}
