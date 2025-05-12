//
//  ArtistIdentificationService.swift
//  artlogger
//
//  Created by Me on 5/12/25.
//


import Foundation
import Combine

class ArtistIdentificationService {
    static let shared = ArtistIdentificationService()
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // Lookup URLs for an artist by name
    func lookupArtistURLs(artistName: String, completion: @escaping (String?, String?) -> Void) {
        // Don't attempt lookup for empty artist names
        guard !artistName.isEmpty else {
            completion(nil, nil)
            return
        }
        
        // Prepare the search query
        let formattedName = artistName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchURL = "https://www.wikidata.org/w/api.php?action=wbsearchentities&search=\(formattedName)&language=en&format=json&limit=1&type=item&origin=*"
        
        // First search for the artist on Wikidata
        guard let url = URL(string: searchURL) else {
            completion(nil, nil)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WikidataSearchResponse.self, decoder: JSONDecoder())
            .sink { result in
                switch result {
                case .finished:
                    break
                case .failure(_):
                    // If search fails, return nil for both URLs
                    completion(nil, nil)
                }
            } receiveValue: { response in
                // If we found a matching entity
                if let firstResult = response.search.first {
                    let wikidataURL = "https://www.wikidata.org/wiki/\(firstResult.id)"
                    
                    // Now fetch the detailed entity to try to find ULAN URL
                    self.fetchEntityDetails(entityId: firstResult.id) { ulanURL in
                        completion(wikidataURL, ulanURL)
                    }
                } else {
                    completion(nil, nil)
                }
            }
            .store(in: &cancellables)
    }
    
    // Fetch entity details to find ULAN URL
    private func fetchEntityDetails(entityId: String, completion: @escaping (String?) -> Void) {
        let detailsURL = "https://www.wikidata.org/w/api.php?action=wbgetentities&ids=\(entityId)&format=json&props=claims&origin=*"
        
        guard let url = URL(string: detailsURL) else {
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
                if let entity = response.entities[entityId],
                   let ulanClaims = entity.claims["P245"], // P245 is the property for ULAN ID
                   let firstClaim = ulanClaims.first,
                   let ulanId = firstClaim.mainsnak.datavalue?.value as? String {
                    // Construct the ULAN URL from the ID
                    let ulanURL = "http://vocab.getty.edu/ulan/\(ulanId)"
                    completion(ulanURL)
                } else {
                    completion(nil)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Response Models

struct WikidataSearchResponse: Decodable {
    let search: [WikidataSearchResult]
    
    struct WikidataSearchResult: Decodable {
        let id: String
        let label: String
        let description: String?
    }
}

struct WikidataEntityResponse: Decodable {
    let entities: [String: WikidataEntity]
    
    struct WikidataEntity: Decodable {
        let claims: [String: [WikidataClaim]]
    }
    
    struct WikidataClaim: Decodable {
        let mainsnak: WikidataMainSnak
    }
    
    struct WikidataMainSnak: Decodable {
        let datavalue: WikidataDataValue?
    }
    
    struct WikidataDataValue: Decodable {
        let value: Any
        
        private enum CodingKeys: String, CodingKey {
            case value
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Try to decode as string first
            if let stringValue = try? container.decode(String.self, forKey: .value) {
                value = stringValue
            } else if let intValue = try? container.decode(Int.self, forKey: .value) {
                value = intValue
            } else if let dictValue = try? container.decode([String: String].self, forKey: .value) {
                value = dictValue
            } else {
                // Fallback to empty string if other types
                value = ""
            }
        }
    }
}
