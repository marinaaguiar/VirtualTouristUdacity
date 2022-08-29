import Foundation
import CoreLocation

private struct FlickrAPIDefinitions {
    static let APIKey = "5055df9b58946662661805e859795b25"
    static let searchMethod = "flickr.photos.search"
    static let format = "json"
}

private struct EndPoint {
    enum QueryItem: String {
        case method
        case APIKey = "api_key"
        case format
        case longitude = "lon"
        case latitude = "lat"
        case perPage = "per_page"
        case page
    }

    let queryItems: [URLQueryItem]

    static func list(latitude: Double, longitude: Double, page: Int) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.flickr.com"
        components.path = "/services/rest/"

        components.queryItems = [
            URLQueryItem(
                name: QueryItem.method.rawValue,
                value: FlickrAPIDefinitions.searchMethod),
            URLQueryItem(
                name: QueryItem.APIKey.rawValue,
                value: FlickrAPIDefinitions.APIKey),
            URLQueryItem(
                name: QueryItem.format.rawValue,
                value: FlickrAPIDefinitions.format),
            URLQueryItem(
                name: QueryItem.latitude.rawValue,
                value: "\(latitude)"),
            URLQueryItem(
                name: QueryItem.longitude.rawValue,
                value: "\(longitude)"),
            URLQueryItem(
                name: QueryItem.perPage.rawValue,
                value: "30"),
            URLQueryItem(
                name: QueryItem.page.rawValue,
                value: "\(page)"),
            URLQueryItem(
                name: "nojsoncallback",
                value: "1"
            )
        ]

        return components.url
    }

    static func photo(serverId: String, photoId: String, secretId: String) -> String {
        let basePath = "https://live.staticflickr.com"
        return "\(basePath)/\(serverId)/\(photoId)_\(secretId).jpg"
    }
}

class FlickrAPIService {

    enum APIError: Swift.Error {
        case failedToConstructURL
        case wrongEncoding
    }

    func loadPhotoList(
        coordinate: CLLocationCoordinate2D,
        page: Int,
        completion: @escaping (Result<FlickrPhotoAlbumResponse, Error>) -> Void
    ) {
        guard let url = EndPoint.list(latitude: coordinate.latitude, longitude: coordinate.longitude, page: page) else {
            completion(.failure(APIError.failedToConstructURL))
            return
        }
//        print(url)

        NetworkingService().fetchGenericData(
            url: url,
            completion: completion
        )
    }

    func buildPhotoURL(
        serverId: String,
        photoId: String,
        secretId: String
    ) -> String {
//        print(EndPoint.photo(serverId: serverId, photoId: photoId, secretId: secretId))
        return EndPoint.photo(serverId: serverId, photoId: photoId, secretId: secretId)
    }

    func getPhotosUrl(_ flickrPhotos: [FlickrPhotoID], completion: @escaping ([String]) -> Void) {
        var imagesUrl: [String] = []
        flickrPhotos.map { photo in
            imagesUrl.append(buildPhotoURL(serverId: photo.server, photoId: photo.id, secretId: photo.secret))
        }
        completion(imagesUrl)
    }
}
