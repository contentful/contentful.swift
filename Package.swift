import PackageDescription

let package = Package(
    name: "Contentful",
    dependencies: [
        .Package(url: "https://github.com/anviking/Decodable", majorVersion: 0),
        .Package(url: "https://github.com/jensravens/Interstellar", majorVersion: 2)
    ],
    exclude: ["Tests/"]
)
