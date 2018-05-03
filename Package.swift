// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Contentful",
    products: [
        .library(
            name: "Contentful",
            targets: ["Contentful"])
    ],
    dependencies: [
        .package(url: "https://github.com/jensravens/Interstellar", .upToNextMinor(from: "2.2.0"))
    ],
    targets: [
        .target(
            name: "Contentful",
            dependencies: [
                "Interstellar"
            ])
    ]
)
