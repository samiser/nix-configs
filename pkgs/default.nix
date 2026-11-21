final: _prev: {
  hyperline = final.callPackage ./hyperline/package.nix { };
  statlocker-companion = final.callPackage ./statlocker-companion/package.nix { };
}
