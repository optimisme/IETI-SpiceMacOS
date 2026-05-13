import SpiceCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                Image(systemName: "display.and.arrow.down")
                    .font(.system(size: 54, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)

                Text("SpiceClient")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("Open a SPICE .vv file and connect with the Homebrew spice-gtk backend.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
            }

            VStack(spacing: 14) {
                Button {
                    model.chooseVirtViewerFile()
                } label: {
                    Label("Choose .vv File", systemImage: "doc.badge.plus")
                        .font(.headline)
                        .frame(minWidth: 180)
                }
                .controlSize(.large)
                .buttonStyle(.bordered)

                if model.selectedConnection != nil {
                    Button {
                        model.launchSelectedConnection()
                    } label: {
                        Label("Launch Spice GTK", systemImage: "play")
                            .font(.headline)
                            .frame(minWidth: 180)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.canLaunch)
                }
            }

            VStack(spacing: 8) {
                if let selectedFileName = model.selectedFileName {
                    Text(selectedFileName)
                        .font(.headline)
                }

                if !model.isBackendAvailable {
                    Label {
                        Text(model.backendInstallMessage)
                            .multilineTextAlignment(.leading)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                    .font(.callout)
                    .foregroundStyle(.red)
                    .padding(12)
                    .frame(maxWidth: 520, alignment: .leading)
                    .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                }

                Text(model.statusMessage)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text(model.backendStatus())
                    .font(.caption)
                    .foregroundStyle(model.backendStatus().contains("not found") ? .red : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 620)
        }
        .padding(42)
        .frame(minWidth: 760, minHeight: 520)
        .onOpenURL { url in
            if url.pathExtension.lowercased() == "vv" {
                model.openVirtViewerFile(at: url)
            }
        }
        .alert("SpiceClient", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}
