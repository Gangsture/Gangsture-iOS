//
//  PacketReceiver.swift
//  Example
//
//  Created by 이유진 on 2022/12/12.
//  Copyright © 2022 Tomoya Hirano. All rights reserved.
//

import Foundation
import MediaPipeHands

class PacketReceiver: NSObject, MediaPipeGraphDelegate {
    struct Batch {
        var timestamp: MediaPipeTimestamp
        var packets: [String: MediaPipePacket]
    }
    
    var handler: ((Batch) -> Void)?
    
    var batch: Batch?
    
    let syncQueue = DispatchQueue(label: "PacketReceiver")
    
    func mediapipeGraph(_ graph: MediaPipeGraph, didOutputPacket packet: MediaPipePacket, fromStream streamName: String) {
        syncQueue.async {
            if let batch = self.batch, batch.timestamp != packet.timestamp {
                let currentBatch = batch
                self.batch = nil
                DispatchQueue.main.async {
                    self.handler?(currentBatch)
                }
            }
            
            if self.batch == nil {
                self.batch = .init(timestamp: packet.timestamp, packets: [:])
            }
            
            self.batch?.packets[streamName] = packet
        }
    }
}
