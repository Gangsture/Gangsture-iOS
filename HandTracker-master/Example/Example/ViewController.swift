//
//  ViewController.swift
//  Example
//
//  Created by Tomoya Hirano on 2020/04/02.
//  Copyright © 2020 Tomoya Hirano. All rights reserved.
//

import UIKit
import AVFoundation
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

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, MediaPipeGraphDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var toggleView: UISwitch!
    let camera = Camera()
    
    let tracker = HandLandmarkTrackingGpu()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camera.setSampleBufferDelegate(self)
        camera.start()
        
        try! tracker.run { (output) in

            let data = output.handLandmarks[0]
            
            let str2 = self.dataToByteString(data: output.handLandmarks[0])
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        tracker.send(buffer: pixelBuffer)
        
        DispatchQueue.main.async {
            if !self.toggleView.isOn {
                self.imageView.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
            }
        }
    }
    
    // MARK: - [Data 를 Byte 바이트 값 문자열로 리턴 실시]
    func dataToByteString(data: Data) -> String {
        

        var returnData = ""
        var xLandmarks = [Float]()
        var yLandmarks = [Float]()
        var zLandmarks = [Float]()
        

        if data != nil
            && data.count>0
            && data.isEmpty == false {
           
            var xData = Data()
            var yData = Data()
            var zData = Data()
            
            
            
            for i in stride(from: 0, through: data.count-1, by: 17) {

                var xlandmark = ""
                var ylandmark = ""
                var zlandmark = ""
                
                var xvalues = [UInt8]()
                xvalues.append(data[i+3])
                xvalues.append(data[i+4])
                xvalues.append(data[i+5])
                xvalues.append(data[i+6])
                let xLandmark = bytesToFloat(bytes: xvalues)
                
                xLandmarks.append(xLandmark)
                var yvalues = [UInt8]()
                yvalues.append(data[i+8])
                yvalues.append(data[i+9])
                yvalues.append(data[i+10])
                yvalues.append(data[i+11])
                let yLandmark = bytesToFloat(bytes: yvalues)

                yLandmarks.append(yLandmark)
                
                var zvalues = [UInt8]()
                zvalues.append(data[i+13])
                zvalues.append(data[i+14])
                zvalues.append(data[i+15])
                zvalues.append(data[i+16])
                let zLandmark = bytesToFloat(bytes: zvalues)

                zLandmarks.append(zLandmark)


            }
            
                
            }

        var inputList = [Double]()
        
        var coordinateString = ""
        for i in 0..<21{

            var resultX = Double(xLandmarks[i]-xLandmarks[0])
            var resultY = Double(yLandmarks[i]-yLandmarks[0])
            var resultZ = Double(zLandmarks[i]-zLandmarks[0])

            inputList.append(Double(xLandmarks[i]))
            inputList.append(Double(xLandmarks[i]))
            inputList.append(Double(xLandmarks[i]))
            inputList.append(resultX)
            inputList.append(resultY)
            inputList.append(resultZ)
        }
        
        let model = GangstureHandModel()
        guard let gangstureHandModelOutput = try? model.prediction(
            hand_type: 0,
            _1_x: inputList[0],
            _1_y: inputList[1],
            _1_z: inputList[2],
            _1_rx: inputList[3],
            _1_ry: inputList[4],
            _1_rz: inputList[5],
            _2_x: inputList[6],
            _2_y: inputList[7],
            _2_z: inputList[8],
            _2_rx: inputList[9],
            _2_ry: inputList[10],
            _2_rz: inputList[11],
            _3_x: inputList[12],
            _3_y: inputList[13],
            _3_z: inputList[14],
            _3_rx: inputList[15],
            _3_ry: inputList[16],
            _3_rz: inputList[17],
            _4_x: inputList[18],
            _4_y: inputList[19],
            _4_z: inputList[20],
            _4_rx: inputList[21],
            _4_ry: inputList[22],
            _4_rz: inputList[23],
            _5_x: inputList[24],
            _5_y: inputList[25],
            _5_z: inputList[26],
            _5_rx: inputList[27],
            _5_ry: inputList[28],
            _5_rz: inputList[29],
            _6_x: inputList[30],
            _6_y: inputList[31],
            _6_z: inputList[32],
            _6_rx: inputList[33],
            _6_ry: inputList[34],
            _6_rz: inputList[35],
            _7_x: inputList[36],
            _7_y: inputList[37],
            _7_z: inputList[38],
            _7_rx: inputList[39],
            _7_ry: inputList[40],
            _7_rz: inputList[41],
            _8_x: inputList[42],
            _8_y: inputList[43],
            _8_z: inputList[44],
            _8_rx: inputList[45],
            _8_ry: inputList[46],
            _8_rz: inputList[47],
            _9_x: inputList[48],
            _9_y: inputList[49],
            _9_z: inputList[50],
            _9_rx: inputList[51],
            _9_ry: inputList[52],
            _9_rz: inputList[53],
            _10_x: inputList[54],
            _10_y: inputList[55],
            _10_z: inputList[56],
            _10_rx: inputList[57],
            _10_ry: inputList[58],
            _10_rz: inputList[59],
            _11_x: inputList[60],
            _11_y: inputList[61],
            _11_z: inputList[62],
            _11_rx: inputList[63],
            _11_ry: inputList[64],
            _11_rz: inputList[65],
            _12_x: inputList[66],
            _12_y: inputList[67],
            _12_z: inputList[68],
            _12_rx: inputList[69],
            _12_ry: inputList[70],
            _12_rz: inputList[71],
            _13_x: inputList[72],
            _13_y: inputList[73],
            _13_z: inputList[74],
            _13_rx: inputList[75],
            _13_ry: inputList[76],
            _13_rz: inputList[77],
            _14_x: inputList[78],
            _14_y: inputList[79],
            _14_z: inputList[80],
            _14_rx: inputList[81],
            _14_ry: inputList[82],
            _14_rz: inputList[83],
            _15_x: inputList[84],
            _15_y: inputList[85],
            _15_z: inputList[86],
            _15_rx: inputList[87],
            _15_ry: inputList[88],
            _15_rz: inputList[89],
            _16_x: inputList[90],
            _16_y: inputList[91],
            _16_z: inputList[92],
            _16_rx: inputList[93],
            _16_ry: inputList[94],
            _16_rz: inputList[95],
            _17_x: inputList[96],
            _17_y: inputList[97],
            _17_z: inputList[98],
            _17_rx: inputList[99],
            _17_ry: inputList[100],
            _17_rz: inputList[101],
            _18_x: inputList[102],
            _18_y: inputList[103],
            _18_z: inputList[104],
            _18_rx: inputList[105],
            _18_ry: inputList[106],
            _18_rz: inputList[107],
            _19_x: inputList[108],
            _19_y: inputList[109],
            _19_z: inputList[110],
            _19_rx: inputList[111],
            _19_ry: inputList[112],
            _19_rz: inputList[113],
            _20_x: inputList[114],
            _20_y: inputList[115],
            _20_z: inputList[116],
            _20_rx: inputList[117],
            _20_ry: inputList[118],
            _20_rz: inputList[119],
            _21_x: inputList[120],
            _21_y: inputList[121],
            _21_z: inputList[122],
            _21_rx: inputList[123],
            _21_ry: inputList[124],
            _21_rz: inputList[125]) else {
            fatalError("Unexpected runtime error.")
        }
        
        let signal = gangstureHandModelOutput.target
        var signalLabel = ""
        
        switch (signal){
        case 0:
            signalLabel = "UP"
            print("Up")
            //            self.tello.up(by: 10)
            
        case 1:
            signalLabel = "Down"
            print("Down")
            //            self.tello.down(by: 10)
        case 2:
            signalLabel = "Left"
            print("Left")
            //            self.tello.left(by: 10)
        case 3:
            signalLabel = "Right"
            print("Right")
            //            self.tello.right(by: 10)
        case 4:
            signalLabel = "Go forward"
//            forwardCount = forwardCount + 1
            print("Go forward")
//            if signal == previousDirection && forwardCount > 30 && tello.activate(){
//                self.tello.forward(by: 30)
//                forwardCount = 0
//            }
            
//            if tello.activate(){
//                self.tello.forward(by: 10)
//            }
                       
        case 5:
            signalLabel = "Back"
            print("Back")
            
//            backwardCount = backwardCount + 1
//            if signal == previousDirection && backwardCount > 30 && tello.activate(){
//                self.tello.back(by: 30)
//                backwardCount = 0
//            }
//            if tello.activate(){
//                self.tello.back(by: 10)
//            }
         
        case 6:
            signalLabel = "Take off"
            print("Take off")
//            takeoffCount = takeoffCount + 1
            
//            if signal == previousDirection && takeoffCount > 30 && tello.activate(){
//                self.tello.takeoff()
//                takeoffCount = 0
//            }
//            if tello.activate(){
//                            self.tello.takeoff()
//            }
            
        case 7:
            signalLabel = "Land"
            print("Land")
//            landCount = landCount + 1
//            if signal == previousDirection && landCount > 30 && tello.activate(){
//                self.tello.land()
//                landCount = 0
//            }
//            if(tello.activate()){
//                self.tello.land()
//            }
                        
        default :
            print("default")
        }

            return returnData
        }
    
    func bytesToFloat(bytes b: [UInt8]) -> Float {
        let littleEndianValue = b.withUnsafeBufferPointer {
            $0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0.pointee }
        }
        let bitPattern = UInt32(littleEndian: littleEndianValue)
        return Float(bitPattern: bitPattern)
    }


     
}
