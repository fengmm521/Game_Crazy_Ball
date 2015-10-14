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
#import "CRunGameCenterAchievements.h"
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
#import "CSprite.h"
#import "CSpriteGen.h"
#import "CRenderer.h"
#import "CTextSurface.h"
#import "CObjectCommon.h"

#define CND_ACHIEVEMENTSENT 0
#define CND_ACHIEVEMENTSRECEIVED 1
#define CND_ERROR 2
#define CND_DESCRIPTIONSRECEIVED 3
#define CND_ONRESETACHIEVEMENTS 4
#define CND_ONANYCOMPLETED 5
#define CND_ONCOMPLETED 6
#define CND_ONCOMPLETEDINDEX 7
#define CND_ACHIEVEMENTSLOADED 8
#define CND_LAST 9

#define ACT_SENDACHIEVEMENT 0
#define ACT_GETACHIEVEMENTS 1
#define ACT_DISPLAYDEFAULT 2
#define ACT_RESETACHIEVEMENTS 3
#define ACT_DISPLAYBANNER 4
#define ACT_DISPLAYBANNERINDEX 5
#define ACT_SENDACHIEVEMENTINDEX 6
#define ACT_SETBANNERTITLE 7
#define ACT_SETBANNERTEXT 8
#define ACT_LAST 9

#define EXP_GETNACHIEVEMENTS 0
#define EXP_GETIDENTIFIER 1
#define EXP_GETTITLE 2
#define EXP_GETDESCRIPTION1 3
#define EXP_GETDESCRIPTION2 4
#define EXP_GETMAXIMUMPOINTS 5
#define EXP_GETPERCENT 6
#define EXP_GETIDENTIFIERINDEX 7
#define EXP_GETTITLEINDEX 8
#define EXP_GETDESCRIPTION1INDEX 9
#define EXP_GETDESCRIPTION2INDEX 10
#define EXP_GETMAXIMUMPOINTSINDEX 11
#define EXP_GETPERCENTINDEX 12
#define EXP_GETINDEX 13

#define ACTION_WAITFORGAMECENTER 0
#define ACTION_WAITFORAUTHENTICATION 1
#define ACTION_WAITFORCOMMAND 2
#define ACTION_WAITFORSENDACHIEVEMENT 3
#define ACTION_WAITFORRECEIVEDACHIEVEMENTS 4
#define ACTION_WAITFORRECEIVEDDESCRIPTIONS 4
#define ACTION_WAITFORRESETACHIEVEMENTS 4
#define FLAG_SENDACHIEVEMENT 0x0001
#define FLAG_GETACHIEVEMENTS 0x0002
#define FLAG_GETDESCRIPTIONS 0x0004
#define FLAG_RESETACHIEVEMENTS 0x0008
#define FLAG_ICONSDONE 0x0010
#define GCA_GETATSTART 0x0001
#define GCA_SHOWBANNER 0x0002
#define GCA_SEQUENTIAL 0x0004
#define GCA_APPLEBANNERS 0x0008

CArrayList* icons;

@implementation CRunGameCenterAchievements

-(int)getNumberOfConditions
{
	return CND_LAST;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    achievementSentCount=-1;
    achievementsReceivedCount=-1;
    descriptionsReceivedCount=-1;
    achievementsResetCount=-1;
    achievementCompletedCount=-1;
    errorCount=-1;
    
    queuedAchivements=[[CArrayList alloc] init];

    eFlags=[file readAInt];
    flags=(FLAG_GETACHIEVEMENTS|FLAG_GETDESCRIPTIONS);
    bLoaded=NO;
    images[0]=[file readAShort];
    images[1]=[file readAShort];
	[ho loadImageList:images withLength:2];
    
    [file skipBytes:6];
    titleFont=[file readLogFont];
    textFont=[file readLogFont];
    titleColor=[file readAColor];
    stringColor=[file readAColor];
    duration=[file readAInt];
    
    title=[file readAString];
    string=[file readAString];
    banners=[[CArrayList alloc] init];
    nextBanners=[[CArrayList alloc] init];
    if (icons==nil)
        icons=[[CArrayList alloc] init];
    iconImages=nil;
    return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
    if (gameCenter!=nil)
        [gameCenter setAchievements:nil];
    [queuedAchivements clearRelease];
    [queuedAchivements release];
    [title release];
    [string release];
    [titleFont release];
    [textFont release];
    [banners clearRelease];
    [nextBanners release];
    if (iconImages!=nil)
        free(iconImages);
}

