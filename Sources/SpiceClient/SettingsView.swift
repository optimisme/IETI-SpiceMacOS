import SpiceCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Section("Backend") {
                HStack {
                    TextField("spicy path", text: $model.backendPath)
                    Button {
                        model.chooseBackendPath()
                    } label: {
                        Label("Choose", systemImage: "folder")
                    }
                }
                Toggle("Show diagnostics", isOn: $model.showDiagnostics)
                Text(model.backendStatus())
                    .foregroundStyle(.secondary)
            }

            if model.showDiagnostics {
                Section("Search Paths") {
                    ForEach(model.backendDiagnostics(), id: \.path) { candidate in
                        HStack(spacing: 12) {
                            Image(systemName: iconName(for: candidate))
                                .foregroundStyle(candidate.isExecutable ? .green : .secondary)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(candidate.path)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Text(statusText(for: candidate))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Open Source Notices") {
                    ForEach(OpenSourceNotices.current) { notice in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(notice.name)
                                    .font(.headline)
                                Spacer()
                                Text(notice.license)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text(notice.role)
                                .foregroundStyle(.secondary)

                            Text(notice.distributionNotes)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Link(notice.sourceURL.absoluteString, destination: notice.sourceURL)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Compatibility") {
                    ForEach(CompatibilityMatrix.current) { feature in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(feature.name)
                                    .font(.headline)
                                Spacer()
                                Text(feature.status.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text(feature.details)
                                .foregroundStyle(.secondary)

                            Text(feature.validationStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 680, height: 460)
        .onChange(of: model.backendPath) { _, _ in model.persistSettings() }
        .onChange(of: model.showDiagnostics) { _, _ in model.persistSettings() }
    }

    private func iconName(for candidate: BackendCandidate) -> String {
        if candidate.isExecutable {
            return "checkmark.circle.fill"
        }

        if candidate.exists {
            return "exclamationmark.triangle"
        }

        return "circle"
    }

    private func statusText(for candidate: BackendCandidate) -> String {
        if candidate.isExecutable {
            return "\(candidate.source.rawValue) · \(candidate.kind.rawValue) · executable"
        }

        if candidate.exists {
            return "\(candidate.source.rawValue) · \(candidate.kind.rawValue) · found but not executable"
        }

        return "\(candidate.source.rawValue) · \(candidate.kind.rawValue) · not found"
    }
}
