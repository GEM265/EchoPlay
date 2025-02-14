//
//  DeezerService.swift
//  EchoPlay
//
//  Created by Gabrielle Mccrae on 12/9/24.
//

import Foundation

class DeezerService {
    static let shared = DeezerService()
    private init() {}

    func fetchTracks(query: String, completion: @escaping (Result<[Track], Error>) -> Void) {
        let queryEncoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.deezer.com/search?q=\(queryEncoded)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 500, userInfo: nil)))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(DeezerResponse.self, from: data)
                completion(.success(response.data))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}

// Response model for Deezer API
struct DeezerResponse: Codable {
    let data: [Track]
}

