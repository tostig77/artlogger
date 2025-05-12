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
            let fields = parseCSVLine(line)
            
            // Skip if we don't have enough fields (should have at least 53 fields)
            guard fields.count >= 53 else { continue }
            
            // Create a MetArtwork from the parsed fields
            // Field indices are based on the new CSV structure
            let artwork = MetArtwork(
                id: fields[4],                                      // Object ID (index 4)
                objectNumber: fields[0],                            // Object Number (index 0)
                isHighlight: fields[1].lowercased() == "true",      // Is Highlight (index 1)
                isTimelineWork: fields[2].lowercased() == "true",   // Is Timeline Work (index 2)
                isPublicDomain: fields[3].lowercased() == "true",   // Is Public Domain (index 3)
                galleryNumber: fields[5],                           // Gallery Number (index 5)
                department: fields[6],                              // Department (index 6)
                accessionYear: fields[7],                           // Accession Year (index 7)
                objectName: fields[8],                              // Object Name (index 8)
                title: fields[9],                                   // Title (index 9)
                culture: fields[10],                                // Culture (index 10)
                period: fields[11],                                 // Period (index 11)
                dynasty: fields[12],                                // Dynasty (index 12)
                reign: fields[13],                                  // Reign (index 13)
                portfolio: fields[14],                              // Portfolio (index 14)
                constituentID: fields[15],                          // Constituent ID (index 15)
                artistRole: fields[16],                             // Artist Role (index 16)
                artistPrefix: fields[17],                           // Artist Prefix (index 17)
                artistDisplayName: fields[18],                      // Artist Display Name (index 18)
                artistDisplayBio: fields[19],                       // Artist Display Bio (index 19)
                artistSuffix: fields[20],                           // Artist Suffix (index 20)
                artistAlphaSort: fields[21],                        // Artist Alpha Sort (index 21)
                artistNationality: fields[22],                      // Artist Nationality (index 22)
                artistBeginDate: fields[23],                        // Artist Begin Date (index 23)
                artistEndDate: fields[24],                          // Artist End Date (index 24)
                artistGender: fields[25],                           // Artist Gender (index 25)
                artistULANURL: fields[26],                          // Artist ULAN URL (index 26)
                artistWikidataURL: fields[27],                      // Artist Wikidata URL (index 27)
                objectDate: fields[28],                             // Object Date (index 28)
                objectBeginDate: fields[29],                        // Object Begin Date (index 29)
                objectEndDate: fields[30],                          // Object End Date (index 30)
                medium: fields[31],                                 // Medium (index 31)
                dimensions: fields[32],                             // Dimensions (index 32)
                creditLine: fields[33],                             // Credit Line (index 33)
                geographyType: fields[34],                          // Geography Type (index 34)
                city: fields[35],                                   // City (index 35)
                state: fields[36],                                  // State (index 36)
                county: fields[37],                                 // County (index 37)
                country: fields[38],                                // Country (index 38)
                region: fields[39],                                 // Region (index 39)
                subregion: fields[40],                              // Subregion (index 40)
                locale: fields[41],                                 // Locale (index 41)
                locus: fields[42],                                  // Locus (index 42)
                excavation: fields[43],                             // Excavation (index 43)
                river: fields[44],                                  // River (index 44)
                classification: fields[45],                         // Classification (index 45)
                rightsAndReproduction: fields[46],                  // Rights and Reproduction (index 46)
                linkResource: fields[47],                           // Link Resource (index 47)
                objectWikidataURL: fields[48],                      // Object Wikidata URL (index 48)
                metadataDate: fields[49],                           // Metadata Date (index 49)
                repository: fields[50],                             // Repository (index 50)
                tags: fields[51],                                   // Tags (index 51)
                tagsAATURL: fields[52],                             // Tags AAT URL (index 52)
                tagsWikidataURL: fields.count > 53 ? fields[53] : "" // Tags Wikidata URL (index 53)
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
            artwork.department.lowercased().contains(normalizedQuery) ||
            artwork.classification.lowercased().contains(normalizedQuery) ||
            artwork.tags.lowercased().contains(normalizedQuery)  // Added tags to search
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
