import Foundation
import VideoToolbox
import AVFoundation

public typealias NALUnit = Array<UInt8>

//Convert drone video format to iOS video format,H264
public class TelloVideoH264Decoder {
    
    let startCode: NALUnit = [0, 0, 0, 1]
    
    var formatDesc: CMVideoFormatDescription?
    var vtdSession: VTDecompressionSession?
    
    var sps: NALUnit?
    var pps: NALUnit?
    
    var stop = true
    
    
    // Decode a stream buffer which contains H264 raw bytes, enqueue the CMSampleBuffer to AVSampleBufferDisplayLayer and call setNeedsDisplay
    public func renderVideoStream(streamBuffer: inout Array<UInt8>, to videoLayer: AVSampleBufferDisplayLayer) {
        stop = false
        while let nalu = readNalUnits(streamBuffer: &streamBuffer) {
            guard !stop else { break }
            
            if let sampleBuffer = getCMSampleBuffer(from: nalu) {
                let attachments:CFArray? = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true)
                if let attachmentArray = attachments {
                    let dic = unsafeBitCast(CFArrayGetValueAtIndex(attachmentArray, 0), to: CFMutableDictionary.self)
                    
                    CFDictionarySetValue(dic,
                                         Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                                         Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
                }
                videoLayer.enqueue(sampleBuffer)
                
                DispatchQueue.main.async { videoLayer.needsDisplay() }
            }
        }
    }
    
    // Stop consuming stream buffer and clean up decoding resources
    public func stopProcessing() {
        stop = true
        cleanUp()
    }
    
    public func decompress(sampleBuffer: CMSampleBuffer, outputHandler: @escaping VTDecompressionOutputHandler) -> OSStatus {
        guard let session = vtdSession else { return -1 }
        return VTDecompressionSessionDecodeFrame(session, sampleBuffer: sampleBuffer, flags: [._EnableAsynchronousDecompression, ._EnableTemporalProcessing], infoFlagsOut: nil, outputHandler: outputHandler)
    }
    
    // Create a CMSampleBuffer from a NAL unit.
    public func getCMSampleBuffer(from nalu: NALUnit) -> CMSampleBuffer? {
        guard nalu.count > 4 else { return nil }
        
        var mNalu = nalu
        let naluType = nalu[4] & 0x1f
        
        var sampleBuffer: CMSampleBuffer?
        switch naluType {
        case 0x05:
            guard initialize(SPS: sps, PPS: pps) else { break }
            sampleBuffer = decodeToCMSampleBuffer(frame: &mNalu)
        case 0x07:
            sps = NALUnit(nalu[4...])
        case 0x08:
            pps = NALUnit(nalu[4...])
        default:
            sampleBuffer = decodeToCMSampleBuffer(frame:&mNalu)
        }
        return sampleBuffer
    }
    
    
    // Get as many as possible NALU units from stream, incomplete unit will be dropped
    public func getNalUnits(streamBuffer: Array<UInt8>) -> NALUnit? {
        guard streamBuffer.count != 0 else { return nil }
        //Make sure start with start code
        if streamBuffer.count < 5 || streamBuffer[0...3] != startCode[...] {
            return nil
        }
        var nalUnits = Array<UInt8>()
        //Find second start code, so startIndex = 4
        var startIndex = 4
        while ((startIndex + 3) < streamBuffer.count) {
            if Array(streamBuffer[startIndex...startIndex+3]) == startCode {
                let units = Array(streamBuffer[0..<startIndex])
                nalUnits.append(contentsOf: units)
            }
            startIndex += 1
        }
        
        return nalUnits
    }
    // Read NAL Units from an inout streamBuffer
    public func readNalUnits(streamBuffer:inout Array<UInt8>) -> NALUnit? {
        guard streamBuffer.count != 0 else { return nil }
        if streamBuffer.count < 5 || streamBuffer[0...3] != startCode[...] {
            return nil
        }
        var startIndex = 4
        while true {
            guard !stop else { return nil }
            while ((startIndex + 3) < streamBuffer.count) {
                if Array(streamBuffer[startIndex...startIndex+3]) == startCode {
                    let units = Array(streamBuffer[0..<startIndex])
                    streamBuffer.removeSubrange(0..<startIndex)
                    return units
                }
                startIndex += 1
            }
            if streamBuffer.count == 0 {
                return nil
            }
        }
    }
    // Free all decoder resources
    public func cleanUp() {
        if let session = vtdSession {
            VTDecompressionSessionInvalidate(session)
            vtdSession = nil
        }
        formatDesc = nil
        sps = nil
        pps = nil
    }
    
