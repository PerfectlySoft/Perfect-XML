// swift-tools-version:4.0
// Generated automatically by Perfect Assistant Application
// Date: 2017-09-21 01:36:55 +0000

import PackageDescription
let package = Package(
	name: "PerfectXML",
	products: [
		.library(name: "PerfectXML", targets: ["PerfectXML"])
	],
	dependencies: [
		.package(url: "https://github.com/PerfectlySoft/Perfect-libxml2.git", from: "2.1.0"),
	],
	targets: [
		.target(name: "PerfectXML", dependencies: []),
		.testTarget(name: "PerfectXMLTests", dependencies: ["PerfectXML"])
	]
)
