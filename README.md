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

## Notes

- Clipboard support is handled by `spice-gtk` and usually requires `spice-vdagent` inside the guest VM.
- Audio and USB redirection are disabled by default.
- This project does not bundle or redistribute `spice-gtk`; users install it locally with Homebrew.
