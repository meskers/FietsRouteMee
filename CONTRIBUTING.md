# Contributing to FietsRouteMee

Thank you for your interest in contributing to FietsRouteMee! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 18.0+ deployment target
- Swift 6.0
- Git

### Development Setup
1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/FietsRouteMee.git`
3. Open `FietsRouteMee.xcodeproj` in Xcode
4. Build and run the project

## 📋 Development Workflow

### Branch Strategy
- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - Feature development branches
- `bugfix/*` - Bug fix branches
- `hotfix/*` - Critical bug fixes for production

### Creating a Feature Branch
```bash
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name
```

### Commit Convention
We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(navigation): add turn-by-turn voice guidance
fix(routing): resolve MapKit route calculation error
docs(readme): update installation instructions
```

## 🏗️ Code Standards

### Swift Style Guide
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftUI for UI components
- Prefer `@StateObject` over `@ObservedObject` for owned objects
- Use `@MainActor` for UI-related code
- Implement proper error handling with `Result` types

### Architecture
- Follow MVVM pattern
- Use Combine for reactive programming
- Implement proper separation of concerns
- Use dependency injection where appropriate

### Documentation
- Document public APIs with Swift DocC
- Add inline comments for complex logic
- Update README.md for user-facing changes
- Update CHANGELOG.md for all changes

## 🧪 Testing

### Unit Tests
- Write unit tests for business logic
- Test error conditions
- Aim for >80% code coverage

### UI Tests
- Test critical user flows
- Test accessibility features
- Test different device sizes

### Manual Testing
- Test on different iOS versions
- Test on different device types
- Test with different accessibility settings

## 📱 iOS Guidelines

### Accessibility
- Ensure VoiceOver compatibility
- Support Dynamic Type
- Provide accessibility labels
- Test with accessibility features enabled

### Performance
- Monitor memory usage
- Optimize for battery life
- Use background processing appropriately
- Implement proper caching strategies

### Privacy
- Follow Apple's privacy guidelines
- Request permissions appropriately
- Handle permission denials gracefully
- Use secure data storage

## 🚀 Release Process

### Version Bumping
Use the version script:
```bash
./scripts/version.sh patch  # 1.0.0 -> 1.0.1
./scripts/version.sh minor  # 1.0.1 -> 1.1.0
./scripts/version.sh major  # 1.1.0 -> 2.0.0
```

### Release Checklist
- [ ] Update CHANGELOG.md
- [ ] Update version numbers
- [ ] Run all tests
- [ ] Test on multiple devices
- [ ] Update documentation
- [ ] Create GitHub release
- [ ] Tag the release

## 🐛 Bug Reports

When reporting bugs, please include:
- iOS version
- Device model
- Steps to reproduce
- Expected behavior
- Actual behavior
- Screenshots or videos if applicable

## 💡 Feature Requests

When suggesting features:
- Describe the use case
- Explain the benefit
- Consider implementation complexity
- Check for existing issues/requests

## 📄 License

By contributing to FietsRouteMee, you agree that your contributions will be licensed under the MIT License.

## 🤝 Code of Conduct

Please be respectful and constructive in all interactions. We aim to create a welcoming environment for all contributors.

## 📞 Contact

- Create an issue for questions
- Use discussions for general questions
- Contact maintainers for urgent matters

---

Thank you for contributing to FietsRouteMee! 🚴‍♂️✨
