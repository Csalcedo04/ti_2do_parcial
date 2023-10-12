{
  description = "Ambiente de desarrollo para parcial segundo corte de IpTI";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    R = pkgs.rWrapper.override {
      packages = with pkgs.rPackages; [
        rmarkdown
        languageserver
        fs
        formatR
      ];
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      nativeBuildInputs = with pkgs; [
        # DB
        mysql80
        # Web App
        nodejs_18
        # Docs
        R
        pandoc
        texlive.combined.scheme-full
        # Ansbile
        ansible
        ansible-language-server
        ansible-lint
        # Terraform
        terraform
        terraform-providers.azurerm
        terraform-ls
        azure-cli
        # Utilidades
        jq
        zip
        dig
      ];
    };
  };
}


