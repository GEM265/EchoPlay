//
//  UserManager.swift
//  EchoPlay
//
//  Created by Gabrielle Mccrae on 11/26/24.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@Observable
class UserManager {
    
    // MARK: - Properties
    var currentUser: FirebaseAuth.User?
    var userData: [String: Any]?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    // MARK: - Initialization
    init() {
        self.currentUser = Auth.auth().currentUser
        
        if let user = self.currentUser {
            fetchUserData { result in
                switch result {
                case .success(let data):
                    print("Cached user data fetched successfully")
                    self.userData = data
                case .failure(let error):
                    print("Error fetching cached user data: \(error)")
                }
            }
        }
    }
    
    // MARK: - Authentication Methods
    func signUp(
        username: String,
        email: String,
        password: String,
        completion: @escaping (Result<User, Error>) -> Void
    ) {
        Task {
            do {
                // Create auth user
                let authResult = try await auth.createUser(withEmail: email, password: password)
                let uid = authResult.user.uid
                
                // Create user model
                let user = User(
                    id: uid,
                    username: username,
                    email: email
                )
                
                // Save to Firestore
                try await db.collection("users").document(uid).setData([
                    "uid": uid,
                    "username": username,
                    "email": email,
                    "createdAt": FieldValue.serverTimestamp()
                ])
                
                await MainActor.run {
                    self.currentUser = authResult.user
                    self.userData = try? JSONSerialization.jsonObject(with: JSONEncoder().encode(user)) as? [String: Any]
                }
                
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func signIn(
        email: String,
        password: String,
        completion: @escaping (Result<User, Error>) -> Void
    ) {
        Task {
            do {
                let authResult = try await auth.signIn(withEmail: email, password: password)
                let uid = authResult.user.uid
                
                let snapshot = try await db.collection("users").document(uid).getDocument()
                guard let userData = snapshot.data() else {
                    throw NSError(domain: "FirestoreError", code: -2, userInfo: [NSLocalizedDescriptionKey: "No user data found"])
                }
                
                // Create user model from Firestore data
                let user = User(
                    id: uid,
                    username: userData["username"] as? String ?? "",
                    email: userData["email"] as? String ?? ""
                )
                
                await MainActor.run {
                    self.currentUser = authResult.user
                    self.userData = userData
                }
                
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            currentUser = nil
            userData = nil
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    // MARK: - User Data Methods
    func fetchUserData(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        if let userData = self.userData {
            completion(.success(userData))
            return
        }
        
        guard let uid = currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])))
            return
        }
        
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "FirestoreError", code: -2, userInfo: [NSLocalizedDescriptionKey: "No user data found"])))
                return
            }
            
            self?.userData = data
            completion(.success(data))
        }
    }
    
    func updateUserProfile(
        username: String? = nil,
        email: String? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let uid = currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])))
            return
        }
        
        var updateData: [String: Any] = [:]
        if let username = username { updateData["username"] = username }
        if let email = email { updateData["email"] = email }
        
        db.collection("users").document(uid).updateData(updateData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

// MARK: - Profile Image and Account Management Extension
extension UserManager {
    func updateProfileImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let uid = currentUser?.uid,
              let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "UserManagerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])))
            return
        }
        
        let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { [weak self] metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "StorageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                // Update Firestore with the new image URL
                self?.db.collection("users").document(uid).updateData([
                    "profileImageURL": downloadURL.absoluteString
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(downloadURL))
                    }
                }
            }
        }
    }
    
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = currentUser else {
            completion(.failure(NSError(domain: "UserManagerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])))
            return
        }
        
        // Delete user data from Firestore
        db.collection("users").document(user.uid).delete { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Delete user authentication
            user.delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    self?.signOut()
                    completion(.success(()))
                }
            }
        }
    }
}

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
    let createdAt: Date?
    
    init(id: String, username: String, email: String) {
        self.id = id
        self.username = username
        self.email = email
        self.createdAt = Date()
    }
}


