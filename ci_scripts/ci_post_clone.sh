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

BUILD_NUMBER="${CI_BUILD_NUMBER:-${GITHUB_RUN_NUMBER:-$(date +%s)}}"
echo "--- ci_post_clone: stamping CURRENT_PROJECT_VERSION=${BUILD_NUMBER} ---"
sed -i '' "s/CURRENT_PROJECT_VERSION: .*/CURRENT_PROJECT_VERSION: ${BUILD_NUMBER}/" \
  "$CI_PRIMARY_REPOSITORY_PATH/project.yml"

echo "--- ci_post_clone: regenerating GreatsOfBharatha.xcodeproj ---"
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "--- ci_post_clone: done ---"
