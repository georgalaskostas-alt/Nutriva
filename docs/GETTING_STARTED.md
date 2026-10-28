# Running Nutriva on a Mac

The initial native iOS app uses SwiftUI and local-only food diary storage. **Online AI is not yet connected.**

1. Install Xcode and XcodeGen (`brew install xcodegen`).
2. Clone the repository: `git clone https://github.com/georgalaskostas-alt/Nutriva.git`
3. Run `cd Nutriva/ios && xcodegen generate`.
4. Open `Nutriva.xcodeproj` in Xcode.
5. Select an iPhone simulator or your iPhone. For a physical device, select your Apple development team under Signing & Capabilities and adjust the bundle identifier if necessary.
6. Press Run.

Food diary entries are stored locally on the device using UserDefaults. This is an initial development prototype, not a production-grade multi-user or health-data storage implementation.

Next: secure authentication, per-user backend storage, validated nutrition database, and online AI with server-side API credentials.