-(int)handleRunObject
{
    switch(action)
    {
        case ACTION_WAITFORGAMECENTER:
            gameCenter=(CESGameCenter*)[rh getStorage:IDENTIFIER];
            if (gameCenter!=nil)
            {
                [gameCenter setAchievements:self];
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
            if (flags&FLAG_GETDESCRIPTIONS)
            {
                flags&=~FLAG_GETDESCRIPTIONS;
                action=ACTION_WAITFORRECEIVEDDESCRIPTIONS;
                [gameCenter getDescriptions];
                break;
            }
            if (flags&FLAG_GETACHIEVEMENTS)
            {
                flags&=~FLAG_GETACHIEVEMENTS;
                action=ACTION_WAITFORRECEIVEDACHIEVEMENTS;
                [gameCenter getAchievements];
                break;
            }
            if (flags&FLAG_SENDACHIEVEMENT)
            {
                BOOL bRet=NO;
                flags&=~FLAG_SENDACHIEVEMENT;
                for (int n=0; n<[queuedAchivements size]; n++)
                {
                    bRet|=[gameCenter sendAchievement:(GKAchievement*)[queuedAchivements get:n]];
                }
                [queuedAchivements clearRelease];
                if (bRet)
                    action=ACTION_WAITFORSENDACHIEVEMENT;
                break;
            }
            if (flags&FLAG_RESETACHIEVEMENTS)
            {
                flags&=~FLAG_RESETACHIEVEMENTS;
                action=ACTION_WAITFORRESETACHIEVEMENTS;
                [gameCenter resetAchievements];
                break;
            }
            break;
    }
    int n;
    if ((flags&FLAG_ICONSDONE)==0)
    {
        CAchievementIcon* icon;
        int count = 0;
        for (n = 0; n < rh->rhNObjects; n++)
        {
            while (rh->rhObjectList[count] == nil)
            {
                count++;
            }
            CObject* pHo = rh->rhObjectList[count];
            count++;
            if (pHo->hoType>=32)
            {
                if (pHo->hoCommon->ocIdentifier==0x47434144)
                {
                    CRunAch* ach=(CRunAch*)((CExtension*)pHo)->ext;
                    int m;
                    for (m=0; m<[icons size]; m++)
                    {
                        icon=(CAchievementIcon*)[icons get:m];
                        if ([ach->identifier compare:icon->identifier]==0)
                        {
                            break;
                        }
                    }
                    if (m==[icons size])
                    {
                        icon=[[CAchievementIcon alloc] init];
                        icon->image=ach->images[1];
                        icon->identifier=[[NSString alloc] initWithString:ach->identifier];
                        [icons add:icon];
                    }
                }
            }
        }
        if ([icons size]>0)
        {
            iconImages=(short*)malloc([icons size]*sizeof(short));
            for (n=0; n<[icons size]; n++)
            {
                icon=(CAchievementIcon*)[icons get:n];
                iconImages[n]=icon->image;
            }
            [ho loadImageList:iconImages withLength:n];
        }
        flags|=FLAG_ICONSDONE;
    }
    for (n=0; n<[banners size]; n++)
    {
        CBanner* banner=(CBanner*)[banners get:n];
        if ([banner handle])
        {
            [banners removeClearIndex:n];
            n--;
        }
    }
    if ([nextBanners size]>0)
    {
        if ([banners size]==0)
        {
            int index=[nextBanners getInt:0];
            [nextBanners removeIndex:0];
            CBanner* banner=[[CBanner alloc] initWithRunData:self andIndex:index];
            [banners add:banner];
        }
    }
    return 0;
}


-(void)achievementSent
{
    achievementSentCount=[ho getEventCount];
    [ho generateEvent:CND_ACHIEVEMENTSENT withParam:0];
    action=ACTION_WAITFORCOMMAND;
}
-(void)resetCompleted
{
    achievementsResetCount=[ho getEventCount];
    [ho generateEvent:CND_ONRESETACHIEVEMENTS withParam:0];
    action=ACTION_WAITFORCOMMAND;
}
-(void)descriptionsReceived
{
    action=ACTION_WAITFORCOMMAND;
    descriptionsReceivedCount=[ho getEventCount];
    [ho generateEvent:CND_DESCRIPTIONSRECEIVED withParam:0];
}
-(void)achievementsReceived
{
    action=ACTION_WAITFORCOMMAND;
    achievementsReceivedCount=[ho getEventCount];
    [ho generateEvent:CND_ACHIEVEMENTSRECEIVED withParam:0];
    bLoaded=YES;
}
-(void)error
{
    action=ACTION_WAITFORCOMMAND;
    errorCount=[ho getEventCount];
    [ho generateEvent:CND_ERROR withParam:0];
}
-(void)addBanner:(int)index
{
    if ((eFlags&GCA_APPLEBANNERS)==0)
    {
        int n;
        if (eFlags&GCA_SEQUENTIAL)
        {
            for (n=0; n<[nextBanners size]; n++)
            {
                int i=[nextBanners getInt:n];
                if (i==index)
                {
                    return;
                }
            }
			[nextBanners addInt:index];
        }
        else
        {
            for (n=0; n<[banners size]; n++)
            {
                CBanner* banner=(CBanner*)[banners get:n];
                if (banner->index==index)
                {
                    return;
                }
            }
            CBanner* banner=[[CBanner alloc] initWithRunData:self andIndex:index];
            [banners add:banner];
        }
    }
}
-(void)achievementCompleted:(int)index
{
    achievementCompletedCount=[ho getEventCount];
    currentCompleted=index;
    [ho generateEvent:CND_ONANYCOMPLETED withParam:0];
    [ho generateEvent:CND_ONCOMPLETED withParam:0];
    [ho generateEvent:CND_ONCOMPLETEDINDEX withParam:0];
    if (eFlags&GCA_SHOWBANNER)
    {
        [self addBanner:index];
    }
}

-(BOOL)achievementSentCnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == achievementSentCount)
	{
		return YES;
	}
	return NO;
}
-(BOOL)onAnyCompletedCnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == achievementCompletedCount)
	{
		return YES;
	}
	return NO;
}
-(BOOL)onCompletedCnd:(CCndExtension*)cnd
{
    NSString* identifier=[cnd getParamExpString:rh withNum:0];
    int index=[gameCenter findCAchievementIndex:identifier];
    if (index==currentCompleted)
    {
        if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
        {
            return YES;
        }
        if ([ho getEventCount] == achievementCompletedCount)
        {
            return YES;
        }
    }
	return NO;
}
-(BOOL)onCompletedIndexCnd:(CCndExtension*)cnd
{
    int index=[cnd getParamExpression:rh withNum:0];
    if (index==currentCompleted)
    {
        if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
        {
            return YES;
        }
        if ([ho getEventCount] == achievementCompletedCount)
        {
            return YES;
        }
    }
	return NO;
}
-(BOOL)onResetAchievementsCnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == achievementsResetCount)
	{
		return YES;
	}
	return NO;
}
-(BOOL)achievementsReceivedCnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == achievementsReceivedCount)
	{
		return YES;
	}
	return NO;
}
-(BOOL)descriptionsReceivedCnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == descriptionsReceivedCount)
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
        case CND_ACHIEVEMENTSENT:
            return [self achievementSentCnd];
        case CND_ACHIEVEMENTSRECEIVED:
            return [self achievementsReceivedCnd];
        case CND_ERROR:
            return [self errorCnd];
        case CND_DESCRIPTIONSRECEIVED:
            return [self achievementsReceivedCnd];
        case CND_ONRESETACHIEVEMENTS:
            return [self onResetAchievementsCnd];
        case CND_ONANYCOMPLETED:
            return [self onAnyCompletedCnd];
        case CND_ONCOMPLETED:
            return [self onCompletedCnd:cnd];
        case CND_ONCOMPLETEDINDEX:
            return [self onCompletedIndexCnd:cnd];
        case CND_ACHIEVEMENTSLOADED:
            return bLoaded;
    }
    return NO;
}

