# Product Principles

1. **Capability-driven, not platform-driven.** The UI reads
   `TvCapabilities`, never `TvPlatform`, to decide what to render. A
   feature difference between two Samsung models is exactly as valid a
   reason to hide a button as a difference between Samsung and LG.

2. **Never claim support the app doesn't have.** Fake devices are always
   labelled as demo devices (`TvDevice.isDevelopmentFake`). Research docs
   describe official vs. reverse-engineered APIs honestly, including
   uncertainty. The roadmap does not promise a platform before its
   provider ships.

3. **Secure by default.** Pairing secrets go through
   `SecureCredentialStore` (Keychain/Keystore), never plain storage. Logs
   never contain tokens, PINs, or certificates. Power-user features that
   carry real risk (APK sideloading) are off by default and clearly
   labelled.

4. **Small, replaceable providers over one god-service.** Every TV
   ecosystem's quirks stay inside its own `TvProvider` implementation.
   Shared code (UI, session orchestration, storage) depends only on the
   `TvProvider` interface and `TvCapabilities`, so a provider can be
   developed, tested, and even removed without touching anything else.

5. **The remote should feel physical.** Large touch targets, press-and-hold
   repeat for volume/channel, instant visual feedback. Premium near-black
   dark mode as the default aesthetic, not a generic Material demo.

6. **Foundation before breadth.** One correct, tested provider
   architecture beats five incomplete vendor integrations. Real protocol
   work is sequenced one platform at a time - see
   `docs/product/feature-roadmap.md`.
