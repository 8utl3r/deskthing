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
    
    // Get the stream format (actual output format)
    AudioStreamBasicDescription asbd;
    propertySize = sizeof(asbd);
    propertyAddress.mSelector = kAudioDevicePropertyStreamFormat;
    propertyAddress.mScope = kAudioDevicePropertyScopeOutput;
    propertyAddress.mElement = kAudioObjectPropertyElementMain;
    
    status = AudioObjectGetPropertyData(
        deviceID,
        &propertyAddress,
        0,
        NULL,
        &propertySize,
        &asbd
    );
    
    if (status != noErr) {
        fprintf(stderr, "Error getting stream format\n");
        return 1;
    }
    
    // Output: sample_rate,bit_depth,channels
    printf("%.0f,%u,%u\n", asbd.mSampleRate, asbd.mBitsPerChannel, asbd.mChannelsPerFrame);
    return 0;
}
