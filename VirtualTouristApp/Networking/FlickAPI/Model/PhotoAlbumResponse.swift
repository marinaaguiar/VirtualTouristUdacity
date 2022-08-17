import Foundation

struct PhotoAlbumResponse: Codable {
    let photos: Photos
    let stat: String
}

struct Photos: Codable {
    let page: Int
    let perpage: Int
    let photo: [PhotoID]
}

struct PhotoID: Codable {
    let id: String
    let secret: String
    let server: String
}