//UrbanMonk's sendAchivement implementation
-(void)sendAchievement:(CActExtension*)act
{
    NSString* identifier=[act getParamExpString:rh withNum:0];
    double percent=[act getParamExpDouble:rh withNum:1];
    
    GKAchievement* achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
    achievement.percentComplete = percent;
    if ((eFlags&GCA_SHOWBANNER)!=0 && (eFlags&GCA_APPLEBANNERS)!=0)
        achievement.showsCompletionBanner=YES;
    
    [queuedAchivements add:achievement];
    flags|=FLAG_SENDACHIEVEMENT;
}
-(void)sendAchievementIndex:(CActExtension*)act
{
    int index=[act getParamExpression:rh withNum:0];
    double percent=[act getParamExpDouble:rh withNum:1];
    CAchievement* ach=[gameCenter getCAchievement:index];
    if (ach!=nil)
    {
        GKAchievement* achievement = [[GKAchievement alloc] initWithIdentifier:ach->identifier];
        achievement.percentComplete = percent;
        if ((eFlags&GCA_SHOWBANNER)!=0 && (eFlags&GCA_APPLEBANNERS)!=0)
            achievement.showsCompletionBanner=YES;
   
        [queuedAchivements add:achievement];
        flags|=FLAG_SENDACHIEVEMENT;
    }
}

