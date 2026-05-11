# Homebrew

Moss has a source-building Homebrew tap at:

```text
https://github.com/urcades/homebrew-moss
```

## Install

```sh
brew tap urcades/moss
brew install moss
```

Then finish setup:

```sh
cd ~
mossctl configure --safety standard
moss-open
mossctl doctor
```

Open `Trusted Senders...`, add a sender, grant the macOS permissions Doctor
reports, then send `/status` from the trusted sender.

## What The Formula Installs

- `MessagesCodexBridge.app` under Homebrew's Cellar/opt prefix.
- `mossctl`, the bridge control CLI.
- `moss-open`, a small launcher for the menu-bar app.

The formula builds from the tagged source release. It does not download or
install a notarized binary artifact.

## Working Directory

Runtime config stores the Codex working directory. For a fresh install, run
`mossctl configure` from the directory you want Codex to use, or set
`MOSS_CODEX_CWD` when launching:

```sh
MOSS_CODEX_CWD=/path/to/workspace moss-open
```

Existing runtime config is preserved unless you edit or recreate it.

## Maintainer Update Checklist

When publishing a new moss release:

1. Create and push the moss release tag.
2. Download the tag archive and compute its SHA-256:

```sh
curl -L https://github.com/urcades/moss/archive/refs/tags/vX.Y.Z.tar.gz -o /tmp/moss-vX.Y.Z.tar.gz
shasum -a 256 /tmp/moss-vX.Y.Z.tar.gz
```

3. Update `Formula/moss.rb` in `urcades/homebrew-moss`.
4. Run:

```sh
brew tap urcades/moss /path/to/homebrew-moss
brew audit --strict --online urcades/moss/moss
brew reinstall --build-from-source urcades/moss/moss
brew test urcades/moss/moss
```

5. Push the tap change.
