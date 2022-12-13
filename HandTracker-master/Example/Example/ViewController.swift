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
import TelloSwift

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, MediaPipeGraphDelegate, TelloVideoSteam {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var droneVideoView: UIImageView!
    @IBOutlet weak var directionLabel: UILabel!
    @IBOutlet weak var droneControlSwitch: UISwitch!
    let camera = Camera()
    let tracker = HandLandmarkTrackingGpu()
    
    var takeoffCount = 0
    var landCount = 0
    var forwardCount = 0
    var backwardCount = 0
    var leftCount = 0
    var rightCount = 0
    var upCount = 0
    var downCount = 0
    var previousDirection = 10
    var isDroneConnected = false
    var isSendControl = true
//    var isSendControl = false
    
    //DroneVideoView related Variables
    var videoLayer : AVSampleBufferDisplayLayer?
    var streamBuffer = Array<UInt8>()
    let decoder = TelloVideoH264Decoder()
    var tello : Tello!
    let startCode : [UInt8] = [0,0,0,1]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camera.setSampleBufferDelegate(self)
        camera.start()
        
        try! tracker.run { (output) in

            let data = output.handLandmarks[0]
            
            let str2 = self.dataToByteString(data: output.handLandmarks[0])
        }
        
        tello = Tello()
        tello.videoDelegate = self
        print("고")
        
        if(isSendControl){
                if self.tello.activate() {
                    self.isDroneConnected = true
                    print("connected:", self.tello.activate())
                    print("battery:", self.tello.battery)
                            tello.enable(video: true)
                            tello.keepAlive(every: 10)
                }else{
                    self.isDroneConnected = false
                    print("연결 안됨")
                }
          
        }


//


        videoLayer = AVSampleBufferDisplayLayer()
        
      
        if let layer = self.videoLayer {
            layer.frame = CGRect(x: 0, y: 0, width: self.droneVideoView.frame.width, height: self.droneVideoView.frame.height)
            layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            
            let _CMTimebasePointer = UnsafeMutablePointer<CMTimebase?>.allocate(capacity: 1)
            let status = CMTimebaseCreateWithMasterClock( allocator: kCFAllocatorDefault, masterClock: CMClockGetHostTimeClock(),  timebaseOut: _CMTimebasePointer )
            layer.controlTimebase = _CMTimebasePointer.pointee
            
            if let controlTimeBase = layer.controlTimebase, status == noErr {
                CMTimebaseSetTime(controlTimeBase, time: CMTime.zero);
                CMTimebaseSetRate(controlTimeBase, rate: 1.0);
            }
            self.droneVideoView.layer.addSublayer(layer)
            layer.display()

        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("뷰디드어페어")
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now().advanced(by: .seconds(2))) { [unowned self] in
            // use either startHandle() or decoder.renderVideoStream(),
            // they just behave in different ways, but eventually the same, giving more flexibility
            
            //self.startHandle()
            self.decoder.renderVideoStream(streamBuffer: &self.streamBuffer, to: self.videoLayer!)
            
        }
        
         
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tello.clearTimer()
        tello.shutdown()
    }
    
    @IBAction func stopButtonDidTap(_ sender: Any) {
        if droneControlSwitch.isOn && isSendControl{
            self.tello.stop()
        }
    }
    
    @IBAction func landButtonDidTap(_ sender: Any) {
        if droneControlSwitch.isOn && isSendControl{
            self.tello.land()
        }
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        tracker.send(buffer: pixelBuffer)
        
        DispatchQueue.main.async {
                self.imageView.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
            
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
//                let zLandmark = Float(0.0)
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
        
//        let model = GangstureModel()
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
            upCount = upCount + 1
            print("Up")
            if signal == previousDirection && upCount > 10 && droneControlSwitch.isOn{
                self.tello.up(by: 30)
                upCount = 0
            }
            
           
            
        case 1:
            signalLabel = "Down"
            downCount = downCount + 1
            print("Down")
            if signal == previousDirection && downCount > 10 && droneControlSwitch.isOn && isSendControl{
                self.tello.down(by: 30)
                downCount = 0
            }
            
        case 2:
            signalLabel = "Left"
            leftCount = leftCount + 1
            print("Left")
            if signal == previousDirection && leftCount > 10 && droneControlSwitch.isOn && isSendControl{
                self.tello.left(by: 30)
                leftCount = 0
            }
            
        case 3:
            signalLabel = "Right"
            rightCount = rightCount + 1
            print("Right")
            if signal == previousDirection && rightCount > 10 && droneControlSwitch.isOn && isSendControl{
                self.tello.right(by: 30)
                rightCount = 0
            }
            
        case 4:
            signalLabel = "Go forward"
            forwardCount = forwardCount + 1
            print("Go forward")
          if signal == previousDirection && forwardCount > 10 && droneControlSwitch.isOn && isSendControl{
            self.tello.forward(by: 30)
            forwardCount = 0
        }
            
                       
        case 5:
            signalLabel = "Back"
            print("Back")
            
            backwardCount = backwardCount + 1
            if signal == previousDirection && backwardCount > 10 && droneControlSwitch.isOn && isSendControl{
                self.tello.back(by: 30)
                backwardCount = 0
            }

        case 6:
            signalLabel = "Take off"
            print("Take off")
            takeoffCount = takeoffCount + 1

            
            if signal == previousDirection && takeoffCount > 10 && droneControlSwitch.isOn && isSendControl{
                print("true")
                self.tello.takeoff()
                takeoffCount = 0
            }

            
        case 7:
            signalLabel = "Land"
            print("Land")
            landCount = landCount + 1
            if signal == previousDirection && landCount > 10 && droneControlSwitch.isOn && isSendControl{
                self.tello.land()
                landCount = 0
            }
       
        default :
            print("default")
        }
        
        previousDirection = Int(signal)
        
        DispatchQueue.main.async {
            self.directionLabel.text = signalLabel
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
    
    func telloStream(receive frame: Data?) {
        
        if let frame = frame {
            let packet = [UInt8](frame)
            streamBuffer.append(contentsOf: packet)
        }
    }
    
    public typealias NALU = Array<UInt8>
    func getNALUnit() -> NALU? {
        
        if streamBuffer.count == 0 {
            return nil
        }
        
        //make sure start with start code
        if streamBuffer.count < 5 || Array(streamBuffer[0...3]) != startCode {
            return nil
        }
        
        //find second start code, so startIndex = 4
        var startIndex = 4
        
        while true {
            
            while ((startIndex + 3) < streamBuffer.count) {
                if Array(streamBuffer[startIndex...startIndex+3]) == startCode {
                    
                    let packet = Array(streamBuffer[0..<startIndex])
                    streamBuffer.removeSubrange(0..<startIndex)
                    
                    return packet
                }
                startIndex += 1
            }
            
            // not found next start code , read more data
            if streamBuffer.count == 0 {
                return nil
            }
        }
    }
    
    func startHandling() {
        while let packet = getNALUnit() {
            if let sampleBuffer = decoder.getCMSampleBuffer(from: packet) {
                let attachments:CFArray? = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true)
                if let attachmentArray = attachments {
                    let dic = unsafeBitCast(CFArrayGetValueAtIndex(attachmentArray, 0), to: CFMutableDictionary.self)
                    
                    CFDictionarySetValue(dic,
                                         Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                                         Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
                }
                
                videoLayer?.enqueue(sampleBuffer)
                
                DispatchQueue.main.async(execute: {
                    self.videoLayer?.needsDisplay()
                    
                })
            }
        }
    }
    
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension CGFloat {
    func ceiling(toDecimal decimal: Int) -> CGFloat {
        let numberOfDigits = CGFloat(abs(pow(10.0, Double(decimal))))
        if self.sign == .minus {
            return CGFloat(Int(self * numberOfDigits)) / numberOfDigits
        } else {
            return CGFloat(ceil(self * numberOfDigits)) / numberOfDigits
        }
    }
}

extension Double {
    func ceiling(toDecimal decimal: Int) -> Double {
        let numberOfDigits = abs(pow(10.0, Double(decimal)))
        if self.sign == .minus {
            return Double(Int(self * numberOfDigits)) / numberOfDigits
        } else {
            return Double(ceil(self * numberOfDigits)) / numberOfDigits
        }
    }
}
