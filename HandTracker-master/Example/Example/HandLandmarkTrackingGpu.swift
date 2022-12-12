//
//  HandLandmarkTrackingGpu.swift
//  Example
//
//  Created by 이유진 on 2022/12/12.
//  Copyright © 2022 Tomoya Hirano. All rights reserved.
//

import Foundation
import MediaPipeHands


class HandLandmarkTrackingGpu: NSObject, MediaPipeGraphDelegate {
    struct Output {
        let handLandmarks: [Data]
        let worldLandmarks: [Data]
        let handedness: [Data]
    }
    
    var receiver = PacketReceiver()
    var graph: MediaPipeGraph?
    
    var lastSend = Date.distantPast
    var minimumTimeInterval = 0.15
    
    func run(handler: @escaping (Output) -> Void) throws {
        let url = Bundle(for: MediaPipeGraph.self).url(forResource: "hand_landmark_tracking_gpu", withExtension: "binarypb")!
        
        let graph = try MediaPipeGraph(graphConfig: Data(contentsOf: url))
        
        graph.setSidePacket(.init(int32: 2), named: "num_hands")
        graph.setSidePacket(.init(int32: 1), named: "model_complexity")
        graph.setSidePacket(.init(bool: true), named: "use_prev_landmarks")
        
        graph.addFrameOutputStream("multi_hand_landmarks", outputPacketType: .raw)
        graph.addFrameOutputStream("multi_hand_world_landmarks", outputPacketType: .raw)
        graph.addFrameOutputStream("multi_handedness", outputPacketType: .raw)
        graph.delegate = receiver
        receiver.handler = { batch in
            handler(Output(
                handLandmarks: batch.packets["multi_hand_landmarks"]?.getArrayOfProtos() ?? [],
                worldLandmarks: batch.packets["multi_hand_world_landmarks"]?.getArrayOfProtos() ?? [],
                handedness: batch.packets["multi_handedness"]?.getArrayOfProtos() ?? [])
            )
        }
        
        try graph.start()
        self.graph = graph
    }
    
    func send(buffer: CVPixelBuffer) {
        let now = Date()
        if now.timeIntervalSince(lastSend) < minimumTimeInterval {
            return
        }
        lastSend = now
        graph?.send(buffer, intoStream: "image", packetType: .pixelBuffer)
    }
    
    
}
