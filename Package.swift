// swift-tools-version:5.3
import PackageDescription

public let package = Package(
    name: "Contentful",
    products: [
        .library(
            name: "Contentful",
            targets: ["Contentful"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/mariuskatcontentful/DVR.git",
            .branch("master")
        ),
        .package(
            url: "https://github.com/mariuskatcontentful/OHHTTPStubs.git",
            .branch("master")
        )
    ],
    targets: [
        .target(
            name: "Contentful"),
        .testTarget(name: "ContentfulTests",
                    dependencies: [
                        "Contentful",
                        .product(name: "DVR", package: "DVR"),
                        .product(name: "OHHTTPStubs", package: "OHHTTPStubs")
                    ],
                    path: "Tests")
    ]
)
