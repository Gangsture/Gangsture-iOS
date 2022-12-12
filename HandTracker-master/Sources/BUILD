# bazel build HandTracker/Sources:MediaPipeHands -c opt --config=ios_arm64

load("@build_bazel_rules_apple//apple:ios.bzl", "ios_framework")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_group")

ios_framework(
    name = "MediaPipeHands",
    hdrs = [
        "MediaPipeGraph.h"
    ],
    infoplists = ["Info.plist"],
    bundle_id = "dev.noppe.HandTracker",
    families = ["iphone", "ipad"],
    minimum_os_version = "11.0",
    deps = [
        "@ios_opencv//:OpencvFramework",
        ":core",
        ":hands"
    ],
)

apple_resource_group(
    name = "module",
    structured_resources = [
        "Modules/module.modulemap",
    ],
)

objc_library(
    name = "core",
    srcs = [
        "MediaPipeGraph.mm"
    ],
    hdrs = [
        "MediaPipeGraph.h",
    ],
    sdk_frameworks = [
        "AVFoundation",
        "CoreGraphics",
        "CoreMedia",
        "UIKit",
        "AssetsLibrary",
    ],
    deps = [
        "//mediapipe/framework/port:parse_text_proto",
        "//mediapipe/objc:mediapipe_framework_ios",
        "//mediapipe/objc:mediapipe_input_sources_ios",
        "//mediapipe/objc:mediapipe_layer_renderer",
    ],
    data = [
        ":module"
    ]
)

objc_library(
    name = "hands",
    data = [
        "//mediapipe/modules/hand_landmark:hand_landmark_full.tflite",
        "//mediapipe/modules/hand_landmark:hand_landmark_tracking_gpu.binarypb",
        "//mediapipe/modules/hand_landmark:handedness.txt",
        "//mediapipe/modules/palm_detection:palm_detection_full.tflite",
    ],
    deps = [
        "//mediapipe/modules/hand_landmark:hand_landmark_tracking_gpu",
    ],
)
