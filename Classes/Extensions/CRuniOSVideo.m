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
// CRunVideo
//
//----------------------------------------------------------------------------------
#import "CRuniOSVideo.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CActExtension.h"
#import "CImageBank.h"
#import "CServices.h"
#import "CImage.h"
#import "CRunView.h"

#define CND_PLAYING 0
#define CND_STOPPED 1
#define CND_PAUSED 2
#define CND_AIRPLAYENABLED 3
#define CND_LAST 4

#define ACT_SETURL 0
#define ACT_INITIALPLAYBACK 1
#define ACT_ENDPLAYBACK 2
#define ACT_REPEAT 3
#define ACT_PLAY 4
#define ACT_VIDEOPAUSE 5
#define ACT_STOP 6
#define ACT_SETPLAYBACKTIME 7
#define ACT_BEGINSEEKFORWARD 8
#define ACT_BEGINSEEKBACKWARD 9
#define ACT_ENDSEEK 10


#define EXP_DURATION 0
#define EXP_STATE 1
#define EXP_PLAYABLEDURATION 2
#define EXP_PLAYBACKTIME 3

#define VFLAG_PLAYATSTART   0x0001
#define VFLAG_REPEAT        0x0002
#define VFLAG_FULLSCREEN    0x0004
#define VFLAG_ALLOWAIRPLAY  0x0008

@implementation CRuniOSVideo

-(int)getNumberOfConditions
{
	return CND_LAST;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    ho->hoImgWidth=[file readAInt];
    ho->hoImgHeight=[file readAInt];
    flags=[file readAInt];
    controls=[file readAShort];
    scaling=[file readAShort];
    url=[file readAString];
    initialPlayback=-1;
    endPlayback=-1;
    
    [self startVideo];
     
    return YES;
}

-(NSURL*)getURL:(NSString*)file
{
    NSURL* pUrl=nil;
    if ([file length]>7)
    {
        NSString* debut=[file substringToIndex:7];
        if ([debut caseInsensitiveCompare:@"http://"]==0)
        {
            pUrl=[NSURL URLWithString:file];
        }
    }
    if (pUrl==nil)
    {
        NSRange point=[file rangeOfString:@"."];
        if (point.location!=NSNotFound)
        {
            NSString* extension=[file substringFromIndex:point.location+1];
            file=[file substringToIndex:point.location];
			NSString* resourcePath = [[NSBundle mainBundle] pathForResource:file ofType:extension];
            if(resourcePath == nil){
				NSLog(@"The video file %@.%@ was not found", file, extension);
				return nil;
			}
			pUrl=[NSURL fileURLWithPath:resourcePath];
        }
    }
    return pUrl;
}
-(void)startVideo
{
    NSURL* pUrl=[self getURL:url];
    if (pUrl!=nil)
    {
        if (moviePlayer==nil)
        {
            moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:pUrl];
        
            [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:moviePlayer];
            [[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(resetTouches:)
														 name:MPMoviePlayerDidEnterFullscreenNotification
													   object:moviePlayer];
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(resetTouches:)
														 name:MPMoviePlayerDidExitFullscreenNotification
													   object:moviePlayer];	
			
    
            moviePlayer.controlStyle = controls;
            moviePlayer.scalingMode=scaling;
            if ((flags&VFLAG_REPEAT)!=0)
            {
                moviePlayer.repeatMode=MPMovieRepeatModeOne;
            }
            else
            {
                moviePlayer.repeatMode=MPMovieRepeatModeNone;
            }
            if (flags&VFLAG_PLAYATSTART)
            {
                moviePlayer.shouldAutoplay = YES;
            }
            else
            {
                moviePlayer.shouldAutoplay = NO;
            }
            if (initialPlayback!=-1)
            {
                moviePlayer.initialPlaybackTime=initialPlayback/1000.0;
            }
            if (endPlayback!=-1)
            {
                moviePlayer.endPlaybackTime=endPlayback/1000.0;
            }
            CGRect rect;
            if (flags&VFLAG_FULLSCREEN)
            {
                rect=CGRectMake(0, 0, rh->rhApp->gaCxWin, rh->rhApp->gaCyWin);
                [rh pause];
            }
            else
            {
                rect=CGRectMake(ho->hoX-rh->rhWindowX, ho->hoY-rh->rhWindowY, ho->hoImgWidth, ho->hoImgHeight);
            }
            [moviePlayer.view setFrame:rect];        
            [rh->rhApp->runView addSubview:moviePlayer.view];
            [moviePlayer setFullscreen:NO animated:YES];
            oldX=ho->hoX;
            oldY=ho->hoY;
        }
        else
        {
            moviePlayer.contentURL=pUrl;
        }
    }
}

