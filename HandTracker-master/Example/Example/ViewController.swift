import AVFoundation
import MediaPipeHands
import MobileCoreServices
import NetworkExtension
import TelloSwift
import UIKit


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, MediaPipeGraphDelegate, TelloVideoSteam {
    //UI Components
    @IBOutlet weak var handVideoView: UIImageView!
    @IBOutlet weak var droneVideoView: UIImageView!
    @IBOutlet weak var directionLabel: UILabel!
    @IBOutlet weak var droneControlActivateSwitch: UISwitch!
    @IBOutlet weak var faceRecognitionLabel: UILabel!
    
    let camera = Camera()  //Mobile camera
    let tracker = HandLandmarkTrackingGpu() //Mediapipe model
    
    // Variables to store the number of AI results used to send controls
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
    var isSendControl = false //Change to true when actually connecting to the drone
    var isMoving = false
    
    
    //Variables related to Tello Drone and VideoStreaming
    var videoLayer : AVSampleBufferDisplayLayer?
    var streamBuffer = Array<UInt8>()
    let decoder = TelloVideoH264Decoder()
    var tello : Tello!//Drone API Class
    let startCode : [UInt8] = [0,0,0,1]
    public typealias NALU = Array<UInt8>
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camera.setSampleBufferDelegate(self)
        camera.start()
        
        tello = Tello()
        tello.videoDelegate = self
        
        if(isSendControl){
            //Connect to Tello Drone
            if self.tello.activate() {
                self.isDroneConnected = true
                print("connected:", self.tello.activate())
                print("battery:", self.tello.battery)
                tello.enable(video: true)
                tello.keepAlive(every: 10)
            }else{
                self.isDroneConnected = false
            }
        }
        
        
        videoLayer = AVSampleBufferDisplayLayer()
        //Initialize UI layer to display drone streaming view
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
        faceRecognitionLabel.isHidden = true
        
        //Put mobile camera video into MediaPipe,get landmark and send control siganl
        try! tracker.run { (output) in
            let data = output.handLandmarks[0]
            let inputlist = self.getInputList(data: output.handLandmarks[0])
            let signal = self.getGesture(inputList: inputlist)
            self.sendSignalToDrone(signal: Int(signal))
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Start to get drone streaming video
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now().advanced(by: .seconds(5))) { [unowned self] in
            self.decoder.renderVideoStream(streamBuffer: &self.streamBuffer, to: self.videoLayer!)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //Terminate connection with drone
        tello.clearTimer()
        tello.shutdown()
    }
    //Stop with a button
    @IBAction func stopButtonDidTap(_ sender: Any) {
        
        if droneControlActivateSwitch.isOn && isSendControl{
            self.tello.stop()
        }
    }
    
    //Land with a button
    @IBAction func landButtonDidTap(_ sender: Any) {
        if droneControlActivateSwitch.isOn && isSendControl{
            self.tello.land()
        }
    }
    
    @IBAction func wifiButtonDidTap(_ sender: Any) {
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
    
    @IBAction func InternetButtonDidTap(_ sender: Any) {
        //If this button is clicked, Wifi will be connected to the Internet
        let configuration = NEHotspotConfiguration.init(ssid: "IITP", passphrase: "K0r3anSquar3!20", isWEP: false)
        configuration.joinOnce = true
        
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
    
    
    //Put the video from the mobile camera into the media pipe and display it on the screen
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        tracker.send(buffer: pixelBuffer)
        
        DispatchQueue.main.async {
            self.handVideoView.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
            
        }
    }
    
    //Convert MediaPipe landmarks to input list for gesture AI
    func getInputList(data: Data) -> [Double] {
        
        var xLandmarks = [Float]()
        var yLandmarks = [Float]()
        var zLandmarks = [Float]()
        
        var inputList = [Double]()
        
        if  data.count>0
                && data.isEmpty == false {
            let xData = Data()
            let yData = Data()
            let zData = Data()
            
            for i in stride(from: 0, through: data.count-1, by: 17) {
                
                let xlandmark = ""
                let ylandmark = ""
                let zlandmark = ""
                
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
        
        for i in 0..<21{
            
            let resultX = Double(xLandmarks[i]-xLandmarks[0])
            let resultY = Double(yLandmarks[i]-yLandmarks[0])
            let resultZ = Double(zLandmarks[i]-zLandmarks[0])
            
            inputList.append(Double(xLandmarks[i]))
            inputList.append(Double(xLandmarks[i]))
            inputList.append(Double(xLandmarks[i]))
            inputList.append(resultX)
            inputList.append(resultY)
            inputList.append(resultZ)
        }
        return inputList
        
    }
    //Put inputlist to Gesture AI Model and get result
    func getGesture(inputList: [Double]) -> Int{
        
        let model = GangstureHandModel()
        guard let gangstureHandModelOutput = try? model.prediction(inputList: inputList) else {
            fatalError("Unexpected runtime error.")
        }
        let signal = gangstureHandModelOutput.target
        return Int(signal)
        
    }
    //Convert bytes type to float type
    func bytesToFloat(bytes b: [UInt8]) -> Float {
        let littleEndianValue = b.withUnsafeBufferPointer {
            $0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0.pointee }
        }
        let bitPattern = UInt32(littleEndian: littleEndianValue)
        return Float(bitPattern: bitPattern)
    }
    
    //Obtain video frame and put it to global user interactive queue
    func telloStream(receive frame: Data?) {
        if let frame = frame {
            let packet = [UInt8](frame)
            streamBuffer.append(contentsOf: packet)
        }
    }
    
    //Send signal to drone through socket based on gesture
    func sendSignalToDrone(signal: Int){
        var signalLabel = ""
        let controlCount = 5 //threshold to signal a drone
        
        switch (signal){
            //Up
        case 0:
            signalLabel = "UP"
            upCount = upCount + 1
            print("Up")
            if signal == previousDirection && upCount > controlCount && droneControlActivateSwitch.isOn&&isSendControl{
                self.tello.up(by: 30)
                upCount = 0
            }
            //Down
        case 1:
            signalLabel = "Down"
            downCount = downCount + 1
            print("Down")
            if signal == previousDirection && downCount > controlCount && droneControlActivateSwitch.isOn && isSendControl{
                self.tello.down(by: 30)
                downCount = 0
            }
            //Left
        case 2:
            signalLabel = "Left"
            leftCount = leftCount + 1
            print("Left")
            if signal == previousDirection && leftCount > controlCount && droneControlActivateSwitch.isOn && isSendControl{
                self.tello.left(by: 30)
                leftCount = 0
            }
            //Right
        case 3:
            signalLabel = "Right"
            rightCount = rightCount + 1
            print("Right")
            if signal == previousDirection && rightCount > controlCount && droneControlActivateSwitch.isOn && isSendControl{
                self.tello.right(by: 30)
                rightCount = 0
            }
            //Go forward
        case 4:
            signalLabel = "Go forward"
            forwardCount = forwardCount + 1
            print("Go forward")
            if signal == previousDirection && forwardCount > controlCount && droneControlActivateSwitch.isOn && isSendControl{
                self.tello.forward(by: 30)
                forwardCount = 0
            }
            //Back
        case 5:
            signalLabel = "Back"
            print("Back")
            backwardCount = backwardCount + 1
            if signal == previousDirection && backwardCount > controlCount && droneControlActivateSwitch.isOn && isSendControl{
                self.tello.back(by: 30)
                backwardCount = 0
            }
            //Take off
        case 6:
            print("Take off")
            takeoffCount = takeoffCount + 1
            if signal == previousDirection && takeoffCount > 10 {
                isMoving = true
                takeoffCount = 0
            }
            
            if signal == previousDirection && takeoffCount > 10 && droneControlActivateSwitch.isOn && isSendControl{
                print("true")
                self.tello.takeoff()
                takeoffCount = 0
            }
            if isMoving {
                signalLabel = "Stop"
            }else {
                signalLabel = "Take off"
            }
            //Land
        case 7:
            signalLabel = "Land"
            print("Land")
            landCount = landCount + 1
            if signal == previousDirection && landCount > 15 && droneControlActivateSwitch.isOn && isSendControl{
                self.tello.land()
                landCount = 0
            }
            
        default :
            print("default")
        }
        
        previousDirection = Int(signal)
        
        DispatchQueue.main.async {
            //Show direction on screen
            self.directionLabel.text = signalLabel
        }
    }
}

//Delegate function related to UIImagePicker
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    @IBAction func photoButtonDidTap(_ sender: Any) {
        //Initiate picker
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.videoQuality = .typeIFrame1280x720
        self.present(picker, animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil);
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        /// Issue the info.plist that matches the bundle ID in Firebase, add it to the project, and unannotate the code
        /*
         picker.dismiss(animated: true, completion: nil)
         
         let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as! URL
         let videoPath = videoUrl.path
         print("videoURL: \(videoUrl)")
         print("videoPath: \(videoPath)")
         
         let data = NSData(contentsOf: videoUrl)!
         
         let now = Date()
         let formatter = DateFormatter()
         formatter.timeZone = TimeZone.current
         
         formatter.dateFormat = "MM-dd-yyyy HH:mm"
         let dateString = formatter.string(from: now)
         
         let filename = "video - " + dateString
         
         
         let metadata = StorageMetadata() //Get metadata of firebase
         metadata.contentType = "video/quicktime"
         let storageRef = storage.reference() //Get storage reference of the firebase storage
         
         let videoRef = storageRef.child("videos/\(filename)")
         
         videoRef.putData(data as Data, metadata: nil){ (metadata, error) in //Uploading to the firebase storage folder
         guard let metadata = metadata else {
         //If there is error in meta data, print "error"
         print("error \(error)")
         return
         }
         print("Put us complete and I got this back: \(String(describing: metadata))")
         // Metadata contains file metadata such as size, content-type.
         let size = metadata.size
         
         // Access to download URL after upload.
         videoRef.downloadURL { (url, error) in
         guard let downloadURL = url else {
         print("Got an generating the URL:)")
         // Uh-oh, an error occurred!
         return
         }
         }
         }
         */
    }
}

extension Collection {
    // Returns the element at the specified index if it is within bounds, otherwise nil
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

