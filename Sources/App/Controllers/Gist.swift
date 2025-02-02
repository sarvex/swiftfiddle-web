import Vapor

struct Gist: Codable {
    let url: String
    let id: String
    let files: [String: File]

    struct File: Codable {
        let filename: String
        let type: String
        let language: String?
        let raw_url: String
        let size: Int
        let truncated: Bool
        let content: String
    }

    static func id(from path: String) throws -> String? {
        guard let pattern = try? NSRegularExpression(pattern: #"^([a-f0-9]{32}(|.png))$"#, options: [.caseInsensitive]) else {
            throw Abort(.internalServerError)
        }

        let matches = pattern.matches(in: path, options: [], range: NSRange(location: 0, length: path.utf16.count))
        guard matches.count == 1 && matches[0].numberOfRanges == 3 else {
            return nil
        }
        
        return path
    }

    static func content(client: Client, id: String) async throws -> Gist {
        let response = try await client.send(
            ClientRequest(
                method: .GET,
                url: "https://api.github.com/gists/\(id)",
                headers: ["User-Agent": "SwiftFiddle"]
            )
        )
        guard let body = response.body else { throw Abort(.notFound) }

        let content = try JSONDecoder().decode(Gist.self, from: body)
        return content
    }
}
