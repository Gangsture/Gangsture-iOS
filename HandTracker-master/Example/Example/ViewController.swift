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
//            print(output.handLandmarks.count)
//            print(output.handLandmarks[0])
            let data = output.handLandmarks[0]
            
            
            //            let str = String(decoding: data, as: UTF8.self) //7���\277\275��؏�<2
            
            //            print(str)
            let str2 = self.dataToByteString(data: output.handLandmarks[0])
            
            //            if(output.worldLandmarks.count == 2){
            //                let str2 = self.dataToByteString(data: output.worldLandmarks[0])
            //                let str3 = self.dataToByteString(data: output.worldLandmarks[1])
            //
            //                DispatchQueue.global().async {
            //                    print("[0]:\(str2)")
            //                    print("[1]:\(str3)")
            //                }
            //
            //            }
        }
        
        do {
            //                let landmarks = try NormalizedLandmark(from: output.worldLandmarks[0] as! Decoder)
            //                  print(landmarks)
            
            //                let value = try JSONDecoder().decode(NormalizedLandmark.self, from: output.worldLandmarks[0])
            //                    print(value)
            
            //                let number = try JSONDecoder().decode(NormalizedLandmark.self, from: output.worldLandmarks[0])
            //                print(number)
            //
            //                } catch {
            //                  print(error)
            //                }
            //
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
        
        // [초기 리턴 데이터 변수 선언 실시]
        var returnData = ""
        var xLandmarks = [Float]()
        var yLandmarks = [Float]()
        var zLandmarks = [Float]()
        
        // [인풋 데이터 널 체크 수행 실시]
        if data != nil
            && data.count>0
            && data.isEmpty == false {
            
            // [바이트 배열 값 확인 실시]
            returnData = "["
//            print("data.count = \(data.count)")
//            print("data = \(String(describing: data))")
//            var num = floatValue(data: data[3])
//            print(num)
            
            
            var xData = Data()
            var yData = Data()
            var zData = Data()
            
            
            
            for i in stride(from: 0, through: data.count-1, by: 17) {
                //                var xlandmark = Data()
                //                var ylandmark = Data()
                //                var zlandmark = Data()
                var xlandmark = ""
                var ylandmark = ""
                var zlandmark = ""
                
                /*
                                let xvalue =
                                  (Float(data[i+3]) << (0*8)) | // shifted by zero bits (not shifted)
                                  (Float(data[i+4]) << (1*8)) | // shifted by 8 bits
                                  (Float(data[i+5]) << (2*8)) | // shifted by 16 bits
                                  (Float(data[i+6]) << (3*8))
                
                                let yvalue =
                                  (Float(data[i+8]) << (0*8)) | // shifted by zero bits (not shifted)
                                  (Float(data[i+9]) << (1*8)) | // shifted by 8 bits
                                  (Float(data[i+10]) << (2*8)) | // shifted by 16 bits
                                  (Float(data[i+11]) << (3*8))
                
                                let zvalue =
                                  (Float(data[i+13]) << (0*8)) | // shifted by zero bits (not shifted)
                                  (Float(data[i+14]) << (1*8)) | // shifted by 8 bits
                                  (Float(data[i+15]) << (2*8)) | // shifted by 16 bits
                                  (Float(data[i+16]) << (3*8))
                */
//                print(String(describing: data[i+3]))
//                print(String(describing: data[i+4]))
//                print(String(describing: data[i+5]))
//                print(String(describing: data[i+6]))
//
                var xvalues = [UInt8]()
                xvalues.append(data[i+3])
                xvalues.append(data[i+4])
                xvalues.append(data[i+5])
                xvalues.append(data[i+6])
                let xLandmark = bytesToFloat(bytes: xvalues)
//                print(xlandmark)
                
                xLandmarks.append(xLandmark)
                var yvalues = [UInt8]()
                yvalues.append(data[i+8])
                yvalues.append(data[i+9])
                yvalues.append(data[i+10])
                yvalues.append(data[i+11])
                let yLandmark = bytesToFloat(bytes: yvalues)
//                print(ylandmark)
               
                yLandmarks.append(yLandmark)
                
                var zvalues = [UInt8]()
                zvalues.append(data[i+13])
                zvalues.append(data[i+14])
                zvalues.append(data[i+15])
                zvalues.append(data[i+16])
                let zLandmark = bytesToFloat(bytes: zvalues)
//                print(zlandmark)
                
                zLandmarks.append(zLandmark)
                
//                print("\(i/17+1)번째 x:\(xLandmark),y:\(yLandmark),z:\(zLandmark)")
                
                
                //                xlandmark += String(describing:data[i+3])
                //                xlandmark += String(describing:data[i+4])
                //                xlandmark += String(describing:data[i+5])
                //                xlandmark += String(describing:data[i+6])
                //
                //                ylandmark += String(describing:data[i+8])
                //                ylandmark += String(describing:data[i+9])
                //                ylandmark += String(describing:data[i+10])
                //                ylandmark += String(describing:data[i+11])
                //
                //                zlandmark += String(describing:data[i+13])
                //                zlandmark += String(describing:data[i+14])
                //                zlandmark += String(describing:data[i+15])
                //                zlandmark += String(describing:data[i+16])
                
                
                //                xlandmark += data[i+3]
                //                xlandmark += data[i+4]
                //                xlandmark += data[i+5]
                //                xlandmark += data[i+6]
                //
                //                ylandmark += data[i+8]
                //                ylandmark += data[i+9]
                //                ylandmark += data[i+10]
                //                ylandmark += data[i+11]
                //
                //                zlandmark += data[i+13]
                //                zlandmark += data[i+14]
                //                zlandmark += data[i+15]
                //                zlandmark += data[i+16]
                
                
                
//                               print("\(i/17+1)번째 x:\(xvalue),y:\(yvalue),z:\(zvalue)")
                
                
                //                    let str = String(decoding: data, as: UTF8.self)
                
                
                //                print("\(i)번째 :\(String(describing: data[i]))")
                //                    returnData += String(describing: data[i]) // [개별 바이트 값을 삽입]
                
                //                    if i != data.count-1 { // [배열 형태로 찍기 위함]
                //                        returnData += ", "
                //                    }
                
                //            for i in stride(from: 0, through: data.count-1, by: 1) {
                //                print("\(i)번째 \(data[i])")
                //            }
                //
                //
                //                returnData += "\(i/17)번째 x: \(xlandmark),y: \(ylandmark),z:\(zlandmark)"
                
                
                
            }
            
                
            }

        var inputList = [Double]()
        
        var coordinateString = ""
        for i in 0..<21{

            var resultX = Double(xLandmarks[i]-xLandmarks[0])
            var resultY = Double(yLandmarks[i]-yLandmarks[0])
            var resultZ = Double(zLandmarks[i]-zLandmarks[0])

//            coordinateString.append(contentsOf: "\(i)번 x:\(targetLandmark.x),y:\(targetLandmark.y),z:\(resultZ)")
//            coordinateString.append(contentsOf: "\(i)번z:\(targetLandmark.z)\n")
           
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
        
            // [리턴 데이터 반환 실시]
            return returnData
        }
    
    func bytesToFloat(bytes b: [UInt8]) -> Float {
        let bigEndianValue = b.withUnsafeBufferPointer {
            $0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0.pointee }
        }
//        let bitPattern = UInt32(bigEndian: bigEndianValue)
        let bitPattern = UInt32(littleEndian: bigEndianValue)
        
        return Float(bitPattern: bitPattern)
    }

        
        func floatValue(data: Data)->Float {
            return Float(bitPattern: UInt32(bigEndian: data.withUnsafeBytes{
                $0.load(as: UInt32.self)
            }))
        }
        
        // MARK: - [Data 를 Byte 바이트 값 문자열로 리턴 실시]
        func dataToByteString(data: [Data]) -> String {
            
            
            // [초기 리턴 데이터 변수 선언 실시]
            var returnData = ""
            
            // [인풋 데이터 널 체크 수행 실시]
            if data.count>0
                && data.isEmpty == false {
                
                // [바이트 배열 값 확인 실시]
                returnData = "["
                //                print("data.count = \(data.count)")
                //                print("data = \(String(describing: data))")
                for j in 0..<2{
//                    print("\(j)번 index")
                    for i in stride(from: 0, through: data[j].count-1, by: 1) {
                        //                    if (i%17==13){
                        //                        print("\(i)번째 :\(String(describing: data[i]))")
                        //                    }
                        
//                        DispatchQueue.global(qos: .utility).async {
//                            print("\(i)번째 :\(String(describing: data[i]))")
//                        }
                        //                    print("\(i)번째 :\(String(describing: data[i]))")
                        
                        //                    returnData += String(describing: data[i]) // [개별 바이트 값을 삽입]
                        
                        //                    if i != data.count-1 { // [배열 형태로 찍기 위함]
                        //                        returnData += ", "
                        //                    }
                    }
                    //                returnData += "]"
                }
            }
            //
            return returnData
        }
        
        
    
}
