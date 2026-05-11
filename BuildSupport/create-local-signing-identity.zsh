#!/bin/zsh
set -euo pipefail

IDENTITY_NAME="${IDENTITY_NAME:-Messages Codex Bridge Local Code Signing}"
KEYCHAIN="${KEYCHAIN:-$HOME/Library/Keychains/login.keychain-db}"
P12_PASSWORD="${P12_PASSWORD:-mcb-local-signing}"

if security find-identity -v -p codesigning -s "$IDENTITY_NAME" "$KEYCHAIN" 2>/dev/null | grep -q 'valid identities found'; then
  echo "$IDENTITY_NAME"
  exit 0
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

openssl req \
  -x509 \
  -newkey rsa:2048 \
  -nodes \
  -days 3650 \
  -subj "/CN=$IDENTITY_NAME/" \
  -addext "keyUsage=digitalSignature" \
  -addext "extendedKeyUsage=codeSigning" \
  -keyout "$TMPDIR/key.pem" \
  -out "$TMPDIR/cert.pem" >/dev/null 2>&1

openssl pkcs12 \
  -export \
  -out "$TMPDIR/identity.p12" \
  -inkey "$TMPDIR/key.pem" \
  -in "$TMPDIR/cert.pem" \
  -passout "pass:$P12_PASSWORD" >/dev/null 2>&1

security import "$TMPDIR/identity.p12" \
  -k "$KEYCHAIN" \
  -P "$P12_PASSWORD" \
  -A \
  -T /usr/bin/codesign >/dev/null

security add-trusted-cert \
  -r trustRoot \
  -p codeSign \
  -k "$KEYCHAIN" \
  "$TMPDIR/cert.pem" >/dev/null 2>&1 || true

echo "$IDENTITY_NAME"
