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
// CRunGameCenterLeaderboard
//
//----------------------------------------------------------------------------------
#import "CRunGameCenterLeaderboard.h"
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
#import "CArrayList.h"
#import "CTextSurface.h"
#import "CFont.h"
#import "CFontInfo.h"
#import "MainViewController.h"

#define CND_SCORESENT 0
#define CND_SCORESRECEIVED 1
#define CND_TITLERECEIVED 2
#define CND_ERROR 3
#define CND_LAST 4

#define ACT_SENDSCORE 0
#define ACT_GETSCORES 1
#define ACT_SETCATEGORY 2
#define ACT_SETTIMESCOPE 3
#define ACT_SETRANGE 4
#define ACT_DISPLAYDEFAULT 5
#define ACT_GETTITLE 6
#define ACT_LAST 7

#define EXP_GETCATEGORY 0
#define EXP_GETTIMESCOPE 1
#define EXP_GETRANGE 2
#define EXP_GETNAME 3
#define EXP_GETSCORE 4
#define EXP_GETNENTRIES 5
#define EXP_GETTITLE 6
#define EXP_LAST 7

#define SCR_NAMEFIRST 0x0002
#define SCR_SENDATSTART 0x0004
#define SCR_DONTDISPLAYSCORES 0x0008
#define SCR_SHOW 0x0020
#define SCR_GETATSTART 0x0040
#define SCR_GETTITLE 0x0080
#define SCR_GETNAMES 0x0100

#define ACTION_WAITFORGAMECENTER 0
#define ACTION_WAITFORAUTHENTICATION 1
#define ACTION_WAITFORCOMMAND 2
#define ACTION_WAITFORSENDSCORE 3
#define ACTION_WAITFORRECEIVESCORES 4
#define ACTION_WAITFORRECEIVETITLE 5
#define ACTION_WAITFORRECEIVENAMES 6

@implementation CRunGameCenterLeaderboard


-(int)getNumberOfConditions
{
	return CND_LAST;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    ho->hoImgWidth=[file readAInt];
    ho->hoImgHeight=[file readAInt];
    
    flags=[file readAInt];
    timeScope=[file readAShort];
    NbScores=[file readAShort];
    NameSize=[file readAShort];
    Logfont=[file readLogFont];
    colorref=[file readAColor];
    [file skipStringOfLength:40];
    category=[file readAString];
    textSurface=nil;
    if (flags&SCR_SHOW)
    {
        flags|=SCR_GETATSTART;
        textSurface = [[CTextSurface alloc] initWidthWidth:ho->hoImgWidth andHeight:ho->hoImgHeight];
    }
    range.location=0;
    range.length=NbScores;
    
    action=0;
    bScoresReceived=NO;
    scoreSentCount=-1;
    scoresReceivedCount=-1;
    titleReceivedCount=-1;
    errorCount=-1;
    scoreSet=[rh->rhApp getScores][0];
    
    return true;
}

-(void)destroyRunObject:(BOOL)bFast
{
    if (textSurface!=nil)
    {
        [textSurface release];
    }
    if (gameCenter!=nil)
    {
        [gameCenter setLeaderboard:nil];
    }
    if (category!=nil)
    {
        [category release];
    }
}


