import Foundation

func assertAppStoreInstallation() {
#if !DEBUG
    guard let receiptURL = Bundle.main.appStoreReceiptURL else {
        fatalError("Missing App Store receipt")
    }

    // A valid receipt must exist regardless of whether the build is
    // distributed via the App Store or TestFlight.
    guard FileManager.default.fileExists(atPath: receiptURL.path) else {
        fatalError("Missing App Store receipt")
    }

    // TestFlight builds contain a sandbox receipt but lack a provisioning
    // profile. Developer-signed or sideloaded apps keep their provisioning
    // profile, so treat that as an indicator of sideloading.
    if Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil {
        fatalError("App not installed from the App Store")
    }
#endif
}
