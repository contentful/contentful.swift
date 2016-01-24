import PackageDescription

let package = Package(
    name: "Contentful",
    dependencies: [
        .Package(url: "https://github.com/neonichu/Decodable", majorVersion: 0, minor: 4),
        .Package(url: "https://github.com/neonichu/Interstellar", majorVersion: 1, minor: 5),
    ]
)

let dep = Package.Dependency.self

#if os(Linux)
package.dependencies.append(dep.Package(url: "https://github.com/neonichu/RequestSession", majorVersion: 0))
#else
package.dependencies.append(dep.Package(url: "https://github.com/neonichu/Clock", majorVersion: 0))
#endif
