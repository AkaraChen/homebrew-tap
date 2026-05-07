cask "aghub" do
  arch arm: "aarch64", intel: "x64"

  version "1.1.0"
  sha256 arm:   "29a2ed107f337e01ae7271effb1f12b75ef3bde148f64036b0b2c761a49e7da7",
         intel: "e9e38bf12d1f4d1afb87ae4b68bde90e6e0d83ac4a5cebfa2cb20eb70f369182"

  url "https://github.com/AkaraChen/aghub/releases/download/v#{version}/aghub_#{arch}.app.tar.gz",
      verified: "github.com/AkaraChen/aghub/"
  name "aghub"
  desc "Manage configuration for AI coding agents"
  homepage "https://aghub.akr.moe/"

  livecheck do
    url "https://github.com/AkaraChen/aghub"
    strategy :github_latest
  end

  app "aghub.app"

  zap trash: [
    "~/Library/Application Support/com.akrc.aghub",
    "~/Library/Caches/com.akrc.aghub",
    "~/Library/Preferences/com.akrc.aghub.plist",
    "~/Library/Saved Application State/com.akrc.aghub.savedState",
    "~/Library/WebKit/com.akrc.aghub",
  ]
end
