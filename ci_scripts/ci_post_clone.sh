#!/bin/sh
# Xcode Cloud bootstrap: validate tag and versions before generating the project.
set -eu

cd "$CI_PRIMARY_REPOSITORY_PATH"
python3 ci_scripts/stamp_release.py \
  --project project.yml \
  --tag "${CI_TAG:-}" \
  --build-number "${CI_BUILD_NUMBER:?Xcode Cloud build number is required}"

if [ -n "${CI_TAG:-}" ]; then
  case "$CI_TAG" in
    tvos-v*) GOB_RELEASE_PLATFORM=TVOS ;;
    *) GOB_RELEASE_PLATFORM=IOS ;;
  esac
  python3 ci_scripts/release_gates.py \
    --repository ganesh47/greatsofbharatha \
    --sha "$(git rev-parse HEAD)" \
    --platform "$GOB_RELEASE_PLATFORM"
fi

echo "Versions validated; generating Xcode project for Cloud build ${CI_BUILD_NUMBER}"
brew install xcodegen
xcodegen generate
