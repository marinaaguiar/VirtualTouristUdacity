import Foundation

struct AppConfiguration {
    static var shared: AppConfiguration {

        struct Static {
            static let instance = AppConfiguration()
        }

        return Static.instance
    }

    let apiKey: String

    private init() {
        self.apiKey = AppConfiguration.fromBundle("apiKey")
    }

    private static func fromBundle(_ key: String) -> String {
        return Bundle.main.infoDictionary![key] as? String ?? ""
    }
}
