import Foundation
import Combine
import CryptoKit // For MD5 hashing

class ArtistInfoService {
    static let shared = ArtistInfoService()
    
    private var cancellables = Set<AnyCancellable>()
    private var nameCache: [String: String] = [:] // Cache for artist names
    private var imageCache: [String: String] = [:] // Cache for artist images
    
    private init() {}
    
    // MARK: - Artist Details Model (simplified)
    
    struct ArtistDetails {
        let name: String
        let birthYear: String
        let deathYear: String
        let imageURL: String?
        let movements: [String]
        let nationality: String
        let biography: String
        
        // Default empty details
        static let empty = ArtistDetails(
            name: "Unknown Artist",
            birthYear: "Unknown",
            deathYear: "Unknown",
            imageURL: nil,
            movements: [],
            nationality: "Unknown",
            biography: ""
        )
    }
    
    // MARK: - Response Models
    
    struct WikidataEntityLabelResponse: Decodable {
        let entities: [String: WikidataEntityLabel]
        
        struct WikidataEntityLabel: Decodable {
            let labels: WikidataLabels?
            let descriptions: WikidataLabels?
            
            enum CodingKeys: String, CodingKey {
                case labels, descriptions
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                labels = try container.decodeIfPresent(WikidataLabels.self, forKey: .labels)
                descriptions = try container.decodeIfPresent(WikidataLabels.self, forKey: .descriptions)
            }
        }
        
        struct WikidataLabels: Decodable {
            let en: WikidataValue?
        }
        
        struct WikidataValue: Decodable {
            let language: String
            let value: String
        }
    }
    
    struct WikidataEntityResponse: Decodable {
        let entities: [String: WikidataEntity]
        
        struct WikidataEntity: Decodable {
            let claims: [String: [WikidataClaim]]?
            let labels: WikidataLabels?
            let descriptions: WikidataLabels?
            
            enum CodingKeys: String, CodingKey {
                case claims, labels, descriptions
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                claims = try container.decodeIfPresent([String: [WikidataClaim]].self, forKey: .claims)
                labels = try container.decodeIfPresent(WikidataLabels.self, forKey: .labels)
                descriptions = try container.decodeIfPresent(WikidataLabels.self, forKey: .descriptions)
            }
        }
        
        struct WikidataLabels: Decodable {
            let en: WikidataValue?
            
            init(en: WikidataValue?) {
                self.en = en
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                
                if let labels = try? container.decode([String: WikidataValue].self),
                   let enValue = labels["en"] {
                    en = enValue
                } else {
                    en = nil
                }
            }
        }
        
        struct WikidataValue: Decodable {
            let language: String
            let value: String
        }
        
        struct WikidataClaim: Decodable {
            let mainsnak: WikidataMainSnak
        }
        
        struct WikidataMainSnak: Decodable {
            let datavalue: WikidataDataValue?
        }
        
        struct WikidataDataValue: Decodable {
            // We'll use different value types for different cases
            let stringValue: String?
            let objectValue: [String: String]?
            
            enum CodingKeys: String, CodingKey {
                case value
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                // Try different approaches to decode the "value" field
                do {
                    // First try to decode as a String
                    stringValue = try container.decode(String.self, forKey: .value)
                    objectValue = nil
                } catch {
                    // If that fails, try as a dictionary of strings
                    do {
                        objectValue = try container.decode([String: String].self, forKey: .value)
                        stringValue = nil
                    } catch {
                        // If both approaches fail, set both to nil
                        stringValue = nil
                        objectValue = nil
                    }
                }
            }
            
            // Helper property to get the value as an Any type
            var value: Any? {
                return stringValue ?? objectValue
            }
        }
    }
    
