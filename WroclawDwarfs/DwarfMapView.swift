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
    @State private var selectedDwarf: Dwarf?
    @State private var showDwarfsList = false
    private let database = DwarfDatabase()
                
    var body: some View {
        NavigationView {
            VStack {
                Map(coordinateRegion: $region, annotationItems: dwarfs) { dwarf in
                    MapAnnotation(coordinate: dwarf.coordinate2D) {
                        VStack {
                            let scaleFactor = max(1, 0.0001 / region.span.latitudeDelta)
                            Image(dwarf.visited ? "dwarf_visited" : "dwarf_not_visited")
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
                        Button("Krasnale") {
                            showDwarfsList.toggle()  // Otwórz lub zamknij listę krasnali
                        }
                    }
                    //WERSJA TESTOWA MA TEN BUTTON! NA KONIEC NALEZU USUNAC BUTTON, FUNCKEJ RELOADNEWDATA, ORAZ FUNKCJE RELOADDATABASE Z PLIKU DWARFFATABASE
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Załaduj Nowe Krasnale") {
                            reloadNewData()  // Załaduj nowe dane z JSON
                        }
                    }
                }
                .onAppear {
                    loadData()
                }
            }
            .sheet(isPresented: $showDwarfsList) {
                DwarfListView(dwarfs: dwarfs, onVisited: { dwarf in
                    markAsVisited(dwarf)
                }, focusOnDwarf: { dwarf in
                    focusOnDwarf(dwarf)
                    showDwarfsList = false // Zamknij sheet po kliknięciu w krasnala
                })
            }
        }
    }
    
    func loadData() {
        dwarfs = database.fetchDwarfs()
    }
    
    func reloadNewData() {
            // Ponownie załaduj dane z JSON
            database.reloadDatabase()
            loadData()  // Załaduj nowe dane z bazy po załadowaniu danych z JSON
    }
    
    func focusOnDwarf(_ dwarf: Dwarf) {
        withAnimation {
            region = MKCoordinateRegion(
                center: dwarf.coordinate2D,
                span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001) // Zoom
            )
        }
    }
    
    func markAsVisited(_ dwarf: Dwarf) {
        let updatedDwarf = Dwarf(id: dwarf.id, name: dwarf.name, description: dwarf.description, coordinate: dwarf.coordinate, visited: true)
        database.markAsVisited(dwarfID: dwarf.id, visited: true)
        
        // Update local data to reflect the new visited state
        if let index = dwarfs.firstIndex(where: { $0.id == dwarf.id }) {
            dwarfs[index].visited = true
        }
    }
}

struct DwarfListView: View {
    var dwarfs: [Dwarf]
    var onVisited: (Dwarf) -> Void
    var focusOnDwarf: (Dwarf) -> Void
    
    var body: some View {
        VStack {
            List(dwarfs) { dwarf in
                HStack {
                    Text(dwarf.name)
                    Spacer()
                    if dwarf.visited {
                        Text("Odwiedzony")
                            .foregroundColor(.green)
                    } else {
                        Text("Nieodwiedzony")
                            .foregroundColor(.red)
                    }
                }
                .onTapGesture {
                    focusOnDwarf(dwarf)  // Funkcja do zmiany lokalizacji i focusu
                }
                .contextMenu {
                    Button("Oznacz jako odwiedzony") {
                        onVisited(dwarf)
                    }
                }
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    DwarfMapView()
}
