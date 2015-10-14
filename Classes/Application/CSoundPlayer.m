/* Copyright (c) 1996-2014 Clickteam
*
* This source code is part of the iOS exporter for Clickteam Multimedia Fusion 2
* and Clickteam Fusion 2.5.
* 
* Permission is hereby granted to any person obtaining a legal copy 
* of Clickteam Multimedia Fusion 2 or Clickteam Fusion 2.5 to use or modify this source 
* code for debugging, optimizing, or customizing applications created with 
* Clickteam Multimedia Fusion 2 and/or Clickteam Fusion 2.5. 
* Any other use of this source code is prohibited.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
* IN THE SOFTWARE.
*/
//----------------------------------------------------------------------------------
//
// CSOUNDPLAYER : synthetiseur MIDI
//
//----------------------------------------------------------------------------------
#import "CSoundPlayer.h"
#import "CRunApp.h"
#import "CSound.h"
#import "CSoundBank.h"
#import <AudioToolbox/AudioToolbox.h>
#import "CALPlayer.h"
#import <AVFoundation/AVFoundation.h>

@implementation CSoundPlayer

-(void)audioSessionInterrupted:(NSNotification*)notification
{
	NSDictionary* interruptionDictionary = [notification userInfo];
	NSNumber* interruptionType = (NSNumber *)[interruptionDictionary valueForKey:AVAudioSessionInterruptionTypeKey];
	if ([interruptionType integerValue] == AVAudioSessionInterruptionTypeBegan)
	{
		[runApp->ALPlayer beginInterruption];
	}
	else if ([interruptionType integerValue] == AVAudioSessionInterruptionTypeEnded)
	{
		[runApp->ALPlayer endInterruption];
	}
}

-(id)initWithApp:(CRunApp*)app
{
	if(self = [super init])
	{
		runApp=app;
		parentPlayer=nil;
		channels = (CSound**)calloc(NCHANNELS, sizeof(CSound*));
		volumes=(int*)calloc(NCHANNELS, sizeof(int));
		frequencies = (int*)calloc(NCHANNELS, sizeof(int));
		bLocked=(BOOL*)calloc(NCHANNELS, sizeof(BOOL));

		bOn=YES;
		bMultipleSounds=YES;

		int n;
		for (n=0; n<NCHANNELS; n++)
		{
			volumes[n]=100;
			bLocked[n]=NO;
		}
		mainVolume=100;

		AVAudioSession* audioSession = [AVAudioSession sharedInstance];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(audioSessionInterrupted:)
													 name:AVAudioSessionInterruptionNotification
												   object:audioSession];
		[audioSession setCategory:AVAudioSessionCategorySoloAmbient error:nil];
		[audioSession setActive:YES error:nil];
	}
    return self;
}

-(id)initWithApp:(CRunApp*)app andSoundPlayer:(CSoundPlayer*)player
{
	if(self = [super init])
	{
		runApp=app;
		parentPlayer = player;
		channels = (CSound**)calloc(NCHANNELS, sizeof(CSound*));
		volumes=(int*)calloc(NCHANNELS, sizeof(int));
		frequencies = (int*)calloc(NCHANNELS, sizeof(int));
		bLocked=(BOOL*)calloc(NCHANNELS, sizeof(BOOL));

		bOn=YES;
		bMultipleSounds=YES;

		int n;
		for (n=0; n<NCHANNELS; n++)
		{
			volumes[n]=100;
			bLocked[n]=NO;
		}
		mainVolume=100;
	}
    return self;
}

-(void)dealloc
{
	free(channels);
	free(volumes);
	free(frequencies);
	free(bLocked);
	[super dealloc];
}

-(void)reset
{
	int n;
	for (n=0; n<NCHANNELS; n++)
	{
//		volumes[n]=100;
		bLocked[n]=NO;
	}
//	mainVolume=100;
}

