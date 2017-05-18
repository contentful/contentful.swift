

## Development and versioning
Development should be done with Xcode as a strict requirement of the project is that iOS, macOS, tvOS, and watchOS stay supported. This, in turn, means that development will be done on a Mac, and it is therefore suggested that [homebrew](https://brew.sh/) be installed. The `make setup_env` command will install or update the necessary brew packages required to work on the contentful.swift project (note that it will not install homebrew for you).

One brew package that the project uses is [direnv](https://direnv.net/) which is used to consolidate all the places the SDK's version number must be injected to one place. Updating the version number before a future release should be done in the `.envrc` file in the root directory of the project.

