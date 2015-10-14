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
#import <Foundation/Foundation.h>
#import "CRunExtension.h"
#import "CRunGameCenterConnect.h"
#import "GameKit/GameKit.h"

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

@interface CRunGameCenterLeaderboard : CRunExtension <GKLeaderboardViewControllerDelegate, ILeaderboard>
{
    CESGameCenter* gameCenter; 
    int flags;
    short timeScope;
    short NbScores;
    short NameSize;
    CFontInfo* Logfont;
    int colorref;
    NSString* category;
    int action;
    BOOL bScoresReceived;
    BOOL bUpdated;
    CTextSurface* textSurface;
    NSRange range;
    int scoreSentCount;
    int scoresReceivedCount;
    int titleReceivedCount;
    int errorCount;
    int scoreSet;
}
-(void)error;
-(void)scoreSent;
-(void)scoresReceived;
-(void)titleReceived;

@end
