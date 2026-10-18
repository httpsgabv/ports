import Foundation
import Testing
@testable import PortsCore

@Suite struct IdentityTests {
    static let kinds: [(command: String, executable: String, kind: String?)] = [
        ("node /Users/g/dev/yt-city/node_modules/.bin/../.pnpm/vite@8.3.4/node_modules/vite/bin/vite.js --port 5174", "node", "VITE"),
        ("node /Users/g/dev/site/node_modules/.bin/next dev --port 3000", "node", "NEXT"),
        ("next-server (v15.1.0)", "next-server (v15.1.0)", "NEXT"),
        ("node /Users/g/dev/a/node_modules/.bin/nuxi dev", "node", "NUXT"),
        ("node /Users/g/dev/a/node_modules/.bin/astro dev", "node", "ASTRO"),
        ("node /Users/g/dev/a/node_modules/.bin/remix-serve build", "node", "REMIX"),
        ("node /Users/g/dev/a/node_modules/.bin/storybook dev -p 6006", "node", "STORYBOOK"),
        ("node /Users/g/dev/a/node_modules/.bin/expo start", "node", "EXPO"),
        ("node /Users/g/dev/a/node_modules/.bin/webpack-dev-server", "node", "WEBPACK"),
        ("ruby bin/rails server", "ruby", "RAILS"),
        ("puma 6.4.2 (tcp://0.0.0.0:3000) [api]", "puma 6.4.2", "RAILS"),
        ("/usr/local/bin/python3 manage.py runserver 8000", "Python", "DJANGO"),
        ("/Users/g/dev/a/.venv/bin/python /Users/g/dev/a/.venv/bin/uvicorn main:app --reload", "Python", "UVICORN"),
        ("python3 -m flask run", "Python", "FLASK"),
        ("/Library/Frameworks/Python.framework/Versions/3.14/Resources/Python.app/Contents/MacOS/Python -m http.server 8765", "/Library/Frameworks/Python.framework/Versions/3.14/Resources/Python.app/Contents/MacOS/Python", "HTTP.SERVER"),
        ("/opt/homebrew/opt/postgresql@16/bin/postgres -D /opt/homebrew/var/postgresql@16", "/opt/homebrew/opt/postgresql@16/bin/postgres", "POSTGRES"),
        ("/opt/homebrew/opt/redis/bin/redis-server 127.0.0.1:6379", "/opt/homebrew/opt/redis/bin/redis-server", "REDIS"),
        ("/opt/homebrew/opt/mysql/bin/mysqld --basedir=/opt/homebrew", "/opt/homebrew/opt/mysql/bin/mysqld", "MYSQL"),
        ("/opt/homebrew/opt/mongodb-community/bin/mongod --config x", "/opt/homebrew/opt/mongodb-community/bin/mongod", "MONGO"),
        // falsos positivos: nomes de pasta não contam
        ("node /Users/g/dev/next-gen/server.js", "node", nil),
        ("node /Users/g/dev/vite-playground/index.js", "node", nil),
        ("/Applications/Raycast.app/Contents/MacOS/Raycast", "/Applications/Raycast.app/Contents/MacOS/Raycast", nil),
    ]

    @Test(arguments: kinds)
    func kind(command: String, executable: String, kind: String?) {
        #expect(detectKind(command: command, executable: executable) == kind)
    }

    // MARK: resolveProject

    let home: URL
    init() throws {
        home = FileManager.default.temporaryDirectory.appending(path: "ports-identity-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
    }

    private func dir(_ path: String) throws -> String {
        let url = home.appending(path: path)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url.path
    }

    private func file(_ path: String, _ contents: String) throws {
        try contents.write(to: home.appending(path: path), atomically: true, encoding: .utf8)
    }

    @Test func gitRootWithPackageName() throws {
        _ = try dir("mono/.git")
        try file("mono/package.json", #"{"name": "@me/mono", "private": true}"#)
        let web = try dir("mono/apps/web")
        let project = resolveProject(cwd: web, home: home.path)
        #expect(project == Project(root: home.appending(path: "mono").path, name: "@me/mono"))
    }

    @Test func gitFileWorktreeCounts() throws {
        _ = try dir("wt")
        try file("wt/.git", "gitdir: /elsewhere/.git/worktrees/wt")
        let sub = try dir("wt/src")
        #expect(resolveProject(cwd: sub, home: home.path).root == home.appending(path: "wt").path)
    }

    @Test func noGitFallsBackToCwdAndFolderName() throws {
        let plain = try dir("plain/sub")
        #expect(resolveProject(cwd: plain, home: home.path) == Project(root: plain, name: "sub"))
    }

    @Test func invalidPackageJsonFallsBackToFolderName() throws {
        _ = try dir("broken/.git")
        try file("broken/package.json", "{ not json")
        let root = home.appending(path: "broken").path
        #expect(resolveProject(cwd: root, home: home.path) == Project(root: root, name: "broken"))
    }

    @Test func neverClimbsAboveHome() throws {
        // .git acima do home (no diretório pai) não pode ser usado
        let inner = try dir("h/project")
        _ = try dir(".git")
        let fakeHome = home.appending(path: "h").path
        #expect(resolveProject(cwd: inner, home: fakeHome) == Project(root: inner, name: "project"))
    }

    @Test func outsideHomeUsesCwd() {
        #expect(resolveProject(cwd: "/private/tmp/x", home: home.path) == Project(root: "/private/tmp/x", name: "x"))
    }
}
