{ stdenv, lib, fetchurl, autoPatchelfHook, gzip }:

stdenv.mkDerivation rec {
  pname = "libftd2xx";
  version = "1.4.27";

  src = fetchurl {
    url = "https://ftdichip.com/wp-content/uploads/2022/07/libftd2xx-x86_64-${version}.tgz";
    sha256 = "sha256-U3/J224e6hEN12YZgtxJoo3iKkUUtYjoozohEQpba0w=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  unpackPhase = ''
    tar xf $src
  '';

  installPhase = ''
    mkdir -p $out/lib $out/include
    cp release/build/libftd2xx.so.${version} $out/lib/
    ln -s $out/lib/libftd2xx.so.${version} $out/lib/libftd2xx.so
    cp release/ftd2xx.h release/WinTypes.h $out/include/
  '';

  meta = with lib; {
    description = "FTDI proprietary D2XX driver library";
    homepage = "https://ftdichip.com/drivers/d2xx-drivers/";
    license = licenses.unfreeRedistributable;
    maintainers = [];
    platforms = [ "x86_64-linux" ];
  };
}

# NEW VERSION:
/*
{ stdenv, lib, fetchurl, autoPatchelfHook, gzip }:

stdenv.mkDerivation rec {
  pname = "libftd2xx";
  version = "1.4.33";

  src = fetchurl {
    url = "https://ftdichip.com/wp-content/uploads/2025/03/libftd2xx-linux-x86_64-${version}.tgz";
    sha256 = "sha256-4mCkWUoxNYO4e/Iwx5zsnUbxHbbc/Xx9T5YyeXAyFNM=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];
  dontBuild = true;
  unpackPhase = ''
    tar -xvf $src
  '';

  installPhase = ''
    mkdir -p $out/lib $out/include
    cp ./linux-x86_64/libftd2xx.so* $out/lib/
    cp ./linux-x86_64/*.h $out/include/
    chmod 0755 $out/lib/*
  '';

  meta = with lib; {
    description = "FTDI proprietary D2XX driver library";
    homepage = "https://ftdichip.com/drivers/d2xx-drivers/";
    license = licenses.unfreeRedistributable;
    maintainers = [];
    platforms = [ "x86_64-linux" ];
  };
}
*/
