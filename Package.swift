// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "HYSurveySDK",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "HYSurveySDK", targets: ["HYSurveySDK"]),
    ],
    targets: [
        .target(
            name: "HYSurveySDK",
            path: "surveySDK",
            sources: ["Classes"],
            resources: [
                .copy("Assets/index.html"),
                .copy("Assets/version.json"),
                .copy("Assets/static"),
            ]
        )
    ],
    swiftLanguageModes: [.v4]
)
