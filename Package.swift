// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FietsRouteMee",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FietsRouteMee",
            targets: ["FietsRouteMee"]
        ),
    ],
    dependencies: [
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
                .product(name: "SwiftUIIntrospect", package: "SwiftUI-Introspect"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON")
            ]
        ),
    ]
)
