import SwiftUI

struct ArtistDetailView: View {
    let artistUrl: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var artistDetails: ArtistInfoService.ArtistDetails?
    @State private var wikipediaBio: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading {
                    loadingView
                } else {
                    // Artist Image
                    artistImageView
                    
                    // Artist Name and Lifespan
                    artistHeaderView
                    
                    Divider()
                    
                    // Artist Information Card
                    artistInfoCard
                    
                    // Biography
                    biographySection
                    
                    // Source Links
                    sourceLinksSection
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Artist")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadArtistDetails()
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Loading artist information...")
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(height: 200)
    }
    
    private var artistImageView: some View {
        Group {
            if let details = artistDetails, let imageURL = details.imageURL {
                AsyncArtworkImage(urlString: imageURL) {
                    // Fallback for when image is loading or failed
                    defaultArtistImage
                }
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 300)
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                // Generic placeholder for artist without image
                defaultArtistImage
                    .padding(.horizontal)
            }
        }
    }
    
    private var defaultArtistImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)
            
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
        }
    }
    
    private var artistHeaderView: some View {
        VStack(alignment: .center, spacing: 8) {
            // Show artist name
            Text(artistDetails?.name ?? "Artist")
                .font(.custom("Georgia", size: 34))
                .fontWeight(.bold)
                .foregroundColor(Color(.darkGray))
                .multilineTextAlignment(.center)
            
            // Show years if available
            if let details = artistDetails,
               details.birthYear != "Unknown" || details.deathYear != "Unknown" {
                Text("\(details.birthYear) - \(details.deathYear)")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // Show nationality if available
            if let details = artistDetails,
               details.nationality != "Unknown" {
                Text(details.nationality)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
    
    private var artistInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Artist Information")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Info Card
            VStack(alignment: .leading, spacing: 12) {
                if let details = artistDetails {
                    // Birth info
                    if details.birthYear != "Unknown" {
                        infoRow(title: "Born:", value: details.birthYear)
                    }
                    
                    // Death info
                    if details.deathYear != "Unknown" && details.deathYear != "Present" {
                        infoRow(title: "Died:", value: details.deathYear)
                    } else if details.deathYear == "Present" {
                        infoRow(title: "Status:", value: "Living")
                    }
                    
                    // Nationality
                    if details.nationality != "Unknown" {
                        infoRow(title: "Country:", value: details.nationality)
                    }
                    
                    // Movements
                    if !details.movements.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Movements:")
                                .font(.headline)
                            
                            ForEach(details.movements, id: \.self) { movement in
                                Text("• \(movement)")
                                    .padding(.leading, 8)
                            }
                        }
                    }
                } else {
                    Text("No information available")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .frame(minHeight: 100)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var biographySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Biography")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Biography content - show either Wikipedia or Wikidata description
            if !wikipediaBio.isEmpty {
                Text(wikipediaBio)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let details = artistDetails, !details.biography.isEmpty {
                Text(details.biography)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No biography available for this artist.")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }
    
    private var sourceLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sources")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Link(destination: URL(string: artistUrl)!) {
                    HStack {
                        Image(systemName: "link")
                        Text("View on Wikidata")
                            .underline()
                    }
                    .foregroundColor(.blue)
                }
                
                if let wikipediaUrl = getWikipediaUrl(from: artistUrl) {
                    Link(destination: URL(string: wikipediaUrl)!) {
                        HStack {
                            Image(systemName: "book.fill")
                            Text("View on Wikipedia")
                                .underline()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 16)
    }
    
    // Helper function to create an info row
    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.headline)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.body)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadArtistDetails() {
        isLoading = true
        
        // Get enhanced artist details
        getEnhancedArtistDetails(from: artistUrl) { details, bio in
            DispatchQueue.main.async {
                self.artistDetails = details
                self.wikipediaBio = bio ?? ""
                self.isLoading = false
            }
        }
    }
    
    // Get enhanced artist details with Wikipedia biography
    private func getEnhancedArtistDetails(from wikidataUrl: String, completion: @escaping (ArtistInfoService.ArtistDetails?, String?) -> Void) {
        // First get basic details from Wikidata
        ArtistInfoService.shared.getArtistDetails(from: wikidataUrl) { details in
            // Then try to fetch Wikipedia bio
            if let details = details {
                // Extract entity ID for Wikipedia lookup
                if let entityId = self.extractEntityId(from: wikidataUrl) {
                    self.fetchWikipediaBio(for: entityId) { biography in
                        completion(details, biography)
                    }
                } else {
                    completion(details, nil)
                }
            } else {
                completion(nil, nil)
            }
        }
    }
    
    // Helper to extract entity ID from Wikidata URL
    private func extractEntityId(from url: String) -> String? {
        if url.contains("/wiki/") {
            if let range = url.range(of: "/wiki/") {
                let id = String(url[range.upperBound...])
                return id.components(separatedBy: "/").first
            }
        } else if url.hasPrefix("Q") {
            return url
        }
        return nil
    }
    
    // Fetch Wikipedia biography
    private func fetchWikipediaBio(for entityId: String, completion: @escaping (String?) -> Void) {
        // First get the Wikipedia article title from Wikidata
        let sitelinkUrl = "https://www.wikidata.org/w/api.php?action=wbgetentities&ids=\(entityId)&format=json&props=sitelinks&sitefilter=enwiki&origin=*"
        
        guard let url = URL(string: sitelinkUrl) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let entities = json["entities"] as? [String: Any],
                  let entity = entities[entityId] as? [String: Any],
                  let sitelinks = entity["sitelinks"] as? [String: Any],
                  let enwiki = sitelinks["enwiki"] as? [String: Any],
                  let title = enwiki["title"] as? String else {
                completion(nil)
                return
            }
            
            // Now fetch the Wikipedia extract
            let extractUrl = "https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&exintro=1&explaintext=1&titles=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title)&origin=*"
            
            guard let wikipediaUrl = URL(string: extractUrl) else {
                completion(nil)
                return
            }
            
            URLSession.shared.dataTask(with: wikipediaUrl) { data, response, error in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let query = json["query"] as? [String: Any],
                      let pages = query["pages"] as? [String: Any] else {
                    completion(nil)
                    return
                }
                
                // Get the first page (there should only be one)
                if let page = pages.values.first as? [String: Any],
                   let extract = page["extract"] as? String {
                    completion(extract)
                } else {
                    completion(nil)
                }
            }.resume()
        }.resume()
    }
    
    // Helper to convert Wikidata URL to Wikipedia URL
    private func getWikipediaUrl(from wikidataUrl: String) -> String? {
        if let entityId = extractEntityId(from: wikidataUrl) {
            return "https://en.wikipedia.org/wiki/Special:GoToLinkedPage/wikidata/\(entityId)"
        }
        return nil
    }
}