-(void)play:(short)handle withNLoops:(int)nLoops andChannel:(int)channel andPrio:(BOOL)bPrio
{
	int n;
	
	if (bOn == NO)
	{
		return;
	}
	
	CSound* sound = [runApp->soundBank getSoundFromHandle:handle];
	if (sound == nil)
	{
		return;
	}
	if (bMultipleSounds == NO)
	{
		channel = 0;
	}
	
	// Recherche un canal avec le son
	for (n = 0; n < NCHANNELS; n++)
	{
		if (channels[n] == sound)
		{
			if (channels[n]->bUninterruptible == NO)
			{
				[sound stop];
				channels[n]->bUninterruptible=NO;
				channels[n] = nil;
				break;
			}
			else
			{
 				return;
			}
		}
	}
	
	// Lance le son
	if (channel < 0)
	{
		for (n = 0; n < NCHANNELS; n++)
		{
			if (channels[n] == nil && bLocked[n]==NO)
			{
				break;
			}
		}
		if (n == NCHANNELS)
		{
			// Stoppe le son sur un canal deja en route
			for (n = 0; n < NCHANNELS; n++)
			{
				if (bLocked[n]==NO)
				{
					if (channels[n] != nil)
					{
						if (channels[n]->bUninterruptible == NO)
						{
							[channels[n] stop];
							channels[n] = nil;
						}
					}
				}
			}
		}
		channel = n;
		if (channel>=0 && channel< NCHANNELS)
		{
			volumes[channel]=mainVolume;
		}
	}
	if (channel < 0 || channel >= NCHANNELS)
	{
		return;
	}
	if (channels[channel] != nil)
	{
		if (channels[channel]->bUninterruptible == NO)
		{
			[channels[channel] stop];
		}
		else
		{
			return;
		}
	}
	channels[channel] = sound;
	sound->bUninterruptible=bPrio;
	[sound play:nLoops channel:channel];
	[sound setVolume:volumes[channel]];
}

-(void)setMultipleSounds:(BOOL)bMultiple
{
	bMultipleSounds = bMultiple;
}

-(void)keepCurrentSounds
{
	for (int n = 0; n < NCHANNELS; n++)
	{
		if (channels[n] != nil)
		{
			if (channels[n]->bPlaying)
			{
				[runApp->soundBank setToLoad:channels[n]->handle];
			}
		}
	}
}

-(void)setOnOff:(BOOL)bState
{
	if (bState != bOn)
	{
		bOn = bState;
		if (bOn == NO)
		{
			[self stopAllSounds];
		}
	}
}

-(BOOL)getOnOff
{
	return bOn;
}

-(void)stopAllSounds
{
	for (int n = 0; n < NCHANNELS; n++)
	{
		if (channels[n] != nil)
		{
			[channels[n] stop];
			channels[n]->bUninterruptible=NO;
			channels[n]=nil;
		}
	}
}

-(void)stopSample:(short)handle
{
	for (int c = 0; c < NCHANNELS; c++)
	{
		if (channels[c] != nil)
		{
			if (channels[c]->handle == handle)
			{
				[channels[c] stop];
				channels[c]->bUninterruptible=NO;
				channels[c] = nil;
			}
		}
	}
}

-(BOOL)isSamplePaused:(short)handle
{
	for (int c = 0; c < NCHANNELS; c++)
	{
		if (channels[c] != nil)
		{
			if (channels[c]->handle == handle)
			{
				return [channels[c] isPaused];
			}
		}
	}
	return NO;
}

-(BOOL)isSoundPlaying
{
	for (int n = 0; n < NCHANNELS; n++)
	{
		if (channels[n] != nil)
		{
			if (channels[n]->bPlaying)
			{
				return YES;
			}
		}
	}
	return NO;
}

-(BOOL)isSamplePlaying:(short)handle
{
	for (int n = 0; n < NCHANNELS; n++)
	{
		if (channels[n] != nil)
		{
			if (channels[n]->handle == handle)
			{
				if (channels[n]->bPlaying)
				{
					return YES;
				}
			}
		}
	}
	return NO;
}

