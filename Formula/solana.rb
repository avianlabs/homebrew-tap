class Solana < Formula
  desc "Web-Scale Blockchain for decentralized apps and marketplaces"
  homepage "https://solana.com"
  url "https://github.com/solana-labs/solana/archive/refs/tags/v1.18.18.tar.gz"
  sha256 "2e534c9dba93bf21e08c5ba6744333bd535459d944e308bdf59e036f7c007a20"
  license "Apache-2.0"
  version_scheme 1

  # This formula tracks the stable channel but the "latest" release on GitHub
  # varies between Mainnet and Testnet releases. This only returns versions
  # from releases with "Mainnet" in the title (e.g. "Mainnet - v1.2.3").
  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :github_releases do |json, regex|
      json.map do |release|
        next if release["draft"] || release["prerelease"]
        next unless release["name"]&.downcase&.include?("mainnet")

        match = release["tag_name"]&.match(regex)
        next if match.blank?

        match[1]
      end
    end
  end

  bottle do
    root_url "https://ghcr.io/v2/avianlabs/tap"
    sha256 cellar: :any,                 arm64_sonoma: "60de43cdfc66ff333a1c3d8792d1a91d2afb74bff1ab7b288e8340885f20470e"
    sha256 cellar: :any,                 ventura:      "a7db839ff13746ad1295451f73708c6e2c79ed9a10c123f7d03ac6e8baf9d4b6"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "53b2afd7b5fbc000ea34c8239f9e231587ccd5eb889becf6f5ad1b7801552fef"
  end

  depends_on "protobuf" => :build
  depends_on "rust" => :build

  depends_on "openssl@3"

  uses_from_macos "llvm" => :build # for libclang
  uses_from_macos "zlib"

  on_linux do
    depends_on "pkg-config" => :build
    depends_on "systemd"
  end

  def install
    %w[
      cli
      bench-streamer
      faucet
      keygen
      log-analyzer
      net-shaper
      stake-accounts
      tokens
      watchtower
    ].each do |bin|
      system "cargo", "install", "--no-default-features", *std_cargo_args(path: bin)
    end

    # Note; the solana-test-validator is installed as bin of the validator cargo project, rather than
    # it's own dedicate project, hence why it's installed outside of the loop above
    system "cargo", "install", "--no-default-features",
      "--bin", "solana-test-validator", *std_cargo_args(path: "validator")
  end

  test do
    assert_match "Generating a new keypair",
      shell_output("#{bin}/solana-keygen new --no-bip39-passphrase --no-outfile")
    assert_match version.to_s, shell_output("#{bin}/solana-keygen --version")
  end
end
