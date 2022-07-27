import CoreLocation
import MapKit

struct Region: Codable {

    static let `default` = Region(latitude: 18.85193455476915, longitude: -41.43647993543636, latitudeDelta: 157.96681642231732, longitudeDelta: 139.47022511649655)

    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let latitudeDelta: CLLocationDegrees
    let longitudeDelta: CLLocationDegrees

    init(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        latitudeDelta: CLLocationDegrees,
        longitudeDelta: CLLocationDegrees
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }

    init(center: CLLocationCoordinate2D, span: MKCoordinateSpan) {
        self.init(
            latitude: center.latitude,
            longitude: center.longitude,
            latitudeDelta: span.latitudeDelta,
            longitudeDelta: span.longitudeDelta
        )
    }

    func toMapRegion() -> MKCoordinateRegion {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)

        return MKCoordinateRegion(center: center, span: span)
    }
}
