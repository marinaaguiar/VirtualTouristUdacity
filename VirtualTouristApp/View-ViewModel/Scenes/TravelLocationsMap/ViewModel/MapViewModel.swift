import UIKit
import MapKit
import CoreData

protocol MapViewModelProtocol: AnyObject {

    func initializeCoreData()
    func saveUserZoomRegion(center: CLLocationCoordinate2D, span: MKCoordinateSpan)
    func saveNewPin(id: String, location: CLLocationCoordinate2D) 
    func getStoredUserRegion() -> Region?
    func setupRegion(in mapView: MKMapView)
    func getObjectID(for pinID: String) -> NSManagedObjectID? 
    func getPins() -> [Pin]?
    func deletePin(id: String)
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
        initializeCoreData()
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

        let sort = NSSortDescriptor(key: "id", ascending: true)
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

    func saveNewPin(id: String, location: CLLocationCoordinate2D) {
        do {
            try storageService.performContainerAction { container in
                let context = container.viewContext

                let newPin = Pin(context: context)
                newPin.id = id
                newPin.latitude = location.latitude
                newPin.longitude = location.longitude

                context.insert(newPin)
                try context.save()
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    func getObjectID(for pinID: String) -> NSManagedObjectID? {
        guard let pins = pins else { return nil}

        for pin in pins {
            if pin.id == pinID {
                return pin.objectID
            }
        }
        return nil
    }

    func getPins() -> [Pin]? {
        guard let pins = pins else {
            return nil
        }
        return pins
    }

    func deletePin(id: String) {
        guard let pins = pins else { return }

        let pinToDelete = { () -> Pin in
            let pin = pins.filter { $0.id != id }
            print(pin.first!.id)
            return pin.first!
        }

        do {
            try storageService.performContainerAction { container in

                let context = container.viewContext
                context.delete(pinToDelete())
                try context.save()
            }
        } catch {
            print("Could not delete \(error.localizedDescription)")
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
