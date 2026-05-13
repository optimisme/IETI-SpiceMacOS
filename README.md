# SpiceClient

SpiceClient is a small macOS SwiftUI launcher for SPICE remote desktop sessions.

It lets you choose a `.vv` virt-viewer file and launches the session with the Homebrew `spice-gtk` backend (`spicy`). 


## Install Dependencies

Install Xcode Command Line Tools if needed:

```bash
xcode-select --install
```

Install Homebrew dependencies:

```bash
brew install spice-gtk
```

Check that the SPICE GTK launcher is available:

```bash
which spicy
```

## Run

From this directory:

```bash
./run.sh
```

In the app:

1. Click `Choose .vv File`.
2. Select your `.vv` file.
3. Click `Launch Spice GTK`.

The app builds a local `SpiceClient.app` under `.build/release/` and launches it.

## Run Without the Launcher UI

To launch a `.vv` file directly from the terminal, use:

```bash
./run-cmd.sh path/to/session.vv
```

This builds and runs the `SpiceCmd` command-line target, parses the `.vv` file with
the same `SpiceCore` parser used by the app, and launches the SPICE backend without
opening the SwiftUI launcher window. The SPICE viewer itself still opens its normal
remote desktop window.

Useful options:

```bash
./run-cmd.sh --print-command path/to/session.vv
./run-cmd.sh --backend /opt/homebrew/bin/spicy path/to/session.vv
```

## Notes

- Clipboard support is handled by `spice-gtk` and usually requires `spice-vdagent` inside the guest VM.
- Audio and USB redirection are disabled by default.
- This project does not bundle or redistribute `spice-gtk`; users install it locally with Homebrew.
