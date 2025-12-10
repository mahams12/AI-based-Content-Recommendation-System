import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let audioDecoderChannel = FlutterMethodChannel(
      name: "com.example.ai_based_content_recommendation_system/audio_decoder",
      binaryMessenger: controller.binaryMessenger
    )
    
    audioDecoderChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "decodeAudioToPCM" {
        guard let args = call.arguments as? [String: Any],
              let audioPath = args["audioPath"] as? String,
              let sampleRate = args["sampleRate"] as? Int else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
          return
        }
        
        self.decodeAudioToPCM(audioPath: audioPath, targetSampleRate: sampleRate) { pcmSamples, error in
          if let error = error {
            result(FlutterError(code: "DECODE_ERROR", message: error.localizedDescription, details: nil))
          } else if let samples = pcmSamples {
            result(samples)
          } else {
            result(FlutterError(code: "UNKNOWN_ERROR", message: "Unknown error occurred", details: nil))
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func decodeAudioToPCM(
    audioPath: String,
    targetSampleRate: Int,
    completion: @escaping ([Double]?, Error?) -> Void
  ) {
    let url = URL(fileURLWithPath: audioPath)
    
    guard FileManager.default.fileExists(atPath: audioPath) else {
      completion(nil, NSError(domain: "AudioDecoder", code: -1, userInfo: [NSLocalizedDescriptionKey: "File not found"]))
      return
    }
    
    let asset = AVAsset(url: url)
    
    guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
      completion(nil, NSError(domain: "AudioDecoder", code: -2, userInfo: [NSLocalizedDescriptionKey: "No audio track found"]))
      return
    }
    
    // Get original sample rate
    let originalFormat = audioTrack.formatDescriptions.first as! CMFormatDescription
    let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(originalFormat)!.pointee
    let originalSampleRate = Int(asbd.mSampleRate)
    
    // Create output settings for AVAssetReader
    let outputSettings: [String: Any] = [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsBigEndianKey: false,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsNonInterleaved: false,
      AVSampleRateKey: targetSampleRate,
      AVNumberOfChannelsKey: 1, // Mono
    ]
    
    // Create asset reader
    var assetReader: AVAssetReader?
    do {
      assetReader = try AVAssetReader(asset: asset)
    } catch {
      completion(nil, error)
      return
    }
    
    guard let reader = assetReader else {
      completion(nil, NSError(domain: "AudioDecoder", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create asset reader"]))
      return
    }
    
    // Create audio output
    let audioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
    reader.add(audioOutput)
    
    // Start reading
    guard reader.startReading() else {
      completion(nil, reader.error ?? NSError(domain: "AudioDecoder", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to start reading"]))
      return
    }
    
    // Read samples
    var pcmSamples: [Double] = []
    
    while reader.status == .reading {
      if let sampleBuffer = audioOutput.copyNextSampleBuffer() {
        if let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
          var length = 0
          var dataPointer: UnsafeMutablePointer<Int8>?
          
          let status = CMBlockBufferGetDataPointer(
            dataBuffer,
            atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &length,
            dataPointerOut: &dataPointer
          )
          
          if status == noErr, let pointer = dataPointer {
            let samples = UnsafeRawPointer(pointer).assumingMemoryBound(to: Int16.self)
            let sampleCount = length / MemoryLayout<Int16>.size
            
            for i in 0..<sampleCount {
              let sample = samples[i]
              pcmSamples.append(Double(sample) / 32768.0)
            }
          }
          
          CMSampleBufferInvalidate(sampleBuffer)
        }
      } else {
        break
      }
    }
    
    // Resample if needed (simple linear resampling)
    let finalSamples: [Double]
    if originalSampleRate != targetSampleRate && pcmSamples.count > 0 {
      finalSamples = resample(samples: pcmSamples, fromRate: originalSampleRate, toRate: targetSampleRate)
    } else {
      finalSamples = pcmSamples
    }
    
    completion(finalSamples, nil)
  }
  
  private func resample(samples: [Double], fromRate: Int, toRate: Int) -> [Double] {
    if fromRate == toRate || samples.isEmpty {
      return samples
    }
    
    let ratio = Double(fromRate) / Double(toRate)
    var resampled: [Double] = []
    let targetCount = Int(Double(samples.count) / ratio)
    
    for i in 0..<targetCount {
      let srcIndex = Int(Double(i) * ratio)
      if srcIndex < samples.count {
        resampled.append(samples[srcIndex])
      }
    }
    
    return resampled
  }
}
