# Cost Widget for macOS

Native macOS WidgetKit companion for [cost-widget](https://github.com/moritalous/cost-widget).

The first milestone is an Apple Silicon (`arm64`) unsigned preview build with sample data. The build runs on the GitHub-hosted `macos-26` runner and is uploaded as a GitHub Actions artifact. Tagging a commit such as `v0.1.0` also publishes the zip to GitHub Releases.

## Build flow

1. Push a change or open a pull request.
2. Open the **macOS build** workflow in GitHub Actions.
3. Download the `CostWidget-macos-arm64-adhoc` artifact.
4. Unzip it on an Apple Silicon Mac.
5. Open `CostWidget.app` once, then add **Token Cost** from the macOS widget gallery.

Cost Widget bundles `ccusage` for Apple Silicon. On first launch, choose your macOS home folder in the app and allow read access. The app then aggregates supported local AI CLI sources (including Claude Code and Codex) and writes a widget snapshot. Claude Code's five-hour block is displayed separately because it is Claude-specific.

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

## GitHub Release distribution

Push a version tag to build and publish an unsigned Apple Silicon release:

```sh
git tag v0.1.0
git push origin v0.1.0
```

On the Mac, right-click `CostWidget.app` and choose **Open** the first time if macOS blocks an unsigned app. Then add **Token Cost** from the widget gallery.