-(void)getAchievements
{
    action=ACTION_WAITFORRECEIVEDACHIEVEMENTS;
    [gameCenter getAchievementsForced];
}
-(void)displayDefault
{
    if (gameCenter!=nil)
    {
        if (gameCenter->localPlayer!=nil)
        {
            if (gameCenter->localPlayer.isAuthenticated)
            {
                GKAchievementViewController* achievementController=[[GKAchievementViewController alloc] init];
                if (achievementController!=nil)
                {
                    [ho->hoAdRunHeader pause];
                    achievementController.achievementDelegate=self;
                    [ho->hoAdRunHeader->rhApp->mainViewController presentViewController:achievementController animated:YES];
                }
                [achievementController release];
            }
        }
    }
}
-(void)achievementViewControllerDidFinish:(GKAchievementViewController*)viewController
{
    [ho->hoAdRunHeader resume];
    [ho->hoAdRunHeader->rhApp->mainViewController dismissViewControllerAnimated:YES];
}
-(void)displayBanner:(CActExtension*)act
{
    NSString* identifier=[act getParamExpString:rh withNum:0];
    int index=[gameCenter findCAchievementIndex:identifier];
    if (index>=0)
    {
        [self addBanner:index];
    }
}
-(void)displayBannerIndex:(CActExtension*)act
{
    int index=[act getParamExpression:rh withNum:0];
    if ([gameCenter getIdentifier:index]!=nil)
    {
        [self addBanner:index];
    }
}
-(void)action:(int)num withActExtension:(CActExtension *)act
{
    switch (num)
    {
        case ACT_SENDACHIEVEMENT:
            [self sendAchievement:act];
            break;
        case ACT_GETACHIEVEMENTS:
            [self getAchievements];
            break;
        case ACT_DISPLAYDEFAULT:
            [self displayDefault];
            break;
        case ACT_RESETACHIEVEMENTS:
            flags|=FLAG_RESETACHIEVEMENTS;
            break;
        case ACT_DISPLAYBANNER:
            [self displayBanner:act];
            break;
        case ACT_DISPLAYBANNERINDEX:
            [self displayBannerIndex:act];
            break;
        case ACT_SENDACHIEVEMENTINDEX:
            [self sendAchievementIndex:act];
            break;
        case ACT_SETBANNERTITLE:
            [title release];
            title=[[NSString alloc] initWithString:[act getParamExpString:rh withNum:0]];
            break;
        case ACT_SETBANNERTEXT:
            [string release];
            string=[[NSString alloc] initWithString:[act getParamExpString:rh withNum:0]];
            break;
    }
}


