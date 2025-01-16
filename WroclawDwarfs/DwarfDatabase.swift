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
                table.column(visited, defaultValue: false)
            })
        } catch {
            print("Błąd tworzenia tabeli: \(error)")
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
    
    enum DwarfError: Error, LocalizedError { //Wlasny enum z definicjami bledow
        case databaseConnectionFailed
        case dataFetchFailed
        case dataInsertFailed
        case dataReloadFailed

        var errorDescription: String? {
            switch self {
            case .databaseConnectionFailed:
                return "Nie udało się połączyć z bazą danych."
            case .dataFetchFailed:
                return "Błąd podczas pobierania danych."
            case .dataInsertFailed:
                return "Błąd podczas dodawania danych."
            case .dataReloadFailed:
                return "Błąd podczas ładowania nowych danych."
            }
        }
    }
    
    func fetchDwarfs() throws -> Set<Dwarf> {
        var dwarfs = Set<Dwarf>()
        do {
            for row in try db.prepare(dwarfsTable) {
                let dwarf = Dwarf(
                    id: row[id],
                    name: row[name],
                    description: row[description],
                    coordinate: Dwarf.Coordinate(latitude: row[latitude], longitude: row[longitude]),
                    visited: row[visited] // Używamy wartości boolowskiej
                )
                dwarfs.insert(dwarf)
            }
        } catch {
            throw DwarfError.dataFetchFailed //Metoda throw
        }
        return dwarfs
    }
    
    func loadInitialDataIfNeeded() { //Funkcja posiada zaimplementowany blok do-catch
        do {
            let dwarfs = try fetchDwarfs()
            guard dwarfs.isEmpty else { return }
            
            guard let url = Bundle.main.url(forResource: "dwarfs", withExtension: "json") else { return }
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let initialDwarfs = try decoder.decode([Dwarf].self, from: data)
                insertDwarfs(initialDwarfs)
            } catch {
                print("Błąd ładowania danych początkowych: \(error.localizedDescription)")
            }
        } catch {
            print("Błąd wczytywania krasnali: \(error.localizedDescription)")
        }
    }
    
    func reloadDatabase() throws { //Funkcja posiada zaimplementowany blok do-catch
        guard let url = Bundle.main.url(forResource: "dwarfs", withExtension: "json") else {
            throw DwarfError.dataReloadFailed
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let initialDwarfs = try decoder.decode([Dwarf].self, from: data)
            try db.run(dwarfsTable.delete()) // Usuwanie danych
            insertDwarfs(initialDwarfs)
        } catch {
            throw DwarfError.dataReloadFailed
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
}