    /// Get artist name from a Wikidata URL
    func getArtistName(from wikidataURL: String, completion: @escaping (String?) -> Void) {
        // Check cache first
        if let cachedName = nameCache[wikidataURL] {
            completion(cachedName)
            return
        }
        
        // Extract the entity ID from the URL
        guard let entityId = extractEntityId(from: wikidataURL) else {
            completion(nil)
            return
        }
        
        // Construct the API URL
        let apiURL = "https://www.wikidata.org/w/api.php?action=wbgetentities&ids=\(entityId)&format=json&props=labels&languages=en&origin=*"
        
        guard let url = URL(string: apiURL) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WikidataEntityLabelResponse.self, decoder: JSONDecoder())
            .sink { result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    print("Error fetching artist name: \(error)")
                    completion(nil)
                }
            } receiveValue: { [weak self] response in
                if let entity = response.entities[entityId],
                   let label = entity.labels?.en?.value {
                    // Cache the result
                    self?.nameCache[wikidataURL] = label
                    completion(label)
                } else {
                    // If no label found, use the entity ID as fallback
                    let fallbackName = "Artist \(entityId)"
                    self?.nameCache[wikidataURL] = fallbackName
                    completion(fallbackName)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Get artist image URL from Wikidata (simplified and more robust)
    func getArtistImageURL(from wikidataURL: String, completion: @escaping (String?) -> Void) {
        // Check cache first
        if let cachedImageURL = imageCache[wikidataURL] {
            completion(cachedImageURL)
            return
        }
        
        // Extract the entity ID from the URL
        guard let entityId = extractEntityId(from: wikidataURL) else {
            completion(nil)
            return
        }
        
        // Construct the API URL to get the image property (P18)
        let apiURL = "https://www.wikidata.org/w/api.php?action=wbgetentities&ids=\(entityId)&format=json&props=claims&origin=*"
        
        guard let url = URL(string: apiURL) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .sink { result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    print("Error fetching artist image: \(error)")
                    completion(nil)
                }
            } receiveValue: { [weak self] data in
                // Manually parse JSON to be more robust
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let entities = json["entities"] as? [String: Any],
                   let entity = entities[entityId] as? [String: Any],
                   let claims = entity["claims"] as? [String: Any],
                   let imageClaims = claims["P18"] as? [[String: Any]],
                   !imageClaims.isEmpty,
                   let firstClaim = imageClaims.first,
                   let mainsnak = firstClaim["mainsnak"] as? [String: Any],
                   let datavalue = mainsnak["datavalue"] as? [String: Any],
                   let value = datavalue["value"] as? String {
                    
                    // Use Wikimedia API for the image
                    let encodedImageName = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                    let imageURL = "https://commons.wikimedia.org/wiki/Special:FilePath/\(encodedImageName)?width=300"
                    
                    // Cache the result
                    self?.imageCache[wikidataURL] = imageURL
                    completion(imageURL)
                } else {
                    completion(nil)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Get detailed artist information from Wikidata
    func getArtistDetails(from wikidataURL: String, completion: @escaping (ArtistDetails?) -> Void) {
        // Extract the entity ID
        guard let entityId = extractEntityId(from: wikidataURL) else {
            completion(nil)
            return
        }
        
        // Construct the API URL to get multiple properties
        let apiURL = "https://www.wikidata.org/w/api.php?action=wbgetentities&ids=\(entityId)&format=json&props=claims|labels|descriptions&languages=en&origin=*"
        
        guard let url = URL(string: apiURL) else {
            completion(nil)
            return
        }
        
        // First get the name so we have at least that
        getArtistName(from: wikidataURL) { [weak self] name in
            guard let self = self else { return }
            
            // Now get the image
            self.getArtistImageURL(from: wikidataURL) { imageURL in
                // Fetch full Wikidata details using manual JSON parsing for robustness
                URLSession.shared.dataTask(with: url) { data, response, error in
                    guard let data = data else {
                        DispatchQueue.main.async {
                            // Create minimal details with just name and image
                            let details = ArtistDetails(
                                name: name ?? "Unknown Artist",
                                birthYear: "Unknown",
                                deathYear: "Unknown",
                                imageURL: imageURL,
                                movements: [],
                                nationality: "Unknown",
                                biography: ""
                            )
                            completion(details)
                        }
                        return
                    }
                    
                    // Parse the JSON manually for more control
                    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let entities = json["entities"] as? [String: Any],
                          let entity = entities[entityId] as? [String: Any] else {
                        DispatchQueue.main.async {
                            let details = ArtistDetails(
                                name: name ?? "Unknown Artist",
                                birthYear: "Unknown",
                                deathYear: "Unknown",
                                imageURL: imageURL,
                                movements: [],
                                nationality: "Unknown",
                                biography: ""
                            )
                            completion(details)
                        }
                        return
                    }
                    
                    // Extract description
                    var biography = ""
                    if let descriptions = entity["descriptions"] as? [String: Any],
                       let enDesc = descriptions["en"] as? [String: Any],
                       let value = enDesc["value"] as? String {
                        biography = value
                    }
                    
                    // Get claims which contain all the detailed info
                    guard let claims = entity["claims"] as? [String: Any] else {
                        DispatchQueue.main.async {
                            let details = ArtistDetails(
                                name: name ?? "Unknown Artist",
                                birthYear: "Unknown",
                                deathYear: "Unknown",
                                imageURL: imageURL,
                                movements: [],
                                nationality: "Unknown",
                                biography: biography
                            )
                            completion(details)
                        }
                        return
                    }
                    
                    // Extract birth year (P569)
                    var birthYear = "Unknown"
                    if let birthClaims = claims["P569"] as? [[String: Any]],
                       let firstBirthClaim = birthClaims.first,
                       let mainsnak = firstBirthClaim["mainsnak"] as? [String: Any],
                       let datavalue = mainsnak["datavalue"] as? [String: Any],
                       let value = datavalue["value"] as? [String: Any],
                       let time = value["time"] as? String {
                        // Format: +YYYY-MM-DDT00:00:00Z
                        if let year = self.extractYear(from: time) {
                            birthYear = year
                        }
                    }
                    
                    // Extract death year (P570)
                    var deathYear = "Unknown"
                    if let deathClaims = claims["P570"] as? [[String: Any]],
                       let firstDeathClaim = deathClaims.first,
                       let mainsnak = firstDeathClaim["mainsnak"] as? [String: Any],
                       let datavalue = mainsnak["datavalue"] as? [String: Any],
                       let value = datavalue["value"] as? [String: Any],
                       let time = value["time"] as? String {
                        // Format: +YYYY-MM-DDT00:00:00Z
                        if let year = self.extractYear(from: time) {
                            deathYear = year
                        }
                    } else if birthYear != "Unknown" {
                        // If no death date but we have birth date, might still be alive
                        deathYear = "Present"
                    }
                    
                    // Extract nationality (P27)
                    var nationality = "Unknown"
                    if let countryClaims = claims["P27"] as? [[String: Any]],
                       let firstCountryClaim = countryClaims.first,
                       let mainsnak = firstCountryClaim["mainsnak"] as? [String: Any],
                       let datavalue = mainsnak["datavalue"] as? [String: Any],
                       let value = datavalue["value"] as? [String: Any],
                       let countryId = value["id"] as? String {
                        // Get country name from ID
                        self.getEntityLabel(entityId: countryId) { countryName in
                            nationality = countryName ?? "Unknown"
                            
                            // Extract art movements (P135)
                            var movements: [String] = []
                            if let movementClaims = claims["P135"] as? [[String: Any]] {
                                let movementIds = movementClaims.compactMap { claim -> String? in
                                    guard let mainsnak = claim["mainsnak"] as? [String: Any],
                                          let datavalue = mainsnak["datavalue"] as? [String: Any],
                                          let value = datavalue["value"] as? [String: Any],
                                          let id = value["id"] as? String else {
                                        return nil
                                    }
                                    return id
                                }
                                
                                // Create dispatch group to wait for all movement names
                                let group = DispatchGroup()
                                for id in movementIds {
                                    group.enter()
                                    self.getEntityLabel(entityId: id) { movementName in
                                        if let name = movementName {
                                            movements.append(name)
                                        }
                                        group.leave()
                                    }
                                }
                                
                                group.notify(queue: .main) {
                                    // Create artist details with all the data
                                    let details = ArtistDetails(
                                        name: name ?? "Unknown Artist",
                                        birthYear: birthYear,
                                        deathYear: deathYear,
                                        imageURL: imageURL,
                                        movements: movements,
                                        nationality: nationality,
                                        biography: biography
                                    )
                                    completion(details)
                                }
                            } else {
                                // No movements found, create details without waiting
                                DispatchQueue.main.async {
                                    let details = ArtistDetails(
                                        name: name ?? "Unknown Artist",
                                        birthYear: birthYear,
                                        deathYear: deathYear,
                                        imageURL: imageURL,
                                        movements: movements,
                                        nationality: nationality,
                                        biography: biography
                                    )
                                    completion(details)
                                }
                            }
                        }
                    } else {
                        // No nationality found
                        DispatchQueue.main.async {
                            let details = ArtistDetails(
                                name: name ?? "Unknown Artist",
                                birthYear: birthYear,
                                deathYear: deathYear,
                                imageURL: imageURL,
                                movements: [],
                                nationality: "Unknown",
                                biography: biography
                            )
                            completion(details)
                        }
                    }
                }.resume()
            }
        }
    }
    
    /// Helper to extract year from Wikidata time format
    private func extractYear(from timeString: String) -> String? {
        // Format: +YYYY-MM-DDT00:00:00Z
        let components = timeString.components(separatedBy: "-")
        if components.count > 0 {
            var yearString = components[0].replacingOccurrences(of: "+", with: "")
            yearString = yearString.trimmingCharacters(in: .whitespaces)
            return yearString
        }
        return nil
    }
    
    /// Get entity label (name) by ID
    func getEntityLabel(entityId: String, completion: @escaping (String?) -> Void) {
        let apiURL = "https://www.wikidata.org/w/api.php?action=wbgetentities&ids=\(entityId)&format=json&props=labels&languages=en&origin=*"
        
        guard let url = URL(string: apiURL) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let entities = json["entities"] as? [String: Any],
                  let entity = entities[entityId] as? [String: Any],
                  let labels = entity["labels"] as? [String: Any],
                  let enLabel = labels["en"] as? [String: Any],
                  let value = enLabel["value"] as? String else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(value)
            }
        }.resume()
    }
    
    /// Extract entity ID from a Wikidata URL
    private func extractEntityId(from url: String) -> String? {
        // Handle both https://www.wikidata.org/wiki/Q123456 and Q123456 formats
        if url.contains("/wiki/") {
            if let range = url.range(of: "/wiki/") {
                let id = String(url[range.upperBound...])
                return id.components(separatedBy: "/").first // Handle any trailing slashes
            }
        } else if url.hasPrefix("Q") {
            // Already an entity ID
            return url
        }
        return nil
    }
}
