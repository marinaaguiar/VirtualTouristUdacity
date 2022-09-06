import Foundation

struct FlickrPhotoAlbumResponse: Codable {
    let photos: FlickrPhotos
    let stat: String
}

struct FlickrPhotos: Codable {
    let page: Int
    let perpage: Int
    let total: Int
    let photo: [FlickrPhotoInfo]
}

struct FlickrPhotoInfo: Codable {
    let id: String
    let secret: String
    let server: String
}

