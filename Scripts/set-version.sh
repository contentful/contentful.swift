#!/bin/bash


echo "CONTENTFUL_SDK_VERSION=$1" > Config.xcconfig
echo "CONTENTFUL_SDK_VERSION=$1" > .env
echo "export CONTENFUL_SDK_VERSION=$1" > .envrc
direnv allow

echo "Done setting new version number. Don't forget to update expecations in user agent string tests! See `'testUserAgentString()'`"
