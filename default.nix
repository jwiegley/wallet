{ rev    ? "c74fa74867a3cce6ab8371dfc03289d9cc72a66e"
, sha256 ? "13bnmpdmh1h6pb7pfzw5w3hm6nzkg9s1kcrwgw1gmdlhivrmnx75"
, pkgs   ? import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
    inherit sha256; }) {
    config.allowUnfree = true;
    config.allowBroken = false;
  }
}:

rec {

keysmith = with pkgs; buildGoModule rec {
  pname = "keysmith";
  version = "74c20ed5";

  src = fetchFromGitHub {
    owner = "dfinity";
    repo = "keysmith";
    rev = "74c20ed5a8ae44214cb12abbfbe8f5887e2a4c33";
    sha256 = "1mvqn2ir5nq5bh1h1aqjsv429m9gcfgky6mij5qnnjivp7i575mi";
    # date = 2021-08-18T23:50:20+02:00;
  };

  vendorSha256 = "1p0r15ihmnmrybf12cycbav80sdj2dv2kry66f4hjfjn6k8zb0dc";
  runVend = false;

  meta = with lib; {
    description = "Hierarchical Deterministic Key Derivation for the Internet Computer";
    homepage = "https://github.com/dfinity/keysmith";
    license = licenses.mit;
    maintainers = with maintainers; [ imalison ];
    platforms = platforms.all;
  };
};

quill = with pkgs; rustPlatform.buildRustPackage rec {
  name = "quill-${version}";
  version = "f1672a79";

  src = fetchFromGitHub {
    owner = "dfinity";
    repo = "quill";
    rev = "f1672a79b483ba09f553d544eff22e829dbf57f4";
    sha256 = "1vfl3c54kz9nri8a5fn32v4sjaql4p9nnb1dgjjk4i3i384nrsfw";
    # date = 2021-09-22T19:45:34+02:00;
  };
  # src = ~/dfinity/master/rs/quill;

  ic = fetchFromGitHub {
    owner = "dfinity";
    repo = "ic";
    rev = "779549eccfcf61ac702dfc2ee6d76ffdc2db1f7f";
    sha256 = "1r31d5hab7k1n60a7y8fw79fjgfq04cgj9krwa6r9z4isi3919v6";
  };

  registry = "file://local-registry";

  preBuild = ''
    export REGISTRY_TRANSPORT_PROTO_INCLUDES=${ic}/rs/registry/transport/proto
    export IC_BASE_TYPES_PROTO_INCLUDES=${ic}/rs/types/base_types/proto
    export IC_PROTOBUF_PROTO_INCLUDES=${ic}/rs/protobuf/def
    export IC_NNS_COMMON_PROTO_INCLUDES=${ic}/rs/nns/common/proto

    export PROTOC=${protobuf}/bin/protoc
    export OPENSSL_DIR=${openssl.dev}
    export OPENSSL_LIB_DIR=${openssl.out}/lib
  '';

  cargoSha256 = "0jzc3iv1sj8rfyl6a549lhnwc0d65cqgzf69pn362gij2fbsnyks";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl protobuf ]
    ++ lib.optionals stdenv.isDarwin [
         libiconv darwin.apple_sdk.frameworks.Security
       ];
};

candid = with pkgs; rustPlatform.buildRustPackage rec {
  name = "candid-${version}";
  version = "81f64da5";

  src = fetchFromGitHub {
    owner = "dfinity";
    repo = "candid";
    rev = "81f64da5a783658d36e5988e91e97eb8d111b153";
    sha256 = "0rwnywvshizww6d5gzi8l907n19zr3ldal9kbh2v3ahnb9rqy151";
    # date = 2021-09-24T14:53:27+02:00;
  };

  registry = "file://local-registry";

  cargoSha256 = "0vramgzvp93kdxyd49fjpm5jilp48r69qpz2ma3nyajwbnqvjpj6";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl protobuf ]
    ++ lib.optionals stdenv.isDarwin [
         libiconv darwin.apple_sdk.frameworks.Security
       ];
};

idl2json = with pkgs; rustPlatform.buildRustPackage rec {
  name = "idl2json-${version}";
  version = "21735b9c";

  src = ~/dfinity/idl2json;
  # src = fetchFromGitHub {
  #   owner = "dfinity-lab";
  #   repo = "idl2json";
  #   rev = "bcb27ac567eba7a7c14c9d70aedd3fb777af281b";
  #   sha256 = "0i61dkzzw6c1g8ab09cpl5p3i4fkbd39zb87za7cqllyfi3iw0pm";
  # };

  registry = "file://local-registry";

  cargoSha256 = "1j9gvzcm0wmifv89lyga5x10cq0v3vrwr9dpr0713vx1x3fijks4";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl protobuf ]
    ++ lib.optionals stdenv.isDarwin [
         libiconv darwin.apple_sdk.frameworks.Security
       ];
};

dfx = pkgs.stdenv.mkDerivation rec {
  name = "dfx-${version}";
  version = "0.8.1";

  src = pkgs.fetchurl {
    url = "https://sdk.dfinity.org/install.sh";
    sha256 = "136zfz52f8h9amia9gfw14sp7p72wgxzv1q2r5cmy1vmsa48rp3w";
    # date = 2021-09-21T08:57:51-0600;
  };

  buildInputs = with pkgs; [ curl cacert ];

  phases = [ "fixupPhase" "installPhase" ];

  installPhase = ''
    export DFX_INSTALL_ROOT=$out/bin
    mkdir -p $DFX_INSTALL_ROOT
    sed -i 's/if ! confirm_license; then/if false; then/' ${src}
    export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    export HOME=$PWD
    DFX_VERSION=${version} bash ${src}
  '';
};

shell = pkgs.mkShell {
  buildInputs = [ keysmith quill candid idl2json dfx ];
};

}
