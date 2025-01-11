//
//  DwarfMapView.swift
//  WroclawDwarfs
//
//  Created by Kacper Gwiazda on 10/01/2025.
//

import SwiftUI
import MapKit

struct DwarfMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.107885, longitude: 17.038538),
        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    )
    
    @State private var dwarfs: [Dwarf] = []
    private let database = DwarfDatabase()
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, annotationItems: dwarfs) { dwarf in
                MapAnnotation(coordinate: dwarf.coordinate2D) {
                    VStack {
                        let scaleFactor = max(1, 0.0001 / region.span.latitudeDelta)
                        Image(systemName: dwarf.visited ? "figure.walk.circle.fill" : "figure.diamond.fill")
                            .resizable()
                            .frame(width: 30 * scaleFactor, height: 30 * scaleFactor)
                            .foregroundColor(dwarf.visited ? .green : .red)
                        Text(dwarf.name)
                            .font(.caption)
                            .foregroundColor(.black)
                    }
                }
            }
            .navigationTitle("Mapa Krasnali")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu("Krasnale") {
                        ForEach(dwarfs, id: \.id) { dwarf in
                            Button(action: {
                                toggleVisited(dwarf)
                            }) {
                                HStack {
                                    Text(dwarf.name)
                                    if dwarf.visited {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                database.loadInitialDataIfNeeded()
                dwarfs = database.fetchDwarfs()
                loadData()
            }
        }
    }

    func loadData() {
        dwarfs = database.fetchDwarfs()
    }
    
    func toggleVisited(_ dwarf: Dwarf) {
        let updatedStatus = !dwarf.visited
        database.markAsVisited(dwarfID: dwarf.id, visited: updatedStatus)
        loadData()
    }
}

#Preview {
    DwarfMapView()
}
