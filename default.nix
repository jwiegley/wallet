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
  version = "3e2de90b";

  src = fetchFromGitHub {
    owner = "dfinity";
    repo = "keysmith";
    rev = "3e2de90bc268392b3000b45c307bf6a123ad04c0";
    sha256 = "1z0sxirk71yabgilq8v5lz4nd2bbm1xyrd5zppif8k9jqhr6v3v3";
    # date = 2021-07-02T02:56:38+02:00;
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
  version = "76dac5dd";

  src = fetchFromGitHub {
    owner = "dfinity";
    repo = "quill";
    rev = "76dac5ddb34f64aab3538ba3b5fa77b38a80ad3d";
    sha256 = "0kyp2ji77a9faii9721k8972py0ac7p4ppqlklz5cikrxcyr6iab";
    # date = 2021-07-14T08:44:25-07:00;
  };

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

  cargoSha256 = "0clniq3whpcg3yx5kb2m81sbnng5z8337ahknz9cmh6qqqi3q3lf";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl protobuf ]
    ++ lib.optionals stdenv.isDarwin [
         libiconv darwin.apple_sdk.frameworks.Security
       ];
};

candid = with pkgs; rustPlatform.buildRustPackage rec {
  name = "candid-${version}";
  version = "21735b9c";

  src = fetchFromGitHub {
    owner = "dfinity";
    repo = "candid";
    rev = "0bbb320e66fddeccb674128640d1a3e6f697386a";
    sha256 = "1i61dkzzw6c1g8ab09cpl5p3i4fkbd39zb87za7cqllyfi3iw0pm";
    # date = 2021-07-27T14:05:09-07:00;
  };

  registry = "file://local-registry";

  # preBuild = ''
  #   export REGISTRY_TRANSPORT_PROTO_INCLUDES=${ic}/rs/registry/transport/proto
  #   export IC_BASE_TYPES_PROTO_INCLUDES=${ic}/rs/types/base_types/proto
  #   export IC_PROTOBUF_PROTO_INCLUDES=${ic}/rs/protobuf/def
  #   export IC_NNS_COMMON_PROTO_INCLUDES=${ic}/rs/nns/common/proto

  #   export PROTOC=${protobuf}/bin/protoc
  #   export OPENSSL_DIR=${openssl.dev}
  #   export OPENSSL_LIB_DIR=${openssl.out}/lib
  # '';

  cargoSha256 = "1vbix102q8ajfb1driai24in2yc3mcrhipkrhjm0yfd2y7m1g5am";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl protobuf ]
    ++ lib.optionals stdenv.isDarwin [
         libiconv darwin.apple_sdk.frameworks.Security
       ];
};

dfx = pkgs.stdenv.mkDerivation rec {
  name = "dfx-${version}";
  version = "0.8.0";

  src = pkgs.fetchurl {
    url = "https://sdk.dfinity.org/install.sh";
    sha256 = "0dqmv1rng3b8jf2gawdhqzl9h9am84kj6d52iyykyn2wzq8h12dg";
    # date = 2021-07-28T08:48:30-0700;
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
  buildInputs = [ keysmith quill candid dfx ];
};

}
