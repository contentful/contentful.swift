// swift-tools-version:4.0
import PackageDescription

public let package = Package(
    name: "Contentful",
    products: [
        .library(
            name: "Contentful",
            targets: ["Contentful"])
    ],
    targets: [
        .target(
            name: "Contentful")
    ]
)
