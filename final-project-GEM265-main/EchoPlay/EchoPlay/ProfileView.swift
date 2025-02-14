//
//  ProfileView.swift
//  EchoPlay
//
//  Created by Gabrielle Mccrae on 11/26/24.
//

import SwiftUI
import FirebaseFirestore

struct ProfileView: View {
    @Environment(UserManager.self) var userManager
    @State private var showEditProfile = false
    @State private var profileImage: UIImage?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    profileHeader
                    
                    // Profile Stats
                    profileStats
                    
                    // Profile Actions
                    profileActions
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            .navigationBarTitle("Profile", displayMode: .inline)
            .sheet(isPresented: $showEditProfile) {
                if let userData = userManager.userData {
                    EditProfileView(userData: userData)
                }
            }
            .background(Color(uiColor: .secondarySystemBackground))
        }
    }
    
    // Profile Header with Avatar, Username, and Bio
    private var profileHeader: some View {
        VStack(spacing: 10) {
            // Profile Image
            profileImageView
            
            // Username
            if let userData = userManager.userData,
               let username = userData["username"] as? String {
                Text(username)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Optional Bio
                if let bio = userData["bio"] as? String, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                ProgressView()
            }
        }
    }
    
    // Profile Image View with Placeholder and Edit Option
    private var profileImageView: some View {
        ZStack(alignment: .bottomTrailing) {
            // Profile Image or Placeholder
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
            }
            
            // Edit Profile Image Button
            Button(action: {
                showEditProfile = true
            }) {
                Image(systemName: "pencil.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .background(Color.white)
                    .clipShape(Circle())
                    .offset(x: -5, y: -5)
            }
        }
    }
    
    // Profile Stats (Followers, Following, etc.)
    private var profileStats: some View {
        HStack(spacing: 30) {
            statItem(value: "0", label: "Followers")
            statItem(value: "0", label: "Following")
            statItem(value: "0", label: "Likes")
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(10)
    }
    
    // Individual Stat Item
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // Profile Actions
    private var profileActions: some View {
        VStack(spacing: 15) {
            // Edit Profile Button
            Button(action: { showEditProfile = true }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Profile")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(10)
            }
            
            // Settings Button
            NavigationLink(destination: SettingsView()) {
                HStack {
                    Image(systemName: "gear")
                    Text("Settings")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(10)
            }
            
            // Sign Out Button
            Button(role: .destructive) {
                userManager.signOut()
            } label: {
                HStack {
                    Image(systemName: "arrow.left.square")
                    Text("Sign Out")
                    Spacer()
                }
                .padding()
                .foregroundColor(.red)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(10)
            }
        }
    }
    
    // Date Formatting Helper
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
//
//  EditProfileView.swift
//  EchoPlay
//
//  Created by Gabrielle Mccrae on 11/26/24.
//

import SwiftUI
import PhotosUI
import FirebaseCore
import FirebaseStorage
import FirebaseFirestore

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var userData: [String: Any]
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    init(userData: [String: Any]) {
        self._userData = State(initialValue: userData)
        self._username = State(initialValue: userData["username"] as? String ?? "")
        self._bio = State(initialValue: userData["bio"] as? String ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Image Section
                Section {
                    photoPicker
                }
                
                // Username Section
                Section(header: Text("Username")) {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                // Bio Section
                Section(header: Text("Bio")) {
                    TextEditor(text: $bio)
                        .frame(height: 100)
                }
                
                // Email Section (view only)
                Section(header: Text("Email")) {
                    Text(userData["email"] as? String ?? "N/A")
                        .foregroundColor(.secondary)
                }
                
                // Member Since Section
                Section(header: Text("Member Since")) {
                    if let createdAt = (userData["createdAt"] as? Timestamp)?.dateValue() {
                        Text(formatDate(createdAt))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(!hasChanges)
                }
            }
            .onAppear {
                loadSavedImage()
            }
        }
    }
    
    // Photo Picker Component
    private var photoPicker: some View {
        VStack {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                if let selectedImageData,
                   let uiImage = UIImage(data: selectedImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                }
                
                Text("Change Profile Photo")
                    .foregroundColor(.blue)
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
        }
    }
    
    // Check if any changes have been made
    private var hasChanges: Bool {
        username != (userData["username"] as? String ?? "") ||
        bio != (userData["bio"] as? String ?? "") ||
        selectedImageData != nil
    }
    
    // Save Profile Changes
    private func saveProfile() {
        Task {
            do {
                var updateData: [String: Any] = [:]

                if username != (userData["username"] as? String ?? "") {
                    updateData["username"] = username
                }

                if bio != (userData["bio"] as? String ?? "") {
                    updateData["bio"] = bio
                }

                // Handle profile image upload if selected
                if let imageData = selectedImageData, !imageData.isEmpty {
                    uploadProfileImage(imageData: imageData) { result in
                        switch result {
                        case .success(let imageURL):
                            updateData["profileImageUrl"] = imageURL.absoluteString
                            Task {
                                await saveProfileDataToFirestore(updateData: updateData)
                            }
                        case .failure(let error):
                            print("Error uploading image: \(error.localizedDescription)")
                        }
                    }
                } else {
                    await saveProfileDataToFirestore(updateData: updateData)
                }
            } catch {
                print("Error updating profile: \(error.localizedDescription)")
            }
        }
    }

    // Upload profile image to Firebase Storage
    private func uploadProfileImage(imageData: Data, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let userId = userData["uid"] as? String else { return }

        let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
        print("Uploading to path: profile_images/\(userId).jpg")
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                }
            }
        }
    }

    // Update Firestore with profile data
    private func saveProfileDataToFirestore(updateData: [String: Any]) async {
        guard let userId = userData["uid"] as? String else { return }

        do {
            try await Firestore.firestore().collection("users").document(userId).updateData(updateData)
            DispatchQueue.main.async {
                dismiss()
            }
        } catch {
            print("Error updating Firestore: \(error.localizedDescription)")
        }
    }

    // Save image to local storage
    private func saveImageToDocuments(imageData: Data) {
        let filename = getDocumentsDirectory().appendingPathComponent("profile_image.jpg")
        do {
            try imageData.write(to: filename)
            print("Image saved to \(filename)")
        } catch {
            print("Error saving image: \(error.localizedDescription)")
        }
    }

    // Load saved image from local storage
    private func loadSavedImage() {
        let path = getDocumentsDirectory().appendingPathComponent("profile_image.jpg")
        if let imageData = try? Data(contentsOf: path) {
            selectedImageData = imageData
        }
    }

    // Get the Documents directory path
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    // Date Formatting Helper
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// Preview for Xcode
#if DEBUG
struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView(userData: [
            "username": "echouser",
            "email": "user@example.com",
            "bio": "Creating awesome content!",
            "createdAt": Timestamp(date: Date())
        ])
    }
}
#endif

