import Foundation

public struct Project: Hashable, Sendable {
    public let root: String   // raiz do git; senão o próprio cwd
    public let name: String   // "name" do package.json da raiz; senão nome da pasta
}

/// Em ordem: o primeiro kind com algum token na linha de comando ganha.
private let kindTokens: [(kind: String, tokens: Set<String>)] = [
    ("VITE", ["vite"]),
    ("NEXT", ["next", "next-server"]),
    ("NUXT", ["nuxt", "nuxi"]),
    ("ASTRO", ["astro"]),
    ("REMIX", ["remix", "remix-serve"]),
    ("STORYBOOK", ["storybook"]),
    ("EXPO", ["expo", "metro"]),
    ("WEBPACK", ["webpack", "webpack-dev-server"]),
    ("RAILS", ["rails", "puma"]),
    ("DJANGO", ["runserver"]),
    ("UVICORN", ["uvicorn"]),
    ("FLASK", ["flask"]),
    ("HTTP.SERVER", ["http.server"]),
    ("POSTGRES", ["postgres"]),
    ("REDIS", ["redis-server"]),
    ("MYSQL", ["mysqld"]),
    ("MONGO", ["mongod"]),
]

/// Compara o **último componente** de cada token (`…/vite/bin/vite.js` → `vite`),
/// então nomes de pasta como `~/dev/next-gen/server.js` não dão falso positivo.
func detectKind(command: String, executable: String) -> String? {
    let tokens = Set((command.split(separator: " ") + [Substring(executable)]).map { token in
        var name = token.split(separator: "/").last.map(String.init) ?? ""
        for ext in [".js", ".mjs", ".cjs", ".ts"] where name.hasSuffix(ext) {
            name.removeLast(ext.count)
        }
        return name
    })
    return kindTokens.first { !$0.tokens.isDisjoint(with: tokens) }?.kind
}

/// Sobe a partir do `cwd` até um `.git` (pasta ou arquivo de worktree), sem passar de `home`.
func resolveProject(cwd: String, home: String = NSHomeDirectory()) -> Project {
    let fm = FileManager.default
    var dir = URL(fileURLWithPath: cwd)
    var root = cwd
    while dir.path == home || dir.path.hasPrefix(home + "/") {
        if fm.fileExists(atPath: dir.appending(path: ".git").path) {
            root = dir.path
            break
        }
        if dir.path == home { break }
        dir.deleteLastPathComponent()
    }
    let rootURL = URL(fileURLWithPath: root)
    let package = (try? Data(contentsOf: rootURL.appending(path: "package.json")))
        .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
    let name = (package?["name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? rootURL.lastPathComponent
    return Project(root: root, name: name)
}
