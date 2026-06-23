# Astro

Astro is a SwiftUI iOS app for exploring orbital assets, space news, and related mission content. The app uses a custom tab shell, a satellite-focused home experience, SwiftData caching, Supabase-backed data, and Apollo GraphQL queries.

## Features

- Satellite exploration home screen with selectable tracked assets
- Space news feed backed by GraphQL article data
- SwiftData cache models for assets and articles
- Subscription/paywall flow with StoreKit support
- Adaptive iPhone and iPad layouts
- Custom SF Symbol and image assets for the app UI

## Tech Stack

- SwiftUI
- SwiftData
- MapKit
- StoreKit
- Supabase
- Apollo iOS / GraphQL
- Xcode project-based iOS build

## Requirements

- Xcode 26 or newer
- iOS 26 SDK
- Swift 6 toolchain included with Xcode
- A Supabase project with GraphQL enabled

## Configuration

Runtime values are read from `Astro/resources/ConfigDev.xcconfig` and `Astro/resources/ConfigRelease.xcconfig`, then exposed through `Info.plist` and `AppEnv`.

Required values:

- `SUPABASE_URL`
- `SUPABASE_KEY`
- `GRAPHQL_ENDPOINT`
- `HAS_UNIQUE_BUCKETS`

For private local overrides, create a separate `*.xcconfig.local` file and keep it out of source control.

## GraphQL

GraphQL operations live in `Astro/graphql/queries/`. Generated Apollo Swift files live under `Astro/graphql/generated/` so the app can build from a fresh checkout without requiring code generation first.

If the schema or operations change, regenerate the Apollo files before committing.

## Development

Open `Astro.xcodeproj` in Xcode, select the Astro scheme, and run on a simulator or device.

From the command line, a build can be started with:

```sh
xcodebuild -project Astro.xcodeproj -scheme Astro -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Git Ignore Notes

The `.gitignore` keeps local machine state and generated build output out of the repository, including Xcode user data, `DerivedData`, SwiftPM `.build`, Apollo's downloaded CLI binary, backup project files, and local secret/config overrides.

Do commit source assets, shared Xcode project metadata, Apollo-generated Swift files, and StoreKit test configuration when they are required for another developer to build or test the app.
