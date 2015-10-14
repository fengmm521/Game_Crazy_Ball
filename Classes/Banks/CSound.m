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
// CSOUND : un echantillon
//
//----------------------------------------------------------------------------------
#import "CSound.h"
#import "CFile.h"
#import "CSoundPlayer.h"
#import "CALPlayer.h"

@implementation CSound

-(id)initWithSoundPlayer:(CSoundPlayer*)p andALPlayer:(CALPlayer*)alp
{
	soundPlayer=p;
    ALPlayer=alp;
    bufferID=0;
	pauseTime = 0;
	gamePaused = NO;
	return self;
}
-(void)dealloc
{
	if (AVPlayer!=nil)
	{
		AVPlayer.delegate=nil;
	}
	if (bPlaying)
	{
		[AVPlayer stop];
	}
	if (AVPlayer!=nil)
	{
		[AVPlayer release];
	}
    if (bufferID!=0)
    {
		[ALPlayer stop:nSound];
        alDeleteBuffers(1, &bufferID);
    }
	[name release];
	[super dealloc];
}
-(void)load:(CFile*)f flags:(short)flags
{
	file=f;
	handle=[file readAShort];
    
    
    short lName=[file readAShort];
    name=[file readAStringWithSize:lName];
    duration=[file readAInt];
    pointer=[file getFilePointer];
    int size=[file readAInt];
	NSData* subData=[file getSubData:size];

    bAudioPlayer=NO;
    if ((flags&(PSOUNDFLAG_IPHONE_AUDIOPLAYER|PSOUNDFLAG_IPHONE_OPENAL))==0)
    {
        if (duration>=15*1000)
        {
            bAudioPlayer=YES;
        }
    }
    else if (flags&PSOUNDFLAG_IPHONE_AUDIOPLAYER)
    {
        bAudioPlayer=YES;
    }
    if (bAudioPlayer)
    {
        NSError* error;
        AVPlayer=[[AVAudioPlayer alloc] initWithData:subData error:&error];
    }
    else
    {
        ALvoid* ALOutData;
        ALenum ALFormat;
        ALsizei ALSize;
        ALsizei ALFreq;
        
        ALOutData=GetOpenALAudioData(subData, &ALSize, &ALFormat, &ALFreq);
        
        if (ALOutData)
        {
            alGenBuffers(1, &bufferID);
            alBufferData(bufferID, ALFormat, ALOutData, ALSize, ALFreq);
            free(ALOutData);
        }
    }
}
-(void)cleanMemory
{
	if (bPlaying==NO)
	{
		if (AVPlayer!=nil)
		{
			AVPlayer.delegate=nil;
			[AVPlayer release];
			AVPlayer=nil;
		}
        if (bufferID!=0)
        {
            alDeleteBuffers(1, &bufferID);
            bufferID=0;
        }
	}
}
-(void)play:(int)nLoops channel:(int)channel
{
    if (bAudioPlayer)
    {
        if (AVPlayer==nil)
        {
            [file seek:pointer];
            int size=[file readAInt];
            NSError* error;
            NSData* subData=[file getSubData:size];
            AVPlayer=[[AVAudioPlayer alloc] initWithData:subData error:&error];	
        }
        if (AVPlayer!=nil)
        {
            if (nLoops>=0) nLoops--;
            AVPlayer.numberOfLoops=nLoops;
            AVPlayer.delegate=self;
            bPlaying=YES;
            AVPlayer.currentTime=0;
            [AVPlayer play];
        }
    }
    else
    {
        if (bufferID==0)
        {
            ALvoid* ALOutData;
            ALenum ALFormat;
            ALsizei ALSize;
            ALsizei ALFreq;
            
            [file seek:pointer];
            int size=[file readAInt];
            NSData* subData=[file getSubData:size];
            ALOutData=GetOpenALAudioData(subData, &ALSize, &ALFormat, &ALFreq);
            
            if (ALOutData)
            {
                alGenBuffers(1, &bufferID);
                alBufferData(bufferID, ALFormat, ALOutData, ALSize, ALFreq);
                free(ALOutData);
            }            
        }
        nSound=[ALPlayer play:self loops:nLoops channel:channel];
        bPlaying=YES;
    }
}
-(void)pause:(BOOL)gamePause
{
	if(!bPaused)
		gamePaused = gamePause;
	if (bPlaying)
	{
		//The sample is uninterruptible so a game-pause does not pause it. Only a manual pause can do that.
		if(gamePause && bUninterruptible)
			return;

        if (bAudioPlayer)
        {
			pauseTime = AVPlayer.currentTime;
            [AVPlayer stop];
        }
        else
        {
            [ALPlayer pause:nSound];
        }
		bPaused=YES;
	}
}
-(BOOL)isPaused
{
	return bPaused;
}


-(void)resume:(BOOL)gameResume
{
	//Do not resume audio on game-resume that wasn't paused by a game-pause.
	if(gameResume==YES && gamePaused==NO)
		return;
	
	if (bPaused)
	{
		bPaused=NO;
		gamePaused = NO;
        if (bAudioPlayer)
        {
			[AVPlayer prepareToPlay];
			AVPlayer.currentTime = pauseTime;
            [AVPlayer play];
        }
        else
        {
            [ALPlayer resume:nSound];
        }
	}
	
}
-(void)stop
{
    if (bAudioPlayer)
    {
        if (AVPlayer!=nil)
        {
            AVPlayer.delegate=nil;
        }
        if (bPlaying)
        {
            [AVPlayer stop];
        }
	}
    else
    {
        [ALPlayer stop:nSound];
    }
    bPlaying=NO;
}
-(void)setVolume:(int)v
{
    volume=v;
    if (bAudioPlayer)
    {
        AVPlayer.volume=(double)v/100.0;
    }
    else
    {
        [ALPlayer setVolume:nSound volume:(float)(v/100.0)];
    }
}
-(int)getVolume
{
	return (int)volume;
}
-(void)setPosition:(int)p
{
    if (bAudioPlayer)
    {
        AVPlayer.currentTime=((double)p)/1000.0;
    }
    else
    {
        if (p==0)
        {
            [ALPlayer rewind:nSound];
        }
    }
}
-(void)setPitch:(float)p
{
    if (bAudioPlayer==NO)
    {
        [ALPlayer setPitch:nSound pitch:p];
    }
}
-(int)getPosition
{
    if (bAudioPlayer)
    {
        return (int)(AVPlayer.currentTime*1000.0);
    }
	else
	{
		return [ALPlayer getPosition:nSound];
	}
    return 0;
}
-(int)getDuration
{
	return duration;
}
-(void)checkPlaying
{
    if (bAudioPlayer==NO)
    {
        bPlaying=[ALPlayer checkPlaying:nSound];
        if (bPlaying==NO && bPaused==NO)
        {
            [soundPlayer removeSound:self];
        }
    }
}
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	bPlaying=NO;
	[soundPlayer removeSound:self];
}
-(void)audioPlayerBeginInterruption:(AVAudioPlayer*)player
{	
}
-(void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
}
-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer*)player error:(NSError*)error
{
}

@end
