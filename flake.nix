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
        terraformVersion = "1.16.5";
        terraformReleases = {
          x86_64-linux = { platform = "linux_amd64"; sha256 = "2bc2fcfff033265c9e02ca0351f01794eb122f62a9b2a49a3294b9e49eaab5e4"; };
          aarch64-linux = { platform = "linux_arm64"; sha256 = "61a50b00485ee4810cf20581ef080fc54d34d666e175c58d9a10501c65c1ccde"; };
          aarch64-darwin = { platform = "darwin_arm64"; sha256 = "ecdef65e24193d627f27c39baeda31295f08c938d8a3d4764f442fb916d4b7dc"; };
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
