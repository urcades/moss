import BridgeCore

// Keeps `swift test` meaningful on this toolchain, which lacks XCTest/Testing.
func bridgeCoreUnitTestCompileProbe() {
    _ = bridgeLocalCommandName("/codex status")
    _ = normalizedTrustedSenderIdentity("User@Example.COM")
}