-(int)handleRunObject
{
    switch(action)
    {
        case ACTION_WAITFORGAMECENTER:
            gameCenter=(CESGameCenter*)[rh getStorage:IDENTIFIER];
            if (gameCenter!=nil)
            {
                [gameCenter setLeaderboard:self];
                action=ACTION_WAITFORAUTHENTICATION;
            }
            break;
        case ACTION_WAITFORAUTHENTICATION:
            if (gameCenter->localPlayer!=nil)
            {
                if (gameCenter->localPlayer.isAuthenticated)
                {
                    action=ACTION_WAITFORCOMMAND;
                }
            }
            break;
        case ACTION_WAITFORCOMMAND:
            if (flags&SCR_GETNAMES)
            {
                flags&=~SCR_GETNAMES;
                [gameCenter getNames];
                action=ACTION_WAITFORRECEIVENAMES;
                break;
            }
            if (flags&SCR_SENDATSTART)
            {
                flags&=~SCR_SENDATSTART;
                [gameCenter sendScore:scoreSet category:category];
                action=ACTION_WAITFORSENDSCORE;
                break;
            }
            if (flags&SCR_GETATSTART)
            {
                flags&=~SCR_GETATSTART;
                [gameCenter getScores:category timeScope:timeScope range:range];
                action=ACTION_WAITFORRECEIVESCORES;
                break;
            }
            if (flags&SCR_GETTITLE)
            {
                flags&=~SCR_GETTITLE;
                [gameCenter getTitle:category];
                action=ACTION_WAITFORRECEIVETITLE;
                break;
            }
            break;
            
    }
    return 0;
}
-(void)scoreSent
{
    scoreSentCount=[ho getEventCount];
    [ho pushEvent:CND_SCORESENT withParam:0];
    action=ACTION_WAITFORCOMMAND;
}
-(void)scoresReceived
{
    flags|=SCR_GETNAMES;
    action=ACTION_WAITFORCOMMAND;
}
-(void)namesReceived
{
    action=ACTION_WAITFORCOMMAND;
    scoresReceivedCount=[ho getEventCount];
    [ho pushEvent:CND_SCORESRECEIVED withParam:0];
    bScoresReceived=YES;
    bUpdated=YES;
}
-(void)titleReceived
{
    titleReceivedCount=[ho getEventCount];
    [ho pushEvent:CND_TITLERECEIVED withParam:0];
}
-(void)error
{
    errorCount=[ho getEventCount];
    [ho pushEvent:CND_ERROR withParam:0];
    action=ACTION_WAITFORCOMMAND;
}

