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
#import "CRunGameCenterConnect.h"
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
#import "MainViewController.h"

#define CND_LOCALPLAYERCON 0
#define CND_LOCALPLAYEROK 1
#define CND_FRIENDSLOADED 2
#define CND_INVITATIONSSENT 3
#define CND_LAST 4
#define ACT_AUTHENTICATE 0
#define ACT_LOADFRIENDS 1
#define ACT_RESETINVITATIONS 2
#define ACT_ADDINVITATION 3
#define ACT_SENDINVITATIONS 4
#define ACT_LAST 2
#define EXP_LPALIAS 0
#define EXP_LPID 1
#define EXP_NUMOFFRIENDS 2
#define EXP_FRIENDALIAS 3
#define EXP_FRIENDID 4
#define EXP_LAST 5

BOOL bAchievementsReceived=NO;

@implementation CESGameCenter

-(id)init:(id<IConnect>)c rh:(CRun*)rh
{
	if(self = [super init])
	{
		connect=c;
		rhPtr=rh;

		// Checks if the API is available
		BOOL localPlayerClassAvailable=(NSClassFromString(@"GKLocalPlayer"))!=nil;
		NSString* reqSysVer=@"4.1";
		NSString* curSysVer=[[UIDevice currentDevice] systemVersion];
		BOOL osVersionSupported=([curSysVer compare:reqSysVer options:NSNumericSearch]!=NSOrderedAscending);
		bAPIAvailable=(localPlayerClassAvailable&&osVersionSupported);


		localPlayer=nil;
		if (bAPIAvailable)
			localPlayer=[GKLocalPlayer localPlayer];

		friendsAlias=[[CArrayList alloc] init];
		friendsID=[[CArrayList alloc] init];
		nEntries=0;
		playerIndex=-1;
		disconnectedAlias = @"";
		isAuthenticating = NO;
	}
    return self;
}
-(void)dealloc
{
    if (friendsAlias!=nil)
    {
        [friendsAlias clearRelease];
        [friendsAlias release];
    }
    if (friendsID!=nil)
    {
        [friendsID clearRelease];
        [friendsID release];
    }
    if (lbScores!=nil)
    {
        [lbScores release];
    }
    if (lbNames!=nil)
    {
        [lbNames clearRelease];
        [lbNames release];
    }
    if (achievements!=nil)
    {
        [achievements clearRelease];
        [achievements release];
    }
    if (playerData!=nil)
    {
        [playerData release];
    }
    if (match!=nil)
    {
        [match release];
    }
	[disconnectedAlias release];
    [super dealloc];
}
-(void)setConnect:(id<IConnect>)c
{
    connect=c;
}
-(void)setLeaderboard:(id<ILeaderboard>)c
{
    leader=c;
}
-(void)setAchievements:(id<IAchievements>)c
{
    achievementsClass=c;
}
-(void)setMultiplayer:(id<IMultiplayer>)m
{
    multiplayer=m;
    if (m!=nil)
    {
        [GKMatchmaker sharedMatchmaker].inviteHandler=^(GKInvite* acceptedInvite, NSArray* playersToInvite)
        {
            if (acceptedInvite)
            {
                GKMatchmakerViewController* mmvc=[[[GKMatchmakerViewController alloc] initWithInvite:acceptedInvite] autorelease];
                mmvc.matchmakerDelegate=self;
                [rhPtr->rhApp->mainViewController presentViewController:mmvc animated:YES];
            }
        };
    }
}
-(void)authenticate
{
	NSThread* mainThread = [NSThread currentThread];
	if([localPlayer respondsToSelector:@selector(setAuthenticateHandler:)])
	{
		void (^gciOSsixBlock)(UIViewController*, NSError*) = ^(UIViewController* controller, NSError* error){

            if (error!=nil)
            {
				NSLog(@"GameCenter Error %i: %@", (int)error.code, [error description]);
                if(error.code == 15)
                {
                    [[[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error %i", (int)error.code] message:[error description] delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease] show];
                }
            }
            else
            {
                if ([localPlayer isAuthenticated])
                {
                    [self performSelector:@selector(didAuthenticate) onThread:mainThread withObject:nil waitUntilDone:NO];
                }
                if(controller != nil)
                {
                    [rhPtr->rhApp->mainViewController presentViewController:controller animated:YES];
                }
            }
		};
		if(isAuthenticating == NO)
		{
			isAuthenticating = YES;
			[localPlayer performSelector:@selector(setAuthenticateHandler:) withObject:gciOSsixBlock];
		}
	}
	else if([localPlayer respondsToSelector:@selector(authenticateWithCompletionHandler:)])
	{
		void (^gciOSfiveBlock)(NSError*) = ^(NSError *error) {
			NSLog(@"iOS 5 GameCenter");
            if (error!=nil)
            {
				NSLog(@"GameCenter Error %i: %@", (int)error.code, [error description]);
                if(error.code == 15)
                {
                    [[[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error %i", (int)error.code] message:[error description] delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease] show];
                }
            }
            else
            {
                if (localPlayer.isAuthenticated)
                {
                    [self performSelector:@selector(didAuthenticate) onThread:mainThread withObject:nil waitUntilDone:NO];
                }
            }
		};

		if(isAuthenticating == NO)
		{
			isAuthenticating = YES;
			[localPlayer performSelector:@selector(authenticateWithCompletionHandler:) withObject:gciOSfiveBlock];
		}
	}
}

-(void)didAuthenticate
{
	if (connect!=nil)
	{
		isAuthenticating = NO;
		[connect authenticated];
	}	
}

-(void)didReceiveFriends
{
	if (connect!=nil)
	{
		[connect friendsOK];
	}
}

-(void)didReceiveNames
{
	if (leader!=nil)
	{
		[leader namesReceived];
	}
}

-(void)didSendScores
{
	if (leader!=nil)
	{
		[leader scoreSent];
	}
}

-(void)didGetError
{
	if (leader!=nil)
	{
		[leader error];
	}
}

-(void)didGetScores
{
	if (leader!=nil)
	{
		[leader scoresReceived];
	}
}

-(void)didGetTitle
{
	if (leader!=nil)
	{
		[leader titleReceived];
	}
}

-(void)didSendAchivement
{
	if (achievementsClass!=nil)
	{
		[achievementsClass achievementSent];
	}
}

-(void)didReceiveAchivement
{
	if (achievementsClass!=nil)
	{
		[achievementsClass achievementsReceived];
	}
}

-(void)didReceiveDescriptions
{
	if (achievementsClass!=nil)
	{
		[achievementsClass descriptionsReceived];
	}
}

-(void)didGetAchivementError
{
	if (achievementsClass!=nil)
	{
		[achievementsClass error];
	}
}


-(void)freeIds
{
	for (int nn=0; nn<[ids count]; nn++)
	{
		NSString* s=(NSString*)[ids objectAtIndex:nn];
		[s release];
	}
	[ids release];
}

-(void)loadFriends
{
	NSThread* mainThread = [NSThread currentThread];
	[friendsAlias clearRelease];
	[friendsID clearRelease];
    if (localPlayer!=nil)
    {
        if (localPlayer.isAuthenticated)
        {
            [localPlayer loadFriendsWithCompletionHandler:^(NSArray* friends, NSError* error)
             {
				 if(friends!=nil)
				 {
					 [GKPlayer loadPlayersForIdentifiers:friends withCompletionHandler:^(NSArray *players, NSError *error) {
						 for (int n=0; n<[friends count]; n++)
						 {
							 GKPlayer* player= [players objectAtIndex:n];
							 [friendsAlias add:[[NSString alloc] initWithString:player.alias]];
							 [friendsID add:[[NSString alloc] initWithString:player.playerID]];
						 }
						 [self performSelector:@selector(didReceiveFriends) onThread:mainThread withObject:nil waitUntilDone:NO];
					 }];
                 }
             }
             ];
        }
    }
}
-(void)sendScore:(int)score category:(NSString*)category
{
    GKScore* scoreReporter=[[[GKScore alloc] initWithCategory:category] autorelease];
    scoreReporter.value=score;
	NSThread* mainThread = [NSThread currentThread];
    
    [scoreReporter reportScoreWithCompletionHandler:^(NSError* error)
     {
         if (error==nil)
         {
			 [self performSelector:@selector(didSendScores) onThread:mainThread withObject:nil waitUntilDone:NO];
         }   
         else
         {
			 [self performSelector:@selector(didGetError) onThread:mainThread withObject:nil waitUntilDone:NO];
         }
     }
     ];
}

-(void)getScores:(NSString*)category timeScope:(int)timeScope range:(NSRange)range
{
    GKLeaderboard* leaderboardRequest=[[GKLeaderboard alloc] init];        
    if (leaderboardRequest!=nil)
    {
        leaderboardRequest.playerScope=GKLeaderboardPlayerScopeGlobal;
        switch(timeScope)
        {
            case 0:
                leaderboardRequest.timeScope=GKLeaderboardTimeScopeToday;
                break;
            case 1:
                leaderboardRequest.timeScope=GKLeaderboardTimeScopeWeek;
                break;
            default:
                leaderboardRequest.timeScope=GKLeaderboardTimeScopeAllTime;
                break;    
        }
		leaderboardRequest.category = category;

		//Objects need to be created outside the game-center thread
		if (lbScores==nil)
		{
			lbScores=[[CArrayList alloc] init];
		}
		else
		{
			[lbScores clear];
		}
		if (lbNames==nil)
		{
			lbNames=[[CArrayList alloc] init];
		}
		else
		{
			[lbNames clearRelease];
		}
		
		NSThread* mainThread = [NSThread currentThread];
		
        [leaderboardRequest loadScoresWithCompletionHandler:^(NSArray* scores, NSError* error)
         {
            if (error==nil)
            {
                @synchronized(lbScores)
				{
					int n;
					ids=[[NSMutableArray alloc] init];
					for (n=0; n<[scores count]; n++)
					{
						GKScore* score=(GKScore*)[scores objectAtIndex:n];
						[lbScores addInt:(int)score.value];
						[ids addObject:[[NSString alloc] initWithString:score.playerID]];
					}
				}
                
                nEntries=leaderboardRequest.maxRange;
				[self performSelector:@selector(didGetScores) onThread:mainThread withObject:nil waitUntilDone:NO];

            }
            else
            {
                [self performSelector:@selector(didGetError) onThread:mainThread withObject:nil waitUntilDone:NO];
            }             
         }
         ];
    }
}

-(void)getNames
{
	NSThread* mainThread = [NSThread currentThread];
    [GKPlayer loadPlayersForIdentifiers:ids withCompletionHandler:^(NSArray* players, NSError* error)
     {
         int nn;
         if (error==nil)
         {
             for (nn=0; nn<[players count]; nn++)
             {
                 GKPlayer* player=(GKPlayer*)[players objectAtIndex:nn];
                 [lbNames add:[[NSString alloc] initWithString:player.alias]];
             }
             [self performSelector:@selector(didReceiveNames) onThread:mainThread withObject:nil waitUntilDone:NO];
         }
         else
         {
			[self performSelector:@selector(didGetError) onThread:mainThread withObject:nil waitUntilDone:NO];
         }
		 [self performSelector:@selector(freeIds) onThread:mainThread withObject:nil waitUntilDone:NO];
     }
     ];
}

-(NSString*)getLeaderboardName:(int)index
{
    if (lbNames!=nil)
    {
        if (index>=0 && index<[lbNames size])
        {
            return (NSString*)[lbNames get:index];
        }
    }
    return @"";
}
-(int)getLeaderboardScore:(int)index
{
    if (lbScores!=nil)
    {
        if (index>=0 && index<[lbScores size])
        {
            return [lbScores getInt:index];
        }
    }
    return 0;        
}
-(int)getLeaderboardNEntries
{
    return (int)nEntries;
}
                
-(void)getTitle:(NSString*)category
{
	NSThread* mainThread = [NSThread currentThread];


	if([GKLeaderboard respondsToSelector:@selector(loadLeaderboardsWithCompletionHandler:)])
	{

		void (^gciOSsixBlock)(NSArray*, NSError*) = ^(NSArray *leaderboards, NSError *error) {
			if(error != nil)
			{
				NSLog(@"Leaderboard error: %@", error);
				return;
			}
			for(GKLeaderboard* board in leaderboards)
			{
				if([category isEqualToString:board.category])
				{
					@synchronized(title)
					{
						if (title!=nil)
							[title release];
						title = [[NSString alloc] initWithString:board.title];
						[self performSelector:@selector(didGetTitle) onThread:mainThread withObject:nil waitUntilDone:NO];
					}
				}
			}
		};
		[[GKLeaderboard class] performSelector:@selector(loadLeaderboardsWithCompletionHandler:) withObject:gciOSsixBlock];
	}
	else if([GKLeaderboard respondsToSelector:@selector(loadCategoriesWithCompletionHandler:)])
	{
		void (^gciOSfiveBlock)(NSArray*, NSArray*, NSError*) = ^(NSArray *categories, NSArray *titles, NSError *error)
		{
			if (error==nil)
			{
				for (int n=0; n<[categories count]; n++)
				{
					NSString* c=(NSString*)[categories objectAtIndex:n];
					if ([category isEqualToString:c]==0)
					{
						@synchronized(title)
						{
							if (title!=nil)
								[title release];
							title=[[NSString alloc] initWithString:(NSString*)[titles objectAtIndex:n]];
						}
						break;
					}
				}
				[self performSelector:@selector(didGetTitle) onThread:mainThread withObject:nil waitUntilDone:NO];
			}
			else
			{
				[self performSelector:@selector(didGetError) onThread:mainThread withObject:nil waitUntilDone:NO];
			}
		};
		[[GKLeaderboard class] performSelector:@selector(loadCategoriesWithCompletionHandler:) withObject:gciOSfiveBlock];
	}
}
-(NSString*)getLeaderboardTitle
{
	@synchronized(title)
	{
		if (title!=nil)
		{
			return title;
		}
	}
    return @"";
}


// ACHIEVEMENTS
//////////////////////////////////////////////////////////////////////////
-(CAchievement*)findCAchievement:(NSString*)identifier
{
    if (achievements!=nil)
    {
        int nn;
        for (nn=0; nn<[achievements size]; nn++)
        {
            CAchievement* ach=(CAchievement*)[achievements get:nn];
            if ([ach->identifier isEqualToString:identifier])
            {
                return ach;
            }
        }
    }
    return nil;
}
-(int)findCAchievementIndex:(NSString*)identifier
{
    if (achievements!=nil)
    {
        int nn;
        for (nn=0; nn<[achievements size]; nn++)
        {
            CAchievement* ach=(CAchievement*)[achievements get:nn];
            if ([ach->identifier isEqualToString:identifier])
            {
                return nn;
            }
        }
    }
    return -1;
}
-(CAchievement*)getCAchievement:(int)index
{
    if (achievements!=nil)
    {
        if (index>=0 && index<[achievements size])
        {
            return (CAchievement*)[achievements get:index];
        }
    }
    return nil;
}
-(NSString*)getIdentifier:(int)index
{
    if (achievements!=nil)
    {
        if (index>=0 && index<[achievements size])
        {
            return ((CAchievement*)[achievements get:index])->identifier;
        }
    }
    return nil;
}
-(void)didCompleteAchivement
{
	if (achievementsClass!=nil)
	{
        int index;
        CAchievement* ach;
        for (index=0; index<[achievements size]; index++)
        {
            ach=(CAchievement*)[achievements get:index];
            if (ach->completed)
            {
                ach->completed=NO;
                [achievementsClass achievementCompleted:index];
            }
        }
	}
}

-(BOOL)sendAchievement:(GKAchievement*)achievement
{
	NSThread* mainThread = [NSThread currentThread];

    if (achievements==nil)
        return NO;
    
    int index;
    CAchievement* ach;
    for (index=0; index<[achievements size]; index++)
    {
        ach=(CAchievement*)[achievements get:index];
        if ([ach->identifier isEqualToString:achievement.identifier])
        {
            break;
        }
    }
    if (index>=[achievements size])
        return NO;
    
    achievement.percentComplete=MIN(achievement.percentComplete, 100);
    if (achievement.percentComplete<=ach->percent)
        return NO;
    
	[achievement reportAchievementWithCompletionHandler:^(NSError* error)
	 {
		 if (error==nil)
		 {
             int oldPercent=ach->percent;
             ach->percent=achievement.percentComplete;
			 [self performSelector:@selector(didSendAchivement) onThread:mainThread withObject:nil waitUntilDone:NO];
             if (oldPercent<100 && achievement.percentComplete>=100)
             {
                 ach->completed=YES;
                 [self performSelector:@selector(didCompleteAchivement) onThread:mainThread withObject:nil waitUntilDone:NO];
             }
		 }
		 else
		 {
			 [self performSelector:@selector(didGetAchivementError) onThread:mainThread withObject:nil waitUntilDone:NO];
		 }
	 }
	 ];
    return YES;
}
-(void)getAchievements
{
    if (bAchievementsReceived)
    {
        [self didReceiveAchivement];
    }
    else
    {
        [self getAchievementsForced];
    }
}
-(void)getAchievementsForced
{
	NSThread* mainThread = [NSThread currentThread];
    [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *array, NSError *error) 
    {
        if (error==nil)
        {
            if (achievements!=nil)
            {
                int n;
                for (n=0; n<[array count]; n++)
                {
                    GKAchievement* achievement=(GKAchievement*)[array objectAtIndex:n];
                
                    int nn;
                    for (nn=0; nn<[achievements size]; nn++)
                    {
                        CAchievement* ach=(CAchievement*)[achievements get:nn];
                        if ([ach->identifier isEqualToString:achievement.identifier])
                        {           
                            ach->percent=achievement.percentComplete;
                        }
                    }
                }
                [self performSelector:@selector(didReceiveAchivement) onThread:mainThread withObject:nil waitUntilDone:NO];
                bAchievementsReceived=YES;
            }
        }
        else
        {
			[self performSelector:@selector(didGetAchivementError) onThread:mainThread withObject:nil waitUntilDone:NO];
        }
    }
     ];
}
-(void)getDescriptions
{
	if (achievements!=nil)
    {
        [self didReceiveDescriptions];
        return;
    }
	achievements=[[CArrayList alloc] init];

    NSThread* mainThread = [NSThread currentThread];

    [GKAchievementDescription loadAchievementDescriptionsWithCompletionHandler:^(NSArray *array, NSError *error) 
    {
        if (error==nil)
        {
            int n;
            for (n=0; n<[array count]; n++)
            {
                GKAchievementDescription* description=(GKAchievementDescription*)[array objectAtIndex:n];
            
                CAchievement* achievement=[[CAchievement alloc] init];
                achievement->identifier=[[NSString alloc] initWithString:description.identifier];
                achievement->title=[[NSString alloc] initWithString:description.title];
                achievement->description1=[[NSString alloc] initWithString:description.unachievedDescription];
                achievement->description2=[[NSString alloc] initWithString:description.achievedDescription];
                achievement->maximumPoints=description.maximumPoints;
                achievement->percent=0;
                achievement->completed=NO;
                [achievements add:achievement];
            }                        
            [self performSelector:@selector(didReceiveDescriptions) onThread:mainThread withObject:nil waitUntilDone:NO];
        }
        else
        {
            [self performSelector:@selector(didGetAchivementError) onThread:mainThread withObject:nil waitUntilDone:NO];
        }
    }
     ];
}
-(NSString*)getATitle:(NSString*)identifier
{
    CAchievement* ach=[self findCAchievement:identifier];
    if (ach!=nil)
    {
        return ach->title;
    }
    return @"";
}
-(NSString*)getADescription1:(NSString*)identifier
{
    CAchievement* ach=[self findCAchievement:identifier];
    if (ach!=nil)
    {
        return ach->description1;
    }
    return @"";
}
-(NSString*)getADescription2:(NSString*)identifier
{
    CAchievement* ach=[self findCAchievement:identifier];
    if (ach!=nil)
    {
        return ach->description2;
    }
    return @"";
}
-(int)getAPercent:(NSString*)identifier
{
    CAchievement* ach=[self findCAchievement:identifier];
    if (ach!=nil)
    {
        return ach->percent;
    }
    return 0;
}
-(NSInteger)getAMaximumPoints:(NSString*)identifier
{
    CAchievement* ach=[self findCAchievement:identifier];
    if (ach!=nil)
    {
        return ach->maximumPoints;
    }
    return 0;
}
-(NSString*)getATitleIndex:(int)index
{
    CAchievement* ach=[self getCAchievement:index];
    if (ach!=nil)
    {
        return ach->title;
    }
    return @"";
}
-(NSString*)getADescription1Index:(int)index
{
    CAchievement* ach=[self getCAchievement:index];
    if (ach!=nil)
    {
        return ach->description1;
    }
    return @"";
}
-(NSString*)getADescription2Index:(int)index
{
    CAchievement* ach=[self getCAchievement:index];
    if (ach!=nil)
    {
        return ach->description2;
    }
    return @"";
}
-(int)getAPercentIndex:(int)index
{
    CAchievement* ach=[self getCAchievement:index];
    if (ach!=nil)
    {
        return ach->percent;
    }
    return 0;
}
-(int)getAMaximumPointsIndex:(int)index
{
    CAchievement* ach=[self getCAchievement:index];
    if (ach!=nil)
    {
        return (int)ach->maximumPoints;
    }
    return 0;
}
-(int)getNAchievements
{
    if (achievements!=nil)
    {
        return [achievements size];
    }
    return 0;
}

-(void)didResetAchievements
{
	if (achievementsClass!=nil)
	{
		[achievementsClass resetCompleted];
	}
}

-(void)resetAchievements
{
    if (achievements!=nil)
    {
		NSThread* mainThread = [NSThread currentThread];

		[GKAchievement resetAchievementsWithCompletionHandler:^(NSError* error)
		{
			if (error==nil)
			{
                int m;
                for (m=0; m<[achievements size]; m++)
                {
                    CAchievement* ach2=(CAchievement*)[achievements get:m];
                    ach2->percent=0;
                }
				[self performSelector:@selector(didResetAchievements) onThread:mainThread withObject:nil waitUntilDone:NO];
            }
        }];		
	}
}

// MULTIPLAYER
//////////////////////////////////////////////////////////////////
-(void)setMultiplayerData:(int)min max:(int)max group:(int)g
{
    minPlayers=min;
    maxPlayers=max;
    group=g;
}
-(void)freePlayers
{
    if (matchPlayers!=nil)
    {
        [matchPlayers clearRelease];
    }
    else
    {
        matchPlayers=[[CArrayList alloc] init];
    }
}
-(void)displayMatch
{
    GKMatchRequest* request=[[[GKMatchRequest alloc] init] autorelease];
    request.minPlayers=minPlayers;
    request.maxPlayers=maxPlayers;
    request.playerGroup=group;
    [self freePlayers];
    
    GKMatchmakerViewController* mmvc=[[[GKMatchmakerViewController alloc] initWithMatchRequest:request] autorelease];
    mmvc.matchmakerDelegate=self;
    [rhPtr->rhApp->mainViewController presentViewController:mmvc animated:YES];
    [rhPtr pause];
}
-(void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)m
{
    [rhPtr resume];
    [rhPtr->rhApp->mainViewController dismissViewControllerAnimated:YES];
    match = [m retain];
    match.delegate=self;
    nPlayers=maxPlayers-match.expectedPlayerCount;
    if (match.expectedPlayerCount==0)
    {
        bStartMatch=YES;
        [self findNames:match.playerIDs];
    }
}
-(void)matchmakerViewController:(GKMatchmakerViewController *)viewController didReceiveAcceptFromHostedPlayer:(NSString *)playerID
{
	//NSLog(@"Did receive accept from hosted player");
}

-(void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController
{
    match=nil;
    [rhPtr resume];
    [rhPtr->rhApp->mainViewController dismissViewControllerAnimated:YES];
}
-(void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    match=nil;
    [rhPtr resume];
    [rhPtr->rhApp->mainViewController dismissViewControllerAnimated:YES];
    if (multiplayer!=nil)
    {
        [multiplayer error];
    }
}

-(void)disconnectMultiplayer
{
	if(multiplayer != nil && match != nil)
		[match disconnect];
}

-(void)findMatch
{
    [self freePlayers];
    
    GKMatchRequest* request=[[[GKMatchRequest alloc] init] autorelease];
    request.minPlayers=minPlayers;
    request.maxPlayers=maxPlayers;
    request.playerGroup=group;
    [[GKMatchmaker sharedMatchmaker] findMatchForRequest:request withCompletionHandler:^(GKMatch *m, NSError *error) 
    {
        if (error==nil && m!=nil)
        {
            match = [m retain];
            match.delegate=self;
            bStartMatch=YES;
            [self findNames:match.playerIDs];
        }
    }
     ];
}
-(void)findNames:(NSArray*)matchIds
{
	NSThread* mainThread = [NSThread currentThread];
    if (matchIds!=nil)
    {
        [GKPlayer loadPlayersForIdentifiers:matchIds withCompletionHandler:^(NSArray* players, NSError* error)
         {
			 if (error==nil)
             {
                 [self freePlayers];
                 for (int nn=0; nn<[players count]; nn++)
                 {
                     GKPlayer* player=(GKPlayer*)[players objectAtIndex:nn];
                     [matchPlayers add:[player retain]];
                 }
                 if (multiplayer!=nil)
                 {
                     if (bPlayerConnected)
                     {      
                         bPlayerConnected=NO;
						 [(id)multiplayer performSelector:@selector(playerConnected) onThread:mainThread withObject:nil waitUntilDone:YES];
                     }  
                     if (bStartMatch)
                     {
                         bStartMatch=NO;
						 [(id)multiplayer performSelector:@selector(matchStarted) onThread:mainThread withObject:nil waitUntilDone:YES];
                     }
                 }
             }
         }
         ];
    }
}

-(void)addPlayers
{
    if (match!=nil)
    {
        GKMatchRequest* request=[[[GKMatchRequest alloc] init] autorelease];
        request.minPlayers=minPlayers;
        request.maxPlayers=maxPlayers;
        request.playerGroup=group;
        [[GKMatchmaker sharedMatchmaker] addPlayersToMatch:match matchRequest:request completionHandler:^(NSError * error)
        {
             if (error==nil)
             {
                 if (match.expectedPlayerCount==0)
                 {
                     [self findNames:match.playerIDs];
                 }
             }
         }
         ];        
    }
}

-(int)getNPlayers
{
    if (matchPlayers!=nil)
    {
        return [matchPlayers size]+1;
    }
    return 0;
}
-(NSString*)getPlayerAlias:(int)index
{
    if (matchPlayers!=nil)
    {
		if(index == 0)
		{
			if(localPlayer != nil)
				return [localPlayer alias];
		}
		else
		{
			GKPlayer* player = (GKPlayer*)[matchPlayers get:index-1];
			if(player != nil)
				return player.alias;
		}
    }
    return @"";
}

-(void)match:(GKMatch*)m didReceiveData:(NSData*)data fromPlayer:(NSString*)playerID
{
    int n;
    if (matchPlayers!=nil)
    {
        for (n=0; n<[matchPlayers size]; n++)
        {
			GKPlayer* player = (GKPlayer*)[matchPlayers get:n];
            if (player != nil && [playerID isEqualToString:player.playerID])
            {
                playerIndex=n;
                playerData=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (multiplayer!=nil)
                {
                    [multiplayer dataReceived];
                }
                break;
            }
        }
    }
}

-(void)match:(GKMatch*)m player:(NSString*)playerID didChangeState:(GKPlayerConnectionState)state
{
	NSThread* mainThread = [NSThread currentThread];

    if (matchPlayers!=nil)
    {
		switch (state)
		{
			case GKPlayerStateUnknown:
				//NSLog(@"Unknown state for: %@", playerID);
				break;

			case GKPlayerStateConnected:
			{
				[GKPlayer loadPlayersForIdentifiers:[NSArray arrayWithObject:playerID] withCompletionHandler:^(NSArray* players, NSError* error)
				 {
					 if (multiplayer!=nil)
					 {
						 for (int nn=0; nn<[players count]; nn++)
						 {
							 GKPlayer* player=(GKPlayer*)[players objectAtIndex:nn];
							 [matchPlayers add:[player retain]];
							 playerIndex = matchPlayers.size-1;
							 [(id)multiplayer performSelector:@selector(playerConnected) onThread:mainThread withObject:nil waitUntilDone:YES];
						 }
					 }
					 //The last player connected - start match (iOS5 behavior)
					 if (match.expectedPlayerCount==0)
					 {
						 bStartMatch=YES;
						 [self findNames:match.playerIDs];
					 }
				 }];
				 break;
			}

			case GKPlayerStateDisconnected:
			{
				for (int n=0; n<[matchPlayers size]; n++)
				{
					GKPlayer* player = (GKPlayer*)[matchPlayers get:n];
					if (player != nil && [playerID isEqualToString:player.playerID])
					{
						//NSLog(@"Player disconnected: %@", player);

						[disconnectedAlias release];
						disconnectedAlias = [[player alias] retain];
						playerIndex=n;

						if (multiplayer!=nil)
							[multiplayer playerDisconnected];

						[matchPlayers removeIndexRelease:n];
						break;
					}
				}
				break;
			}
		}
    }
}

-(void)match:(GKMatch*)m didFailWithError:(NSError *)error
{
    if (multiplayer!=nil)
    {
		//NSLog(@"Match failed with error: %@", error);
        [multiplayer error];
    }
}

-(void)match:(GKMatch*)m connectionWithPlayerFailed:(NSString *)playerID withError:(NSError *)error
{
    if (multiplayer!=nil)
    {
		//NSLog(@"Connection with player: %@ failed", playerID);
        [multiplayer error];
    }
}

-(void)sendAllPlayers:(NSString*)string dataMode:(GKMatchSendDataMode)mode
{
    NSError* pError = nil;
    if (match!=nil)
    {
        NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        [match sendDataToAllPlayers:data withDataMode:mode error:&pError];
        if (pError!=nil)
        {
            if (multiplayer!=nil)
            {
                [multiplayer error];
            }
        }
    }
}
-(void)sendPlayer:(int)index data:(NSString*)string dataMode:(GKMatchSendDataMode)mode
{
    if (match!=nil)
    {
        if (matchPlayers!=nil)
        {
            NSError* pError = nil;
			GKPlayer* player = (GKPlayer*)[matchPlayers get:index];
			if(player != nil)
			{
				NSString* playerID= player.playerID;
				NSArray* array=[NSArray arrayWithObject:playerID];
				NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
				[match sendData:data toPlayers:array withDataMode:mode error:&pError];
				if (pError!=nil)
				{
					if (multiplayer!=nil)
					{
						[multiplayer error];
					}
				}
			}
        }
    }
}
-(NSString*)getData
{
    if (playerData!=nil)
    {
        return playerData;
    }
    return @"";
}
-(int)getPlayerIndex
{
    return (int)playerIndex;
}
    
@end

@implementation CRunGameCenterConnect

-(int)getNumberOfConditions
{
	return CND_LAST;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    // Read EditData
    [file skipBytes:4];
    [file skipBytes:4];
    flags=[file readAInt];
    localPlayerCount=-1;
    friendsCount=-1;
    invitationsSentCount=-1;
    invitations=nil;

    gameCenter=(CESGameCenter*)[ho->hoAdRunHeader getStorage:IDENTIFIER];
    if (gameCenter==nil)
    {
        gameCenter=[[CESGameCenter alloc] init:self rh:ho->hoAdRunHeader];
        [ho->hoAdRunHeader addStorage:gameCenter withID:IDENTIFIER];
    }
    else
    {
        [gameCenter setConnect:self];
    }
    
    if (flags&GCFLAG_AUTHENTICATE)
    {
        [gameCenter authenticate];
    }
    return TRUE;
}

-(void)destroyRunObject:(BOOL)bFast
{
    [gameCenter setConnect:nil];
    if (invitations!=nil)
    {
        [invitations release];
    }
}
             
             

// Conditions 
//////////////////////////////////////////////////////////////////
-(void)authenticated
{
    localPlayerCount=[ho getEventCount];
    [ho pushEvent:CND_LOCALPLAYERCON withParam:0];    
}
-(void)friendsOK
{
    friendsCount=[ho getEventCount];
    [ho pushEvent:CND_FRIENDSLOADED withParam:0];    
}
-(BOOL)invitationsSent
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == invitationsSentCount)
	{
		return YES;
	}
	return NO;    
}
-(BOOL)friendsLoaded
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == friendsCount)
	{
		return YES;
	}
	return NO;    
}
-(BOOL)localPlayerCon
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == localPlayerCount)
	{
		return YES;
	}
	return NO;    
}
-(BOOL)localPlayerOK
{
    if (gameCenter->localPlayer!=nil)
    {
        return gameCenter->localPlayer.isAuthenticated;
    }
    return NO;
}
-(BOOL)condition:(int)num withCndExtension:(CCndExtension *)cnd
{
    switch(num)
    {
        case CND_LOCALPLAYERCON:
            return [self localPlayerCon];
        case CND_LOCALPLAYEROK:
            return [self localPlayerOK];
        case CND_FRIENDSLOADED:
            return [self friendsLoaded];
        case CND_INVITATIONSSENT:
            return [self invitationsSent];
    }
    return NO;
}

