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
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: dwarfs) { dwarf in
            MapAnnotation(coordinate: dwarf.coordinate2D) {
                VStack {
                    let scaleFactor = max(1, 0.0001 / region.span.latitudeDelta)
                    Image(systemName: "figure.diamond.fill")
                        .resizable()
                        .frame(width: 30 * scaleFactor, height: 30 * scaleFactor)
                        .foregroundColor(.red)
                    Text(dwarf.name)
                        .font(.caption)
                        .foregroundColor(.black)
                }
            }
        }
        .onAppear {
            loadDwarfsData()
        }
    }
    
    func loadDwarfsData() {
        guard let url = Bundle.main.url(forResource: "dwarfs", withExtension: "json") else {
            print("Brak pliku JSON z danymi krasnali.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            dwarfs = try decoder.decode([Dwarf].self, from: data)
        } catch {
            print("Błąd wczytywania danych: \(error)")
        }
    }
}


struct DwarfDetailView: View {
    var dwarf: Dwarf
    
    var body: some View {
        VStack {
            Text(dwarf.name)
                .font(.title)
                .fontWeight(.bold)
            Text(dwarf.description)
                .font(.body)
                .padding(.top, 10)
            Button("Close") {
                // Add functionality here
            }
            .padding(.top, 20)
        }
        .padding()
    }
}

#Preview {
    DwarfMapView()
}
