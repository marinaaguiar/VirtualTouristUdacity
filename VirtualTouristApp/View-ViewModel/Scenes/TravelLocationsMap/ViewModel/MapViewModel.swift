import UIKit
import MapKit
import CoreData

protocol MapViewModelProtocol: AnyObject {

    func initializeCoreData()
    func refreshItems() 
    func saveUserZoomRegion(center: CLLocationCoordinate2D, span: MKCoordinateSpan)
    func saveNewPin(id: String, location: CLLocationCoordinate2D)
    func getStoredUserRegion() -> Region?
    func setupRegion(in mapView: MKMapView)
    func getObjectID(for id: String) -> NSManagedObjectID?
    func getPins() -> [Pin]?
    func deletePin(with id: String)
    func editPin(id: String, newlocation: CLLocationCoordinate2D)
}

protocol MapViewModelDelegate: AnyObject {
    func didLoad()
}

class MapViewModel: MapViewModelProtocol {

    private weak var delegate: MapViewModelDelegate?
    private let storageService = DataController.shared
    private let defaults = UserDefaults.standard

    private var pins: [Pin]?
    private var photos: [Photo]?

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

    func editPin(id: String, newlocation: CLLocationCoordinate2D) {

        do {
            try storageService.performContainerAction { container in
                let context = container.viewContext

                let fetchRequest = Pin.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", id)

                let matchingPins = try context.fetch(fetchRequest)
                matchingPins.forEach { pin in
                    pin.latitude = newlocation.latitude
                    pin.longitude = newlocation.longitude

                    pin.photos?.forEach({ object in
                        guard let photo = object as? Photo else { return }
                        context.delete(photo)
                    })
                }
                try context.save()
            }
        } catch {
            print("Could not edit pin \(error.localizedDescription)")
        }
    }

    func getPins() -> [Pin]? {
        guard let pins = pins else {
            return nil
        }
        return pins
    }

    func deletePin(with id: String) {
        do {
            try storageService.performContainerAction { container in
                let context = container.viewContext

                // we get all pins matching the ID we have
                let fetchRequest = Pin.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", id)

                // when we delete each pin. we expect that we'll have either
                // 0 or 1 matching pin, but we have to handle the possibility
                // of more, as the database doesn't know we can only have one.
                let matchingPins = try context.fetch(fetchRequest)
                matchingPins.forEach { pin in context.delete(pin) }

                try context.save()
            }
        } catch {
            print("Could not delete \(error.localizedDescription)")
        }
    }

    func getObjectID(for id: String) -> NSManagedObjectID? {
        guard let pins = pins else { return nil }
        let pinSelected = pins.filter { $0.id == id }
        print("PIN SELECTED ID: \(pinSelected.first?.objectID)")
        return pinSelected.first?.objectID
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