//
//  ProfileInfoRow.swift
//  EchoPlay
//
//  Created by Gabrielle Mccrae on 11/26/24.
//

import SwiftUI

struct ProfileInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}

//
//  SettingsView.swift
//  EchoPlay
//
//  Created by Gabrielle Mccrae on 11/26/24.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(UserManager.self) var userManager
    @Environment(\.colorScheme) var colorScheme  // Detect the current color scheme
    @State private var isNotificationsEnabled = true
    @State private var isPrivateProfileEnabled = false
    @State private var streamingQuality: StreamingQuality = .medium
    @State private var isDarkModeEnabled = false
    @State private var showAccountDeletionConfirmation = false

    // Image-related state
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false

    enum StreamingQuality: String, CaseIterable, Identifiable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case extreme = "Extreme"

        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationView {
            Form {
                // Profile Image Section
                Section(header: Text("Profile")) {
                    VStack {
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                        Button("Change Profile Image") {
                            showImagePicker = true
                        }
                    }
                }

                // Account Section
                Section(header: Text("Account")) {
                    NavigationLink(destination: AccountSettingsView()) {
                        HStack {
                            Image(systemName: "person.circle")
                            Text("Account Details")
                        }
                    }

                    Button(role: .destructive, action: {
                        showAccountDeletionConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Account")
                        }
                        .foregroundColor(.red)
                    }
                }

                // Playback Settings
                Section(header: Text("Playback")) {
                    Picker("Streaming Quality", selection: $streamingQuality) {
                        ForEach(StreamingQuality.allCases) { quality in
                            Text(quality.rawValue).tag(quality)
                        }
                    }

                    Toggle("Gapless Playback", isOn: .constant(true))
                    Toggle("Crossfade", isOn: .constant(false))
                }

                // Privacy Section
                Section(header: Text("Privacy")) {
                    Toggle("Private Profile", isOn: $isPrivateProfileEnabled)

                    NavigationLink(destination: PrivacySettingsView()) {
                        HStack {
                            Image(systemName: "lock.shield")
                            Text("Privacy Controls")
                        }
                    }
                }

                // Notifications Section
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $isNotificationsEnabled)

                    if isNotificationsEnabled {
                        NavigationLink(destination: NotificationSettingsView()) {
                            HStack {
                                Image(systemName: "bell")
                                Text("Notification Preferences")
                            }
                        }
                    }
                }

                // Appearance Section
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $isDarkModeEnabled)

                    Picker("App Theme", selection: .constant(0)) {
                        Text("System Default").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                }

                // About Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: TermsOfServiceView()) {
                        Text("Terms of Service")
                    }

                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("Privacy Policy")
                    }
                }
            }
            .navigationTitle("Settings")
            .alert(isPresented: $showAccountDeletionConfirmation) {
                Alert(
                    title: Text("Delete Account"),
                    message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        userManager.deleteAccount { result in
                            switch result {
                            case .success:
                                print("Account successfully deleted")
                            case .failure(let error):
                                print("Account deletion failed: \(error.localizedDescription)")
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(isImagePickerPresented: $showImagePicker, selectedImage: $profileImage)
            }
            .onAppear {
                loadProfileImage()
            }
            .preferredColorScheme(isDarkModeEnabled ? .dark : .light) // Switch the theme based on the toggle
        }
    }

    // Load the saved profile image
    func loadProfileImage() {
        let path = getDocumentsDirectory().appendingPathComponent("profile_image.jpg")
        if let image = UIImage(contentsOfFile: path.path) {
            profileImage = image
        }
    }

    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}

