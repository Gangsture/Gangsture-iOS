// Copyright 2019 The MediaPipe Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "MediaPipeGraph.h"
#import "mediapipe/objc/MPPGraph.h"
#include "mediapipe/framework/port/parse_text_proto.h"

#define CSTR(str) [str cStringUsingEncoding:NSUTF8StringEncoding]

@interface MediaPipePacket ()
@property mediapipe::Packet packet;
@end
@implementation MediaPipePacket

- (instancetype)initWithInt32:(NSInteger)value {
    return [self initWithPacket: mediapipe::MakePacket<int32_t>(value)];
}

- (instancetype)initWithFloat:(float)value {
    return [self initWithPacket: mediapipe::MakePacket<float>(value)];
}

- (instancetype)initWithBool:(BOOL)value {
    return [self initWithPacket: mediapipe::MakePacket<bool>(value)];
}

- (instancetype)initWithPacket:(const mediapipe::Packet)packet {
    self = [super init];
    if (self) {
        _packet = packet;
    }
    return self;
}

- (MediaPipeTimestamp)timestamp {
    return self.packet.Timestamp().Microseconds();
}

- (void)setTimestamp:(MediaPipeTimestamp)timestamp {
    _packet = _packet.At(mediapipe::Timestamp(timestamp));
}

- (NSArray<NSData *> *)getArrayOfProtos {
    NSMutableArray *messages = [NSMutableArray new];
    auto vector = self.packet.GetVectorOfProtoMessageLitePtrs().value();
    
    std::string serialized;
    
    for(auto &message: vector) {
        auto serialized = message->SerializeAsString();
        [messages addObject:[NSData dataWithBytes:serialized.data() length:serialized.length()]];
        message->AppendToString(&serialized);
    }

    return messages;
}

- (NSString *)getTypeName {
    auto name = self.packet.GetTypeId().name();
    return [NSString stringWithCString:name.c_str() encoding:NSUTF8StringEncoding];
}

@end

@interface MediaPipeGraph () <MPPGraphDelegate>
@property MPPGraph *graph;
@end

@implementation MediaPipeGraph

- (instancetype)initWithBinaryGraphConfig:(const NSData *)configData
{
    self = [super init];
    if (self) {
        mediapipe::CalculatorGraphConfig config;
        config.ParseFromArray(configData.bytes, configData.length);
        _graph = [[MPPGraph alloc] initWithGraphConfig:config];
        _graph.delegate = self;
        
        
    }
    return self;
}

- (instancetype)initWithTextGraphConfig:(const NSString *)configString
{
    self = [super init];
    if (self) {
        mediapipe::CalculatorGraphConfig config = mediapipe::ParseTextProtoOrDie<mediapipe::CalculatorGraphConfig>(CSTR(configString));
        _graph = [[MPPGraph alloc] initWithGraphConfig:config];
        _graph.delegate = self;
    }
    return self;
}

- (int) maxFramesInFlight {
    return _graph.maxFramesInFlight;
}

- (void)mediapipeGraph:(MPPGraph *)graph didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer fromStream:(const std::string &)streamName {
    if ([_delegate respondsToSelector:@selector(mediapipeGraph:didOutputPixelBuffer:fromStream:)]) {
        NSString *streamNameMapped = [NSString stringWithCString:streamName.c_str() encoding:NSUTF8StringEncoding];
        [_delegate mediapipeGraph:self didOutputPixelBuffer:pixelBuffer fromStream:streamNameMapped];
    }
}

- (void)mediapipeGraph:(MPPGraph *)graph didOutputPacket:(const mediapipe::Packet *)packet fromStream:(const std::string &)streamName {
    if([_delegate respondsToSelector:@selector(mediapipeGraph:didOutputPacket:fromStream:)]) {
        NSString *streamNameMapped = [NSString stringWithCString:streamName.c_str() encoding:NSUTF8StringEncoding];
        MediaPipePacket *packetObject = [[MediaPipePacket alloc] initWithPacket:*packet];
        [_delegate mediapipeGraph:self didOutputPacket:packetObject fromStream:streamNameMapped];
    }
}

- (void)mediapipeGraph:(MPPGraph *)graph didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer fromStream:(const std::string &)streamName timestamp:(const mediapipe::Timestamp &)timestamp {
    if ([_delegate respondsToSelector:@selector(mediapipeGraph:didOutputPixelBuffer:fromStream:timestamp:)]) {
        NSString *streamNameMapped = [NSString stringWithCString:streamName.c_str() encoding:NSUTF8StringEncoding];
        [_delegate mediapipeGraph:self didOutputPixelBuffer:pixelBuffer fromStream:streamNameMapped timestamp:timestamp.Value()];
    }
}

