#!/bin/bash

set -e # forward failure to the rest of the program

which -s brew
if [[ $? != 0 ]] ; then
    echo "ERROR: Homebrew must be installed on your machine in order to configure your environment"
    echo "for developing contentful.swift. Please visit https://brew.sh/ for installation instructions."
    exit 1
else
    brew update
fi


if ! brew ls --versions carthage > /dev/null; then
  echo "Installing carthage via homebrew"
  brew install carthage
fi

if ! brew ls --versions swiftlint > /dev/null; then
  echo "Installing swiftlint via homebrew"
  brew install swiftlint
fi


# Update carthage and swiftlint
brew outdated carthage || brew upgrade carthage
brew outdated swiftlint || brew upgrade swiftlint

# Install project dependencies
bundle install
carthage bootstrap --use-submodules --no-build

