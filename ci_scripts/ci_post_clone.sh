#!/bin/sh
# Xcode Cloud post-clone hook — regenerates the Xcode project from project.yml
# and stamps MARKETING_VERSION from the git tag when triggered by a tag push.

set -e

echo "--- ci_post_clone: installing XcodeGen ---"
brew install xcodegen

if [ -n "${CI_TAG:-}" ]; then
  VERSION="${CI_TAG#v}"
  echo "--- ci_post_clone: stamping MARKETING_VERSION=${VERSION} from tag ${CI_TAG} ---"
  sed -i '' "s/MARKETING_VERSION: .*/MARKETING_VERSION: ${VERSION}/" \
    "$CI_PRIMARY_REPOSITORY_PATH/project.yml"
else
  echo "--- ci_post_clone: no tag, keeping dev MARKETING_VERSION ---"
fi

echo "--- ci_post_clone: regenerating GreatsOfBharatha.xcodeproj ---"
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "--- ci_post_clone: done ---"
