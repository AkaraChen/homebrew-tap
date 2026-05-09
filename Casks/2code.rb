cask "2code" do
  arch arm: "aarch64", intel: "x64"

  version "2.0.0"
  sha256 arm:   "8f5fc4f3924081abd924ae0587c3f480a5e440499e353159047d0499c3557796",
         intel: "3461886357118e6e01e0a3309e913582e5651ed00cdccc64ba8e97f896a407fa"

  url "https://github.com/AkaraChen/2code/releases/download/v#{version}/2code_#{version}_#{arch}.dmg",
      verified: "github.com/AkaraChen/2code/"
  name "2code"
  name "two-code"
  desc "Desktop workspace for terminal, AI agents, and git"
  homepage "https://2code.akr.moe/"

  livecheck do
    url "https://github.com/AkaraChen/2code"
    strategy :github_latest
  end

  app "2code.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/2code.app"]
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
