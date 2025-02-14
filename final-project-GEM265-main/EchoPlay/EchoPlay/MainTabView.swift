//
//  MainTabView.swift
//  EchoPlay
//
//  Created by Gabrielle Mccrae on 11/26/24.
//

import SwiftUI
import FirebaseAuth

// Define MainTabView as a SwiftUI View
struct MainTabView: View {
    @State private var playlists: [DiscoverPlaylist] = []  // Use DiscoverPlaylist type

    var body: some View {
        TabView {
            DiscoverView(playlists: $playlists)
                .tabItem {
                    Label("Discover", systemImage: "play.circle.fill")
                }
            
            TrendingView()
                .tabItem {
                    Label("Trending", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            CreateView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle")
                }
            
            PlaylistsView(playlists: $playlists)  // Pass the playlists of type DiscoverPlaylist
                .tabItem {
                    Label("Playlists", systemImage: "music.note.list")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}
