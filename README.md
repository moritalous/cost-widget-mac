# Cost Widget for macOS

Native macOS WidgetKit companion for [cost-widget](https://github.com/moritalous/cost-widget).

The first milestone is an Apple Silicon (`arm64`) unsigned preview build with sample data. The build runs on the GitHub-hosted `macos-26` runner and is uploaded as a GitHub Actions artifact.

## Build flow

1. Push a change or open a pull request.
2. Open the **macOS build** workflow in GitHub Actions.
3. Download the `CostWidget-macos-arm64-unsigned` artifact.
4. Unzip it on an Apple Silicon Mac.
5. Open `CostWidget.app` once, then add **Token Cost** from the macOS widget gallery.

The current widget intentionally uses sample data. Claude Code log access, `ccusage`, App Group sharing, and release packaging will be added after the first real-Mac widget validation.

## Local project generation on macOS

```sh
brew install xcodegen
xcodegen generate --spec project.yml
xcodebuild \
  -project CostWidget.xcodeproj \
  -scheme CostWidget \
  -configuration Debug \
  -sdk macosx \
  -arch arm64 \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build
```
