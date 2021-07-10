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
  version = "fb4cc8ce";

  src = fetchFromGitHub {
    owner = "dfinity";
    repo = "quill";
    rev = "fb4cc8ce075a68f29775111c5210fb91c360201b";
    sha256 = "02ga2xkdxs36mfr4lv43cy6wkf27c28bdkzfkp3az5jvyk17mkfr";
    # date = 2021-07-07T16:11:07+02:00;
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

  cargoSha256 = "1l8vggynj0a3cdmmzgcy1m5af9xkm5b51jj27ghrknm412325zx5";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl protobuf ]
    ++ lib.optionals stdenv.isDarwin [
         libiconv darwin.apple_sdk.frameworks.Security
       ];
};

dfx = pkgs.stdenv.mkDerivation rec {
  name = "dfx-${version}";
  version = "0.7.5";

  src = pkgs.fetchurl {
    url = "https://sdk.dfinity.org/install.sh";
    sha256 = "0y3x6lbqi5q2ybsj87h18lrwqdikwcz3irmb2lcc441aiy22hkj7";
    # date = 2021-07-08T18:07:03-0700;
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
