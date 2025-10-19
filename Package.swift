// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FietsRouteMee",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "FietsRouteMee",
            targets: ["FietsRouteMee"]
        ),
    ],
    dependencies: [
        // MapLibre Native for better cycling maps and offline support
        .package(url: "https://github.com/maplibre/maplibre-native-ios", from: "5.15.0"),
        
        // GraphHopper for offline routing
        .package(url: "https://github.com/graphhopper/graphhopper-swift", from: "1.0.0"),
        
        // SwiftUI Extensions for better UI
        .package(url: "https://github.com/siteline/SwiftUI-Introspect", from: "0.12.0"),
        
        // Networking improvements
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.8.0"),
        
        // JSON handling
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "FietsRouteMee",
            dependencies: [
                .product(name: "MapLibre", package: "maplibre-native-ios"),
                .product(name: "GraphHopper", package: "graphhopper-swift"),
                .product(name: "SwiftUIIntrospect", package: "SwiftUI-Introspect"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON")
            ]
        ),
    ]
)