// Actions
/////////////////////////////////////////////////////////////////
-(void)resetInvitations
{
    if (invitations!=nil)
    {
        [invitations removeAllObjects];
    }
}
-(void)addInvitation:(CActExtension*)act
{
    int num=[act getParamExpression:rh withNum:0];
    if (invitations==nil)
    {
        invitations=[[NSMutableArray alloc] init];
    }
    if (gameCenter->localPlayer!=nil)
    {
        if (gameCenter->localPlayer.isAuthenticated)
        {
            if (gameCenter->friendsID!=nil)
            {
                if (num>=0 && num<[gameCenter->friendsID size])
                {
                    [invitations addObject:(id)[gameCenter->friendsID get:num]];
                }
            }
        }
    }
}
-(void)sendInvitations
{
    NSString* reqSysVer=@"4.2";
    NSString* curSysVer=[[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported=([curSysVer compare:reqSysVer options:NSNumericSearch]!=NSOrderedAscending);    
    if (osVersionSupported==NO)
    {
        return;
    }
    if (invitations==nil)
    {
        return;
    }
    if ([invitations count]==0)
    {
        return;
    }
    
    if (gameCenter->localPlayer.isAuthenticated)
    {
        GKFriendRequestComposeViewController* friendRequestController=[[GKFriendRequestComposeViewController alloc] init];
        friendRequestController.composeViewDelegate=self;
        [ho->hoAdRunHeader pause];
        [ho->hoAdRunHeader->rhApp->mainViewController presentViewController:friendRequestController animated:YES];
        [friendRequestController release];
    }
}
-(void)friendRequestComposeViewControllerDidFinish:(GKFriendRequestComposeViewController*)controller
{
    [ho->hoAdRunHeader->rhApp->mainViewController dismissViewControllerAnimated:YES];
    [ho->hoAdRunHeader resume];
    invitationsSentCount=[ho getEventCount];
    [ho pushEvent:CND_INVITATIONSSENT withParam:0];    
}

-(void)action:(int)num withActExtension:(CActExtension *)act
{
    switch (num)
    {
        case ACT_AUTHENTICATE:
            [gameCenter authenticate];
            break;
        case ACT_LOADFRIENDS:
            [gameCenter loadFriends];
            break;
        case ACT_RESETINVITATIONS:
            [self resetInvitations];
            break;
        case ACT_ADDINVITATION:
            [self addInvitation:act];
            break;
        case ACT_SENDINVITATIONS:
            [self sendInvitations];
            break;
    }
}

// Expressions
//////////////////////////////////////////////////////////////////
-(CValue*)getAlias
{
    CValue* ret=[rh getTempValue:0];
    [ret forceString:@""];
    if (gameCenter->localPlayer!=nil)
    {
        if (gameCenter->localPlayer.isAuthenticated)
        {
            [ret forceString:gameCenter->localPlayer.alias];
        }
    }
    return ret;
}
-(CValue*)getID
{
    CValue* ret=[rh getTempValue:0];
    [ret forceString:@""];
    if (gameCenter->localPlayer!=nil)
    {
        if (gameCenter->localPlayer.isAuthenticated)
        {
            [ret forceString:gameCenter->localPlayer.playerID];
        }
    }
    return ret;
}
-(CValue*)getFriendsCount
{
    CValue* ret=[rh getTempValue:0];
    if (gameCenter->localPlayer!=nil)
    {
        if (gameCenter->localPlayer.isAuthenticated)
        {
            if (gameCenter->friendsAlias!=nil)
            {
                [ret forceInt:[gameCenter->friendsAlias size]];
            }
        }
    }
    return ret;
}
-(CValue*)getFriendAlias
{
    CValue* ret=[rh getTempValue:0];
    [ret forceString:@""];
    int index=[[ho getExpParam] getInt];
    if (index>=0)
    {
        if (gameCenter->localPlayer!=nil)
        {
            if (gameCenter->localPlayer.isAuthenticated)
            {
                if (gameCenter->friendsAlias!=nil)
                {
                    NSString* alias=(NSString*)[gameCenter->friendsAlias get:index];
                    if (alias!=nil)
                    {
                        [ret forceString:alias];
                    }
                }
            }
        }
    }
    return ret;
}
-(CValue*)getFriendID
{
    CValue* ret=[rh getTempValue:0];
    [ret forceString:@""];
    int index=[[ho getExpParam] getInt];
    if (index>=0)
    {
        if (gameCenter->localPlayer!=nil)
        {
            if (gameCenter->localPlayer.isAuthenticated)
            {
                if (gameCenter->friendsAlias!=nil)
                {
                    NSString* ID=(NSString*)[gameCenter->friendsID get:index];
                    if (ID!=nil)
                    {
                        [ret forceString:ID];
                    }
                }
            }
        }
    }
    return ret;
}
-(CValue*)expression:(int)num
{
    switch(num)
    {
        case EXP_LPALIAS:
            return [self getAlias];
        case EXP_LPID:
            return [self getID];
        case EXP_NUMOFFRIENDS:
            return [self getFriendsCount];
        case EXP_FRIENDALIAS:
            return [self getFriendAlias];
        case EXP_FRIENDID:
            return [self getFriendID];
    }
    return nil;
}
@end

@implementation CAchievement

-(void)dealloc
{
    [title release];
    [identifier release];
    [description1 release];
    [description2 release];
    [super dealloc];
}

@end

