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
#import "CRunGameCenterAchievement.h"
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
#import "CSpriteGen.h"

#define CND_LAST 0
#define EXP_GETTITLE 0
#define EXP_GETDESCRIPTION1 1
#define EXP_GETDESCRIPTION2 2
#define EXP_GETMAXIMUMPOINTS 3
#define EXP_GETPERCENT 4

#define ACTION_WAITFORGAMECENTER 0
#define ACTION_WAITFORCOMMAND 1

@implementation CRunGameCenterAchievement

-(int)getNumberOfConditions
{
	return CND_LAST;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    [file skipBytes:4];
    images[0]=[file readAShort];
    images[1]=[file readAShort];
    [ho loadImageList:images withLength:2];    
    if (images[0]>=0)
    {
        CImage* img=[ho->hoAdRunHeader->rhApp->imageBank getImageFromHandle:images[0]];
        if (img!=nil)
        {
            ho->hoImgWidth=img->width;
            ho->hoImgHeight=img->height;
        }        
    }
    identifier=[file readAString];
    return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
    [identifier release];
}

-(int)handleRunObject
{
    switch(action)
    {
        case ACTION_WAITFORGAMECENTER:
            gameCenter=(CESGameCenter*)[rh getStorage:IDENTIFIER];
            if (gameCenter!=nil)
            {
                action=ACTION_WAITFORCOMMAND;
            }
            break;
    }
    return 0;
}

-(void)displayRunObject:(CRenderer*)renderer
{
    if (gameCenter!=nil)
    {
        int i;
        int percent=[gameCenter getAPercent:identifier];
        if (percent<100)
        {
            i=images[0];
        }
        else
        {
            i=images[1];
        }
        if (i>=0)
        {
            CRun* rhPtr=ho->hoAdRunHeader;
            int x=ho->hoX;
            int y=ho->hoY;
            [rhPtr->spriteGen pasteSpriteEffect:renderer withImage:i andX:x andY:y andFlags:0 andInkEffect:0 andInkEffectParam:0];
        }
    }
}

-(CValue*)getTitle
{
    CValue* ret=[rh getTempValue:0];
    [ret forceString:@""];
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
    if (gameCenter!=nil)
    {
        [ret forceString:[gameCenter getADescription2:identifier]];
    }
    return ret;
}
-(CValue*)getMaximumPoints
{
    CValue* ret=[rh getTempValue:0];
    if (gameCenter!=nil)
    {
        [ret forceInt:(int)[gameCenter getAMaximumPoints:identifier]];
    }
    return ret;
}
-(CValue*)getPercent
{
    CValue* ret=[rh getTempValue:0];
    if (gameCenter!=nil)
    {
        [ret forceDouble:[gameCenter getAPercent:identifier]];
    }
    return ret;
}

-(CValue*)expression:(int)num
{
    switch(num)
    {
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
    }
    return nil;
}


@end
