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
// CRunGameCenterAchievements
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"
#import "CRunGameCenterConnect.h"
#import "GameKit/GameKit.h"
#import "IDrawable.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CFontInfo;
@class CBitmap;
@class CImage;
@class CESGameCenter;
@class CArrayList;
@class CRun;
@class CESGameCenter;
@class CTextSurface;
@class CSpriteGen;
@class CSprite;
@class CFont;

@interface CRunGameCenterAchievements : CRunExtension <IAchievements, GKAchievementViewControllerDelegate>
{
@public
    CESGameCenter* gameCenter; 
    int achievementSentCount;
    int achievementsReceivedCount;
    int descriptionsReceivedCount;
    int achievementsResetCount;
    int achievementCompletedCount;
    int errorCount;
    CArrayList* queuedAchivements;
    int flags;
    int eFlags;
    int action;
    int currentCompleted;
    short images[2];
    short* iconImages;
    NSString* title;
    NSString* string;
    CArrayList* banners;
    CArrayList* nextBanners;
    CFontInfo* titleFont;
    CFontInfo* textFont;
    int titleColor;
    int stringColor;
    int duration;
    BOOL bLoaded;
}

@end

@interface CBanner : NSObject <IDrawable>
{
@public
    CRunGameCenterAchievements* rdPtr;
    CSprite* sprite;
    int xx, yy, sx, sy;
    int step;
    int yDisplay;
    int yDest, yMiddle;
    double speed;
    double angle;
    int length;
    int index;
    CSpriteGen* spriteGen;
    CTextSurface* textSurface1;
    CTextSurface* textSurface2;
    int syText;
    NSString* title;
    NSString* string;
    double timeStart;
    short iconImage;
}
-(id)initWithRunData:(CRunGameCenterAchievements*)rdPtr andIndex:(int)i;
-(BOOL)handle;
-(void)spriteDraw:(CRenderer*)renderer withSprite:(CSprite*)spr andImageBank:(CImageBank*)bank andX:(int)x andY:(int)y;
-(void)spriteKill:(CSprite*)spr;
-(CMask*)spriteGetMask;
-(void)dealloc;

@end

@interface CRunAch : CRunExtension
{
@public
    short images[2];
    NSString* identifier;
    int action;
    CESGameCenter* gameCenter;
}
@end

@interface CAchievementIcon : NSObject
{
@public
    NSString* identifier;
    short image;
}
@end