-(void)displayRunObject:(CRenderer*)renderer
{
	if ((flags&SCR_SHOW)==0)
		return;
    if (bScoresReceived==NO)
        return;
	
	if(!bUpdated)
	{
		[textSurface draw:renderer withX:ho->hoX andY:ho->hoY andEffect:0 andEffectParam:0];
		return;	
	}
	
	bUpdated = NO;
	[textSurface manualClear:colorref];
    
    int maxScores, i;
	NSString* names[NbScores];
	for (i = 0; i < NbScores; i++)
	{
		names[i] = [gameCenter getLeaderboardName:i];
        if ([names[i] length]==0)
        {
            break;
        }
		if ([names[i] length] > NameSize)
		{
			names[i] = [[names[i] substringToIndex:NameSize] retain];
		}
	}
    maxScores=MIN(i, NbScores);
    
	int ADJ = 4; // move strings up 4 pixels
    
    CFont* font = [CFont createFromFontInfo:Logfont];
	if ((flags & SCR_DONTDISPLAYSCORES) != 0)
	{
		CRect rc;
		// Compute coordinates
		rc.left = 0;
		rc.right = ho->hoImgWidth;
		rc.top = 0;
		rc.bottom = (ho->hoImgHeight / NbScores);
        
		// draw names
		for (int a = 0; a < maxScores; a++)
		{
			[textSurface manualDrawText:names[a] withFlags:DT_VALIGN|DT_TOP andRect:rc andColor:colorref andFont:font];
			rc.top += ho->hoImgHeight / NbScores;
			rc.bottom += ho->hoImgHeight / NbScores;
		}
	}
	else
	{
		// Draw text
		if (0 != (flags & SCR_NAMEFIRST))
		{
			CRect rc;
            
			// Compute coordinates
			rc.left = 0;
			rc.right = (ho->hoImgWidth / 4)*3;
			rc.top = 0;
			rc.bottom = (ho->hoImgHeight / NbScores);
            
			// draw names
			for (int a = 0; a < maxScores; a++)
			{
				[textSurface manualDrawText:names[a] withFlags:DT_VALIGN|DT_TOP andRect:rc andColor:colorref andFont:font];
				rc.top += ho->hoImgHeight / NbScores;
				rc.bottom += ho->hoImgHeight / NbScores;
			}
            
			// Compute coordinates
			rc.left = (ho->hoImgWidth / 4)*3;
			rc.right = rc.left + (ho->hoImgWidth / 4);
			rc.top = 0;
			rc.bottom = ho->hoImgHeight / NbScores;
            
			// draw scores
			for (int a = 0; a < maxScores; a++)
			{
				NSString* score = [NSString stringWithFormat:@"%i",[gameCenter getLeaderboardScore:a]];
				
				CRect tmpRect = rc;
#ifdef __IPHONE_8_0
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
				CGSize scoreSize;
				if([score respondsToSelector:@selector(sizeWithAttributes:)])
					scoreSize = [score sizeWithAttributes:@{NSFontAttributeName:[font createFont]}];
				else
					scoreSize = [score sizeWithFont:[font createFont]];
#pragma clang diagnostic pop
#else
				CGSize scoreSize = [score sizeWithFont:[font createFont]];
#endif
				tmpRect.left = rc.right - scoreSize.width;
				tmpRect.bottom = rc.bottom-ADJ;
				[textSurface manualDrawText:score withFlags:DT_VALIGN|DT_TOP andRect:tmpRect andColor:colorref andFont:font];
				
				rc.top += ho->hoImgHeight / NbScores;
				rc.bottom += ho->hoImgHeight / NbScores;
			}
		}
		else
		{
			CRect rc;
            
			// Compute coordinates
			rc.left = 0;
			rc.right = (ho->hoImgWidth/4);
			rc.top = 0;
			rc.bottom = (ho->hoImgHeight / NbScores);
            
			// draw scores
			for (int a = 0; a < maxScores; a++)
			{
				[textSurface manualDrawText:[NSString stringWithFormat:@"%i",[gameCenter getLeaderboardScore:a]] withFlags:DT_TOP andRect:rc andColor:colorref andFont:font];
				rc.top += ho->hoImgHeight / NbScores;
				rc.bottom += ho->hoImgHeight / NbScores;
			}
            
			// Compute coordinates
			rc.left = ho->hoImgWidth / 4;
			rc.right = rc.left + ((ho->hoImgWidth / 4) * 3);
			rc.top = 0;
			rc.bottom = ho->hoImgHeight / NbScores;
            
			// draw names
			for (int a = 0; a < maxScores; a++)
			{
				CRect tmpRect = rc;

				NSString* name = names[a];
#ifdef __IPHONE_8_0
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
				CGSize nameSize;
				if([name respondsToSelector:@selector(sizeWithAttributes:)])
					nameSize = [name sizeWithAttributes:@{NSFontAttributeName:[font createFont]}];
				else
					nameSize = [name sizeWithFont:[font createFont]];
#pragma clang diagnostic pop
#else
				CGSize nameSize = [name sizeWithFont:[font createFont]];
#endif
				tmpRect.left = rc.right - nameSize.width;
				tmpRect.bottom = rc.bottom-ADJ;
				[textSurface manualDrawText:names[a] withFlags:DT_TOP andRect:tmpRect andColor:colorref andFont:font];
                
				rc.top += ho->hoImgHeight / NbScores;
				rc.bottom += ho->hoImgHeight / NbScores;
			}
		}
	}
	[textSurface manualUploadTexture];
	[textSurface draw:renderer withX:ho->hoX andY:ho->hoY andEffect:0 andEffectParam:0];
    [font release];
    
}

-(BOOL)scoreSentCnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == scoreSentCount)
	{
		return YES;
	}
	return NO;    
}
-(BOOL)scoresReceivedCnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == scoresReceivedCount)
	{
		return YES;
	}
	return NO;    
}
-(BOOL)titleReceivedCnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == titleReceivedCount)
	{
		return YES;
	}
	return NO;    
}
-(BOOL)errorCnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == errorCount)
	{
		return YES;
	}
	return NO;    
}
-(BOOL)condition:(int)num withCndExtension:(CCndExtension *)cnd
{
    switch(num)
    {
        case CND_SCORESENT:
            return [self scoreSentCnd];
        case CND_SCORESRECEIVED:
            return [self scoresReceivedCnd];
        case CND_TITLERECEIVED:
            return [self titleReceivedCnd];
        case CND_ERROR:
            return [self errorCnd];
    }
    return NO;
}



