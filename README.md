# Sila for Twitch

<img src="https://github.com/agg23/Sila/blob/master/Icon.svg" width="384px">

Sila is a native Twitch client designed for Apple Vision Pro. Bypass the official Twitch websites with it's annoying touch targets and tiny UI and experience Twitch in a more enjoyable manner.

You can download it from the App Store at https://apps.apple.com/us/app/sila-for-twitch/id6479336617. If you really enjoy the app, or just want to help me pay for my dev account subscription, you can donate [here on Github](https://github.com/sponsors/agg23/).

## Features

- Native application for a smooth experience; no reliance on a separate web browser. Designed to feel right at home on visionOS.
- Native-like video playback with controls an UI customized to the Twitch experience. Uses `WKWebView` internally (see [FAQ](#faq))
- Live chat integration with inline Twitch emotes (both static and animated). Other emote sources coming soon.
- Log in to see your followed channels, and launch directly into their livestreams.
- Watch multiple streams simultaneously (requires all but one stream to be muted).
- Start watching new streams with Siri, and build automations via Shortcuts.

No Twitch account is required for use, but if you chose to use it, your existing subscriptions and Twitch Turbo status will be used. Twitch will also properly keep track of your watch time for drops and end of the year summaries.

## Screenshots

![Video](https://github.com/agg23/Sila/blob/assets/screenshots/Video.jpg) ![Chat](https://github.com/agg23/Sila/blob/assets/screenshots/Chat.jpg)
![Popular](https://github.com/agg23/Sila/blob/assets/screenshots/Popular.jpg) ![Mixed View](https://github.com/agg23/Sila/blob/assets/screenshots/Mixed%20View.jpg)

## Automation

Sila supports several automation mechanisms: Shortcuts and deeplinking.

The included Shortcuts are:

- Open Stream - Opens a live video window for the specified channel, if the channel exists and is live
- Live Following Channels - Returns a list of live channels followed by your account
- Most Popular Streams - Returns a list of the most popular streams on Twitch
- Streams in Category - Returns a list of the most popular streams in a given category

Deeplinking uses the `sila://` URL scheme. Supported routes are:

- `sila://watch?stream=[streamerName]` - Opens a live video window for the specified channel, if the channel exists and is live
- `sila://following` - Opens the Following tab
- `sila://popular` - Opens the Popular tab
- `sila://categories` - Opens the Categories tab
- `sila://category?id=[categoryID]` - Opens the specified category, in the Categories tab, if the category exists

## Building

Sila is straightforward to build, with everything being self-contained to Xcode and SPM. The only things that should be required of you as a developer is changing the signing team (as is typical for iOS) and adding secrets to `Keys.xcconfig`:

1. Create `Keys.xcconfig` in the root directory of the repo, alongside `Sila.xcodeproj`.
2. Add the following content:

```
API_CLIENT_ID = "[insert id here]"
API_SECRET = "[insert secret here]"
```

You must obtain these keys from the Twitch developer portal, with your own registered application: https://dev.twitch.tv/console/apps. You must create a "Confidential" client with `http://localhost` as your OAuth redirect URL. We choose "Confidential" here as Twitch does not allow unauthorized clients to access certain key APIs unless it comes from a "Confidential" client. So while it's wrong to ship a private key with the application, we have no choice.

## FAQ

### Why "Sila"

[Sila is the Inuit word for breath or spirit](https://en.wikipedia.org/wiki/Silap_Inua), which matches well with the ghost mascot I imagined for the icon. I searched through a bunch of names relating to ghost and Twitch and cloud, including in non-English languages, and Sila was the best one I found. After using it for a while, I think it fits quite well.

### Why use a `WKWebView`? Why not a native `AVPlayer`?

It's against Twitch's ToS to directly access the raw HLS stream, similar to what Streamlink does. It can be made to work, but it's error prone, and it doesn't display ads properly (just displaying a blank placeholder screen), though this may be considered a benefit. In addition, you lose to the ad blocking with subs without extracting a cookie from the web client. In other words, its finicky, and Twitch doesn't like it, which isn't something I wanted to deal with for an app I planned to submit to the App Store.

### Why is this code so weird?

This is my first time writing for an Apple platform in close to a decade. SwiftUI is brand new to me, and I went through many iterations trying to figure out good patterns. I imagine there's still plenty of issues with the codebase, so if you spot something, let me know in an issue or open a PR to fix it yourself.
