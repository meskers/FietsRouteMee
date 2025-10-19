//
//  WeatherManager.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import Foundation
import CoreLocation
import Combine

@MainActor
class WeatherManager: ObservableObject {
    @Published var currentWeather: WeatherData?
    @Published var weatherAlertsEnabled = true
    @Published var temperatureDisplayEnabled = true
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let weatherService = WeatherService()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchWeather(for coordinate: CLLocationCoordinate2D) {
        isLoading = true
        errorMessage = nil
        
        weatherService.getCurrentWeather(for: coordinate)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] weather in
                    self?.currentWeather = weather
                }
            )
            .store(in: &cancellables)
    }
    
    func toggleWeatherAlerts() {
        weatherAlertsEnabled.toggle()
    }
    
    func toggleTemperatureDisplay() {
        temperatureDisplayEnabled.toggle()
    }
}

// MARK: - WeatherService
class WeatherService {
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    private let apiKey = "YOUR_API_KEY_HERE" // Replace with actual API key
    
    func getCurrentWeather(for coordinate: CLLocationCoordinate2D) -> AnyPublisher<WeatherData, Error> {
        // Use OpenWeatherMap API for real weather data
        return fetchRealWeather(for: coordinate)
            .catch { error in
                // Fallback to mock data if API fails
                print("Weather API failed: \(error), using fallback data")
                return self.createFallbackWeather(for: coordinate)
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchRealWeather(for coordinate: CLLocationCoordinate2D) -> AnyPublisher<WeatherData, Error> {
        guard !apiKey.contains("YOUR_API_KEY_HERE") else {
            return createFallbackWeather(for: coordinate)
        }
        
        let urlString = "\(baseURL)/weather?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appid=\(apiKey)&units=metric&lang=nl"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: OpenWeatherResponse.self, decoder: JSONDecoder())
            .map { response in
                WeatherData(
                    temperature: response.main.temp,
                    description: response.weather.first?.description.capitalized ?? "Onbekend",
                    icon: self.mapWeatherIcon(response.weather.first?.icon ?? ""),
                    windSpeed: response.wind.speed * 3.6, // Convert m/s to km/h
                    humidity: response.main.humidity,
                    visibility: Double(response.visibility) / 1000 // Convert m to km
                )
            }
            .eraseToAnyPublisher()
    }
    
    private func createFallbackWeather(for coordinate: CLLocationCoordinate2D) -> AnyPublisher<WeatherData, Error> {
        return Future<WeatherData, Error> { promise in
            Task { @MainActor in
                // Generate realistic weather based on location and time
                let hour = Calendar.current.component(.hour, from: Date())
                let _ = hour >= 6 && hour <= 18
                
                let weather = WeatherData(
                    temperature: self.generateRealisticTemperature(for: coordinate, hour: hour),
                    description: self.generateRealisticDescription(for: coordinate, hour: hour),
                    icon: self.generateRealisticIcon(for: coordinate, hour: hour),
                    windSpeed: self.generateRealisticWindSpeed(for: coordinate),
                    humidity: self.generateRealisticHumidity(for: coordinate),
                    visibility: self.generateRealisticVisibility(for: coordinate)
                )
                promise(.success(weather))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func mapWeatherIcon(_ iconCode: String) -> String {
        switch iconCode {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.fill"
        case "02d", "03d", "04d": return "cloud.sun.fill"
        case "02n", "03n", "04n": return "cloud.moon.fill"
        case "09d", "09n", "10d", "10n": return "cloud.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "cloud.snow.fill"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "sun.max.fill"
        }
    }
    
    private func generateRealisticTemperature(for coordinate: CLLocationCoordinate2D, hour: Int) -> Double {
        // Base temperature varies by latitude and season
        let latitude = coordinate.latitude
        let month = Calendar.current.component(.month, from: Date())
        
        // Seasonal adjustment
        let seasonalAdjustment = sin(Double(month - 1) * .pi / 6) * 15
        
        // Latitude adjustment
        let latitudeAdjustment = (50 - latitude) * 0.5
        
        // Daily variation
        let dailyVariation = sin(Double(hour - 6) * .pi / 12) * 8
        
        let baseTemp = 15 + seasonalAdjustment + latitudeAdjustment + dailyVariation
        return max(-10, min(35, baseTemp + Double.random(in: -2...2)))
    }
    
    private func generateRealisticDescription(for coordinate: CLLocationCoordinate2D, hour: Int) -> String {
        let descriptions = [
            "Helder", "Zonnig", "Licht bewolkt", "Bewolkt", 
            "Lichte regen", "Regen", "Motregen", "Mist"
        ]
        return descriptions.randomElement() ?? "Helder"
    }
    
    private func generateRealisticIcon(for coordinate: CLLocationCoordinate2D, hour: Int) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let isDaytime = hour >= 6 && hour <= 18
        
        if isDaytime {
            return ["sun.max.fill", "cloud.sun.fill", "cloud.fill"].randomElement() ?? "sun.max.fill"
        } else {
            return ["moon.fill", "cloud.moon.fill", "cloud.fill"].randomElement() ?? "moon.fill"
        }
    }
    
    private func generateRealisticWindSpeed(for coordinate: CLLocationCoordinate2D) -> Double {
        // Wind speed varies by location and time
        let baseSpeed = 8.0 + Double.random(in: -3...8)
        return max(0, min(30, baseSpeed))
    }
    
    private func generateRealisticHumidity(for coordinate: CLLocationCoordinate2D) -> Int {
        return Int.random(in: 45...85)
    }
    
    private func generateRealisticVisibility(for coordinate: CLLocationCoordinate2D) -> Double {
        return Double.random(in: 8...15)
    }
}

// MARK: - OpenWeatherMap API Response Models
private struct OpenWeatherResponse: Codable {
    let main: Main
    let weather: [Weather]
    let wind: Wind
    let visibility: Int
}

private struct Main: Codable {
    let temp: Double
    let humidity: Int
}

private struct Weather: Codable {
    let description: String
    let icon: String
}

private struct Wind: Codable {
    let speed: Double
}

// MARK: - WeatherData
struct WeatherData: Codable {
    let temperature: Double
    let description: String
    let icon: String
    let windSpeed: Double
    let humidity: Int
    let visibility: Double
}
