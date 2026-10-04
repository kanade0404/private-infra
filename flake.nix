{
  description = "private-infra dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    # The locked nixpkgs no longer supports Intel macOS.
    flake-utils.lib.eachSystem [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "terraform";
        };
        # GCP's required_version is exact. Keep the official CLI pinned separately
        # from nixpkgs so a flake update cannot silently change it.
        terraformVersion = "1.11.4";
        terraformReleases = {
          x86_64-linux = { platform = "linux_amd64"; sha256 = "1ce994251c00281d6845f0f268637ba50c0005657eb3cf096b92f753b42ef4dc"; };
          aarch64-linux = { platform = "linux_arm64"; sha256 = "a43d1d0da9b9bab214a8305a39db0e40869572594ccf50c416a7756499143633"; };
          aarch64-darwin = { platform = "darwin_arm64"; sha256 = "867e0808fa971217043e25b7a792b10720c79b1546f8a68479b74f138be73e18"; };
        };
        release = terraformReleases.${system};
        terraform = pkgs.stdenvNoCC.mkDerivation {
          pname = "terraform";
          version = terraformVersion;
          src = pkgs.fetchurl {
            url = "https://releases.hashicorp.com/terraform/${terraformVersion}/terraform_${terraformVersion}_${release.platform}.zip";
            inherit (release) sha256;
          };
          nativeBuildInputs = [ pkgs.unzip ];
          sourceRoot = ".";
          dontBuild = true;
          installPhase = ''
            runHook preInstall
            install -Dm755 terraform "$out/bin/terraform"
            install -Dm644 LICENSE.txt "$out/share/licenses/terraform/LICENSE.txt"
            runHook postInstall
          '';
          meta = {
            description = "Terraform CLI for the GCP stack";
            homepage = "https://developer.hashicorp.com/terraform";
            license = pkgs.lib.licenses.bsl11;
            platforms = builtins.attrNames terraformReleases;
            mainProgram = "terraform";
          };
        };
      in
      {
        packages = {
          inherit terraform;
          inherit (pkgs) trivy;
        };
        devShells.default = pkgs.mkShell {
          packages = [ terraform ] ++ (with pkgs; [
            opentofu
            tflint
            trivy
            terraform-docs
            awscli2
            google-cloud-sdk
            jq
            lefthook
            nodejs
            actionlint
            shellcheck
          ]);
        };
      });
}