-(BOOL)isChannelPlaying:(int)channel
{
	if (channel > 0 && channel < NCHANNELS)
	{
		if (channels[channel] != nil)
		{
			if (channels[channel]->bPlaying)
			{
				return YES;
			}
		}
	}
	return NO;
}

-(BOOL)isChannelPaused:(int)channel
{
	if (channel > 0 && channel < NCHANNELS)
	{
		if (channels[channel] != nil)
		{
			return [channels[channel] isPaused];
		}
	}
	return NO;
}

-(void)setPositionSample:(short)handle withPosition:(int)pos
{
	for (int n = 0; n < NCHANNELS; n++)
	{
		if (channels[n] != nil)
		{
			if (channels[n]->handle == handle)
			{
				[channels[n] setPosition:pos];
			}
		}
	}
}

-(int)getPositionSample:(short)handle
{
	for (int n = 0; n < NCHANNELS; n++)
	{
		if (channels[n] != nil)
		{
			if (channels[n]->handle == handle)
			{
				return [channels[n] getPosition];
			}
		}
	}
	return 0;
}

-(void)pauseSample:(short)handle
{
	for (int n = 0; n < NCHANNELS; n++)
	{
		if (channels[n] != nil)
		{
			if (channels[n]->handle == handle)
			{
				[channels[n] pause:NO];
			}
		}
	}
}

-(void)resumeSample:(short)handle
{
	for (int n = 0; n < NCHANNELS; n++)
	{
		if (channels[n] != nil)
		{
			if (channels[n]->handle == handle)
			{
				[channels[n] resume:NO];
			}
		}
	}
}

-(void)pause:(BOOL)gamePause
{
	for (int n = 0; n < NCHANNELS; n++)
	{
		if (channels[n] != nil)
		{
			[channels[n] pause:gamePause];
		}
	}
}

-(void)resume:(BOOL)gameResume
{
	for (int n = 0; n < NCHANNELS; n++)
	{
		if (channels[n] != nil)
		{
			[channels[n] resume:gameResume];
		}
	}
}

-(void)pauseChannel:(int)channel
{
	if (channel >= 0 && channel < NCHANNELS)
	{
		if (channels[channel] != nil)
		{
			[channels[channel] pause:NO];
		}
	}
}

-(void)stopChannel:(int)channel
{
	if (channel >= 0 && channel < NCHANNELS)
	{
		if (channels[channel] != nil)
		{
			[channels[channel] stop];
			channels[channel]->bUninterruptible=NO;
			channels[channel] = nil;
		}
	}
}

-(void)resumeChannel:(int)channel
{
	if (channel >= 0 && channel < NCHANNELS)
	{
		if (channels[channel] != nil)
		{
			[channels[channel] resume:NO];
		}
	}
}

-(void)setPositionChannel:(int)channel withPosition:(int)pos
{
	if (channel >= 0 && channel < NCHANNELS)
	{
		if (channels[channel] != nil)
		{
			[channels[channel] setPosition:pos];
		}
	}
}

-(int)getPositionChannel:(int)channel
{
	if (channel >= 0 && channel < NCHANNELS)
	{
		if (channels[channel] != nil)
		{
			return [channels[channel] getPosition];
		}
	}
	return 0;
}

-(void)setVolumeSample:(short)handle withVolume:(int)v
{
	if (v<0) v=0;
	if (v>100) v=100;
	int n;
	for (n = 0; n < NCHANNELS; n++)
	{
		if (channels[n] != nil)
		{
			if (channels[n]->handle == handle)
			{
				volumes[n]=v;
				[channels[n] setVolume:v];
			}
		}
	}
}