-(CValue*)getNAchievements
{
    if (gameCenter!=nil)
    {
        return [rh getTempValue:[gameCenter getNAchievements]];
    }
    return [rh getTempValue:0];
}
-(CValue*)getTitle
{
    CValue* ret=[rh getTempValue:0];
    [ret forceString:@""];
    NSString* identifier=[[ho getExpParam] getString];
    if (gameCenter!=nil)
    {
        [ret forceString:[gameCenter getATitle:identifier]];
    }
    return ret;
}
-(CValue*)getDescription1
{
    CValue* ret=[rh getTempValue:0];
    [ret forceString:@""];
    NSString* identifier=[[ho getExpParam] getString];
    if (gameCenter!=nil)
    {
        [ret forceString:[gameCenter getADescription1:identifier]];
    }
    return ret;
}
-(CValue*)getDescription2
{
    CValue* ret=[rh getTempValue:0];
    [ret forceString:@""];
    NSString* identifier=[[ho getExpParam] getString];
    if (gameCenter!=nil)
    {
        [ret forceString:[gameCenter getADescription2:identifier]];
    }
    return ret;
}
-(CValue*)getMaximumPoints
{
    CValue* ret=[rh getTempValue:0];
    NSString* identifier=[[ho getExpParam] getString];
    if (gameCenter!=nil)
    {
        [ret forceInt:(int)[gameCenter getAMaximumPoints:identifier]];
    }
    return ret;
}
-(CValue*)getPercent
{
    CValue* ret=[rh getTempValue:0];
    NSString* identifier=[[ho getExpParam] getString];
    if (gameCenter!=nil)
    {
        [ret forceDouble:[gameCenter getAPercent:identifier]];
    }
    return ret;
}
-(CValue*)getTitleIndex
{
    CValue* ret=[rh getTempValue:0];
    [ret forceString:@""];
    int index=[[ho getExpParam] getInt];
    if (gameCenter!=nil)
    {
        [ret forceString:[gameCenter getATitleIndex:index]];
    }
    return ret;
}
-(CValue*)getDescription1Index
{
    CValue* ret=[rh getTempValue:0];
    [ret forceString:@""];
    int index=[[ho getExpParam] getInt];
    if (gameCenter!=nil)
    {
        [ret forceString:[gameCenter getADescription1Index:index]];
    }
    return ret;
}
-(CValue*)getDescription2Index
{
    CValue* ret=[rh getTempValue:0];
    [ret forceString:@""];
    int index=[[ho getExpParam] getInt];
    if (gameCenter!=nil)
    {
        [ret forceString:[gameCenter getADescription2Index:index]];
    }
    return ret;
}
-(CValue*)getMaximumPointsIndex
{
    CValue* ret=[rh getTempValue:0];
    int index=[[ho getExpParam] getInt];
    if (gameCenter!=nil)
    {
        [ret forceInt:[gameCenter getAMaximumPointsIndex:index]];
    }
    return ret;
}
-(CValue*)getPercentIndex
{
    CValue* ret=[rh getTempValue:0];
    int index=[[ho getExpParam] getInt];
    if (gameCenter!=nil)
    {
        [ret forceDouble:[gameCenter getAPercentIndex:index]];
    }
    return ret;
}
-(CValue*)getIndex
{
    CValue* ret=[rh getTempValue:0];
    NSString* identifier=[[ho getExpParam] getString];
    if (gameCenter!=nil)
    {
        int index=[gameCenter findCAchievementIndex:identifier];
        [ret forceInt:index];
    }
    return ret;
}
-(CValue*)getIdentifierIndex
{
    CValue* ret=[rh getTempValue:0];
    [ret forceString:@""];
    int index=[[ho getExpParam] getInt];
    if (gameCenter!=nil)
    {
        CAchievement* ach=[gameCenter getCAchievement:index];
        if (ach!=nil)
        {
            [ret forceString:ach->identifier];
        }
    }
    return ret;
}
-(CValue*)expression:(int)num
{
    switch(num)
    {
        case EXP_GETNACHIEVEMENTS:
            return [self getNAchievements];
        case EXP_GETTITLE:
            return [self getTitle];
        case EXP_GETDESCRIPTION1:
            return [self getDescription1];
        case EXP_GETDESCRIPTION2:
            return [self getDescription2];
        case EXP_GETMAXIMUMPOINTS:
            return [self getMaximumPoints];
        case EXP_GETPERCENT:
            return [self getPercent];
        case EXP_GETIDENTIFIERINDEX:
            return [self getIdentifierIndex];
        case EXP_GETTITLEINDEX:
            return [self getTitleIndex];
        case EXP_GETDESCRIPTION1INDEX:
            return [self getDescription1Index];
        case EXP_GETDESCRIPTION2INDEX:
            return [self getDescription2Index];
        case EXP_GETMAXIMUMPOINTSINDEX:
            return [self getMaximumPointsIndex];
        case EXP_GETPERCENTINDEX:
            return [self getPercentIndex];
        case EXP_GETINDEX:
            return [self getIndex];
    }
    return nil;
}


