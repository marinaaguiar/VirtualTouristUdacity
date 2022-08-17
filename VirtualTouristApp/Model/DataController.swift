import UIKit
import CoreData

struct DataController {

    enum PersistentContainer: String {
        case virtualTouristApp = "VirtualTouristApp"
    }

    static let shared = Self.init(persistentContainer: .virtualTouristApp)

    private let persistentContainer: NSPersistentContainer

    private init(persistentContainer: PersistentContainer) {
        self.persistentContainer = NSPersistentContainer(name: persistentContainer.rawValue)
    }

    // MARK: - Core Data stack

    func loadPersistentStores(completion: @escaping (Result<NSPersistentStoreDescription?, Error>) -> Void) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error = error {
                completion(.failure(error))
            }
            completion(.success(storeDescription))
        }
    }

    func performContainerAction(action: (NSPersistentContainer) throws -> Void) throws {
        try action(persistentContainer)
    }

    // MARK: - Core Data Saving support

    func saveContext() -> Result<Void, Error> {
        let context = persistentContainer.viewContext

        if context.hasChanges {
            return Result { try context.save() }
        }

        return .success(())
    }
}
