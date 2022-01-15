{ rev    ? "f7ef5b19964910a06d964932f460fad94cc2e91d"
, sha256 ? "1b7zfphix8lh393c0fpcgc8ylg8bh5xbk9rs59rf21f9w296l11c"
, pkgs   ? import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
    inherit sha256; }) {
    config.allowUnfree = true;
    config.allowBroken = false;
  }
}:

rec {

quill = with pkgs; rustPlatform.buildRustPackage rec {
  name = "quill-${version}";
  version = "0fd137b9";

  src = fetchFromGitHub {
    owner = "dfinity";
    repo = "quill";
    rev = "b41a4e8b86f011cdc6ba2950f7b4b71e9ddbe92a";
    sha256 = "sha256-7dlg8v/wYn1Bd9qTFLMvs/XqDVOF1Z4bAbUd18S1hPI=";
    # date = 2021-12-17T16:36:30+01:00;
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

  cargoSha256 = "sha256-6AlTytxj8sb/8epvEPuF9S4v2V7XOiQKRCutupxTa9A=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl protobuf ]
    ++ lib.optionals stdenv.isDarwin [
         libiconv darwin.apple_sdk.frameworks.Security
       ];
};

candid = with pkgs; rustPlatform.buildRustPackage rec {
  name = "candid-${version}";
  version = "c477d01d";

  src = fetchFromGitHub {
    owner = "dfinity";
    repo = "candid";
    rev = "c477d01dbea6c92e184da0f299087ae71bf2e2ec";
    sha256 = "0mdgx73sd4jl4x7brqgms6j7072253g5zspndv8qba903bq9bnnl";
    # date = 2021-12-13T13:42:34-08:00;
  };

  registry = "file://local-registry";

  cargoSha256 = "sha256-iaY235hVKyvuuISyf2+AZ27oOnMRzxxwhK/W5nzynAE=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl protobuf ]
    ++ lib.optionals stdenv.isDarwin [
         libiconv darwin.apple_sdk.frameworks.Security
       ];
};

idl2json = with pkgs; rustPlatform.buildRustPackage rec {
  name = "idl2json-${version}";
  version = "7251ed1d";

  src = ~/dfinity/idl2json;
  # src = fetchFromGitHub {
  #   owner = "dfinity";
  #   repo = "idl2json";
  #   rev = "7251ed1da8d50cd4ae4abc5a796e308a10d9ac40";
  #   sha256 = "1hxrgcdi0cm6wisna425l7zn50g5q7yb6wqjgr0wks1yjc6kfzn0";
  # };

  registry = "file://local-registry";

  cargoSha256 = "1sjndk2dh9ka0qky1y06bwzsafrw21pqaqwbh2cv660fayx0lq18";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl protobuf ]
    ++ lib.optionals stdenv.isDarwin [
         libiconv darwin.apple_sdk.frameworks.Security
       ];
};

# dfx = pkgs.stdenv.mkDerivation rec {
#   name = "dfx-${version}";
#   version = "0.8.2";

#   src = pkgs.fetchurl {
#     url = "https://sdk.dfinity.org/install.sh";
#     sha256 = "0yqxhmrri4wnfcn9d6fxw9ykf09wcfsmnjyvla9jgkzxfxbw04fd";
#     # date = 2021-10-04T10:36:14-0700;
#   };

#   buildInputs = with pkgs; [ curl cacert ];

#   phases = [ "fixupPhase" "installPhase" ];

#   installPhase = ''
#     export DFX_INSTALL_ROOT=$out/bin
#     mkdir -p $DFX_INSTALL_ROOT
#     sed -i 's/if ! confirm_license; then/if false; then/' ${src}
#     export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
#     export HOME=$PWD
#     DFX_VERSION=${version} bash ${src}
#   '';
# };

shell = pkgs.mkShell {
  buildInputs = [ quill candid idl2json ];
};

}
