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
#import "CRunGameCenterMultiplayer.h"
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

#define CND_MATCHSTARTED 0
#define CND_MATCHCHANGED 1
#define CND_PLAYERCONNECTED 2
#define CND_PLAYERDISCONNECTED 3
#define CND_DATARECEIVED 4
#define CND_ERROR 5
#define CND_LAST 6

#define ACT_DISPLAYMATCH 0
#define ACT_FINDMATCH 1
#define ACT_ADDPLAYERS 2
#define ACT_SENDUNRELIABLE 3
#define ACT_SENDRELIABLE 4
#define ACT_SENDALLUNRELIABLE 5
#define ACT_SENDALLRELIABLE 6
#define ACT_SETMINPLAYERS 7
#define ACT_SETMAXPLAYERS 8
#define ACT_SETGROUP 9
#define ACT_DISCONNECT 10

#define EXP_GETNPLAYERS 0
#define EXP_GETPLAYERALIAS 1
#define EXP_GETDATA 2
#define EXP_GETPLAYERINDEX 3
#define EXP_GETDISCONNECTEDALIAS 4
#define EXP_GETALIASLASTEVENT 5


#define ACTION_WAITFORGAMECENTER 0
#define ACTION_WAITFORAUTHENTICATION 1
#define ACTION_WAITFORCOMMAND 2

#define FLAG_DISPLAYMATCH 0x0001
#define FLAG_FINDMATCH 0x0002
#define FLAG_ADDPLAYERS 0x0004
#define FLAG_FINDNAMES 0x0008
#define FLAG_DISCONNECT 0x0010

@implementation CRunGameCenterMultiplayer


-(int)getNumberOfConditions
{
	return CND_LAST;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    [file skipBytes:4];
    minPlayers=[file readAShort];
    maxPlayers=[file readAShort];
    group=[file readAInt];
    matchStartedCount=-1;
    matchChangedCount=-1;
    playerConnectedCount=-1;
    playerDisconnectedCount=-1;
    dataReceivedCount=-1;
    errorCount=-1;
    bOK=NO;
    return YES;
}

-(int)handleRunObject
{
    switch(action)
    {
        case ACTION_WAITFORGAMECENTER:
            gameCenter=(CESGameCenter*)[rh getStorage:IDENTIFIER];
            if (gameCenter!=nil)
            {
                [gameCenter setMultiplayer:self];
                action=ACTION_WAITFORAUTHENTICATION;
            }
            break;
        case ACTION_WAITFORAUTHENTICATION:
            if (gameCenter->localPlayer!=nil)
            {
                if (gameCenter->localPlayer.isAuthenticated)
                {
                    action=ACTION_WAITFORCOMMAND;
                    bOK=YES;
                    [gameCenter setMultiplayerData:minPlayers max:maxPlayers group:group];
                }
            }
            break;
        case ACTION_WAITFORCOMMAND:
            if (flags&FLAG_DISPLAYMATCH)
            {
                flags&=~FLAG_DISPLAYMATCH;
                [gameCenter displayMatch];
            }
            if (flags&FLAG_FINDMATCH)
            {
                flags&=~FLAG_FINDMATCH;
                [gameCenter findMatch];
            }
            if (flags&FLAG_ADDPLAYERS)
            {
                flags&=~FLAG_ADDPLAYERS;
                [gameCenter addPlayers];
            }
			if (flags&FLAG_DISCONNECT)
            {
                flags&=~FLAG_DISCONNECT;
                [gameCenter disconnectMultiplayer];
            }
            break;
    }
    return 0;
}