-(void)sendScore:(CActExtension*)act
{
    scoreSet=[act getParamExpression:rh withNum:0];
    flags|=SCR_SENDATSTART|SCR_GETATSTART;    
}
-(void)getScores
{
    flags|=SCR_GETATSTART;
}
-(void)getTitleAct
{
    flags|=SCR_GETTITLE;
}
-(void)setCategory:(CActExtension*)act
{
    category=[[NSString alloc] initWithString:[act getParamExpString:rh withNum:0]];
}
-(void)setTimeScope:(CActExtension*)act
{
    timeScope=[act getParamExpression:rh withNum:0];
    if (timeScope<0)
        timeScope=0;
    if (timeScope>=3)
        timeScope=2;
}
-(void)setRange:(CActExtension*)act
{
    int r=[act getParamExpression:rh withNum:0]-1;
    if (r<0)
    {
        r=0;
    }
    range.location=r;
}
-(void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController*)viewController
{
    [ho->hoAdRunHeader->rhApp->mainViewController dismissViewControllerAnimated:YES];
    [ho->hoAdRunHeader resume];
}
-(void)displayDefault
{
    if (gameCenter!=nil)
    {
        if (gameCenter->localPlayer!=nil)
        {
            if (gameCenter->localPlayer.isAuthenticated)
            {
                GKLeaderboardViewController* leaderboardController=[[GKLeaderboardViewController alloc] init];
                if (leaderboardController!=nil)
                {                    
                    leaderboardController.category=category;
                    leaderboardController.timeScope=timeScope;
                    [ho->hoAdRunHeader pause];
                    leaderboardController.leaderboardDelegate=self;
                    [ho->hoAdRunHeader->rhApp->mainViewController presentViewController:leaderboardController animated:YES];
                }
            }
        }
        
    }
}
-(void)action:(int)num withActExtension:(CActExtension *)act
{
    switch (num)
    {
        case ACT_SENDSCORE:
            [self sendScore:act];
            break;
        case ACT_GETSCORES:
            [self getScores];
            break;
        case ACT_SETCATEGORY:
            [self setCategory:act];
            break;
        case ACT_SETTIMESCOPE:
            [self setTimeScope:act];
            break;
        case ACT_SETRANGE:
            [self setRange:act];
            break;
        case ACT_DISPLAYDEFAULT:
            [self displayDefault];
            break;
        case ACT_GETTITLE:
            [self getTitleAct];
            break;
    }
}


-(CValue*)getCategory
{
    return [rh getTempString:category];
}
-(CValue*)getName
{
    CValue* ret=[rh getTempString:@""];
    int index=[[ho getExpParam] getInt];
    if (index>=0 && index<NbScores)
    {
        if (gameCenter!=nil && gameCenter->localPlayer!=nil)
        {
            if (gameCenter->localPlayer.isAuthenticated)
            {
                [ret forceString:[gameCenter getLeaderboardName:index]];
            }
        }
    }
    return ret;
}
-(CValue*)getScore
{
    CValue* ret=[rh getTempValue:0];
    int index=[[ho getExpParam] getInt];
    if (index>=0 && index<NbScores)
    {
        if (gameCenter!=nil && gameCenter->localPlayer!=nil)
        {
            if (gameCenter->localPlayer.isAuthenticated)
            {
                [ret forceInt:[gameCenter getLeaderboardScore:index]];
            }
        }
    }
    return ret;
}
-(CValue*)getNEntries
{
    CValue* ret=[rh getTempValue:0];
    if (gameCenter!=nil && gameCenter->localPlayer!=nil)
    {
        if (gameCenter->localPlayer.isAuthenticated)
        {
            [ret forceInt:[gameCenter getLeaderboardNEntries]];
        }
    }
    return ret;
}
-(CValue*)getTitle
{
    CValue* ret=[rh getTempString:@""];
    if (gameCenter!=nil)
    {
        [ret forceString:[gameCenter getLeaderboardTitle]];
    }
    return ret;
}
-(CValue*)expression:(int)num
{
    switch(num)
    {
        case EXP_GETCATEGORY:
            return [self getCategory];
        case EXP_GETTIMESCOPE:
            return [rh getTempValue:timeScope];
        case EXP_GETRANGE:
            return [rh getTempValue:(int)range.location];
        case EXP_GETNAME:
            return [self getName];
        case EXP_GETSCORE:
            return [self getScore];
        case EXP_GETNENTRIES:
            return [self getNEntries];
        case EXP_GETTITLE:
            return [self getTitle];
    }
    return nil;
}

@end
