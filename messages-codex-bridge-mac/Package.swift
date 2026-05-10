// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MessagesCodexBridgeMac",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "BridgeCore", targets: ["BridgeCore"]),
        .executable(name: "MessagesCodexBridgeApp", targets: ["MessagesCodexBridgeApp"]),
        .executable(name: "MessagesCodexBridgeHelper", targets: ["MessagesCodexBridgeHelper"]),
        .executable(name: "MessagesCodexPermissionBroker", targets: ["MessagesCodexPermissionBroker"]),
        .executable(name: "codexmsgctl-swift", targets: ["codexmsgctl-swift"]),
        .executable(name: "BridgeCoreSelfTest", targets: ["BridgeCoreSelfTest"]),
        .executable(name: "BridgeCoreTests", targets: ["BridgeCoreTests"])
    ],
    targets: [
        .target(name: "BridgeCore"),
        .executableTarget(
            name: "MessagesCodexBridgeApp",
            dependencies: ["BridgeCore"],
            linkerSettings: [.linkedFramework("AppKit"), .linkedFramework("ServiceManagement")]
        ),
        .executableTarget(
            name: "MessagesCodexBridgeHelper",
            dependencies: ["BridgeCore"]
        ),
        .executableTarget(
            name: "MessagesCodexPermissionBroker",
            dependencies: ["BridgeCore"],
            linkerSettings: [.linkedFramework("AppKit"), .linkedFramework("ApplicationServices")]
        ),
        .executableTarget(
            name: "codexmsgctl-swift",
            dependencies: ["BridgeCore"]
        ),
        .executableTarget(
            name: "BridgeCoreSelfTest",
            dependencies: ["BridgeCore"]
        ),
        .executableTarget(
            name: "BridgeCoreTests",
            dependencies: ["BridgeCore"]
        )
    ]
)
