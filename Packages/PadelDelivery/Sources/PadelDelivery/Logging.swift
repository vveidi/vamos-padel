import os

/// One log for the whole package.
///
/// The subsystem is shared by the watch and the phone: the package runs on
/// both, and it has no way of knowing which app it is currently in. The
/// "delivery" category tells its lines apart from everything else the two apps
/// write.
let logger = Logger(subsystem: "com.vveidi.padel", category: "delivery")
