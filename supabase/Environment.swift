import Foundation

enum Environment {
    static func value(for key: String) -> String {
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil),
              let contents = try? String(contentsOfFile: path) else {
            fatalError("⚠️ Missing .env file in app bundle.")
        }
        for line in contents.components(separatedBy: .newlines) {
            let parts = line.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let k = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let v = String(parts[1]).trimmingCharacters(in: .whitespaces)
                if k == key { return v }
            }
        }
        fatalError("⚠️ Missing key \(key) in .env file.")
    }
}
