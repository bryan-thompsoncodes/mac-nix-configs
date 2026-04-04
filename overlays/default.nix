{inputs, ...}: {
  # Unstable nixpkgs overlay - makes pkgs.unstable available
  unstable = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
  # Zen Browser overlay - makes pkgs.zen-browser available
  zen-browser = final: _prev: {
    zen-browser = inputs.zen-browser.packages.x86_64-linux.beta;
  };
}
