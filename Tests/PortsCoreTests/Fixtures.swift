// Real output captured on macOS 26.6 (trimmed).
enum Fixture {
    static let lsofListen = """
    p620
    crapportd
    f10
    n*:58996
    f14
    n*:58996
    p627
    cControlCenter
    f9
    n*:7000
    f10
    n*:7000
    f11
    n*:5000
    f12
    n*:5000
    p41643
    cRaycast
    f16
    n127.0.0.1:7265
    p47102
    cnode
    f26
    n[::1]:5174
    p97731
    cfigma_agent
    f6
    n127.0.0.1:44950

    """

    static let psDetails = """
      620 Sun Sep 27 11:32:32 2026       0.0  14464 /usr/libexec/rapportd
      627 Sun Sep 27 11:32:32 2026       0.0  82032 /System/Library/CoreServices/ControlCenter.app/Contents/MacOS/ControlCenter
    41643 Wed Sep 30 21:45:35 2026       0.0  36192 /Applications/Raycast.app/Contents/MacOS/Raycast
    47102 Sat Oct 17 21:15:53 2026       1.5  16496 node
    97731 Thu Oct  1 19:53:42 2026       0.0  11136 /Users/gabriel/Library/Application Support/Figma/FigmaAgent.app/Contents/MacOS/figma_agent

    """

    static let psCommand = """
      620 /usr/libexec/rapportd
      627 /System/Library/CoreServices/ControlCenter.app/Contents/MacOS/ControlCenter
    41643 /Applications/Raycast.app/Contents/MacOS/Raycast UPDATED_VERSION AUTOMATIC_UPDATE
    47102 node /Users/gabriel/Documents/dev/yt-city/node_modules/vite/bin/vite.js --port 5174 --strictPort
    97731 /Users/gabriel/Library/Application Support/Figma/FigmaAgent.app/Contents/MacOS/figma_agent

    """

    static let lsofCwd = """
    p620
    fcwd
    n/
    p47102
    fcwd
    n/Users/gabriel/Documents/dev/yt-city
    p97731
    fcwd
    n/

    """

    // `lsof -nP -iTCP -sTCP:LISTEN,ESTABLISHED -Fpcn` real (17/out), + um node com conexão de saída.
    static let lsofTCP = """
    p620
    crapportd
    f10
    n*:58996
    f20
    n172.20.10.11:58996->172.20.10.1:58465
    p671
    cidentityservicesd
    f12
    n172.20.10.11:61000->17.57.146.20:5223
    p900
    cnode
    f20
    n[::1]:3000
    f21
    n127.0.0.1:60001->127.0.0.1:5432
    p7359
    cPython
    f3
    n127.0.0.1:8781
    f4
    n127.0.0.1:8781->127.0.0.1:64384
    f5
    n127.0.0.1:8781->127.0.0.1:64390
    p7373
    cnc
    f3
    n127.0.0.1:64384->127.0.0.1:8781

    """
}
