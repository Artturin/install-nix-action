#!/usr/bin/env bash
set -euo pipefail

# Set jobs to number of cores
sudo sh -c 'echo max-jobs = auto >> /tmp/nix.conf'
# Allow binary caches for runner user
sudo sh -c 'echo trusted-users = root runner >> /tmp/nix.conf'

if [[ $INPUT_SKIP_ADDING_NIXPKGS_CHANNEL = "true" ]]; then
  extra_cmd=--no-channel-add
else
  extra_cmd=
fi

sh <(curl -L ${INPUT_INSTALL_URL:-https://nixos.org/nix/install}) \
  --nix-extra-conf-file /tmp/nix.conf --darwin-use-unencrypted-nix-store-volume $extra_cmd

if [[ $OSTYPE =~ darwin ]]; then
  # Disable spotlight indexing of /nix to speed up performance
  sudo mdutil -i off /nix

  # macOS needs certificates hints
  cert_file=/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt
  echo "::set-env name=NIX_SSL_CERT_FILE::$cert_file"
  export NIX_SSL_CERT_FILE=$cert_file
  sudo launchctl setenv NIX_SSL_CERT_FILE "$cert_file"
fi

# Set paths
echo "::add-path::/nix/var/nix/profiles/per-user/runner/profile/bin"
echo "::add-path::/nix/var/nix/profiles/default/bin"
if [[ $INPUT_SKIP_ADDING_NIXPKGS_CHANNEL != "true" ]]; then
echo "::set-env name=NIX_PATH::/nix/var/nix/profiles/per-user/root/channels"
fi