//
//  DwarfMapView.swift
//  WroclawDwarfs
//
//  Created by Kacper Gwiazda on 10/01/2025.
//

import SwiftUI
import MapKit

struct DwarfMapView: View {
    @State public var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.107885, longitude: 17.038538),
        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    )
    
    @State private var dwarfs: [Dwarf] = []
    @State private var selectedDwarf: Dwarf?
    @State private var showDwarfsList = false
    @State private var searchText: String = ""

    
    private let database = DwarfDatabase()
    
    var filteredDwarfs: [Dwarf] {
        if searchText.isEmpty {
            return dwarfs
        } else {
            return dwarfs.filter { $0.name.lowercased().contains(searchText.lowercased()) } //Funkcja wyzszego rzedu - filter
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Map(coordinateRegion: $region, annotationItems: dwarfs) { dwarf in
                    MapAnnotation(coordinate: dwarf.coordinate2D) {
                        ZStack {
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
                            .onTapGesture {
                                focusOnDwarf(dwarf)
                                selectDwarf(dwarf)
                            }
                            
                            // Szczegóły krasnala
                            if let selected = selectedDwarf, selected.id == dwarf.id {
                                VStack(spacing: 5) {
                                    Text(dwarf.name)
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    Text(dwarf.description)
                                        .foregroundColor(.black)
                                    
                                    // Przycisk do zmiany stanu "Odwiedzone"
                                    Button(action: {
                                        markAsVisited(dwarf)
                                    }) {
                                        Text(dwarf.visited ? "Nieodwiedzone" : "Odwiedzony")
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(dwarf.visited ? Color.red : Color.green)
                                            .cornerRadius(8)
                                    }
                                    .padding(2)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(radius: 2)
                                }
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(radius: 5)
                                .offset(y: -104)
                            }
                        }
                    }
                }
                .gesture(
                    TapGesture()
                        .onEnded {
                            if selectedDwarf != nil {
                                selectedDwarf = nil
                            }
                        }
                )
                .navigationTitle("Mapa krasnali")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Lista Krasnali") {
                            showDwarfsList.toggle()
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Reload") {
                            reloadNewData()
                        }
                    }
                }
                .onAppear {
                    loadData()
                }
            }
            .sheet(isPresented: $showDwarfsList) {
                DwarfListView(
                    dwarfs: filteredDwarfs,
                    onVisited: { dwarf in
                        markAsVisited(dwarf)
                    },
                    focusOnDwarf: { dwarf in
                        focusOnDwarf(dwarf)
                        showDwarfsList = false
                    },
                    searchText: $searchText
                )
            }
        }
    }
    
    func loadData() {
        do {
            let dwarfs: Set<Dwarf> = try database.fetchDwarfs()
            self.dwarfs = Array(dwarfs)
        } catch {
            print("Błąd wczytywania danych: \(error.localizedDescription)")
        }
    }
    
    func reloadNewData() {
        do {
            try database.reloadDatabase()
            loadData()
        } catch {
            print("Błąd ładowania nowych danych: \(error.localizedDescription)")
        }
    }
    
    func focusOnDwarf(_ dwarf: Dwarf) {
        withAnimation {
            region = MKCoordinateRegion(
                center: dwarf.coordinate2D,
                span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
            )
        }
    }
    
    func selectDwarf(_ dwarf: Dwarf) {
        if selectedDwarf?.id == dwarf.id {
            selectedDwarf = nil
        } else {
            selectedDwarf = dwarf
        }
    }
    
    func markAsVisited(_ dwarf: Dwarf) {
            let updatedDwarf = Dwarf(id: dwarf.id, name: dwarf.name, description: dwarf.description, coordinate: dwarf.coordinate, visited: true)
            database.markAsVisited(dwarfID: dwarf.id, visited: true)
        
            if let index = dwarfs.firstIndex(where: { $0.id == dwarf.id }) {
                dwarfs[index].visited.toggle()
            }
    }
}


struct DwarfListView: View {
    var dwarfs: [Dwarf]
    var onVisited: (Dwarf) -> Void
    var focusOnDwarf: (Dwarf) -> Void
    
    @State private var isSortedByVisited: Bool = false
        
    var sortedDwarfs: [Dwarf] {
        isSortedByVisited
            ? dwarfs.sorted { $0.visited && !$1.visited }
            : dwarfs
    }
    
    @Binding var searchText: String
    
    var body: some View {
        VStack {
            HStack {
                TextField("Szukaj krasnala...", text: $searchText)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    isSortedByVisited.toggle()
                }) {
                    Text(isSortedByVisited ? "Sortuj domyślnie" : "Sortuj według odwiedzenia")
                }
                .padding()
            }
            if sortedDwarfs.isEmpty {
                Text("Brak wyników wyszukiwania")
                    .foregroundColor(.gray)
                    .padding()
            }
            List(sortedDwarfs) { dwarf in
                HStack {
                    Text(dwarf.name)
                    Spacer()
                    Text(dwarf.visited ? "Odwiedzony" : "Nieodwiedzony")
                        .foregroundColor(dwarf.visited ? .green : .red)
                }
                .onTapGesture {
                    focusOnDwarf(dwarf)
                }
            }
        }
    }
}


#Preview {
    DwarfMapView()
}
