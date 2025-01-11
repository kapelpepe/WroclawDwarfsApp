//
//  DwarfDatabase.swift
//  WroclawDwarfs
//
//  Created by Kacper Gwiazda on 11/01/2025.
//

import Foundation
import SQLite

struct DwarfDatabase {
    private let db: Connection
    private let dwarfsTable = Table("dwarfs")
    private let id = Expression<String>("id")
    private let name = Expression<String>("name")
    private let description = Expression<String>("description")
    private let latitude = Expression<Double>("latitude")
    private let longitude = Expression<Double>("longitude")
    
    init() {
        // Lokalizacja bazy danych
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/dwarfs.sqlite3"
        
        do {
            db = try Connection(path)
            createTable()
        } catch {
            fatalError("Nie można połączyć się z bazą danych: \(error)")
        }
    }
    
    private let visited = Expression<Bool>("visited")

    private func createTable() {
        do {
            try db.run(dwarfsTable.create(ifNotExists: true) { table in
                table.column(id, primaryKey: true)
                table.column(name)
                table.column(description)
                table.column(latitude)
                table.column(longitude)
                table.column(visited, defaultValue: false) // Domyślnie nieodwiedzony
            })
        } catch {
            print("Błąd tworzenia tabeli: \(error)")
        }
    }
    
    func markAsVisited(dwarfID: String, visited: Bool) {
        let dwarf = dwarfsTable.filter(id == dwarfID)
        do {
            try db.run(dwarf.update(self.visited <- visited))
        } catch {
            print("Błąd aktualizacji odwiedzin: \(error)")
        }
    }
    
    func insertDwarfs(_ dwarfs: [Dwarf]) {
        do {
            for dwarf in dwarfs {
                let insert = dwarfsTable.insert(or: .replace,
                                                id <- dwarf.id,
                                                name <- dwarf.name,
                                                description <- dwarf.description,
                                                latitude <- dwarf.coordinate.latitude,
                                                longitude <- dwarf.coordinate.longitude)
                try db.run(insert)
            }
        } catch {
            print("Błąd dodawania danych: \(error)")
        }
    }
    
    func fetchDwarfs() -> [Dwarf] {
        var dwarfs = [Dwarf]()
        do {
            for row in try db.prepare(dwarfsTable) {
                let dwarf = Dwarf(
                    id: row[id],
                    name: row[name],
                    description: row[description],
                    coordinate: Dwarf.Coordinate(latitude: row[latitude], longitude: row[longitude]),
                    visited: row[visited]
                )
                dwarfs.append(dwarf)
            }
        } catch {
            print("Błąd wczytywania danych: \(error)")
        }
        return dwarfs
    }
    
    func loadInitialDataIfNeeded() {
        guard fetchDwarfs().isEmpty else { return }
        
        guard let url = Bundle.main.url(forResource: "dwarfs", withExtension: "json") else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let initialDwarfs = try decoder.decode([Dwarf].self, from: data)
            insertDwarfs(initialDwarfs)
        } catch {
            print("Błąd ładowania danych początkowych: \(error)")
        }
    }
}