-(void)endVideo
{
    if (moviePlayer!=nil)
    {
		[moviePlayer pause];
		[moviePlayer stop];
		[moviePlayer setFullscreen:NO animated:NO];
		[moviePlayer setControlStyle:MPMovieControlStyleNone];
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:MPMoviePlayerPlaybackDidFinishNotification
													  object:moviePlayer];
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:MPMoviePlayerDidEnterFullscreenNotification
													  object:moviePlayer];
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:MPMoviePlayerDidExitFullscreenNotification
													  object:moviePlayer];
		
		[moviePlayer.view removeFromSuperview];
		[moviePlayer release];
		moviePlayer=nil;
    }
}

- (void)moviePlayBackDidFinish:(NSNotification*)notification 
{   
    if (flags&VFLAG_FULLSCREEN)
    {
        [self endVideo];
        [rh resume];
    }
}

-(void)resetTouches:(NSNotification*)notification
{
	[rh->rhApp resetTouches];
}

-(void)destroyRunObject:(BOOL)bFast
{
    [self endVideo];
	[rh->rhApp resetTouches];
}
-(int)handleRunObject
{
    if (rh->rhApp->bStatusBar==NO)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    }
    return 0;
}
-(void)displayRunObject:(CRenderer *)renderer
{
    if ((flags&VFLAG_FULLSCREEN)==0)
    {
        if (oldX!=ho->hoX || oldY!=ho->hoY)
        {
            oldX=ho->hoX;
            oldY=ho->hoY;
            CGRect rect=CGRectMake(ho->hoX-rh->rhWindowX, ho->hoY-rh->rhWindowY, ho->hoImgWidth, ho->hoImgHeight);
            [moviePlayer.view setFrame:rect];        
        }
    }
}

-(BOOL)condition:(int)num withCndExtension:(CCndExtension *)cnd
{
    switch(num)
    {
        case CND_PLAYING:
            return [self cndPlaying];
        case CND_STOPPED:
            return [self cndStopped];
        case CND_PAUSED:
            return [self cndPaused];
        case CND_AIRPLAYENABLED:
            return [self cndAirplayEnabled];
    }
    return NO;
}
-(BOOL)cndPlaying
{
    if (moviePlayer!=nil)
    {
        return moviePlayer.playbackState==MPMoviePlaybackStatePlaying;
    }
    return NO;
}
-(BOOL)cndStopped
{
    if (moviePlayer!=nil)
    {
        return moviePlayer.playbackState==MPMoviePlaybackStateStopped;
    }
    return YES;
}
-(BOOL)cndPaused
{
    if (moviePlayer!=nil)
    {
        return moviePlayer.playbackState==MPMoviePlaybackStatePaused;
    }
    return NO;
}
-(BOOL)cndAirplayEnabled
{
    if (moviePlayer!=nil && [moviePlayer respondsToSelector:@selector(isAirPlayVideoActive)])
		return [moviePlayer isAirPlayVideoActive];
    return NO;
}

