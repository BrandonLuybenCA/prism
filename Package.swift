// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Prism",
    platforms: [.iOS(.v17)],
    products: [
        .executable(name: "Prism", targets: ["Prism"])
    ],
    targets: [
        .executableTarget(
            name: "Prism",
            path: "Sources"
        )
    ]
)
