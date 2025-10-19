# 🚴‍♂️ FietsRouteMee

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/meskers/FietsRouteMee)
[![iOS](https://img.shields.io/badge/iOS-18.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Build Status](https://github.com/meskers/FietsRouteMee/workflows/CI/badge.svg)](https://github.com/meskers/FietsRouteMee/actions)

**Modern Cycling Route Planner for iOS** - Built with SwiftUI and MapKit

FietsRouteMee is a comprehensive cycling route planner app designed specifically for Dutch cyclists, featuring advanced route planning, turn-by-turn navigation, and integration with Dutch cycling infrastructure.

## ✨ Features

### 🗺️ Advanced Route Planning
- **Interactive Maps** - Powered by MapKit with custom cycling overlays
- **Address Search** - Find destinations with intelligent search
- **Multiple Bike Types** - City, mountain, e-bike, and racing bike optimization
- **Dutch Cycling Junctions** - Integration with fietsknooppunten network
- **Waypoint Support** - Plan complex routes with multiple stops

### 🧭 Navigation & Guidance
- **Turn-by-Turn Navigation** - Real-time voice guidance
- **Live Tracking** - GPS tracking with emergency contacts
- **Offline Maps** - Download maps for offline use
- **3D Maps** - Immersive navigation experience

### 📱 Modern iOS Experience
- **iOS 18+ Design** - Latest iOS design language with Liquid Glass effects
- **Accessibility** - Full VoiceOver and accessibility support
- **Dark Mode** - Automatic dark mode support
- **Dynamic Type** - Scalable text for better readability

### 🚲 Cycling-Specific Features
- **Bike Type Optimization** - Routes optimized for your bike type
- **Surface Information** - Know what surfaces you'll encounter
- **Elevation Profiles** - Detailed elevation data
- **Difficulty Ratings** - Route difficulty assessment
- **Weather Integration** - Real-time weather information

### 📊 Activity & Performance
- **Activity Tracking** - Track your cycling activities
- **Performance Monitoring** - Monitor speed, distance, and performance
- **Collections** - Organize and manage your favorite routes
- **Data Export** - Export your data in various formats

## 🚀 Getting Started

### Prerequisites
- iOS 18.0 or later
- Xcode 15.0 or later (for development)
- Swift 6.0

### Installation

#### From Source
1. Clone the repository:
   ```bash
   git clone https://github.com/meskers/FietsRouteMee.git
   cd FietsRouteMee
   ```

2. Open in Xcode:
   ```bash
   open FietsRouteMee.xcodeproj
   ```

3. Build and run on simulator or device

#### From GitHub Releases
1. Download the latest release from [GitHub Releases](https://github.com/meskers/FietsRouteMee/releases)
2. Install on your iOS device

### Development Setup
See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed development setup instructions.

## 🏗️ Architecture

### Tech Stack
- **SwiftUI** - Modern declarative UI framework
- **MapKit** - Apple's mapping and location services
- **Core Data** - Data persistence and management
- **Combine** - Reactive programming framework
- **Core Location** - GPS and location services
- **AVFoundation** - Voice navigation and audio

### Design Patterns
- **MVVM** - Model-View-ViewModel architecture
- **Singleton** - For shared managers and services
- **Repository** - For data access abstraction
- **Observer** - For reactive data binding

### Project Structure
```
FietsRouteMee/
├── Models/           # Data models and entities
├── Views/            # SwiftUI views and components
├── Managers/         # Business logic and state management
├── Services/         # External service integrations
├── Resources/        # Assets, fonts, and resources
└── Utils/           # Utilities and extensions
```

## 📱 Screenshots

*Screenshots will be added in future releases*

## 🔧 Configuration

### API Keys
The app uses several external services. Configure API keys in `Info.plist`:

- **OpenWeatherMap** - For weather data
- **OpenRouteService** - For advanced routing (optional)

### Permissions
The app requires the following permissions:
- **Location** - For GPS tracking and route calculation
- **Maps** - For map display and navigation
- **Microphone** - For voice navigation (optional)

## 🚀 Version Management

### Current Version
- **Version**: 1.0.0
- **Build**: 202501271200
- **iOS Target**: 18.0+

### Version Bumping
Use the included version script:
```bash
./scripts/version.sh patch  # 1.0.0 -> 1.0.1
./scripts/version.sh minor  # 1.0.1 -> 1.1.0
./scripts/version.sh major  # 1.1.0 -> 2.0.0
```

### Release Process
1. Update `CHANGELOG.md`
2. Bump version using script
3. Create GitHub release
4. Deploy to App Store (future)

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

### Code Standards
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Write comprehensive tests
- Document public APIs

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Cor Meskers**
- GitHub: [@meskers](https://github.com/meskers)
- Email: [Contact via GitHub](https://github.com/meskers/FietsRouteMee/issues)

## 🙏 Acknowledgments

- Apple for SwiftUI and MapKit
- OpenStreetMap contributors
- Dutch cycling infrastructure providers
- Open source community

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/meskers/FietsRouteMee/issues)
- **Discussions**: [GitHub Discussions](https://github.com/meskers/FietsRouteMee/discussions)
- **Email**: [Contact via GitHub](https://github.com/meskers/FietsRouteMee/issues)

## 🗺️ Roadmap

### Version 1.1.0 (Planned)
- [ ] Enhanced offline maps
- [ ] Social features and sharing
- [ ] Advanced route analytics
- [ ] Apple Watch companion app

### Version 1.2.0 (Planned)
- [ ] Multi-day trip planning
- [ ] Community routes
- [ ] Advanced weather integration
- [ ] Performance improvements

### Version 2.0.0 (Future)
- [ ] Apple CarPlay support
- [ ] Advanced AI route suggestions
- [ ] Integration with fitness apps
- [ ] Premium features

---

**Made with ❤️ for Dutch cyclists** 🚴‍♂️🇳🇱