    func decodeToCMSampleBuffer(frame: inout NALUnit) -> CMSampleBuffer? {
        guard vtdSession != nil else { return nil }
        var bigLen = CFSwapInt32HostToBig(UInt32(frame.count - 4))
        memcpy(&frame, &bigLen, 4)
        var blockBuffer: CMBlockBuffer?
        var status = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault, memoryBlock: &frame, blockLength: frame.count, blockAllocator: kCFAllocatorNull, customBlockSource: nil, offsetToData: 0, dataLength: frame.count, flags: 0, blockBufferOut: &blockBuffer)
        
        guard status == kCMBlockBufferNoErr else { return nil }
        
        var sampleBuffer: CMSampleBuffer?
        let sampleSizeArray = [frame.count]
        status = CMSampleBufferCreateReady(allocator: kCFAllocatorDefault, dataBuffer: blockBuffer, formatDescription: formatDesc, sampleCount: 1, sampleTimingEntryCount: 0, sampleTimingArray: nil, sampleSizeEntryCount: sampleSizeArray.count, sampleSizeArray: sampleSizeArray, sampleBufferOut: &sampleBuffer)
        
        guard status == noErr else { return nil }
        return sampleBuffer
    }
    
    func initialize(SPS: NALUnit?, PPS: NALUnit?) -> Bool {
        guard let SPS = SPS, let PPS = PPS else { return false }
        guard createH264FormatDescription(SPS: SPS, PPS: PPS) == noErr else { return false }
        guard createVTDecompressionSession() == noErr else { return false }
        return true
    }
    
    func createH264FormatDescription(SPS sps: Array<UInt8>, PPS pps: Array<UInt8>) -> OSStatus {
        if formatDesc != nil { formatDesc = nil }
        
        let status = sps.withUnsafeBufferPointer { spsBP -> OSStatus in //<- Specify return type explicitly.
            pps.withUnsafeBufferPointer { ppsBP in
                let paramSet = [spsBP.baseAddress!, ppsBP.baseAddress!]
                let paramSizes = [spsBP.count, ppsBP.count]
                return paramSet.withUnsafeBufferPointer { paramSetBP in
                    paramSizes.withUnsafeBufferPointer { paramSizesBP in
                        CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: kCFAllocatorDefault, parameterSetCount: 2, parameterSetPointers: paramSetBP.baseAddress!, parameterSetSizes: paramSizesBP.baseAddress!, nalUnitHeaderLength: 4, formatDescriptionOut: &formatDesc)
                    }
                }
            }
        }
        
        return status
    }
    
    func createVTDecompressionSession() -> OSStatus {
        guard formatDesc != nil else { return -1 }
        
        if let session = vtdSession {
            let accept = VTDecompressionSessionCanAcceptFormatDescription(session, formatDescription: formatDesc!)
            guard !accept else { return 0 }
            // If current session cannot aceept the format, invalidate and create a new one
            VTDecompressionSessionInvalidate(session)
            vtdSession = nil
        }
        
        var decoderParameters: [String: CFBoolean]?
#if os(macOS)
        decoderParameters = [String: CFBoolean]()
        decoderParameters!.updateValue(kCFBooleanTrue, forKey: kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder as String)
#endif
        
        var destPBAttributes = [String: UInt32]()
        destPBAttributes.updateValue(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, forKey: kCVPixelBufferPixelFormatTypeKey as String)
        let status = VTDecompressionSessionCreate(allocator: kCFAllocatorDefault, formatDescription: formatDesc!, decoderSpecification: decoderParameters as CFDictionary?, imageBufferAttributes: destPBAttributes as CFDictionary, outputCallback: nil, decompressionSessionOut: &vtdSession)
        return status
    }
}

func decodeFrameCallback(_ decompressionOutputRefCon: UnsafeMutableRawPointer?, _ sourceFrameRefCon: UnsafeMutableRawPointer?, _ status: OSStatus, _ infoFlags: VTDecodeInfoFlags, _ imageBuffer: CVImageBuffer?, _ presentationTimeStamp: CMTime, _ presentationDuration: CMTime) -> Void {
}

