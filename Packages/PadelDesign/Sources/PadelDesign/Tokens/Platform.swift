import CoreGraphics

enum Platform {
    /// - Note: The Mac takes the phone's numbers. Nothing ships there — it is
    ///   where the package's tests and previews run.
    static func value(watch: CGFloat, phone: CGFloat) -> CGFloat {
        #if os(watchOS)
            watch
        #else
            phone
        #endif
    }
}
