package com.example.ai_based_content_recommendation_system

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.ai_based_content_recommendation_system/audio_decoder"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Use the default FlutterActivity registration so that all plugins
        // (path_provider, permission_handler, record, etc.) are wired up.
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "decodeAudioToPCM" -> {
                    val audioPath = call.argument<String>("audioPath")
                    val sampleRate = call.argument<Int>("sampleRate") ?: 16000
                    
                    if (audioPath == null) {
                        result.error("INVALID_ARGUMENT", "Audio path is null", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        val pcmSamples = decodeAudioToPCM(audioPath, sampleRate)
                        result.success(pcmSamples)
                    } catch (e: Exception) {
                        result.error("DECODE_ERROR", "Failed to decode audio: ${e.message}", e.stackTraceToString())
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun decodeAudioToPCM(audioPath: String, targetSampleRate: Int): List<Double> {
        val extractor = MediaExtractor()
        var codec: MediaCodec? = null
        
        try {
            extractor.setDataSource(audioPath)
            
            // Find audio track
            var audioTrackIndex = -1
            var audioFormat: MediaFormat? = null
            
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                
                if (mime.startsWith("audio/")) {
                    audioTrackIndex = i
                    audioFormat = format
                    break
                }
            }
            
            if (audioTrackIndex == -1 || audioFormat == null) {
                throw Exception("No audio track found in file")
            }
            
            extractor.selectTrack(audioTrackIndex)
            
            // Get original sample rate
            val originalSampleRate = audioFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            val channelCount = audioFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
            
            // Create decoder
            val mime = audioFormat.getString(MediaFormat.KEY_MIME) ?: throw Exception("MIME type not found")
            codec = MediaCodec.createDecoderByType(mime)
            codec.configure(audioFormat, null, null, 0)
            codec.start()
            
            val pcmSamples = mutableListOf<Double>()
            val bufferInfo = MediaCodec.BufferInfo()
            var inputEOS = false
            var outputEOS = false
            
            while (!outputEOS) {
                // Feed input
                if (!inputEOS) {
                    val inputBufferIndex = codec.dequeueInputBuffer(10000)
                    if (inputBufferIndex >= 0) {
                        val inputBuffer = codec.getInputBuffer(inputBufferIndex)
                        val sampleSize = extractor.readSampleData(inputBuffer!!, 0)
                        
                        if (sampleSize < 0) {
                            codec.queueInputBuffer(inputBufferIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputEOS = true
                        } else {
                            val presentationTimeUs = extractor.sampleTime
                            codec.queueInputBuffer(inputBufferIndex, 0, sampleSize, presentationTimeUs, 0)
                            extractor.advance()
                        }
                    }
                }
                
                // Get output
                val outputBufferIndex = codec.dequeueOutputBuffer(bufferInfo, 10000)
                when (outputBufferIndex) {
                    MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        // Format changed, continue
                    }
                    MediaCodec.INFO_TRY_AGAIN_LATER -> {
                        // No output available, continue
                    }
                    else -> {
                        if (outputBufferIndex >= 0) {
                            val outputBuffer = codec.getOutputBuffer(outputBufferIndex)
                            if (outputBuffer != null && bufferInfo.size > 0) {
                                // Convert PCM bytes to doubles
                                val pcmBytes = ByteArray(bufferInfo.size)
                                outputBuffer.get(pcmBytes)
                                
                                // Convert 16-bit PCM to doubles (-1.0 to 1.0)
                                val samples = ByteBuffer.wrap(pcmBytes).order(ByteOrder.LITTLE_ENDIAN)
                                while (samples.remaining() >= 2) {
                                    val sample = samples.short.toDouble() / 32768.0
                                    pcmSamples.add(sample)
                                }
                            }
                            
                            codec.releaseOutputBuffer(outputBufferIndex, false)
                            
                            if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                                outputEOS = true
                            }
                        }
                    }
                }
            }
            
            // Resample if needed
            val finalSamples = if (originalSampleRate != targetSampleRate) {
                resample(pcmSamples, originalSampleRate, targetSampleRate)
            } else {
                pcmSamples
            }
            
            // Convert to mono if stereo
            val monoSamples = if (channelCount == 2) {
                convertToMono(finalSamples)
            } else {
                finalSamples
            }
            
            return monoSamples
            
        } finally {
            codec?.stop()
            codec?.release()
            extractor.release()
        }
    }
    
    private fun resample(samples: List<Double>, fromRate: Int, toRate: Int): List<Double> {
        if (fromRate == toRate) return samples
        
        val ratio = fromRate.toDouble() / toRate.toDouble()
        val resampled = mutableListOf<Double>()
        
        for (i in 0 until (samples.size / ratio).toInt()) {
            val srcIndex = (i * ratio).toInt()
            if (srcIndex < samples.size) {
                resampled.add(samples[srcIndex])
            }
        }
        
        return resampled
    }
    
    private fun convertToMono(stereoSamples: List<Double>): List<Double> {
        val mono = mutableListOf<Double>()
        for (i in 0 until stereoSamples.size step 2) {
            if (i + 1 < stereoSamples.size) {
                // Average left and right channels
                mono.add((stereoSamples[i] + stereoSamples[i + 1]) / 2.0)
            } else {
                mono.add(stereoSamples[i])
            }
        }
        return mono
    }
}
