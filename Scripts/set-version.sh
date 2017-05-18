#!/bin/bash


echo "CONTENTFUL_SDK_VERSION=$1" > Config.xcconfig
echo "CONTENTFUL_SDK_VERSION=$1" > .env
echo "export CONTENFUL_SDK_VERSION=$1" > .envrc
direnv allow

