import CoreGraphics

/// Where the two screens' numbers part company.
///
/// The radii and the ramp both carry a watch value and a phone value, and both
/// were resolving them with their own copy of the same `#if os(watchOS)`. One
/// copy, so that adding a third platform — or changing what the Mac stands in
/// for — is one edit rather than a search.
enum Platform {
    /// The value for the platform this is being drawn on.
    ///
    /// The Mac takes the phone's numbers. Nothing ships there — it is where
    /// the package's tests and previews run — and of the two the phone is the
    /// one a Mac-sized window looks like.
    static func value(watch: CGFloat, phone: CGFloat) -> CGFloat {
        #if os(watchOS)
            watch
        #else
            phone
        #endif
    }
}