-(void)matchStarted
{
    matchStartedCount=[ho getEventCount];
    [ho generateEvent:CND_MATCHSTARTED withParam:0];
}
-(void)matchChanged
{
    matchChangedCount=[ho getEventCount];
    [ho generateEvent:CND_MATCHCHANGED withParam:0];
}
-(void)playerConnected
{
    playerConnectedCount=[ho getEventCount];
    [ho generateEvent:CND_PLAYERCONNECTED withParam:0];
}
-(void)playerDisconnected
{
    playerDisconnectedCount=[ho getEventCount];
    [ho generateEvent:CND_PLAYERDISCONNECTED withParam:0];
}
-(void)dataReceived
{
    dataReceivedCount=[ho getEventCount];
    [ho generateEvent:CND_DATARECEIVED withParam:0];
}
-(void)error
{
    errorCount=[ho getEventCount];
    [ho generateEvent:CND_ERROR withParam:0];
}
-(BOOL)matchStartedCnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == matchStartedCount)
	{
		return YES;
	}
	return NO;    
}
-(BOOL)matchChangedCnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == matchChangedCount)
	{
		return YES;
	}
	return NO;    
}
-(BOOL)playerConnectedCnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == playerConnectedCount)
	{
		return YES;
	}
	return NO;    
}
-(BOOL)playerDisconnectedCnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == playerDisconnectedCount)
	{
		return YES;
	}
	return NO;    
}
-(BOOL)dataReceivedCnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == dataReceivedCount)
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
        case CND_MATCHSTARTED:
            return [self matchStartedCnd];
        case CND_MATCHCHANGED:
            return [self matchChangedCnd];
        case CND_PLAYERCONNECTED:
            return [self playerConnectedCnd];
        case CND_PLAYERDISCONNECTED:
            return [self playerDisconnectedCnd];
        case CND_DATARECEIVED:
            return [self dataReceivedCnd];
        case CND_ERROR:
            return [self errorCnd];
    }
    return NO;
}


-(void)actDisplayMatch
{
    flags|=FLAG_DISPLAYMATCH;
}
-(void)actFindMatch
{
    flags|=FLAG_FINDMATCH;
}
-(void)actAddPlayers
{
    flags|=FLAG_ADDPLAYERS;
}

-(void)actDisconnect
{
    flags|=FLAG_DISCONNECT;
}
-(void)actSendUnreliable:(CActExtension*)act
{
    int index=[act getParamExpression:rh withNum:0];
    NSString* data=[act getParamExpString:rh withNum:1];
    if (gameCenter!=nil)
    {
        if (gameCenter->localPlayer!=nil)
        {
            if (gameCenter->localPlayer.isAuthenticated)
            {
                [gameCenter sendPlayer:index data:data dataMode:GKMatchSendDataUnreliable];
            }
        }
    }
}
-(void)actSendReliable:(CActExtension*)act
{
    int index=[act getParamExpression:rh withNum:0];
    NSString* data=[act getParamExpString:rh withNum:1];
    if (gameCenter!=nil)
    {
        if (gameCenter->localPlayer!=nil)
        {
            if (gameCenter->localPlayer.isAuthenticated)
            {
                [gameCenter sendPlayer:index data:data dataMode:GKMatchSendDataReliable];
            }
        }
    }
}
-(void)actSendAllUnreliable:(CActExtension*)act
{
    NSString* data=[act getParamExpString:rh withNum:0];
    if (gameCenter!=nil)
    {
        if (gameCenter->localPlayer!=nil)
        {
            if (gameCenter->localPlayer.isAuthenticated)
            {
                [gameCenter sendAllPlayers:data dataMode:GKMatchSendDataUnreliable];
            }
        }
    }
}
-(void)actSendAllReliable:(CActExtension*)act
{
    NSString* data=[act getParamExpString:rh withNum:0];
    if (gameCenter!=nil)
    {
        if (gameCenter->localPlayer!=nil)
        {
            if (gameCenter->localPlayer.isAuthenticated)
            {
                [gameCenter sendAllPlayers:data dataMode:GKMatchSendDataReliable];
            }
        }
    }
}
-(void)actSetMinPlayers:(CActExtension*)act
{
    int players=[act getParamExpression:rh withNum:0];
    minPlayers=MAX(players, 2);
    if (gameCenter!=nil)
    {
        [gameCenter setMultiplayerData:minPlayers max:maxPlayers group:group];
    }
}
-(void)actSetMaxPlayers:(CActExtension*)act
{
    int players=[act getParamExpression:rh withNum:0];
    maxPlayers=MAX(players, MAX(minPlayers, 2));
    if (gameCenter!=nil)
    {
        [gameCenter setMultiplayerData:minPlayers max:maxPlayers group:group];
    }
}
-(void)actSetGroup:(CActExtension*)act
{
    group=[act getParamExpression:rh withNum:0];
    if (gameCenter!=nil)
    {
        [gameCenter setMultiplayerData:minPlayers max:maxPlayers group:group];
    }
}
-(void)action:(int)num withActExtension:(CActExtension *)act
{
    switch (num)
    {
        case ACT_DISPLAYMATCH:
            [self actDisplayMatch];
            break;
        case ACT_FINDMATCH:
            [self actFindMatch];
            break;
        case ACT_ADDPLAYERS:
            [self actAddPlayers];
            break;
        case ACT_SENDUNRELIABLE:
            [self actSendUnreliable:act];
            break;
        case ACT_SENDRELIABLE:
            [self actSendReliable:act];
            break;
        case ACT_SENDALLUNRELIABLE:
            [self actSendAllUnreliable:act];
            break;
        case ACT_SENDALLRELIABLE:
            [self actSendAllReliable:act];
            break;
        case ACT_SETMINPLAYERS:
            [self actSetMinPlayers:act];
            break;
        case ACT_SETMAXPLAYERS:
            [self actSetMaxPlayers:act];
            break;
        case ACT_SETGROUP:
            [self actSetGroup:act];
            break;
		case ACT_DISCONNECT:
			[self actDisconnect];
			break;
    }
}

