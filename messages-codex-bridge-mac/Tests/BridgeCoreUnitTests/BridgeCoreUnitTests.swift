import BridgeCore

func bridgeCoreUnitTestCompileProbe() {
    _ = bridgeLocalCommandName("/codex status")
    _ = normalizedTrustedSenderIdentity("User@Example.COM")
}
