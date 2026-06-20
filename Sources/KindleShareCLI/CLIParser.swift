import Foundation

public enum CLICommand: Equatable {
    case serve(folder: URL, port: UInt16)
}

public enum CLIParser {
    public enum ParseError: LocalizedError, Equatable {
        case missingCommand
        case unknownCommand(String)
        case missingFolder
        case missingValue(String)
        case invalidPort(String)
        case unknownOption(String)

        public var errorDescription: String? {
            switch self {
            case .missingCommand:
                "Missing command."
            case .unknownCommand(let command):
                "Unknown command: \(command)"
            case .missingFolder:
                "Missing required option: --folder"
            case .missingValue(let option):
                "Missing value for \(option)."
            case .invalidPort(let value):
                "Invalid port: \(value)"
            case .unknownOption(let option):
                "Unknown option: \(option)"
            }
        }
    }

    public static func parse(_ arguments: [String]) throws -> CLICommand {
        guard let command = arguments.first else {
            throw ParseError.missingCommand
        }

        switch command {
        case "serve":
            return try parseServe(Array(arguments.dropFirst()))
        case "-h", "--help", "help":
            throw ParseError.missingCommand
        default:
            throw ParseError.unknownCommand(command)
        }
    }

    private static func parseServe(_ arguments: [String]) throws -> CLICommand {
        var folder: URL?
        var port: UInt16 = 8787
        var index = 0

        while index < arguments.count {
            let option = arguments[index]

            switch option {
            case "--folder", "-f":
                let value = try value(after: option, in: arguments, at: index)
                folder = URL(filePath: value)
                index += 2
            case "--port", "-p":
                let value = try value(after: option, in: arguments, at: index)
                guard let parsedPort = UInt16(value), parsedPort > 0 else {
                    throw ParseError.invalidPort(value)
                }
                port = parsedPort
                index += 2
            default:
                throw ParseError.unknownOption(option)
            }
        }

        guard let folder else {
            throw ParseError.missingFolder
        }

        return .serve(folder: folder, port: port)
    }

    private static func value(after option: String, in arguments: [String], at index: Int) throws -> String {
        let valueIndex = index + 1
        guard valueIndex < arguments.count else {
            throw ParseError.missingValue(option)
        }
        return arguments[valueIndex]
    }
}