- (void)setMaxFramesInFlight:(int)maxFramesInFlight {
    _graph.maxFramesInFlight = maxFramesInFlight;
}

- (void)setHeaderPacket:(const MediaPipePacket *)packet forStream:(const NSString *)streamName {
    [_graph setHeaderPacket:packet.packet forStream:CSTR(streamName)];
}

- (void)setSidePacket:(const MediaPipePacket *)packet named:(const NSString *)name {
    [_graph setSidePacket:packet.packet named:CSTR(name)];
}

- (void)addSidePackets:(NSDictionary<NSString *, MediaPipePacket*> *)extraSidePackets {
    for (NSString * key in extraSidePackets) {
        [self setSidePacket:extraSidePackets[key] named:key];
    }
}

- (void)addFrameOutputStream:(const NSString *)outputStreamName
            outputPacketType:(MediaPipePacketType)packetType {
    return [_graph addFrameOutputStream:CSTR(outputStreamName) outputPacketType:(MPPPacketType)packetType];
}

- (BOOL)startWithError:(NSError **)error {
    return [_graph startWithError:error];
}

- (BOOL)sendPacket:(const MediaPipePacket *)packet
        intoStream:(const NSString *)streamName
             error:(NSError **)error {
    return [_graph sendPacket:packet.packet intoStream:CSTR(streamName) error:error];
}

- (BOOL)movePacket:(MediaPipePacket *)packet
        intoStream:(const NSString *)streamName
             error:(NSError **)error {
    return [_graph movePacket:packet.packet intoStream:CSTR(streamName) error:error];
}

- (BOOL)setMaxQueueSize:(int)maxQueueSize
              forStream:(const NSString *)streamName
                  error:(NSError **)error {
    return [_graph setMaxQueueSize:maxQueueSize forStream:CSTR(streamName) error:error];
}

- (MediaPipePacket *)packetWithPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                packetType:(MediaPipePacketType)packetType {
    return [[MediaPipePacket alloc] initWithPacket:[_graph packetWithPixelBuffer:pixelBuffer packetType:(MPPPacketType)packetType]];
}

- (MediaPipePacket *)imagePacketWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    return [[MediaPipePacket alloc] initWithPacket:[_graph imagePacketWithPixelBuffer:pixelBuffer]];
}

- (BOOL)sendPixelBuffer:(CVPixelBufferRef)imageBuffer
             intoStream:(const NSString *)inputName
             packetType:(MediaPipePacketType)packetType
              timestamp:(NSTimeInterval)timestamp
         allowOverwrite:(BOOL)allowOverwrite {
    return [_graph sendPixelBuffer:imageBuffer intoStream:CSTR(inputName) packetType:(MPPPacketType)packetType timestamp:mediapipe::Timestamp(timestamp) allowOverwrite:allowOverwrite];
}

- (BOOL)sendPixelBuffer:(CVPixelBufferRef)pixelBuffer
             intoStream:(const NSString *)inputName
             packetType:(MediaPipePacketType)packetType
              timestamp:(NSTimeInterval)timestamp {
    return [_graph sendPixelBuffer:pixelBuffer intoStream:CSTR(inputName) packetType:(MPPPacketType)packetType timestamp:mediapipe::Timestamp(timestamp)];
}

- (BOOL)sendPixelBuffer:(CVPixelBufferRef)imageBuffer
             intoStream:(const NSString *)inputName
             packetType:(MediaPipePacketType)packetType
              timestamp:(NSTimeInterval)timestamp
         allowOverwrite:(BOOL)allowOverwrite
                  error:(NSError **)error {
    return [_graph sendPixelBuffer:imageBuffer intoStream:CSTR(inputName) packetType:(MPPPacketType)packetType timestamp:mediapipe::Timestamp(timestamp) allowOverwrite:allowOverwrite error:error];
}

- (BOOL)sendPixelBuffer:(CVPixelBufferRef)pixelBuffer
             intoStream:(const NSString *)inputName
             packetType:(MediaPipePacketType)packetType {
    return [_graph sendPixelBuffer:pixelBuffer intoStream:CSTR(inputName) packetType:(MPPPacketType)packetType];
}

- (void)cancel {
    [_graph cancel];
}

- (BOOL)hasInputStream:(const NSString *)inputName {
    return [_graph hasInputStream:CSTR(inputName)];
}

- (BOOL)closeInputStream:(const NSString *)inputName error:(NSError **)error {
    return [_graph closeInputStream:CSTR(inputName) error:error];
}

- (BOOL)closeAllInputStreamsWithError:(NSError **)error {
    return [_graph closeAllInputStreamsWithError:error];
}

- (BOOL)waitUntilIdleWithError:(NSError **)error {
    return [_graph waitUntilDoneWithError:error];
}

@end


