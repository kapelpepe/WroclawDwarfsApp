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
    @State private var searchText: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let database = DwarfDatabase()
    
    var filteredDwarfs: [Dwarf] {
        if searchText.isEmpty {
            return dwarfs
        } else {
            return dwarfs.filter { $0.name.lowercased().contains(searchText.lowercased()) }
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
                                    .padding(5)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(radius: 5)
                                }
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(radius: 5)
                                .offset(y: -105)
                                .animation(.easeInOut(duration: 0.3), value: selectedDwarf)
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
                .navigationTitle("Mapa Krasnali")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Krasnale") {
                            showDwarfsList.toggle()
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Załaduj Nowe Krasnale") {
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
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Informacja"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
    @Binding var searchText: String
    
    var body: some View {
        VStack {
            TextField("Szukaj krasnala...", text: $searchText)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            if dwarfs.isEmpty {
                Text("Brak wyników wyszukiwania")
                    .foregroundColor(.gray)
                    .padding()
            }
            List(dwarfs) { dwarf in
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
