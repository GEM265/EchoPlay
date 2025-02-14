import SwiftUI
import AVKit
import Foundation

// Data Models

    // Manually implement Decodable and Encodable
    enum CodingKeys: String, CodingKey {
        case id, title, url
    }

// Track model
struct Track: Identifiable, Codable {
    let id: Int
    let title: String
    let preview: String?
    let artist: Artist
    let album: Album?

    struct Artist: Codable {
        let name: String
    }

    struct Album: Codable {
        let coverMedium: String?

        enum CodingKeys: String, CodingKey {
            case coverMedium = "cover_medium"
        }
    }
}

// DiscoverSongTrack model
struct DiscoverSongTrack: Identifiable, Codable {
    let id: UUID
    var title: String
    var url: URL  // Add a URL to the song
}

// MARK: - Main DiscoverView
struct DiscoverView: View {
    @State private var tracks: [Track] = []
    @State private var isLoading = true
    @State private var player: AVPlayer? = nil
    @State private var searchQuery: String = "top"  // Default search query

    @Binding var playlists: [DiscoverPlaylist]  // Binding for playlists

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    TextField("Search for tracks...", text: $searchQuery)
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        .onChange(of: searchQuery) { newQuery in
                            loadTracks(query: newQuery)
                        }

                    Button(action: {
                        loadTracks(query: searchQuery)
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .padding(.trailing)
                    }
                }

                // Content
                ZStack {
                    if isLoading {
                        ProgressView("Loading songs...")
                            .scaleEffect(1.5)
                    } else {
                        TabView {
                            ForEach(tracks) { track in
                                TrackView(track: track, player: $player, playlists: $playlists)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .navigationTitle("Discover")
                        .navigationBarHidden(true)
                    }
                }
            }
        }
        .onAppear {
            configureAudioSession()
            loadTracks(query: searchQuery)
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

    func loadTracks(query: String) {
        isLoading = true
        DeezerService.shared.fetchTracks(query: query) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tracks):
                    self.tracks = tracks.shuffled()
                    self.isLoading = false
                case .failure(let error):
                    print("Error loading tracks: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - TrackView for Individual Track Display
struct TrackView: View {
    let track: Track
    @Binding var player: AVPlayer?
    @Binding var playlists: [DiscoverPlaylist]  // Binding for playlists
    @State private var isPlaying = false
    @State private var selectedPlaylistIndex: Int? = nil

    var body: some View {
        ZStack {
            // Background Image
            AsyncImage(url: URL(string: track.album?.coverMedium ?? "")) { image in
                image.resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } placeholder: {
                Color.black
            }

            VStack {
                Spacer()

                // Track Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(track.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(track.artist.name)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))

                    // Play/Pause Button
                    Button(action: {
                        playPreview(track.preview ?? "")
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                    }
                    .padding(.top, 20)

                    // Add to Playlist Picker
                    Picker("Select Playlist", selection: $selectedPlaylistIndex) {
                        ForEach(playlists.indices, id: \.self) { index in
                            Text(playlists[index].name).tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.top, 10)

                    // Add to Playlist Button
                    Button(action: {
                        if let index = selectedPlaylistIndex {
                            // Map DiscoverSongTrack to SongTrack
                            let newSong = SongTrack(title: track.title, url: URL(string: "https://www.example.com/song.mp3")!)  // Replace with a real URL
                            playlists[index].tracks.append(newSong)
                            savePlaylists() // Save the updated playlists
                        }
                    }) {
                        Label("Add to Playlist", systemImage: "plus.circle")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .disabled(selectedPlaylistIndex == nil)
                }
                .padding()
            }
        }
        .ignoresSafeArea()
    }

    func playPreview(_ previewURL: String) {
        guard let url = URL(string: previewURL), !previewURL.isEmpty else {
            print("Invalid or empty preview URL: \(previewURL)")
            return
        }

        if player?.currentItem?.asset as? AVURLAsset == AVURLAsset(url: url) {
            if isPlaying {
                player?.pause()
            } else {
                player?.play()
            }
            isPlaying.toggle()
        } else {
            player = AVPlayer(url: url)
            player?.play()
            isPlaying = true
        }
    }

    // Function to save playlists persistently
    func savePlaylists() {
        if let encoded = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(encoded, forKey: "savedPlaylists")
        }
    }
}
