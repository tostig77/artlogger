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
            let labels: WikidataLabels
            let descriptions: WikidataLabels?
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
            let claims: [String: [WikidataClaim]]
            let labels: WikidataLabels
            let descriptions: WikidataLabels
            
            enum CodingKeys: String, CodingKey {
                case claims
                case labels
                case descriptions
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                claims = try container.decode([String: [WikidataClaim]].self, forKey: .claims)
                labels = try container.decode(WikidataLabels.self, forKey: .labels)
                
                if let descriptions = try? container.decode(WikidataLabels.self, forKey: .descriptions) {
                    self.descriptions = descriptions
                } else {
                    self.descriptions = WikidataLabels(en: nil)
                }
            }
        }
        
        struct WikidataLabels: Decodable {
            let en: WikidataValue?
            
            init(en: WikidataValue?) {
                self.en = en
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
                case .failure(_):
                    completion(nil)
                }
            } receiveValue: { [weak self] response in
                if let entity = response.entities[entityId],
                   let label = entity.labels.en?.value {
                    // Cache the result
                    self?.nameCache[wikidataURL] = label
                    completion(label)
                } else {
                    completion(nil)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Get artist image URL from Wikidata (simplified)
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
            .decode(type: WikidataEntityResponse.self, decoder: JSONDecoder())
            .sink { result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    print("Error decoding: \(error)")
                    completion(nil)
                }
            } receiveValue: { [weak self] response in
                if let entity = response.entities[entityId],
                   let imageClaims = entity.claims["P18"], // P18 is the property for image
                   let firstClaim = imageClaims.first,
                   let datavalue = firstClaim.mainsnak.datavalue,
                   let imageName = datavalue.stringValue {
                    
                    // Use a more reliable approach for Wikimedia image URLs
                    // Directly use Wikimedia API
                    let imageURL = "https://commons.wikimedia.org/wiki/Special:FilePath/\(imageName)?width=300"
                    
                    // Cache the result
                    self?.imageCache[wikidataURL] = imageURL
                    completion(imageURL)
                } else {
                    completion(nil)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Get basic artist details from Wikidata (simplified)
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
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WikidataEntityResponse.self, decoder: JSONDecoder())
            .sink { result in
                switch result {
                case .finished:
                    break
                case .failure(_):
                    completion(nil)
                }
            } receiveValue: { response in
                guard let entity = response.entities[entityId] else {
                    completion(nil)
                    return
                }
                
                // Extract artist name
                let name = entity.labels.en?.value ?? "Unknown Artist"
                
                // Extract birth year (P569)
                var birthYear = "Unknown"
                if let birthClaims = entity.claims["P569"],
                   let birthClaim = birthClaims.first,
                   let birthDataValue = birthClaim.mainsnak.datavalue,
                   let birthObject = birthDataValue.objectValue,
                   let time = birthObject["time"] {
                    // Format: +YYYY-MM-DDT00:00:00Z
                    let components = time.components(separatedBy: "-")
                    if components.count > 0 {
                        let yearString = components[0].replacingOccurrences(of: "+", with: "")
                        birthYear = yearString
                    }
                }
                
                // Extract death year (P570)
                var deathYear = "Unknown"
                if let deathClaims = entity.claims["P570"],
                   let deathClaim = deathClaims.first,
                   let deathDataValue = deathClaim.mainsnak.datavalue,
                   let deathObject = deathDataValue.objectValue,
                   let time = deathObject["time"] {
                    let components = time.components(separatedBy: "-")
                    if components.count > 0 {
                        let yearString = components[0].replacingOccurrences(of: "+", with: "")
                        deathYear = yearString
                    }
                } else if birthYear != "Unknown" {
                    // If no death date but we have birth date, might still be alive
                    deathYear = "Present"
                }
                
                // Extract image URL (P18)
                var imageURL: String? = nil
                if let imageClaims = entity.claims["P18"],
                   let imageClaim = imageClaims.first,
                   let imageDataValue = imageClaim.mainsnak.datavalue,
                   let imageName = imageDataValue.stringValue {
                    
                    // Use a more reliable approach for Wikimedia image URLs
                    // Directly use Wikimedia API
                    imageURL = "https://commons.wikimedia.org/wiki/Special:FilePath/\(imageName)?width=300"
                }
                
                // Extract movements (P135) - simplified approach
                var movements: [String] = []
                // In a real app, we'd fetch movement names, but for simplicity we'll skip that
                
                // Extract biography from description
                let biography = entity.descriptions.en?.value ?? ""
                
                // Create artist details
                let details = ArtistDetails(
                    name: name,
                    birthYear: birthYear,
                    deathYear: deathYear,
                    imageURL: imageURL,
                    movements: movements,
                    nationality: "Unknown", // Simplified
                    biography: biography
                )
                
                completion(details)
            }
            .store(in: &cancellables)
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
