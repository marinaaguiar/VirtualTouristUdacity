import Foundation
import UIKit

class ImageLoader {

    private var loadedImages = [URL: UIImage]()
    private var runningRequests = [UUID: URLSessionDataTask]()
    var viewModel: PhotoAlbumViewModelProtocol!

    func loadImage(_ url: String, _ completion: @escaping (Result<UIImage, Error>) -> Void) -> UUID? {

        guard let url = URL(string: url) else { return nil }

        // Generate a new uuid
        let uuid = UUID()

        // If image already exists in loadedImages
        // Call completion handler
        // and return nil, since there is no need to generate a new UUID
        if let image = loadedImages[url] {
            completion(.success(image))
            return nil
        }
        // When/If the task is completed remove the UUID from runningRequests dictionary
        // Extract the image and save in-memory cache (loadedImages dictionary)
        // Save image on CoreData
        let task = URLSession.shared.dataTask(with: url)
        { data, response, error in
            defer {self.runningRequests.removeValue(forKey: uuid) }

            if let data = data, let image = UIImage(data: data) {
                self.loadedImages[url] = image
                self.viewModel.saveImage(image: image)
                completion(.success(image))
                return
            }

            guard let error = error else {
                return
            }

            guard (error as NSError).code == NSURLErrorCancelled else {
                completion(.failure(error))
                return
            }
        }
        task.resume()

        //Data task is stored in the runningRequest dictionary using the UUID created
        runningRequests[uuid] = task
        return uuid
    }

    func cancelLoad(_ uuid: UUID) {
        runningRequests[uuid]?.cancel()
        runningRequests.removeValue(forKey: uuid)
    }
}

class UIImageLoader {

    static let loader = UIImageLoader()

    private let imageLoader = ImageLoader()
    private var uuidMap = [UIImageView: UUID]()

    private init() {}

    //When the load is completed
    //It is necessary to remove the UIImageView from the uuidMap dictionary
    func load(_ url: String, for imageView: UIImageView) {

        let token = imageLoader.loadImage(url) { result in
            defer { self.uuidMap.removeValue(forKey: imageView) }
            do {
                let image = try result.get()
                DispatchQueue.main.async {
                    imageView.image = image
                }
            } catch {
                // handle the error
            }
        }
        if let token = token {
            uuidMap[imageView] = token
        }
    }

    func cancel(for imageView: UIImageView) {
        if let uuid = uuidMap[imageView] {
            imageLoader.cancelLoad(uuid)
            uuidMap.removeValue(forKey: imageView)
        }
    }
}
