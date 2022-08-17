import Foundation
import UIKit
import Kingfisher

protocol PhotoAlbumViewModelProtocol: AnyObject {
    var imagesUrlString: [String] { get }
    var isLoading: Bool { get }
    func loadData()
    func loadMoreData()
    func updateImage(imageView: UIImageView, imageUrl: String?)
}


protocol PhotoAlbumViewModelDelegate: AnyObject {
    func didLoad()
    func didLoadWithError()
}


class PhotoAlbumViewModel: PhotoAlbumViewModelProtocol {

    private let networkingService = NetworkingService()
    private let apiService = FlickrAPIService()
    private weak var delegate: PhotoAlbumViewModelDelegate?
    private var photos: [PhotoID] = []
    var imagesUrlString: [String] = []
    var isLoading: Bool = false
    private var page: Int = 1
    private var latitude: Double
    private var longitude: Double
    

    // MARK: - Dependencie Injection

    init(delegate: PhotoAlbumViewModelDelegate?, latitude: Double, longitude: Double) {
        self.delegate = delegate
        self.latitude = latitude
        self.longitude = longitude
    }

    // MARK: - Methods

    func loadData() {
        apiService.loadPhotoList(coordinate: .init(latitude: latitude, longitude: longitude), page: 1) { result in
            switch result {
            case .success(let data):
                self.photos = data.photos.photo
                self.imagesUrlString = self.photos.map { photo in
                    return self.apiService.buildPhotoURL(serverId: photo.server, photoId: photo.id, secretId: photo.secret)
                }
                print("Loaded data sucessfully")
                self.delegate?.didLoad()
            case .failure(let error):
                print("Fail to load data \(error.localizedDescription)")
                self.delegate?.didLoadWithError()
            }
        }
    }

    func loadMoreData() {
        page += 1
        apiService.loadPhotoList(coordinate: .init(latitude: latitude, longitude: longitude), page: page) { result in
            switch result {
            case .success(let data):
                self.photos.append(contentsOf: data.photos.photo)
                self.imagesUrlString = self.photos.map { photo in
                    return self.apiService.buildPhotoURL(serverId: photo.server, photoId: photo.id, secretId: photo.secret)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.delegate?.didLoad()
                }
                print("Loaded data sucessfully")
            case .failure(let error):
                print("Fail to load data \(error.localizedDescription)")
                self.delegate?.didLoadWithError()
            }
        }
    }

    func updateImage(imageView: UIImageView, imageUrl: String?) {
        if let urlString = imageUrl,
            let url = URL(string: urlString) {

            imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: nil)
        }
    }
}
