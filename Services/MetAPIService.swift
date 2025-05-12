import Foundation
import Combine

class MetAPIService {
    static let shared = MetAPIService()
    
    private let baseURL = "https://collectionapi.metmuseum.org/public/collection/v1"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // Fetch artwork details by object ID
    func fetchArtworkDetails(objectID: String, completion: @escaping (Result<MetAPIArtworkResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/objects/\(objectID)") else {
            completion(.failure(NSError(domain: "MetAPIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: MetAPIArtworkResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    completion(.failure(error))
                }
            } receiveValue: { response in
                completion(.success(response))
            }
            .store(in: &cancellables)
    }
    
    // Enrich a MetArtwork with image details from the API
    func enrichMetArtwork(_ artwork: MetArtwork, completion: @escaping (Result<MetArtwork, Error>) -> Void) {
        fetchArtworkDetails(objectID: artwork.id) { result in
            switch result {
            case .success(let response):
                var updatedArtwork = artwork
                updatedArtwork.primaryImageSmall = response.primaryImageSmall
                updatedArtwork.primaryImageLarge = response.primaryImage
                updatedArtwork.additionalImages = response.additionalImages
                completion(.success(updatedArtwork))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// Response model for the Met API
struct MetAPIArtworkResponse: Codable {
    let objectID: Int
    let isHighlight: Bool
    let accessionNumber: String
    let isPublicDomain: Bool
    let primaryImage: String
    let primaryImageSmall: String
    let additionalImages: [String]
    let constituents: [MetAPIConstituent]?
    let department: String
    let objectName: String
    let title: String
    let culture: String
    let period: String
    let dynasty: String
    let reign: String
    let portfolio: String
    let artistRole: String
    let artistPrefix: String
    let artistDisplayName: String
    let artistDisplayBio: String
    let artistSuffix: String
    let artistAlphaSort: String
    let artistNationality: String
    let artistBeginDate: String
    let artistEndDate: String
    let artistGender: String?
    let artistULAN_URL: String?
    let artistWikidata_URL: String?
    let objectDate: String
    let objectBeginDate: Int
    let objectEndDate: Int
    let medium: String
    let dimensions: String
    let creditLine: String
    let geographyType: String
    let city: String
    let state: String
    let county: String
    let country: String
    let region: String
    let subregion: String
    let locale: String
    let locus: String
    let excavation: String
    let river: String
    let classification: String
    let rightsAndReproduction: String
    let linkResource: String
    let objectURL: String
    let objectWikidata_URL: String?
    let metadataDate: String
    let repository: String
    let tags: [MetAPITag]?
    
    struct MetAPIConstituent: Codable {
        let constituentID: Int
        let role: String
        let name: String
        let constituentULAN_URL: String?
        let constituentWikidata_URL: String?
        let gender: String?
    }
    
    struct MetAPITag: Codable {
        let term: String
        let AAT_URL: String?
        let Wikidata_URL: String?
    }
}
