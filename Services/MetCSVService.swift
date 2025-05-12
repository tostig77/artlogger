//
//  MetCSVService.swift
//  artlogger
//
//  Created by Me on 5/12/25.
//


import Foundation

class MetCSVService {
    private var artworks: [MetArtwork] = []
    private var isLoaded = false
    
    // Singleton instance
    static let shared = MetCSVService()
    
    private init() {}
    
    // Load the CSV file
    func loadCSV(completion: @escaping (Bool, String?) -> Void) {
        // Check if already loaded
        if isLoaded {
            completion(true, nil)
            return
        }
        
        // Get the path to the CSV file
        if let path = Bundle.main.path(forResource: "met_database", ofType: "csv") {
            do {
                // Read the CSV file
                let csvString = try String(contentsOfFile: path, encoding: .utf8)
                
                // Parse the CSV
                artworks = parseCSV(csvString)
                isLoaded = true
                completion(true, nil)
            } catch {
                completion(false, "Failed to read CSV file: \(error.localizedDescription)")
            }
        } else {
            completion(false, "Met database CSV file not found")
        }
    }
    
    // Parse the CSV content into MetArtwork objects
    private func parseCSV(_ csvString: String) -> [MetArtwork] {
        var artworks: [MetArtwork] = []
        
        // Split the CSV into lines
        let lines = csvString.components(separatedBy: "\n")
        
        // Skip the header line
        guard lines.count > 1 else { return [] }
        
        // Process each line (starting from index 1 to skip the header)
        for i in 1..<lines.count {
            let line = lines[i]
            if line.isEmpty { continue }
            
            // Parse the CSV line
            // Note: This is a simplistic approach. For production, use a more robust CSV parser
            let fields = parseCSVLine(line)
            
            // Skip if we don't have enough fields
            guard fields.count >= 42 else { continue }
            
            // Create a MetArtwork from the parsed fields
            let artwork = MetArtwork(
                id: fields[3],
                objectNumber: fields[0],
                isHighlight: fields[1].lowercased() == "true",
                isPublicDomain: fields[2].lowercased() == "true",
                department: fields[4],
                objectName: fields[5],
                title: fields[6],
                culture: fields[7],
                period: fields[8],
                dynasty: fields[9],
                reign: fields[10],
                portfolio: fields[11],
                artistRole: fields[12],
                artistPrefix: fields[13],
                artistDisplayName: fields[14],
                artistDisplayBio: fields[15],
                artistSuffix: fields[16],
                artistAlphaSort: fields[17],
                artistNationality: fields[18],
                artistBeginDate: fields[19],
                artistEndDate: fields[20],
                objectDate: fields[21],
                objectBeginDate: fields[22],
                objectEndDate: fields[23],
                medium: fields[24],
                dimensions: fields[25],
                creditLine: fields[26],
                geographyType: fields[27],
                city: fields[28],
                state: fields[29],
                county: fields[30],
                country: fields[31],
                region: fields[32],
                subregion: fields[33],
                locale: fields[34],
                locus: fields[35],
                excavation: fields[36],
                river: fields[37],
                classification: fields[38],
                rightsAndReproduction: fields[39],
                linkResource: fields[40],
                metadataDate: fields[41],
                repository: fields.count > 42 ? fields[42] : ""
            )
            
            artworks.append(artwork)
        }
        
        return artworks
    }
    
    // Helper method to properly parse CSV lines (handling commas inside quotes)
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        // Add the last field
        fields.append(currentField)
        
        return fields
    }
    
    // Search for artworks matching a query
    func searchArtworks(query: String) -> [MetArtwork] {
        guard !query.isEmpty else { return [] }
        
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return artworks.filter { artwork in
            artwork.title.lowercased().contains(normalizedQuery) ||
            artwork.artistDisplayName.lowercased().contains(normalizedQuery) ||
            artwork.objectName.lowercased().contains(normalizedQuery) ||
            artwork.department.lowercased().contains(normalizedQuery)
        }
    }
    
    // Get a specific artwork by ID
    func getArtwork(id: String) -> MetArtwork? {
        return artworks.first { $0.id == id }
    }
    
    // Get count of loaded artworks
    func getArtworkCount() -> Int {
        return artworks.count
    }
}
