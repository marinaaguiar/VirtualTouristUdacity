import CoreData
import Foundation
import UIKit

struct PhotoLoadResult {
    let operationID: UUID
    let result: Result<UIImage, Error>
}

class PhotoCache {
    private let operationQueue = OperationQueue()
    private var backgroundContext: NSManagedObjectContext!

    static let shared = PhotoCache.init()

    private init() {
        try! DataController.shared.performContainerAction { container in
            backgroundContext = container.newBackgroundContext()
            backgroundContext.mergePolicy = NSMergePolicy.overwrite
        }

        operationQueue.maxConcurrentOperationCount = 3
    }

    func fetchImage(urlString: String, completion: @escaping (PhotoLoadResult) -> Void) -> UUID {
        let loadID = UUID()

        operationQueue.addOperation {
            if let image = self.getLocalImage(urlString: urlString) {
                completion(.init(operationID: loadID, result: .success(image)))
                return
            }

            guard let url = URL(string: urlString) else {
                completion(.init(operationID: loadID, result: .failure(PhotoCacheError.failedToGetURL)))
                return
            }

            self.getRemoteImage(url: url) { result in
                completion(.init(operationID: loadID, result: result))
            }
        }

        return UUID()
    }
}

enum PhotoCacheError: Error {
    case noData
    case failedToGetImage
    case failedToGetURL
}

private extension PhotoCache {
    func getRemoteImage(url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                completion(.failure(PhotoCacheError.noData))
                return
            }

            guard let image = UIImage(data: data) else {
                completion(.failure(PhotoCacheError.failedToGetImage))
                return
            }

            self.storeImage(urlString: url.absoluteString, data: data)
            completion(.success(image))
        }

        task.resume()
    }

    func storeImage(urlString: String, data: Data) {
        try! DataController.shared.performContainerAction { container in
            let context = container.newBackgroundContext()
            context.mergePolicy = NSMergePolicy.overwrite

            context.performAndWait {
                let request: NSFetchRequest<Photo> = Photo.fetchRequest()

                let predicate = NSPredicate(format: "url = %@", urlString)
                request.predicate = predicate

                try! context.fetch(request).forEach { photo in
                    photo.image = data
                }

                try! context.save()
            }
        }
    }

    func getLocalImage(urlString: String) -> UIImage? {
        var photoData: Data?

        backgroundContext.performAndWait {
            let request: NSFetchRequest<Photo> = Photo.fetchRequest()

            let predicate = NSPredicate(format: "url = %@", urlString)
            request.predicate = predicate

            photoData = try? backgroundContext.fetch(request).first?.image
        }

        guard let data = photoData, let image = UIImage(data: data) else {
            return nil
        }

        return image
    }
}
