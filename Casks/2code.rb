cask "2code" do
  version "1.4.2"
  sha256 "f25b21d80a3829a70e46b74f925f337f24aa6959a664c5f68b280e65fe91946b"

  url "https://github.com/AkaraChen/2code/releases/download/v#{version}/two-code_#{version}_aarch64.dmg",
      verified: "github.com/AkaraChen/2code/"
  name "2code"
  name "two-code"
  desc "Desktop workspace for terminal, AI agents, and git"
  homepage "https://2code.akr.moe/"

  livecheck do
    url "https://github.com/AkaraChen/2code"
    strategy :github_latest
  end

  depends_on arch: :arm64

  app "two-code.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/two-code.app"]
  end

  zap trash: [
    "~/Library/Application Support/com.akrc.code",
    "~/Library/Caches/com.akrc.code",
    "~/Library/Logs/com.akrc.code",
    "~/Library/Preferences/com.akrc.code.plist",
    "~/Library/Saved Application State/com.akrc.code.savedState",
    "~/Library/WebKit/com.akrc.code",
  ]

  caveats <<~EOS
    2code is not signed with an Apple Developer ID. This cask removes the
    quarantine attribute from the installed app so macOS can open it.
  EOS
end
