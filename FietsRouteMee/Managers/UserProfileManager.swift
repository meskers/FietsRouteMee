//
//  UserProfileManager.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 10/10/2025.
//

import Foundation
import SwiftUI
import PhotosUI
import Combine

class UserProfileManager: ObservableObject {
    @Published var userName: String = "Fietser"
    @Published var userPhoto: UIImage?
    @Published var joinDate: Date = Date()
    
    private let userDefaults = UserDefaults.standard
    private let userNameKey = "user_name"
    private let userPhotoKey = "user_photo"
    private let joinDateKey = "join_date"
    
    init() {
        loadUserData()
    }
    
    func updateUserName(_ name: String) {
        userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        userDefaults.set(userName, forKey: userNameKey)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func updateUserPhoto(_ image: UIImage?) {
        userPhoto = image
        
        if let image = image {
            // Resize and compress image to stay under 1MB for UserDefaults
            let resizedImage = resizeImage(image, maxSize: CGSize(width: 512, height: 512))
            
            // Save compressed image (max ~200KB)
            if let imageData = resizedImage.jpegData(compressionQuality: 0.6) {
                // Check size - UserDefaults has a 4MB limit per key
                if imageData.count < 1_000_000 { // Under 1MB
                    userDefaults.set(imageData, forKey: userPhotoKey)
                    print("✅ UserProfile: Photo saved (\(imageData.count / 1024)KB)")
                } else {
                    print("⚠️ UserProfile: Photo too large (\(imageData.count / 1024)KB), not saving")
                }
            }
        } else {
            userDefaults.removeObject(forKey: userPhotoKey)
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func resizeImage(_ image: UIImage, maxSize: CGSize) -> UIImage {
        let size = image.size
        
        // Calculate new size maintaining aspect ratio
        let widthRatio = maxSize.width / size.width
        let heightRatio = maxSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // Resize image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
    
    func resetProfile() {
        userName = "Fietser"
        userPhoto = nil
        joinDate = Date()
        
        userDefaults.removeObject(forKey: userNameKey)
        userDefaults.removeObject(forKey: userPhotoKey)
        userDefaults.removeObject(forKey: joinDateKey)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    private func loadUserData() {
        // Load user name
        if let savedName = userDefaults.string(forKey: userNameKey) {
            userName = savedName
        }
        
        // Load user photo
        if let imageData = userDefaults.data(forKey: userPhotoKey) {
            userPhoto = UIImage(data: imageData)
        }
        
        // Load join date
        if let savedDate = userDefaults.object(forKey: joinDateKey) as? Date {
            joinDate = savedDate
        } else {
            // Set default join date if none exists
            userDefaults.set(joinDate, forKey: joinDateKey)
        }
    }
    
    var formattedJoinDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "nl_NL")
        return "Sinds \(formatter.string(from: joinDate))"
    }
    
    var hasCustomPhoto: Bool {
        return userPhoto != nil
    }
}
