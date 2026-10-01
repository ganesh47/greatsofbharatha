#!/bin/sh
# Xcode Cloud bootstrap: validate tag and versions before generating the project.
set -eu

cd "$CI_PRIMARY_REPOSITORY_PATH"
python3 ci_scripts/stamp_release.py \
  --project project.yml \
  --tag "${CI_TAG:-}" \
  --build-number "${CI_BUILD_NUMBER:?Xcode Cloud build number is required}"

if [ -n "${CI_TAG:-}" ]; then
  python3 ci_scripts/release_gates.py \
    --repository ganesh47/greatsofbharatha \
    --sha "$(git rev-parse HEAD)"
fi

echo "Versions validated; generating Xcode project for Cloud build ${CI_BUILD_NUMBER}"
brew install xcodegen
xcodegen generate
