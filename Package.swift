import PackageDescription

let package = Package(
    name: "Contentful",
    dependencies: [
        .Package(url: "https://github.com/Hearst-DD/ObjectMapper", majorVersion: 2, minor: 2),
        .Package(url: "https://github.com/jensravens/Interstellar", majorVersion: 2)
    ],
    exclude: ["Tests/"]
)
