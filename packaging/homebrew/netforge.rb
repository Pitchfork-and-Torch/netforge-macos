# Homebrew formula stub — not yet in homebrew-core.
# Usage (after tap): brew install pitchfork-and-torch/tap/netforge
class Netforge < Formula
  desc "Local network performance tuning and optional hardening for macOS"
  homepage "https://netforge.jonbailey.xyz"
  url "https://github.com/Pitchfork-and-Torch/netforge-macos/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "REPLACE_WITH_SHA256"
  license "MIT"

  def install
    prefix.install Dir["*"]
  end

  def caveats
    <<~EOS
      Install system hooks (requires sudo):
        sudo #{opt_prefix}/src/install-network-auto.sh
      Status (no root):
        #{opt_prefix}/src/netforge-status.sh
    EOS
  end

  test do
    assert_match "NetForge", shell_output("#{opt_prefix}/src/netforge-status.sh --json")
  end
end
