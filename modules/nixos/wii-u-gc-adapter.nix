{ lib, stdenv, fetchFromGitHub, pkg-config, udev, libusb1 }:

stdenv.mkDerivation rec {
  pname = "wii-u-gc-adapter-service";
  version = "unstable-2024-01-01"; # Update this date as needed

  src = fetchFromGitHub {
    owner = "vgfreak95";
    repo = "wii-u-gc-adapter-service";
    rev = "master";
    sha256 = "sha256-CmKH0M5GXV/y9yii4fqNqpElLd7ez/h3LTsMycycCAk=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    udev
    libusb1
  ];

  # Patch the Makefile to use dynamic libraries instead of static ones
  preBuild = ''
    export NIX_LDFLAGS="-lusb-1.0 -ludev $NIX_LDFLAGS"

    # Create symlinks with the static library names pointing to the shared libraries
    mkdir -p staticlibs
    echo  ${udev}/lib
    ls ${udev}/lib/
    ln -sf ${libusb1}/lib/libusb-1.0.so staticlibs/libusb-1.0.a
    ln -sf ${udev}/lib/libudev.so staticlibs/libudev.a
    export LIBRARY_PATH=$LIBRARY_PATH:$(pwd)/staticlibs
  '';

  # Patch the makefile to fix the warning issue
  postPatch = ''
    substituteInPlace Makefile \
      --replace "-Wno-format" "-Wformat"
   '';

  # The makefile should handle the build process
  buildPhase = ''
    runHook preBuild
    make
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Install the binary
    mkdir -p $out/bin
    cp wii-u-gc-adapter $out/bin

    runHook postInstall
  '';

  meta = with lib; {
    description = "Service for Wii U GameCube Controller Adapter";
    homepage = "https://github.com/vgfreak95/wii-u-gc-adapter-service";
    license = licenses.unfree; # Update with actual license if known
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
