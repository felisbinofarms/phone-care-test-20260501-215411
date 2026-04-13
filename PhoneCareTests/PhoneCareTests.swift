import Testing
import Foundation
@testable import PhoneCare

@Suite("PhoneCare Sanity Checks")
struct PhoneCareTests {

    @Test("Module imports successfully")
    func moduleImports() {
        // If this compiles and runs, the PhoneCare module is accessible.
        #expect(true)
    }

    @Test("Health score calculator is available")
    func calculatorAvailable() {
        let input = HealthScoreInput(
            totalStorageBytes: 100,
            usedStorageBytes: 50,
            totalPhotos: 0,
            duplicatePhotos: 0,
            totalContacts: 0,
            duplicateContacts: 0,
            batteryHealth: 1.0,
            batteryLevel: 1.0,
            totalPermissions: 0,
            appropriatelySetPermissions: 0
        )
        let result = HealthScoreCalculator.calculate(from: input)
        #expect(result.compositeScore >= 0)
        #expect(result.compositeScore <= 100)
    }

    @Test("Privacy guardrails block forbidden imports in app sources")
    func privacyGuardrailsBlockForbiddenImports() throws {
        let violations = try findForbiddenPatterns(
            in: appSourceFiles(),
            patterns: [
                "import Firebase",
                "import Amplitude",
                "import Segment",
                "import Mixpanel",
                "import RevenueCat",
                "import AppsFlyer",
                "import Alamofire",
                "import FacebookLogin",
                "import GoogleSignIn",
                "import AppTrackingTransparency",
                "URLSession(",
                "URLSession."
            ]
        )

        #expect(
            violations.isEmpty,
            "Forbidden privacy-impacting imports or APIs found:\n\(violations.joined(separator: "\n"))"
        )
    }

    @Test("Privacy guardrails block external package managers and remote package references")
    func privacyGuardrailsBlockExternalDependencies() throws {
        let projectFile = try String(contentsOf: repoRoot.appendingPathComponent("PhoneCare.xcodeproj/project.pbxproj"))
        let projectYAML = try String(contentsOf: repoRoot.appendingPathComponent("project.yml"))
        let fileManager = FileManager.default

        #expect(!projectFile.contains("XCRemoteSwiftPackageReference"), "project.pbxproj contains a remote Swift package reference")
        #expect(!projectYAML.contains("\npackages:"), "project.yml declares Swift packages")
        #expect(!fileManager.fileExists(atPath: repoRoot.appendingPathComponent("Podfile").path), "Podfile should not exist")
        #expect(!fileManager.fileExists(atPath: repoRoot.appendingPathComponent("Pods").path), "Pods directory should not exist")
    }

    @Test("Privacy manifesto copy stays aligned with the zero-data-collection promise")
    func privacyManifestoCopyIsConsistent() {
        #expect(PrivacyManifesto.summaryText.contains("All processing stays on your iPhone"))
        #expect(PrivacyManifesto.detailsText.contains("fully on-device"))
        #expect(PrivacyManifesto.detailsText.contains("do not collect personal data"))
        #expect(PrivacyManifesto.noCollectionPoints.contains("No third-party analytics SDKs"))
        #expect(PrivacyManifesto.appStoreLabelValue == "Data Not Collected")
    }

    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func appSourceFiles() throws -> [URL] {
        let enumerator = FileManager.default.enumerator(
            at: repoRoot.appendingPathComponent("PhoneCare"),
            includingPropertiesForKeys: nil
        )

        var files: [URL] = []
        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "swift" else { continue }
            files.append(url)
        }
        return files
    }

    private func findForbiddenPatterns(in files: [URL], patterns: [String]) throws -> [String] {
        var violations: [String] = []

        for fileURL in files {
            let contents = try String(contentsOf: fileURL)
            for pattern in patterns where contents.contains(pattern) {
                let relativePath = fileURL.path.replacingOccurrences(of: repoRoot.path + "/", with: "")
                violations.append("\(relativePath): contains '\(pattern)'")
            }
        }

        return violations
    }
}
