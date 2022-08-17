//
//  MapAnnotation.swift
//  VirtualTouristApp
//
//  Created by Marina Aguiar on 7/29/22.
//

import MapKit

class MapAnnotation: NSObject, MKAnnotation {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?

    init(
        id: String = UUID().uuidString,
        coordinate: CLLocationCoordinate2D,
        title: String? = nil,
        subtitle: String? = nil
    ) {
        self.id = id
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}
