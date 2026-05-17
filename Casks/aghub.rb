cask "aghub" do
  arch arm: "aarch64", intel: "x64"

  version "1.1.0"
  sha256 arm:   "857d9b3c9128d5196ca8bf0db2e2c76350d03178c7ac6aaa123966eb78b7d304",
         intel: "8c7d379398283c50e58485b132ac73afa7a9250150c214a3d024b5793955ab2a"

  url "https://github.com/AkaraChen/aghub/releases/download/v#{version}/aghub_#{arch}.app.tar.gz",
      verified: "github.com/AkaraChen/aghub/"
  name "aghub"
  desc "Manage configuration for AI coding agents"
  homepage "https://aghub.akr.moe/"

  livecheck do
    url "https://github.com/AkaraChen/aghub"
    strategy :github_latest
  end

  depends_on :macos

  app "aghub.app"

  zap trash: [
    "~/Library/Application Support/com.akrc.aghub",
    "~/Library/Caches/com.akrc.aghub",
    "~/Library/Preferences/com.akrc.aghub.plist",
    "~/Library/Saved Application State/com.akrc.aghub.savedState",
    "~/Library/WebKit/com.akrc.aghub",
  ]
end
