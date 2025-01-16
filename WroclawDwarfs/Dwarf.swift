//
//  Dwarf.swift
//  WroclawDwarfs
//
//  Created by Kacper Gwiazda on 10/01/2025.
//

import Foundation
import MapKit

protocol Description { //Wlasny protokol
    var id: String {get}
    var name: String {get}
    var description: String {get}
}

struct Dwarf: Identifiable, Codable, Equatable, Hashable, Description {
    var id: String
    var name: String
    var description: String
    var coordinate: Coordinate
    var visited: Bool
    
    struct Coordinate: Codable, Equatable, Hashable {
        var latitude: Double
        var longitude: Double
    }
    
    var coordinate2D: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
