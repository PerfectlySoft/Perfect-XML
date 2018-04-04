// swift-tools-version:4.0
// Generated automatically by Perfect Assistant 2
// Date: 2018-03-31 16:19:33 +0000
import PackageDescription

let package = Package(
	name: "PerfectXML",
	products: [
		.library(name: "PerfectXML", targets: ["PerfectXML"])
	],
	dependencies: [
		.package(url: "https://github.com/PerfectlySoft/Perfect-libxml2.git", "3.0.0"..<"4.0.0")
	],
	targets: [
		.target(name: "PerfectXML", dependencies: []),
		.testTarget(name: "PerfectXMLTests", dependencies: ["PerfectXML"])
	]
)