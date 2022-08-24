import Foundation
import UIKit
import Kingfisher
import CoreData

protocol PhotoAlbumViewModelProtocol: AnyObject {
    var imagesUrlString: [String] { get }
    var photos: [Photo]? { get }
    var isLoading: Bool { get }
    func loadData()
    func refreshItems()
    func getPin(pinID: NSManagedObjectID)
    func isPhotoAlbumAlreadyExists()
    func numberOfRows() -> Int
    func fillCell(atIndexPath indexPath: Int) -> PhotoCell
}


protocol PhotoAlbumViewModelDelegate: AnyObject {
    func didLoad()
    func didLoadWithError()
}

class PhotoAlbumViewModel: PhotoAlbumViewModelProtocol {

    private let networkingService = NetworkingService()
    private let apiService = FlickrAPIService()
    private weak var delegate: PhotoAlbumViewModelDelegate?

    var imagesUrlString: [String] = []
    var isLoading: Bool = false
    private var page: Int = 1

    private var latitude: Double
    private var longitude: Double

    private let storageService = DataController.shared
    private var pin: Pin!
    internal var photos: [Photo]?

    // MARK: - Dependencie Injection

    init(delegate: PhotoAlbumViewModelDelegate?, latitude: Double, longitude: Double) {
        self.delegate = delegate
        self.latitude = latitude
        self.longitude = longitude
    }
}

    // MARK: - CoreData

extension PhotoAlbumViewModel {

    func refreshItems() {
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()

            let predicate = NSPredicate(format: "pin = %@", pin)
            request.predicate = predicate

        do {
            try storageService.performContainerAction { container in
                let context = container.viewContext
                let objects = try context.fetch(request)
                self.photos = objects
                self.delegate?.didLoad()
            }
        } catch {
            print("Error fetching data from context \(error)")
        }
    }

    func isPhotoAlbumAlreadyExists() {
        if let photos = pin.photos, photos.count != 0 {
            print("The album already exists")
        } else {
            loadData()
            print("The album does not exist, it is necessary to load from the api")
        }
    }

    func numberOfRows() -> Int {
        return photos?.count ?? 0
    }

    func fillCell(atIndexPath indexPath: Int) -> PhotoCell {
        guard let photos = photos else {
            fatalError("Not able to get photos")
        }
        let photo = photos[indexPath]
        return PhotoCell(imageUrl: photo.url)
    }

    func saveImages(imagesUrl: [String]) {
        do {
            try storageService.performContainerAction { container in
                let context = container.viewContext

                for imageUrl in imagesUrl {
                    let newPhoto = Photo(context: context)
                    newPhoto.url = imageUrl
                    newPhoto.pin = pin

                    // Save the data
                    context.insert(newPhoto)
                    try context.save()
                }
            }
        } catch {
            print(error.localizedDescription)
        }

    }

//    func deleteImage(indexPathItem: Int) {
//        guard let album = album else { return }
//
//        do {
//            try storageService.performContainerAction { container in
//
//                let context = container.viewContext
//                context.delete(album[indexPathItem])
//                try context.save()
//            }
//        } catch {
//            print("Could not delete \(error.localizedDescription)")
//        }
//    }

    func getPin(pinID: NSManagedObjectID) {

        do {
            try storageService.performContainerAction { container in
                let context = container.viewContext

                let pin = context.object(with: pinID) as! Pin
                self.pin = pin
            }
        } catch {
            print("Could not get pin \(error.localizedDescription)")
        }
    }
}

    //MARK: - API Service

extension PhotoAlbumViewModel {

    func loadData() {
        apiService.loadPhotoList(coordinate: .init(latitude: latitude, longitude: longitude), page: 1) { result in
            switch result {
            case .success(let data):
                let flickrPhotos = data.photos.photo
                self.saveImages(
                    imagesUrl: flickrPhotos.map { photo in
                        return self.apiService.buildPhotoURL(
                            serverId: photo.server,
                            photoId: photo.id,
                            secretId: photo.secret
                        )
                    })
                print("Loaded data sucessfully")
                self.refreshItems()
                self.delegate?.didLoad()
            case .failure(let error):
                print("Fail to load data \(error.localizedDescription)")
                self.delegate?.didLoadWithError()
            }
        }
    }
}
