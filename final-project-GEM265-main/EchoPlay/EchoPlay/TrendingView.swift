//
//  TrendingView.swift
//  Spotify
//
//  Created by Gabrielle Mccrae on 12/6/24.
//

import SwiftUI
import AVKit

struct TrendingView: View {
    @State private var tracks: [Track] = []
    @State private var isLoading = true
    @State private var player: AVPlayer? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading trending tracks...")
                } else {
                    List(tracks) { track in
                        HStack {
                            // Safely load album cover with fallback
                            AsyncImage(url: URL(string: track.album?.coverMedium ?? "")) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "music.note")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 50, height: 50)
                            .cornerRadius(5)
                            
                            VStack(alignment: .leading) {
                                Text(track.title)
                                    .font(.headline)
                                Text(track.artist.name)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                playPreview(track.preview ?? "")
                            }) {
                                Image(systemName: "play.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .navigationTitle("Trending")
                }
            }
        }
        .onAppear { // Load trending tracks when the view appears
            configureAudioSession()
            loadTrendingTracks()
        }
    }
    
    func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    func loadTrendingTracks() {
        // Call fetchTracks method with "top" query for trending tracks
        DeezerService.shared.fetchTracks(query: "top") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tracks):
                    self.tracks = tracks
                    self.isLoading = false
                case .failure(let error):
                    print("Error loading trending tracks: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func playPreview(_ previewURL: String) {
        guard let url = URL(string: previewURL), !previewURL.isEmpty else {
            print("Invalid or empty preview URL: \(previewURL)")
            return
        }
        player = AVPlayer(url: url)
        player?.play()
    }
}
