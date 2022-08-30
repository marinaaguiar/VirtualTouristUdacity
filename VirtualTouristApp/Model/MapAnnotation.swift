import MapKit

class MapAnnotation: MKPointAnnotation {
    let id: String

    init(
        id: String = UUID().uuidString,
        coordinate: CLLocationCoordinate2D,
        title: String? = nil,
        subtitle: String? = nil
    ) {
        self.id = id

        super.init()
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}
