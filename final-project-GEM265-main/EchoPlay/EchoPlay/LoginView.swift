//
//  LoginView.swift
//  EchoPlay
//
//  Created by Gabrielle Mccrae on 11/26/24.
//

import SwiftUI

struct LoginView: View {
    @Environment(UserManager.self) var userManager
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var isShowingError: Bool = false
    @State private var isSignUpMode: Bool = false
    
    var body: some View {
        VStack {
            Text("EchoPlay!")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 30)
            
            VStack(spacing: 20) {
                if isSignUpMode {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                }
                
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
            }
            .textInputAutocapitalization(.never)
            .padding(.horizontal, 40)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            VStack(spacing: 15) {
                Button(isSignUpMode ? "Create Account" : "Sign In") {
                    performAuthentication()
                }
                .buttonStyle(.borderedProminent)
                
                Button(isSignUpMode ? "Back to Login" : "Create Account") {
                    withAnimation {
                        isSignUpMode.toggle()
                        errorMessage = ""
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 30)
        }
        .alert("Authentication Error", isPresented: $isShowingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func performAuthentication() {
        if isSignUpMode {
            userManager.signUp(username: username, email: email, password: password) { result in
                switch result {
                case .success:
                    errorMessage = ""
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            }
        } else {
            userManager.signIn(email: email, password: password) { result in
                switch result {
                case .success:
                    errorMessage = ""
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            }
        }
    }
}
import FirebaseStorage
import FirebaseFirestore
import UIKit

class FirebaseManager {
    static let shared = FirebaseManager()
    private let storage = Storage.storage()
    private let firestore = Firestore.firestore()
    
    private init() {}
    
    func uploadProfileImage(_ image: UIImage, for userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "Invalid Image", code: 0, userInfo: nil)))
            return
        }
        
        let storageRef = storage.reference().child("profile_pictures/\(userId).jpg")
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    self.saveProfileImageURL(url.absoluteString, for: userId) { result in
                        completion(result)
                    }
                }
            }
        }
    }
    
    private func saveProfileImageURL(_ url: String, for userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        firestore.collection("users").document(userId).setData(["profileImageUrl": url], merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(url))
            }
        }
    }
}