-(void)action:(int)num withActExtension:(CActExtension *)act
{
    switch(num)
    {
        case ACT_SETURL:
            url=[act getParamExpString:rh withNum:0];
            [self startVideo];
            break;
        case ACT_INITIALPLAYBACK:
             [self actInitialPlayback:act];
            break;
        case ACT_ENDPLAYBACK:
            [self actEndPlayback:act];
            break;
        case ACT_REPEAT:
            [self actRepeat:act];
            break;
        case ACT_PLAY:
            if (moviePlayer!=nil)
                [moviePlayer play];
            break;
        case ACT_VIDEOPAUSE:
            if (moviePlayer!=nil)
                [moviePlayer pause];
            break;
        case ACT_STOP:
            if (moviePlayer!=nil)
                [moviePlayer stop];
            break;
        case ACT_SETPLAYBACKTIME:
            [self actSetPlaybackTime:act];
            break;
        case ACT_BEGINSEEKFORWARD:
            if (moviePlayer!=nil)
                [moviePlayer beginSeekingForward];
            break;
        case ACT_BEGINSEEKBACKWARD:
            if (moviePlayer!=nil)
                [moviePlayer beginSeekingBackward];
            break;
        case ACT_ENDSEEK:
            if (moviePlayer!=nil)
                [moviePlayer endSeeking];
            break;
    }
}
-(void)actInitialPlayback:(CActExtension*)act
{
    initialPlayback=[act getParamExpression:rh withNum:0];
    if (moviePlayer!=nil)
    {
        moviePlayer.initialPlaybackTime=initialPlayback/1000.0;
    }
}
-(void)actEndPlayback:(CActExtension*)act
{
    endPlayback=[act getParamExpression:rh withNum:0];
    if (moviePlayer!=nil)
    {
        moviePlayer.endPlaybackTime=endPlayback/1000.0;
    }
}
-(void)actSetPlaybackTime:(CActExtension*)act
{
    int time=[act getParamExpression:rh withNum:0];
    if (moviePlayer!=nil)
    {
        moviePlayer.currentPlaybackTime=time/1000.0;
    }
}
-(void)actRepeat:(CActExtension*)act
{
    int repeat=[act getParamExpression:rh withNum:0];
    if (repeat==0)
    {
        flags&=~VFLAG_REPEAT;
    }
    else
    {
        flags|=VFLAG_REPEAT;
    }
    if (moviePlayer!=nil)
    {
        if ((flags&VFLAG_REPEAT)!=0)
        {
            moviePlayer.repeatMode=MPMovieRepeatModeOne;
        }
        else
        {
            moviePlayer.repeatMode=MPMovieRepeatModeNone;
        }
    }
}

-(CValue*)expression:(int)num
{
    switch (num)
    {
        case EXP_DURATION:
            return [self expDuration];
        case EXP_STATE:
            return [self expState];
        case EXP_PLAYABLEDURATION:
            return [self expPlayableDuration];
        case EXP_PLAYBACKTIME:
            return [self expPlaybackTime];
    }
    return [rh getTempValue:0];
}
-(CValue*)expPlaybackTime
{
    CValue* ret=[rh getTempValue:0];
    if (moviePlayer!=nil)
    {
        int time=moviePlayer.currentPlaybackTime*1000;
        if (time<0)
            time=0;
        [ret forceInt:time];
    }
    return ret;
}

-(CValue*)expDuration
{
    CValue* ret=[rh getTempValue:0];
    if (moviePlayer!=nil)
    {
        [ret forceInt:moviePlayer.duration*1000];
    }
    return ret;
}

-(CValue*)expPlayableDuration
{
    CValue* ret=[rh getTempValue:0];
    if (moviePlayer!=nil)
    {
        [ret forceInt:moviePlayer.playableDuration*1000];
    }
    return ret;
}
-(CValue*)expState
{
    CValue* ret=[rh getTempValue:0];
    if (moviePlayer!=nil)
    {
        [ret forceInt:(int)moviePlayer.playbackState];
    }
    return ret;
}





@end
