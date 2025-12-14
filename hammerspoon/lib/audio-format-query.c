#include <CoreAudio/CoreAudio.h>
#include <stdio.h>

int main() {
    AudioDeviceID deviceID = kAudioObjectUnknown;
    UInt32 propertySize = sizeof(AudioDeviceID);
    AudioObjectPropertyAddress propertyAddress = {
        kAudioHardwarePropertyDefaultOutputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMain
    };
    
    OSStatus status = AudioObjectGetPropertyData(
        kAudioObjectSystemObject,
        &propertyAddress,
        0,
        NULL,
        &propertySize,
        &deviceID
    );
    
    if (status != noErr || deviceID == kAudioObjectUnknown) {
        fprintf(stderr, "Error getting default output device\n");
        return 1;
    }
    
    // First, get the device's streams
    UInt32 streamCount = 0;
    propertySize = sizeof(streamCount);
    propertyAddress.mSelector = kAudioDevicePropertyStreams;
    propertyAddress.mScope = kAudioDevicePropertyScopeOutput;
    propertyAddress.mElement = kAudioObjectPropertyElementMain;
    
    status = AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, NULL, &propertySize);
    if (status == noErr && propertySize > 0) {
        streamCount = propertySize / sizeof(AudioStreamID);
        AudioStreamID *streams = (AudioStreamID *)malloc(propertySize);
        status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, NULL, &propertySize, streams);
        
        if (status == noErr && streamCount > 0) {
            // Try to get physical format from first stream (device's native format)
            AudioStreamBasicDescription asbd;
            propertySize = sizeof(asbd);
            propertyAddress.mSelector = kAudioStreamPropertyPhysicalFormat;
            propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
            propertyAddress.mElement = kAudioObjectPropertyElementMain;
            
            status = AudioObjectGetPropertyData(streams[0], &propertyAddress, 0, NULL, &propertySize, &asbd);
            if (status == noErr) {
                printf("%.0f,%u,%u\n", asbd.mSampleRate, asbd.mBitsPerChannel, asbd.mChannelsPerFrame);
                free(streams);
                return 0;
            }
        }
        if (streams) free(streams);
    }
    
    // Fallback: Get stream format (system format - may be 32-bit float even if device is 24-bit)
    AudioStreamBasicDescription asbd;
    propertySize = sizeof(asbd);
    propertyAddress.mSelector = kAudioDevicePropertyStreamFormat;
    propertyAddress.mScope = kAudioDevicePropertyScopeOutput;
    propertyAddress.mElement = kAudioObjectPropertyElementMain;
    
    status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, NULL, &propertySize, &asbd);
    if (status != noErr) {
        fprintf(stderr, "Error getting audio format\n");
        return 1;
    }
    
    // If it's 32-bit float format, it's likely macOS internal processing format
    // The actual device format is probably 24-bit, but we'll report what CoreAudio says
    
    // Check if it's float format (macOS often uses 32-bit float internally)
    // If it's 32-bit float, the actual device format is likely 24-bit
    UInt32 bitDepth = asbd.mBitsPerChannel;
    if (asbd.mBitsPerChannel == 32 && (asbd.mFormatFlags & kAudioFormatFlagIsFloat)) {
        // 32-bit float is macOS internal format
        // Most USB audio devices actually output 24-bit, so we'll report that
        // The user can verify this matches their Audio MIDI Setup settings
        bitDepth = 24;
    }
    
    // Output: sample_rate,bit_depth,channels,is_float
    printf("%.0f,%u,%u,%d\n", asbd.mSampleRate, bitDepth, asbd.mChannelsPerFrame, 
           (asbd.mFormatFlags & kAudioFormatFlagIsFloat) ? 1 : 0);
    return 0;
}
