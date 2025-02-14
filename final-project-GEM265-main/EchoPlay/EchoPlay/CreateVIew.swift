//
//  CreateView.swift
//  EchoPlay
//
//  Created by Gabrielle Mccrae on 11/26/24.
//

import SwiftUI

struct CreateView: View {
    @State private var customContentName: String = ""       // Name for the custom content
    @State private var selectedSong: SongTrack? = nil       // The song selected by the user
    @State private var showingSongPicker: Bool = false      // To show the song picker sheet
    @State private var customContents: [CustomContent] = [] // Store the created content
    @State private var availableSongs: [SongTrack] = []     // List of songs from the Deezer API
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Enter content name", text: $customContentName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    showingSongPicker = true
                }) {
                    HStack {
                        Image(systemName: "music.note")
                        Text(selectedSong?.title ?? "Select a Song")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                }
                
                Button(action: addCustomContent) {
                    Text("Create Content")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(customContentName.isEmpty || selectedSong == nil)
                
                List {
                    ForEach(customContents, id: \.id) { content in
                        VStack(alignment: .leading) {
                            Text(content.name)
                                .font(.headline)
                            Text(content.track.title)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Create Content")
            .sheet(isPresented: $showingSongPicker) {
                SongPickerView(
                    songs: availableSongs,
                    selectedSong: $selectedSong,
                    onAddSong: { showingSongPicker = false }
                )
            }
            .onAppear {
                getAllAvailableSongs()
            }
            .padding()
        }
    }
    
    // MARK: - Functions
    
    func addCustomContent() {
        guard let song = selectedSong else { return }
        let newContent = CustomContent(name: customContentName, track: song)
        customContents.append(newContent)
        customContentName = ""
        selectedSong = nil
    }
    
    func getAllAvailableSongs() {
        DeezerService.shared.fetchTracks(query: "popular") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tracks):
                    self.availableSongs = tracks.compactMap { track in
                        // Safely unwrap track.preview
                        if let preview = track.preview, let previewURL = URL(string: preview) {
                            return SongTrack(title: track.title, url: previewURL)
                        } else {
                            return nil  // Skip tracks with invalid or missing preview URLs
                        }
                    }
                case .failure(let error):
                    print("Error fetching tracks: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Data Model for Custom Content

struct CustomContent: Identifiable {
    var id = UUID()
    var name: String
    var track: SongTrack
}
