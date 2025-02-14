import SwiftUI
import AVFoundation

struct PlaylistsView: View {
    @Binding var playlists: [DiscoverPlaylist]
    @State private var newPlaylistName: String = ""
    @State private var showingAddPlaylistAlert = false
    @State private var showingAddSongSheet = false
    @State private var selectedPlaylistIndex: Int? = nil
    @State private var songToAdd: SongTrack?
    @State private var audioPlayer: AVPlayer?  // AVPlayer to handle audio playback
    @State private var isPlaying: Bool = false  // Track if song is playing
    @State private var currentTrack: SongTrack?  // Track the currently playing song

    var body: some View {
        NavigationView {
            List {
                ForEach(playlists.indices, id: \.self) { index in
                    Section(header: HStack {
                        Text(playlists[index].name)
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            deletePlaylist(at: index)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }) {
                        ForEach(playlists[index].tracks, id: \.id) { track in
                            HStack {
                                Text(track.title)
                                Spacer()
                                Button(action: {
                                    // Handle play/pause for the selected track
                                    playPauseSong(track)
                                }) {
                                    let playPauseIcon = getPlayPauseIcon(for: track)
                                    Image(systemName: playPauseIcon)
                                        .foregroundColor(isPlaying && currentTrack?.id == track.id ? .blue : .primary)
                                }
                                Button(action: {
                                    // Handle deletion of the track
                                    deleteTrack(at: track, in: index)
                                }) {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Playlists")
            .toolbar {
                Button(action: {
                    showingAddPlaylistAlert = true
                }) {
                    Image(systemName: "plus.circle")
                        .font(.title)
                }
                
                Button(action: {
                    showingAddSongSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                }
            }
            .onAppear {
                loadPlaylists()
            }
            .alert("New Playlist", isPresented: $showingAddPlaylistAlert) {
                VStack {
                    TextField("Playlist name", text: $newPlaylistName)
                    Button("Add", action: addPlaylist)
                    Button("Cancel", role: .cancel) {}
                }
            }
            .sheet(isPresented: $showingAddSongSheet) {
                SongPickerView(
                    songs: getAllAvailableSongs(),
                    selectedSong: $songToAdd,
                    onAddSong: addSongToPlaylist
                )
            }
        }
    }

    // MARK: - Functions

    func playPauseSong(_ track: SongTrack) {
        // Check if the selected track is already the current track
        if currentTrack?.id == track.id {
            // If it's the current track, toggle the play/pause state
            if isPlaying {
                audioPlayer?.pause()
                isPlaying = false
            } else {
                audioPlayer?.play()
                isPlaying = true
            }
        } else {
            // If it's a different track, stop the current one and play the new track
            if let currentPlayer = audioPlayer {
                currentPlayer.pause()  // Stop the current track
            }
            
            // Set the audio player to the new track and start playing
            audioPlayer = AVPlayer(url: track.url)
            audioPlayer?.play()
            isPlaying = true
            currentTrack = track
        }
    }

    func getPlayPauseIcon(for track: SongTrack) -> String {
        if currentTrack?.id == track.id {
            return isPlaying ? "pause.circle" : "play.circle"
        } else {
            return "play.circle"
        }
    }

    // MARK: - Playlist Management

    func deletePlaylist(at index: Int) {
        playlists.remove(at: index)
        savePlaylists()
    }

    func deleteTrack(at track: SongTrack, in playlistIndex: Int) {
        if let trackIndex = playlists[playlistIndex].tracks.firstIndex(where: { $0.id == track.id }) {
            playlists[playlistIndex].tracks.remove(at: trackIndex)
            savePlaylists()
        }
    }

    func loadPlaylists() {
        if let savedData = UserDefaults.standard.data(forKey: "savedPlaylists"),
           let decoded = try? JSONDecoder().decode([DiscoverPlaylist].self, from: savedData) {
            playlists = decoded
        } else {
            playlists = []  // Initialize with an empty array if no saved data exists
        }
    }

    func addPlaylist() {
        guard !newPlaylistName.isEmpty else { return }
        let newPlaylist = DiscoverPlaylist(name: newPlaylistName, tracks: [])
        playlists.append(newPlaylist)
        savePlaylists()
        newPlaylistName = ""
    }

    func savePlaylists() {
        if let encoded = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(encoded, forKey: "savedPlaylists")
        }
    }

    func getAllAvailableSongs() -> [SongTrack] {
        // Replace with real data if necessary
        return [
            SongTrack(title: "Song 1", url: URL(string: "https://www.example.com/song1.mp3")!),
            SongTrack(title: "Song 2", url: URL(string: "https://www.example.com/song2.mp3")!),
            SongTrack(title: "Song 3", url: URL(string: "https://www.example.com/song3.mp3")!)
        ]
    }

    func addSongToPlaylist() {
        guard let selectedPlaylistIndex = selectedPlaylistIndex, let song = songToAdd else { return }
        playlists[selectedPlaylistIndex].tracks.append(song)
        savePlaylists()
        showingAddSongSheet = false
    }
}

// MARK: - Data Models

struct DiscoverPlaylist: Identifiable, Codable {
    var id = UUID()  // Default value for new playlists
    var name: String
    var tracks: [SongTrack]

    enum CodingKeys: String, CodingKey {
        case name, tracks
    }

    init(name: String, tracks: [SongTrack]) {
        self.name = name
        self.tracks = tracks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        tracks = try container.decode([SongTrack].self, forKey: .tracks)
        id = UUID() // Ensure that 'id' is always generated
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(tracks, forKey: .tracks)
    }
}

struct SongTrack: Identifiable, Codable {
    var id = UUID()  // Default value for new songs
    var title: String
    var url: URL

    enum CodingKeys: String, CodingKey {
        case title, url
    }

    init(title: String, url: URL) {
        self.title = title
        self.url = url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        url = try container.decode(URL.self, forKey: .url)
        id = UUID() // Ensure that 'id' is always generated
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(url, forKey: .url)
    }
}

// MARK: - Song Picker View

struct SongPickerView: View {
    var songs: [SongTrack]
    @Binding var selectedSong: SongTrack?
    var onAddSong: () -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(songs) { song in
                    Button(action: {
                        selectedSong = song
                    }) {
                        Text(song.title)
                            .foregroundColor(selectedSong?.id == song.id ? .blue : .primary)
                    }
                    .background(selectedSong?.id == song.id ? Color.gray.opacity(0.2) : Color.clear)
                }
            }
            .navigationTitle("Select a Song")
            .toolbar {
                Button("Add Song") {
                    onAddSong()
                }
            }
        }
    }
}