// Placeholder views for navigation destinations
struct AccountSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Account Information")) {
                Text("Manage account details")
            }
        }
        .navigationTitle("Account Settings")
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Privacy Controls")) {
                Toggle("Show Online Status", isOn: .constant(true))
                Toggle("Allow Profile Visibility", isOn: .constant(true))
            }
        }
        .navigationTitle("Privacy Controls")
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Notification Preferences")) {
                Toggle("New Followers", isOn: .constant(true))
                Toggle("Playlist Updates", isOn: .constant(true))
                Toggle("Recommended Music", isOn: .constant(false))
            }
        }
        .navigationTitle("Notification Settings")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            Text("Terms of Service")
                .font(.title)
                .padding()

            Text("Lorem ipsum...")
                .padding()
        }
        .navigationTitle("Terms of Service")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("Privacy Policy")
                .font(.title)
                .padding()

            Text("Lorem ipsum...")
                .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

// ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.selectedImage = selectedImage
                saveImageToDocuments(image: selectedImage)  // Save the image
            }
            parent.isImagePickerPresented = false
        }

        func saveImageToDocuments(image: UIImage) {
            guard let data = image.jpegData(compressionQuality: 0.8) else { return }
            let filename = getDocumentsDirectory().appendingPathComponent("profile_image.jpg")
            do {
                try data.write(to: filename)
                print("Image saved to \(filename)")
            } catch {
                print("Error saving image: \(error.localizedDescription)")
            }
        }

        func getDocumentsDirectory() -> URL {
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
    }

    @Binding var isImagePickerPresented: Bool
    @Binding var selectedImage: UIImage?

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// Preview for Xcode
#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif



// Preview for Xcode
#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
#endif
