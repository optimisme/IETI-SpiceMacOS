import Foundation
import SpiceCore

enum CommandLineError: Error, LocalizedError {
    case missingFile
    case tooManyFiles
    case missingBackendValue
    case fileNotFound(String)
    case unreadableFile(String)
    case helpRequested

    var errorDescription: String? {
        switch self {
        case .missingFile:
            "Missing .vv file argument."
        case .tooManyFiles:
            "Only one .vv file can be launched at a time."
        case .missingBackendValue:
            "Missing value after --backend."
        case .fileNotFound(let path):
            "File not found: \(path)"
        case .unreadableFile(let path):
            "Could not read file as UTF-8: \(path)"
        case .helpRequested:
            nil
        }
    }
}

struct CommandLineOptions {
    var filePath: String?
    var backendPath: String?
    var printCommand = false
}

func parseArguments(_ arguments: [String]) throws -> CommandLineOptions {
    var options = CommandLineOptions()
    var index = 0

    while index < arguments.count {
        let argument = arguments[index]

        switch argument {
        case "-h", "--help":
            throw CommandLineError.helpRequested
        case "--print-command":
            options.printCommand = true
        case "--backend":
            let valueIndex = index + 1
            guard valueIndex < arguments.count else {
                throw CommandLineError.missingBackendValue
            }

            options.backendPath = arguments[valueIndex]
            index += 1
        default:
            if argument.hasPrefix("--backend=") {
                options.backendPath = String(argument.dropFirst("--backend=".count))
            } else if argument.hasPrefix("-") {
                throw BackendError.launchFailed("Unknown option: \(argument)")
            } else if options.filePath == nil {
                options.filePath = argument
            } else {
                throw CommandLineError.tooManyFiles
            }
        }

        index += 1
    }

    guard options.filePath != nil else {
        throw CommandLineError.missingFile
    }

    return options
}

func usage() -> String {
    """
    Usage: run-cmd.sh [--backend PATH] [--print-command] FILE.vv

    Launches FILE.vv directly with the configured SPICE backend, without opening
    the SpiceClient SwiftUI launcher.

    Options:
      --backend PATH    Use a specific spicy or remote-viewer executable.
      --print-command   Print the sanitized backend command before launching.
      -h, --help        Show this help.
    """
}

func displayMessage(for error: Error) -> String {
    let localizedError = error as? LocalizedError
    let description = localizedError?.errorDescription ?? error.localizedDescription
    guard let recoverySuggestion = localizedError?.recoverySuggestion, !recoverySuggestion.isEmpty else {
        return description
    }

    return "\(description)\n\n\(recoverySuggestion)"
}

do {
    let options = try parseArguments(Array(CommandLine.arguments.dropFirst()))
    let filePath = options.filePath!
    guard FileManager.default.fileExists(atPath: filePath) else {
        throw CommandLineError.fileNotFound(filePath)
    }

    guard let contents = String(data: try Data(contentsOf: URL(fileURLWithPath: filePath)), encoding: .utf8) else {
        throw CommandLineError.unreadableFile(filePath)
    }

    let imported = try VirtViewerFileParser.parse(contents)
    let launcher = BackendLauncher()
    let configuration = BackendConfiguration(customBackendPath: options.backendPath)

    if options.printCommand {
        let plan = try launcher.makeLaunchPlan(
            profile: imported.profile,
            password: imported.password,
            configuration: configuration
        )
        print(plan.sanitizedDescription)
    }

    let process = try launcher.launch(
        profile: imported.profile,
        password: imported.password,
        configuration: configuration
    )
    process.waitUntilExit()
    exit(process.terminationStatus)
} catch CommandLineError.helpRequested {
    print(usage())
} catch {
    fputs("Error: \(displayMessage(for: error))\n\n\(usage())\n", stderr)
    exit(1)
}
