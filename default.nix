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
  version = "d88d72bc";

  src = fetchFromGitHub {
    owner = "dfinity";
    repo = "quill";
    rev = "d88d72bc929be6e0e9f3e55553dd5b9d0dbfcc82";
    sha256 = "0ivv2b2z58hl1cdw0v54p49gfaam17ylvnxpd8f4wcqglyxgjsz6";
    # date = 2021-07-12T14:35:41-07:00;
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

  cargoSha256 = "0k029wf79x6wkfzmkcsmpk7r5jm2vax94mnnyr69q6b33zwm8v5s";

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
    rev = "21735b9cb824f1a4049e5be9c16feedff5c19f05";
    sha256 = "1fsadfxgm5bpy73djw31hackzqvkinf860wvm6ncblr83521ac0j";
    # date = 2021-07-07T14:06:28-07:00;
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

  cargoSha256 = "08badqjg8r3yjwgpbxy7rjr53v9gmx7jwblwf5a60lngpki696g6";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl protobuf ]
    ++ lib.optionals stdenv.isDarwin [
         libiconv darwin.apple_sdk.frameworks.Security
       ];
};

dfx = pkgs.stdenv.mkDerivation rec {
  name = "dfx-${version}";
  version = "0.7.7";

  src = pkgs.fetchurl {
    url = "https://sdk.dfinity.org/install.sh";
    sha256 = "08wf14hj61w5x0vv8h6yg3fkfqm18mds303gfrb22192lajkxwy0";
    # date = 2021-07-13T18:01:32-0700;
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
