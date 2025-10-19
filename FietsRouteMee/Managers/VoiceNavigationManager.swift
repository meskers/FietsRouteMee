//
//  VoiceNavigationManager.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import Foundation
import AVFoundation
import CoreLocation
import Combine

class VoiceNavigationManager: ObservableObject {
    // MARK: - Singleton
    static let shared = VoiceNavigationManager()
    
    @Published var isVoiceEnabled = true
    @Published var voiceVolume: Float = 0.8
    @Published var voiceSpeed: Float = 0.5
    @Published var isSpeaking = false
    @Published var currentInstruction: String = ""
    
    private let synthesizer = AVSpeechSynthesizer()
    private var currentVoice: AVSpeechSynthesisVoice?
    private var cancellables = Set<AnyCancellable>()
    private let settingsManager = AppSettingsManager.shared
    
    private init() {
        setupAudioSession()
        configureVoice()
        
        // Listen to settings changes
        settingsManager.$isVoiceEnabled
            .assign(to: \.isVoiceEnabled, on: self)
            .store(in: &cancellables)
        
        settingsManager.$voiceVolume
            .assign(to: \.voiceVolume, on: self)
            .store(in: &cancellables)
        
        settingsManager.$voiceSpeed
            .assign(to: \.voiceSpeed, on: self)
            .store(in: &cancellables)
        
        settingsManager.$voiceLanguage
            .sink { [weak self] _ in
                self?.configureVoice()
            }
            .store(in: &cancellables)
    }
    
    func speakInstruction(_ instruction: String, priority: VoicePriority = .normal) {
        guard isVoiceEnabled && !instruction.isEmpty else { return }
        
        // Configure audio session to prevent buffer warnings
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ VoiceNavigationManager: Failed to configure audio session: \(error)")
            // Continue anyway - don't return, just log the error
        }
        
        // Stop current speech if higher priority
        if priority == .high && isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        guard !instruction.isEmpty else { return }
        
        let utterance = AVSpeechUtterance(string: instruction)
        
        // Validate and set rate
        let baseRate = AVSpeechUtteranceDefaultSpeechRate
        let adjustedRate = baseRate * voiceSpeed
        utterance.rate = max(AVSpeechUtteranceMinimumSpeechRate, min(AVSpeechUtteranceMaximumSpeechRate, adjustedRate))
        
        // Validate and set volume
        utterance.volume = max(0.0, min(1.0, voiceVolume))
        utterance.pitchMultiplier = 1.0
        utterance.voice = currentVoice ?? AVSpeechSynthesisVoice(language: "nl-NL")
        
        // Configure voice based on priority
        switch priority {
        case .low:
            utterance.rate = max(AVSpeechUtteranceMinimumSpeechRate, utterance.rate * 0.8)
            utterance.volume *= 0.7
        case .normal:
            break
        case .high:
            utterance.rate = min(AVSpeechUtteranceMaximumSpeechRate, utterance.rate * 1.2)
            utterance.volume = min(1.0, utterance.volume * 1.3)
        }
        
        // Ensure we're on main thread for UI updates
        DispatchQueue.main.async {
            self.currentInstruction = instruction
            self.isSpeaking = true
        }
        
        // Speak the instruction
        synthesizer.speak(utterance)
        
        // Reset speaking state after estimated completion
        let estimatedDuration = Double(instruction.count) * 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) {
            self.isSpeaking = false
        }
    }
    
    func speakTurnInstruction(_ instruction: RouteInstruction, distance: Double) {
        let spokenText = generateTurnInstructionText(instruction, distance: distance)
        speakInstruction(spokenText, priority: .high)
    }
    
    func speakDistanceUpdate(_ distance: Double) {
        let spokenText = generateDistanceText(distance)
        speakInstruction(spokenText, priority: .low)
    }
    
    func startNavigation(for route: BikeRoute) {
        // Start voice navigation for the given route
        speakInstruction("Navigatie gestart. Volg de route naar bestemming.", priority: .high)
    }
    
    func stopNavigation() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        currentInstruction = ""
    }
    
    func speakArrival() {
        speakInstruction("Je bent aangekomen op je bestemming", priority: .high)
    }
    
    func speakRouteStart() {
        speakInstruction("Navigatie gestart. Volg de instructies", priority: .high)
    }
    
    func speakRouteEnd() {
        speakInstruction("Navigatie beëindigd", priority: .normal)
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func configureVoice() {
        // Try to use Dutch voice if available, with error handling
        let voices = AVSpeechSynthesisVoice.speechVoices()
        
        // Try to find Dutch voice
        if let dutchVoice = voices.first(where: { $0.language.hasPrefix("nl") }) {
            currentVoice = dutchVoice
            print("✅ Voice: Using Dutch voice - \(dutchVoice.name)")
        } else if let englishVoice = voices.first(where: { $0.language.hasPrefix("en") }) {
            currentVoice = englishVoice
            print("✅ Voice: Using English voice - \(englishVoice.name)")
        } else if !voices.isEmpty {
            // Fallback to any available voice
            currentVoice = voices.first
            print("⚠️ Voice: Using fallback voice - \(voices.first?.name ?? "unknown")")
        } else {
            // Use system default
            currentVoice = AVSpeechSynthesisVoice(language: "nl-NL")
            print("⚠️ Voice: Using system default voice")
        }
    }
    
    private func generateTurnInstructionText(_ instruction: RouteInstruction, distance: Double) -> String {
        let distanceText = formatDistanceForSpeech(distance)
        
        switch instruction.type {
        case .start:
            return "Start je route. \(distanceText)"
        case .turnLeft:
            return "Over \(distanceText) linksaf"
        case .turnRight:
            return "Over \(distanceText) rechtsaf"
        case .straight:
            return "Ga rechtdoor voor \(distanceText)"
        case .destination:
            return "Je bestemming is over \(distanceText)"
        case .roundabout:
            return "Over \(distanceText) de rotonde op"
        case .uTurn:
            return "Over \(distanceText) omkeren"
        }
    }
    
    private func generateDistanceText(_ distance: Double) -> String {
        if distance < 50 {
            return "nog \(Int(distance)) meter"
        } else if distance < 1000 {
            return "nog \(Int(distance / 100))honderd meter"
        } else {
            let kilometers = distance / 1000
            return "nog \(String(format: "%.1f", kilometers)) kilometer"
        }
    }
    
    private func formatDistanceForSpeech(_ distance: Double) -> String {
        if distance < 50 {
            return "\(Int(distance)) meter"
        } else if distance < 1000 {
            return "\(Int(distance / 100))honderd meter"
        } else {
            let kilometers = distance / 1000
            return "\(String(format: "%.1f", kilometers)) kilometer"
        }
    }
}

enum VoicePriority {
    case low
    case normal
    case high
}

// MARK: - Voice Settings
struct VoiceSettings {
    var isEnabled: Bool = true
    var volume: Float = 0.8
    var speed: Float = 0.5
    var language: String = "nl-NL"
    var voiceType: VoiceType = .standard
    
    enum VoiceType {
        case standard
        case premium
        case custom
    }
}
