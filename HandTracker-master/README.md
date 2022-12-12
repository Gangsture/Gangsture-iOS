# HandTracker

Forked from: https://github.com/noppefoxwolf/HandTracker

# Building MediaPipeHands.framework

1. Setup mediapipe repo.
2. Clone this repo inside the mediapipe directory.
3. Run `bazel build HandTracker/Sources:MediaPipeHands -c opt --config=ios_arm64`

# Using precompiled MediaPipeHands.framework

See [Example/Example.xcworkspace](Example/Example.xcworkspace)
```
platform :ios, '14.0'

target 'Example' do
  use_frameworks!

  pod 'MediaPipeHands', :podspec => 'https://github.com/szotp-lc/HandTracker/releases/download/1.4/MediaPipeHands.podspec'
end
```