//
//  ViewController.swift
//  Example
//
//  Created by Tomoya Hirano on 2020/04/02.
//  Copyright © 2020 Tomoya Hirano. All rights reserved.
//

import AVFoundation
import MediaPipeHands
import MobileCoreServices
import NetworkExtension
import TelloSwift
import UIKit


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, MediaPipeGraphDelegate, TelloVideoSteam , UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var droneVideoView: UIImageView!
    @IBOutlet weak var directionLabel: UILabel!
    @IBOutlet weak var droneControlSwitch: UISwitch!
    @IBOutlet weak var faceButton: UIButton!
    @IBOutlet weak var faceLabel: UILabel!
    
    //    let storage = Storage.storage()
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
    //    var isSendControl = true
    var isSendControl = false
    var isMoving = false
    
    
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
        
        faceLabel.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("뷰디드어페어")
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now().advanced(by: .seconds(5))) { [unowned self] in
            // use either startHandle() or decoder.renderVideoStream(),
            // they just behave in different ways, but eventually the same, giving more flexibility
            
            //            self.startHandle()
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
    
    @IBAction func wifiButtonDidTap(_ sender: Any) {
        print("dronewifi")
        //If this button is clicked, Wifi will be connected to the drone
        let configuration = NEHotspotConfiguration.init(ssid: "TELLO-98F9B8", passphrase: "DonotHavePassword", isWEP: false)
        configuration.joinOnce = true
        
        //Connect to the drone's Wifi
        NEHotspotConfigurationManager.shared.apply(configuration) { (error) in
            if error != nil { //There are error
                if error?.localizedDescription == "already associated." //The error is what the Wifi is already connected to the drone
                {
                    print("Connected")
                }
                else{
                    print("No Connected") //There are error and not connected to the drone yet.
                }
            }
            else {
                print("Connected")
            }
        }
        print("Complete to connect to the drone button")
    }
    
    @IBAction func faceButtonDidTap(_ sender: Any) {
        switch faceLabel.isHidden{
        case true: faceLabel.isHidden = false
            droneControlSwitch.isOn = true
        case false: faceLabel.isHidden = true
            droneControlSwitch.isOn = true
        }
    }
    
    @IBAction func InternetButtonDidTap(_ sender: Any) {
        print("internet wifi")
        //If this button is clicked, Wifi will be connected to the Internet
        let configuration = NEHotspotConfiguration.init(ssid: "IITP", passphrase: "K0r3anSquar3!20", isWEP: false)
        //        configuration.joinOnce = true
        
        //Connect to the Internet
        NEHotspotConfigurationManager.shared.apply(configuration) { (error) in
            if error != nil {
                if error?.localizedDescription == "already associated."
                {
                    print("Connected")
                }
                else{
                    print("No Connected") //Print "No Connected" when there is error and it is not connected yet.
                }
            }
            else {
                print("Connected")
            }
        }
    }
    
    @IBAction func photoButtonDidTap(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeMovie as String]
        //        picker.videoQuality = .typeIFrame1280x720
        self.present(picker, animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil);
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        //        let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as! URL
        //        let videoPath = videoUrl.path
        //        print("videoURL: \(videoUrl)")
        //        print("videoPath: \(videoPath)")
        //
        //        let data = NSData(contentsOf: videoUrl)!
        //
        //        let metadata = StorageMetadata() //get metadata of firebase
        //        metadata.contentType = "video/quicktime"
        //        let storageRef = storage.reference() //get storage reference of the firebase storage
        //
        //        let videoRef = storageRef.child("videos/video0001111.MOV")
        //
        //        videoRef.putData(data as Data, metadata: nil){ (metadata, error) in //uploading to the firebase storage folder
        //            guard let metadata = metadata else {
        //                //If there is error in meta data, print "error"
        //                print("error\(error)")
        //                return
        //            }
        //            print("Put us complete and I got this back: \(String(describing: metadata))")
        //            // Metadata contains file metadata such as size, content-type.
        //            let size = metadata.size
        //
        //            // Access to download URL after upload.
        //            videoRef.downloadURL { (url, error) in
        //                guard let downloadURL = url else {
        //                    print("Got an generating the URL:)")
        //                    // Uh-oh, an error occurred!
        //                    return
        //                }
        //            }
        //        }
        //
        //        /*
        //         let fileManager = FileManager.default
        //
        //         while true {
        //         if FileManager.default.fileExists(atPath: videoPath!) {
        //         try! FileManager.default.removeItem(atPath: videoPath!)
        //         print("deleted!!")
        //         break
        //         }
        //         }*/
        //        /*
        //         if videoUrl.startAccessingSecurityScopedResource() {
        //         print("Start Accessing Security Scope Resource")
        //
        //         do {
        //         try! FileManager.default.removeItem(at: videoUrl)
        //         print("removed!")
        //         }
        //         catch{
        //         print("error is in here~~")
        //         }
        //         videoUrl.stopAccessingSecurityScopedResource()
        //         }
        //         */
        //        /*if CFURLStartAccessingSecurityScopedResource(videoUrl as CFURL){
        //         print("Start Accessing Security Scope Resource")
        //         CFURLStopAccessingSecurityScopedResource(videoUrl as CFURL)
        //         }*/
        ////        let paths
        //        if FileManager.default.fileExists(atPath: videoUrl.path){
        //            print("Here is a video~")
        //            do{
        //                try FileManager.default.removeItem(at: videoUrl)
        //                print("video is DELETED.")
        //            }catch{
        //                print("ERROR: \(error)")
        //            }
        //        }
        print("Done")
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
        
        
        let model = GangstureHandModel()
        guard let gangstureHandModelOutput = try? model.prediction(inputList: inputList) else {
            fatalError("Unexpected runtime error.")
        }
        
        let signal = gangstureHandModelOutput.target
        
        sendSignalToDrone(signal: Int(signal))
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
    
    func sendSignalToDrone(signal: Int){
        var signalLabel = ""
        let controlCount = 5 //num of stack
        
        switch (signal){
        case 0:
            signalLabel = "UP"
            upCount = upCount + 1
            print("Up")
            if signal == previousDirection && upCount > controlCount && droneControlSwitch.isOn&&isSendControl{
                self.tello.up(by: 30)
                upCount = 0
            }
            
            
            
        case 1:
            signalLabel = "Down"
            downCount = downCount + 1
            print("Down")
            if signal == previousDirection && downCount > controlCount && droneControlSwitch.isOn && isSendControl{
                self.tello.down(by: 30)
                downCount = 0
            }
            
        case 2:
            signalLabel = "Left"
            leftCount = leftCount + 1
            print("Left")
            if signal == previousDirection && leftCount > controlCount && droneControlSwitch.isOn && isSendControl{
                self.tello.left(by: 30)
                leftCount = 0
            }
            
        case 3:
            signalLabel = "Right"
            rightCount = rightCount + 1
            print("Right")
            if signal == previousDirection && rightCount > controlCount && droneControlSwitch.isOn && isSendControl{
                self.tello.right(by: 30)
                rightCount = 0
            }
            
        case 4:
            signalLabel = "Go forward"
            forwardCount = forwardCount + 1
            print("Go forward")
            if signal == previousDirection && forwardCount > controlCount && droneControlSwitch.isOn && isSendControl{
                self.tello.forward(by: 30)
                forwardCount = 0
            }
            
            
        case 5:
            signalLabel = "Back"
            print("Back")
            
            backwardCount = backwardCount + 1
            if signal == previousDirection && backwardCount > controlCount && droneControlSwitch.isOn && isSendControl{
                self.tello.back(by: 30)
                backwardCount = 0
            }
            
        case 6:
            
            print("Take off")
            takeoffCount = takeoffCount + 1
            if signal == previousDirection && takeoffCount > 10 {
                
                isMoving = true
                takeoffCount = 0
            }
            
            
            
            if signal == previousDirection && takeoffCount > 10 && droneControlSwitch.isOn && isSendControl{
                print("true")
                self.tello.takeoff()
                takeoffCount = 0
                
            }
            if isMoving {
                signalLabel = "Stop"
            }else {
                signalLabel = "Take off"
            }
            
            
        case 7:
            signalLabel = "Land"
            print("Land")
            landCount = landCount + 1
            if signal == previousDirection && landCount > 15 && droneControlSwitch.isOn && isSendControl{
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
    }
    
    func sendSignalVelocity(signal: Int) {
        
        print("속도로보내기ㅣ")
        var signalLabel = ""
        let controlCount = 0 //num of stack
        
        var leftright = 0
        var forebackward = 0
        var updown = 0
        var yawvelocity = 0
        
        let speed = 10
        
        switch (signal){
        case 0:
            updown = speed
            signalLabel = "UP"
            upCount = upCount + 1
            print("Up")
            
            if upCount > controlCount && droneControlSwitch.isOn && isSendControl{
                //                let result = tello.telloSyncCommand(cmd: "rc \(leftright) \(forebackward) \(updown) \(yawvelocity)")
                let result = tello.telloSyncCommand(cmd: "rc 0 0 10 0")
                upCount = 0
            }
            
        case 1:
            updown = -speed
            signalLabel = "Down"
            downCount = downCount + 1
            print("Down")
            if downCount > controlCount && droneControlSwitch.isOn && isSendControl{
                //                let result = tello.telloSyncCommand(cmd: "rc \(leftright) \(forebackward) \(updown) \(yawvelocity)")
                let result = tello.telloSyncCommand(cmd: "rc 0 0 -10 0")
                downCount = 0
            }
            
        case 2:
            leftright = -speed
            signalLabel = "Left"
            leftCount = leftCount + 1
            print("Left")
            if leftCount > controlCount && droneControlSwitch.isOn && isSendControl{
                //                let result = tello.telloSyncCommand(cmd: "rc \(leftright) \(forebackward) \(updown) \(yawvelocity)")
                let result = tello.telloSyncCommand(cmd: "rc -10 0 0 0")
                leftCount = 0
            }
            
        case 3:
            leftright = speed
            signalLabel = "Right"
            rightCount = rightCount + 1
            print("Right")
            if rightCount > controlCount && droneControlSwitch.isOn && isSendControl{
                //                let result = tello.telloSyncCommand(cmd: "rc \(leftright) \(forebackward) \(updown) \(yawvelocity)")
                let result = tello.telloSyncCommand(cmd: "rc 10 0 0 0")
                rightCount = 0
            }
            
        case 4:
            forebackward = speed
            signalLabel = "Go forward"
            forwardCount = forwardCount + 1
            print("Go forward")
            print(forwardCount)
            if forwardCount > controlCount && droneControlSwitch.isOn && isSendControl{
                //                let result = tello.telloSyncCommand(cmd: "rc \(leftright) \(forebackward) \(updown) \(yawvelocity)")
                let result = tello.telloSyncCommand(cmd: "rc 0 10 0 0")
                
                forwardCount = 0
                
            }
            
            
        case 5:
            forebackward = -speed
            signalLabel = "Back"
            print("Back")
            backwardCount = backwardCount + 1
            if backwardCount > controlCount && droneControlSwitch.isOn && isSendControl{
                //                let result = tello.telloSyncCommand(cmd: "rc \(leftright) \(forebackward) \(updown) \(yawvelocity)")
                let result = tello.telloSyncCommand(cmd: "rc 0 -10 0 0")
                backwardCount = 0
            }
            
            
        case 6:
            signalLabel = "Take off"
            print("Take off")
            takeoffCount = takeoffCount + 1
            if takeoffCount > 15 && droneControlSwitch.isOn && isSendControl{
                print("true")
                self.tello.takeoff()
                takeoffCount = 0
                
            }
        case 7:
            signalLabel = "Land"
            print("Land")
            landCount = landCount + 1
            if landCount > 15 && droneControlSwitch.isOn && isSendControl{
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
