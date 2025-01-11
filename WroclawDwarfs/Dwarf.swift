//
//  Dwarf.swift
//  WroclawDwarfs
//
//  Created by Kacper Gwiazda on 10/01/2025.
//

import Foundation
import MapKit

struct Dwarf: Identifiable, Decodable {
    var id: String
    var name: String
    var description: String
    var coordinate: Coordinate
    var visited: Bool

    struct Coordinate: Decodable {
        var latitude: Double
        var longitude: Double
    }
    
    var coordinate2D: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