-(void)setFreqSample:(short)handle withFreq:(int)v
{
	if (v<0) v=0;
	if (v>100000) v=100000;
    if (v==0)
    {
        v=42000;
    }

	int n;
	for (n = 0; n < NCHANNELS; n++)
	{
		if (channels[n] != nil)
		{
			if (channels[n]->handle == handle)
			{
				frequencies[n]=v;
				[channels[n] setPitch:v/42000.0f];
			}
		}
	}
}

-(void)setVolumeChannel:(int)channel withVolume:(int)v
{
	if (v<0) v=0;
	if (v>100) v=100;

	if (channel >= 0 && channel < NCHANNELS)
	{
		volumes[channel]=v;
		if (channels[channel] != nil)
		{
			[channels[channel] setVolume:v];
		}
	}
}

-(void)setFreqChannel:(int)channel withFreq:(int)v
{
	if (v<0) v=0;
	if (v>100000) v=100000;
    if (v==0)
    {
        v=42000;
    }
    
	if (channel >= 0 && channel < NCHANNELS)
	{
		volumes[channel]=v;
		if (channels[channel] != nil)
		{
			frequencies[channel]=v;
			[channels[channel] setPitch:v/42000.0f];
		}
	}
}
-(int)getSampleFrequency:(NSString*)name
{
	int c=[self getChannel:name];
	if (c>=0)
	{
		return frequencies[c];
	}
	return 0;
}

-(int)getFrequencyChannel:(int)channel
{
	if (channel >= 0 && channel < NCHANNELS)
	{
		if (channels[channel] != nil)
		{
			return frequencies[channel];
		}
	}
	return 0;
}


-(int)getVolumeChannel:(int)channel
{
	if (channel >= 0 && channel < NCHANNELS)
	{
		if (channels[channel] != nil)
		{
			return volumes[channel];
		}
	}
	return 0;
}

-(int)getDurationChannel:(int)channel
{
	if (channel >= 0 && channel < NCHANNELS)
	{
		if (channels[channel] != nil)
		{
			return [channels[channel] getDuration];
		}
	}
	return 0;
}
-(void)setMainVolume:(int)v
{
 	if (v<0) v=0;
	if (v>100) v=100;

	mainVolume=v;
	int n;
	for (n=0; n<NCHANNELS; n++)
	{
		volumes[n]=v;
		if (channels[n]!=nil)
		{
			[channels[n] setVolume:v];
		}
	}
}
-(int)getMainVolume
{
	return mainVolume;
}

-(void)removeSound:(CSound*)s
{
	int n;
	for (n=0; n<NCHANNELS; n++)
	{
		if (channels[n]==s)
		{
			channels[n]->bUninterruptible=NO;
			channels[n]=nil;
		}
	}
}
-(void)checkPlaying
{
	int n;
	for (n = 0; n < NCHANNELS; n++)
	{
		if (channels[n] != nil)
		{
            [channels[n] checkPlaying];
		}
	}
}

-(void)lockChannel:(int)channel
{
	if (channel >= 0 && channel < NCHANNELS)
	{
		bLocked[channel]=YES;
	}
}

-(void)unLockChannel:(int)channel
{
	if (channel >= 0 && channel < NCHANNELS)
	{
		bLocked[channel]=NO;
	}
}

-(int)getChannel:(NSString*)name
{
	int c;
	for (c = 0; c < NCHANNELS; c++)
	{
		if (channels[c] != nil)
		{
			if ([channels[c]->name compare:name]==0)
			{
				return c;
			}
		}
	}
	return -1;
}
-(int)getSamplePosition:(NSString*)name
{
	int c=[self getChannel:name];
	if (c>=0)
	{
		return [channels[c] getPosition];
	}
	return 0;
}
-(int)getSampleVolume:(NSString*)name
{
	int c=[self getChannel:name];
	if (c>=0)
	{
		return [channels[c] getVolume];
	}
	return 0;
}
-(int)getSampleDuration:(NSString*)name
{
	int c=[self getChannel:name];
	if (c>=0)
	{
		return [channels[c] getDuration];
	}
	return 0;
}

@end
