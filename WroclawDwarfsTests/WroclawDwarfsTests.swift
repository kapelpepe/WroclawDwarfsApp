//
//  WroclawDwarfsTests.swift
//  WroclawDwarfsTests
//
//  Created by Kacper Gwiazda on 10/01/2025.
//

import XCTest
import MapKit
@testable import WroclawDwarfs

final class DwarfMapViewTests: XCTestCase {
    
    func testFocusOnDwarf() {
        // Arrange: Tworzymy przykładowego krasnala i obiekt DwarfMapView
        let testDwarf = Dwarf(
            id: "test_id",
            name: "Test Dwarf",
            description: "Opis krasnala testowego",
            coordinate: Dwarf.Coordinate(latitude: 51.1100, longitude: 17.0300),
            visited: false
        )
        
        let dwarfMapView = DwarfMapView()
        
        dwarfMapView.focusOnDwarf(testDwarf) //Wywolujemy metode focusOn na danych testowych
        
        let expectedRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.1100, longitude: 17.0300),
            span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        )
        
        XCTAssertEqual(dwarfMapView.region.center.latitude, expectedRegion.center.latitude, accuracy: 0.01)
        XCTAssertEqual(dwarfMapView.region.center.longitude, expectedRegion.center.longitude, accuracy: 0.01)
    }
}