@end

@implementation CRunAch
@end
@implementation CAchievementIcon
@end

@implementation CBanner
#define SXLEFT 16
#define SYTOP 8
#define SXBETWEEN 16
#define SYBETWEEN 2
#define STEP_COMING 0
#define STEP_WAITING 1
#define STEP_LEAVING 2
#define STEP_ABORT 3
#define SYTOPIMAGE 12
#define SXLEFTIMAGE 12

-(void)startMovement:(int)dest withStart:(int)start andSpeed:(double)s
{
    speed=s;
    length=dest-start;
    yMiddle=(start+dest)/2;
    yDest=dest;
    angle=0;
}
-(BOOL)move
{
    BOOL ret=NO;
    angle+=speed;
    if (angle>=3.1416)
    {
        yy=yDest;
        ret=YES;
    }
    yy=yMiddle+length*(-cos(angle))/2;
    [spriteGen modifOwnerDrawSprite:sprite withX1:xx andY1:yy andX2:xx+sx andY2:yy+sy];

    return ret;
}
-(id)initWithRunData:(CRunGameCenterAchievements*)r andIndex:(int)i
{
	if(self = [super init])
	{
		rdPtr=r;
		index=i;

		spriteGen=rdPtr->rh->spriteGen;

		CFont* titleFont = [CFont createFromFontInfo:rdPtr->titleFont];
		CFont* textFont = [CFont createFromFontInfo:rdPtr->textFont];

		title=[[NSString alloc] initWithFormat:rdPtr->title, [rdPtr->gameCenter getATitleIndex:index]];
		string=[[NSString alloc] initWithFormat:rdPtr->string, [rdPtr->gameCenter getATitleIndex:index]];
		CGSize size = [title sizeWithFont:[titleFont createFont] constrainedToSize:CGSizeMake(1000, 100000) lineBreakMode:0];
		int sxText = (int)size.width;
		syText = (int)size.height;
		size = [string sizeWithFont:[textFont createFont] constrainedToSize:CGSizeMake(1000, 100000) lineBreakMode:0];
		sxText=MAX(sxText, (int)size.width);

		// Looks for Achievement icon
		int n;
		iconImage=rdPtr->images[1];
		NSString* identifier=[rdPtr->gameCenter getIdentifier:index];
		for (n=0; n<[icons size]; n++)
		{
			CAchievementIcon* icon = (CAchievementIcon*)[icons get:n];
			if ([icon->identifier compare:identifier]==0)
			{
				iconImage=rdPtr->iconImages[n];
				break;
			}
		}

		CImage* background = [rdPtr->rh->rhApp->imageBank getImageFromHandle:rdPtr->images[0]];
		CImage* icon = [rdPtr->rh->rhApp->imageBank getImageFromHandle:iconImage];
		sx=MAX(background->width, icon->width+SXLEFT+SXBETWEEN+sxText+SXLEFT);
		sy=MAX(background->height, MAX(SYTOP*2+syText*2+SYBETWEEN, icon->height+SYTOPIMAGE*2));
		xx=rdPtr->rh->rhApp->gaCxWin/2-sx/2;
		yDisplay=32;
		for (n=0; n<[rdPtr->banners size]; n++)
		{
			CBanner* banner=(CBanner*)[rdPtr->banners get:n];
			if (banner!=self)
			{
				yDisplay=MAX(yDisplay, banner->yDisplay+banner->sy+4);
			}
		}

		yy=-sy;

		textSurface1 = [[CTextSurface alloc] initWidthWidth:sxText andHeight:syText];
		[textSurface1 setText:title withFlags:DT_LEFT|DT_TOP andColor:rdPtr->titleColor andFont:titleFont];
		textSurface2 = [[CTextSurface alloc] initWidthWidth:sxText andHeight:syText];
		[textSurface2 setText:string withFlags:DT_LEFT|DT_TOP andColor:rdPtr->stringColor andFont:textFont];

		sprite=[spriteGen addOwnerDrawSprite:xx withY1:yy andX2:xx+sx andY2:yy+sy andLayer:100 andZOrder:0 andBackColor:0 andFlags:0 andObject:rdPtr->ho andDrawable:self];

		[self startMovement:yDisplay withStart:yy andSpeed:0.07];
		if (yDisplay<rdPtr->rh->rhApp->gaCyWin)
			step=STEP_COMING;
		else
			step=STEP_ABORT;

		[titleFont release];
		[textFont release];
    }
    return self;
}
-(void)dealloc
{
    [spriteGen delSpriteFast:sprite];
    [textSurface1 release];
    [textSurface2 release];
    [string release];
    [title release];
    [super dealloc];
}
-(BOOL)handle
{
    double time;
    switch(step)
    {
        case STEP_COMING:
            if ([self move])
            {
                step=STEP_WAITING;
                timeStart=CFAbsoluteTimeGetCurrent()*1000;
            }
            break;
        case STEP_WAITING:
            time= CFAbsoluteTimeGetCurrent()*1000;
            if (time-timeStart>rdPtr->duration)
            {
                [self startMovement:-sy withStart:yy andSpeed:0.1];
                step=STEP_LEAVING;
            }
            break;
        case STEP_LEAVING:
            if ([self move])
            {
                return YES;
            }
            break;
        case STEP_ABORT:
            return YES;
    }
    return NO;
}
-(void)spriteDraw:(CRenderer*)renderer withSprite:(CSprite*)spr andImageBank:(CImageBank*)bank andX:(int)x andY:(int)y
{
	BOOL resample = YES;
    
	CImage* background = [bank getImageFromHandle:rdPtr->images[0]];
	CImage* icon = [bank getImageFromHandle:iconImage];
    if (background!=nil && icon!=nil)
    {
        double sprScaleX=((double)sx)/((double)background->width);
        double sprScaleY=((double)sy)/((double)background->height);
		[background setResampling:resample];

		renderer->renderScaledRotatedImage(background, 0, sprScaleX, sprScaleY, 0, 0, x, y, background->width, background->height, 0, 0);
		renderer->renderScaledRotatedImage(icon, 0, 1, 1, 0, 0, x+SXLEFTIMAGE, y+sy/2-icon->height/2, icon->width, icon->height, 0, 0);

        int syLines=syText*2+SYBETWEEN;
        int yText=y+sy/2-syLines/2;
        [textSurface1 draw:renderer withX:x+SXLEFT+icon->width+SXBETWEEN andY:yText andEffect:0 andEffectParam:0];
        [textSurface2 draw:renderer withX:x+SXLEFT+icon->width+SXBETWEEN andY:yText+syText+SYBETWEEN andEffect:0 andEffectParam:0];
    }
}
-(void)spriteKill:(CSprite*)spr
{
    
}
-(CMask*)spriteGetMask
{
    return nil;
}


@end





