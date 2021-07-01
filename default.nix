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

keysmith = pkgs.stdenv.mkDerivation rec {
  name = "keysmith-${version}";
  version = "0.0.0-unknown";

  src = pkgs.fetchFromGitHub {
    owner = "dfinity";
    repo = "keysmith";
    rev = "166664ba7fb0c843c5441e3b0bac17580ccdc8ae";
    sha256 = "0fvpx18lys1qyrxbwyj04rdf6ikxvmlbl8jawbxnmkbh2wq63n8q";
    # date = 2021-06-14T19:32:48+02:00;
  };

  buildInputs = with pkgs; [ gnumake go git ];

  buildPhase = ''
    export HOME=$PWD
    go build
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv keysmith $out/bin
  '';
};

quill = with pkgs; rustPlatform.buildRustPackage rec {
  name = "quill-${version}";
  version = "0baa53c175";

  src = fetchFromGitHub {
    owner = "dfinity";
    repo = "quill";
    rev = "0baa53c175a831c0ad1a8c29b2dc0f437d105530";
    sha256 = "1igggarq4kyln8hzsbpamz5q2hgh5d3bfkm8vfmafh013x4h55bf";
    # date = 2021-06-18T08:16:07+02:00;
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
  '';

  cargoSha256 = "0h756lkvyqwsw3984dm0ys6qrdl22isg2zh2mmzqyw8220fgdzph";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl protobuf ]
    ++ lib.optionals stdenv.isDarwin [
         libiconv darwin.apple_sdk.frameworks.Security
       ];
};

dfx = pkgs.stdenv.mkDerivation rec {
  name = "dfx-${version}";
  version = "0.7.2";

  src = pkgs.fetchurl {
    url = "https://sdk.dfinity.org/install.sh";
    sha256 = "029lx3blylnkn1n6md8f00qxswhb17xv851dmsnybjq2z6g8jc8i";
    # date = 2021-06-20T22:37:13-0700;
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
  buildInputs = [ keysmith quill dfx ];
};

}
