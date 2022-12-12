cd ..
bazel build HandTracker/Sources:MediaPipeHands -c opt --config=ios_arm64
BUILD_DIR=applebin_ios-ios_arm64-opt-ST-2967bd56a867
rm -rf HandTracker/Example/Pods/MediaPipeHands/MediaPipeHands.framework
unzip bazel-out/$BUILD_DIR/bin/HandTracker/Sources/MediaPipeHands.zip -d HandTracker/Example/Pods/MediaPipeHands