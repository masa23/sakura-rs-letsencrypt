#!/bin/sh

LEGO_VERSION=v0.3.1

echo "Download lego"
curl -L -O https://github.com/xenolf/lego/releases/download/$LEGO_VERSION/lego_freebsd_amd64.tar.xz
xz -dv lego_freebsd_amd64.tar.xz
tar xvf lego_freebsd_amd64.tar
rm lego_freebsd_amd64.tar
