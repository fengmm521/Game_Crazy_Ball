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
// CRunGameCenterConnect
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"
#import "GameKit/GameKit.h"
#import "CExtStorage.h"

@protocol IConnect	
-(void)authenticated;
-(void)friendsOK;
@end
@protocol ILeaderboard
-(void)scoreSent;
-(void)scoresReceived;
-(void)namesReceived;
-(void)titleReceived;
-(void)error;
@end
@protocol IAchievements
-(void)achievementSent;
-(void)achievementsReceived;
-(void)descriptionsReceived;
-(void)resetCompleted;
-(void)achievementCompleted:(int)index;
-(void)error;
@end
@protocol IMultiplayer
-(void)matchStarted;
-(void)matchChanged;
-(void)playerConnected;
-(void)playerDisconnected;
-(void)dataReceived;
-(void)error;
@end


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

#define GCFLAG_AUTHENTICATE 0x0001
#define GCFLAG_CONNECTOK 0x0002
#define IDENTIFIER 0x4743434E

@interface CRunGameCenterConnect : CRunExtension <GKFriendRequestComposeViewControllerDelegate, IConnect >
{  
    int flags;
    int localPlayerCount;
    int friendsCount;
    int invitationsSentCount;
	int resetAChievements;
    CESGameCenter* gameCenter;
    NSMutableArray* invitations;
}
-(void)authenticated;
-(void)friendsOK;
@end


@interface CAchievement : NSObject
{
@public
    NSString* identifier;
    NSString* title;
    NSString* description1;
    NSString* description2;
    double percent;
    NSInteger maximumPoints;
    BOOL completed;
}
@end

@interface CESGameCenter : CExtStorage <GKMatchmakerViewControllerDelegate, GKMatchDelegate>
{
@public    
    GKLocalPlayer* localPlayer;
    id<IConnect> connect;
    id<ILeaderboard> leader;
    id<IAchievements> achievementsClass;
    id<IMultiplayer> multiplayer;
    BOOL bAPIAvailable;
    CArrayList* friendsAlias;
    CArrayList* friendsID;
    CArrayList* lbNames;
    CArrayList* lbScores;
    NSUInteger nEntries;
    NSMutableArray* ids;
    NSString* title;
    CRun* rhPtr;
    CArrayList* achievements;
    NSUInteger minPlayers;
    NSUInteger maxPlayers;
    NSUInteger group;
    GKMatch* match;
    NSUInteger nPlayers;
	CArrayList* matchPlayers;		//Array of GKPlayer objects
    NSUInteger playerIndex;
    NSString* playerData;
	NSString* disconnectedAlias;
    BOOL bPlayerConnected;
    BOOL bStartMatch;
    int resetAchievements;
	BOOL isAuthenticating;
}
-(id)init:(id<IConnect>)c rh:(CRun*)rh;
-(void)authenticate;
-(void)loadFriends;
-(void)setLeaderboard:(id<ILeaderboard>)leaderboard;
-(void)setAchievements:(id<IAchievements>)ach;
-(void)sendScore:(int)score category:(NSString*)category;
-(void)getScores:(NSString*)category timeScope:(int)timeScope range:(NSRange)range;
-(void)getNames;
-(NSString*)getLeaderboardName:(int)index;
-(int)getLeaderboardScore:(int)index;
-(int)getLeaderboardNEntries;
-(NSString*)getLeaderboardTitle;
-(void)getTitle:(NSString*)category;
-(BOOL)sendAchievement:(GKAchievement*)achievement;
-(void)getAchievements;
-(void)getAchievementsForced;
-(void)getDescriptions;
-(NSInteger)getAMaximumPoints:(NSString*)identifier;
-(int)getAPercent:(NSString*)identifier;
-(NSString*)getADescription2:(NSString*)identifier;
-(NSString*)getADescription1:(NSString*)identifier;
-(NSString*)getATitle:(NSString*)identifier;
-(int)getAMaximumPointsIndex:(int)identifier;
-(int)getAPercentIndex:(int)identifier;
-(NSString*)getADescription2Index:(int)identifier;
-(NSString*)getADescription1Index:(int)identifier;
-(NSString*)getATitleIndex:(int)identifier;
-(int)getNAchievements;
-(void)setMultiplayer:(id<IMultiplayer>) m;
-(void)setMultiplayerData:(int)min max:(int)max group:(int)g;
-(void)displayMatch;
-(void)findMatch;
-(void)disconnectMultiplayer;
-(void)findNames:(NSArray*)matchIds;
-(void)addPlayers;
-(int)getNPlayers;
-(NSString*)getPlayerAlias:(int)index;
-(void)sendAllPlayers:(NSString*)string dataMode:(GKMatchSendDataMode)mode;
-(void)sendPlayer:(int)index data:(NSString*)string dataMode:(GKMatchSendDataMode)mode;
-(NSString*)getData;
-(int)getPlayerIndex;
-(CAchievement*)findCAchievement:(NSString*)identifier;
-(int)findCAchievementIndex:(NSString*)identifier;
-(CAchievement*)getCAchievement:(int)index;
-(void)resetAchievements;
-(NSString*)getIdentifier:(int)index;

-(void)didAuthenticate;
-(void)didReceiveFriends;
-(void)didReceiveNames;
-(void)didSendScores;
-(void)didGetError;
-(void)didGetScores;
-(void)didGetTitle;
-(void)didSendAchivement;
-(void)didReceiveAchivement;
-(void)didReceiveDescriptions;
-(void)didGetAchivementError;
-(void)freeIds;

@end
