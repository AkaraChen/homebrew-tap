cask "2code" do
  arch arm: "aarch64", intel: "x64"

  version "2.1.0"
  sha256 arm:   "b6ac40172a35841edc633fa16f6b730cb65477a618bf55712e7e681f4d14e24f",
         intel: "0c56357e4b252fdcad9b5682fcfcd22b123504a504872287778c270006652aa6"

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

  depends_on :macos

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
