# Sila for Twitch

<img src="https://github.com/agg23/Sila/blob/master/Icon.svg" width="384px">

Sila is a native Twitch client designed for Apple Vision Pro. Bypass the official Twitch websites with it's annoying touch targets and tiny UI and experience Twitch in a more enjoyable manner.

It is not available on the App Store, but you can [download it from TestFlight](https://testflight.apple.com/join/tvPhZZ8w). If you really enjoy the app, or just want to help me pay for my dev account subscription, you can donate [here on Github](https://github.com/sponsors/agg23/).

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

## FAQ

### Why is Sila not available in the App Store?

After several frustrating rounds of submissions to the App Store, it seems like Apple is not going to approve the app for some reason. Among other issues, App Review stated that Sila was "too similar to the website", and does not warrant being an app. I obviously think this is ridiculous, and it's very disappointing that I can't properly share Sila with people.

In the meantime, you can get it via TestFlight at: https://testflight.apple.com/join/tvPhZZ8w

### Why "Sila"

[Sila is the Inuit word for breath or spirit](https://en.wikipedia.org/wiki/Silap_Inua), which matches well with the ghost mascot I imagined for the icon. I searched through a bunch of names relating to ghost and Twitch and cloud, including in non-English languages, and Sila was the best one I found. After using it for a while, I think it fits quite well.

### Why use a `WKWebView`? Why not a native `AVPlayer`?

It's against Twitch's ToS to directly access the raw HLS stream, similar to what Streamlink does. It can be made to work, but it's error prone, and it doesn't display ads properly (just displaying a blank placeholder screen), though this may be considered a benefit. In addition, you lose to the ad blocking with subs without extracting a cookie from the web client. In other words, its finicky, and Twitch doesn't like it, which isn't something I wanted to deal with for an app I planned to submit to the App Store.

### Why is this code so weird?

This is my first time writing for an Apple platform in close to a decade. SwiftUI is brand new to me, and I went through many iterations trying to figure out good patterns. I imagine there's still plenty of issues with the codebase, so if you spot something, let me know in an issue or open a PR to fix it yourself.