-(CValue*)expGetNPlayers
{
    if (gameCenter!=nil)
    {
        return [rh getTempValue:[gameCenter getNPlayers]];
    }
    return [rh getTempValue:0];            
}
-(CValue*)expGetPlayerAlias
{
    int index=[[ho getExpParam] getInt];
    if (gameCenter!=nil)
    {
		NSString* playerAlias = [gameCenter getPlayerAlias:index];
		if(playerAlias != nil)
			return [rh getTempString:playerAlias];
    }
    return [rh getTempString:@""];
}
-(CValue*)expGetData
{
    if (gameCenter!=nil)
        return [rh getTempString:[gameCenter getData]];
    return [rh getTempString:@""];
}
-(CValue*)expGetPlayerIndex
{
    if (gameCenter!=nil)
        return [rh getTempValue:[gameCenter getPlayerIndex]+1];
    return [rh getTempValue:0];
}
-(CValue*)expGetDisconnectedAlias
{
    return [rh getTempString:gameCenter->disconnectedAlias];
}
-(CValue*)expGetAliasLastEvent
{
    if (gameCenter!=nil)
    {
		NSString* playerAlias = [gameCenter getPlayerAlias:[gameCenter getPlayerIndex]+1];
		if(playerAlias != nil)
			return [rh getTempString:playerAlias];
    }
    return [rh getTempString:@""];
}

-(CValue*)expression:(int)num
{
    switch(num)
    {
        case EXP_GETNPLAYERS:
            return [self expGetNPlayers];
        case EXP_GETPLAYERALIAS:
            return [self expGetPlayerAlias];
        case EXP_GETDATA:
            return [self expGetData];
        case EXP_GETPLAYERINDEX:
            return [self expGetPlayerIndex];
		case EXP_GETDISCONNECTEDALIAS:
			return [self expGetDisconnectedAlias];
		case EXP_GETALIASLASTEVENT:
			return [self expGetAliasLastEvent];
    }
    return nil;
}
@end
 
