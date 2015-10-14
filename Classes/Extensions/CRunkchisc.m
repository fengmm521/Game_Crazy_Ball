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
// CRUNKCHISC
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CRunkchisc.h"

#import "CActExtension.h"
#import "CCndExtension.h"

#import "CExtension.h"
#import "CPoint.h"
#import "CCreateObjectInfo.h"
#import "CFile.h"
#import "CFontInfo.h"

#import "CRect.h"
#import "CRunApp.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CServices.h"
#import "CTextSurface.h"
#import "CFont.h"
#import "CFontInfo.h"
#import "CIni.h"
#import "ModalInput.h"

//Properties
#define SCR_HIDEONSTART 0x0001
#define SCR_NAMEFIRST 0x0002
#define SCR_CHECKONSTART 0x0004
#define SCR_DONTDISPLAYSCORES 0x0008
#define SCR_FULLPATH 0x0010

//CONDITIONS
#define CND_ISPLAYER 0
#define CND_VISIBLE 1

//EXPRESSIONS
#define EXP_VALUE 0
#define EXP_NAME 1
#define EXP_GETXPOSITION 2
#define EXP_GETYPOSITION 3

//ACTIONS
#define ACT_ASKNAME 0
#define ACT_HIDE 1
#define ACT_SHOW 2
#define ACT_RESET 3
#define ACT_CHANGENAME 4
#define ACT_CHANGESCORE 5
#define ACT_SETPOSITION 6
#define ACT_SETXPOSITION 7
#define ACT_SETYPOSITION 8
#define ACT_INSERTNEWSCORE 9
#define ACT_SETCURRENTFILE 10

@implementation CRunkchisc

-(int)getNumberOfConditions
{
	return 2;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	started = 0;
	nformat = [[NSNumberFormatter alloc] init];
	
	[ho setX:cob->cobX];
	[ho setY:cob->cobY];

	NbScores = [file readAShort];
	NameSize = [file readAShort];
	Flags = [file readAShort];
	if (ho->hoAdRunHeader->rhApp->bUnicode == false)
	{
		Logfont = [file readLogFont16];
	}
	else
	{
		Logfont = [file readLogFont];
	}
	colorref = [file readAColor];
	[file skipStringOfLength:40];
	for (int i = 0; i < 20; i++)
	{
		Names[i] = [file readAStringWithSize:41];
		originalNames[i] = [[NSString alloc] initWithString:Names[i]];
	}
	for (int i = 0; i < 20; i++)
	{
		Scores[i] = [file readAInt];
		originalScores[i] = Scores[i];
	}
	[ho setWidth:[file readAShort]];
	[ho setHeight:[file readAShort]];
	if ((Flags & SCR_HIDEONSTART) == 0)
	{
		sVisible = true;
	}
	IniName = [file readAStringWithSize:260];
    if ([IniName length]==0)
        IniName = @"hiscores.ini";
	ini = [CIni getINIforFile:IniName];
	for (int a = 0; a < 20; a++)
	{
		// Get name
		Names[a] = [[ini getValueFromGroup:@"HiScore" withKey:[NSString stringWithFormat:@"N%i",a] andDefaultValue:Names[a]] retain];
		
		// Get scores
		NSString* defaultString = [NSString stringWithFormat:@"%i",Scores[a]];
		NSString* r = [ini getValueFromGroup:@"HiScore" withKey:[NSString stringWithFormat:@"S%i",a] andDefaultValue:defaultString];
		if([r isEqualToString:@""])
			Scores[a] = 0;
		else
			Scores[a] = (int)[r integerValue];
	}
	textSurface = [[CTextSurface alloc] initWidthWidth:ho->hoImgWidth andHeight:ho->hoImgHeight];
	modalInput = nil;
	updated = true;
	return true;
}

-(void)saveHiScores
{
	for (int a = 0; a < NbScores; a++)
	{
		// Put name
		//(String group, String keyName, String value, String fileName)
		NSString* keyName = [NSString stringWithFormat:@"N%i",a];
		[ini writeValueToGroup:@"HiScore" withKey:keyName andValue:Names[a]];
		
		// Put scores
		keyName = [NSString stringWithFormat:@"S%i",a];
		[ini writeValueToGroup:@"HiScore" withKey:keyName andValue:[NSString stringWithFormat:@"%i",Scores[a]]];
	}
	[ini saveIni];
}

-(void)destroyRunObject:(BOOL)bFast
{
	[self saveHiScores];
    [IniName release];
	
	if(modalInput != nil)
		[modalInput release];

	[CIni closeIni:ini];
	[textSurface release];
}

-(int)handleRunObject
{
	short a, b;
	short players[4];
	BOOL TriOk;
	CRun* rhPtr = ho->hoAdRunHeader;
	int score1, score2;
	if ((Flags & SCR_CHECKONSTART) != 0)
	{
		// Init player order
		for (a = 0; a < 4; a++)
		{
			players[a] = a;
		}
		// Sort player order (bigger score asked first)
		do
		{
			TriOk = true;
			for (a = 1; a < 4; a++)
			{
				score1 = [rhPtr->rhApp getScores][a];
				score2 = [rhPtr->rhApp getScores][a-1];
				if (score1 > score2)
				{
					b = players[a - 1];
					players[a - 1] = players[a];
					players[a] = b;
					TriOk = false;
				}
			}
		} while (false == TriOk);
		started++;
		int shown = 0;
		// Check for hi-scores
		for (a = 0; a < rhPtr->rhNPlayers; a++)
		{
			if ([self CheckScore:players[a]]) //popup shown
			{
				shown++;
			}
		}
		if (shown > 0)
		{
			return REFLAG_ONESHOT + REFLAG_DISPLAY;
		}
		if (started > 1)
		{
			return REFLAG_ONESHOT + REFLAG_DISPLAY;
		}
		return REFLAG_DISPLAY; //keep handlerunobject running.
	}
	else
	{
		return REFLAG_ONESHOT + REFLAG_DISPLAY;
	}
}

-(void)displayRunObject:(CRenderer*)renderer
{
	if (!sVisible)
		return;
	
	if(!updated)
	{
		[textSurface draw:renderer withX:ho->hoX andY:ho->hoY andEffect:0 andEffectParam:0];
		return;	
	}
	
	updated = false;
	[textSurface manualClear:colorref];

	NSString* names[20];
	for (int i = 0; i < 20; i++)
	{
		names[i] = Names[i];
		if ([names[i] length] > NameSize)
		{
			names[i] = [[names[i] substringToIndex:NameSize] retain];
		}
	}
	int ADJ = 4; // move strings up 4 pixels

	if ((Flags & SCR_DONTDISPLAYSCORES) != 0)
	{
		CRect rc;
		// Compute coordinates
		rc.left = 0;
		rc.right = ho->hoImgWidth;
		rc.top = 0;
		rc.bottom = (ho->hoImgHeight / NbScores);

		// draw names
		for (int a = 0; a < NbScores; a++)
		{
			[textSurface manualDrawText:names[a] withFlags:DT_VALIGN|DT_TOP andRect:rc andColor:colorref andFont:[CFont createFromFontInfo:Logfont]];
			rc.top += ho->hoImgHeight / NbScores;
			rc.bottom += ho->hoImgHeight / NbScores;
		}
	}
	else
	{
		CFont* font = [CFont createFromFontInfo:Logfont];
		
		// Draw text
		if (0 != (Flags & SCR_NAMEFIRST))
		{
			CRect rc;

			// Compute coordinates
			rc.left = 0;
			rc.right = (ho->hoImgWidth / 4)*3;
			rc.top = 0;
			rc.bottom = (ho->hoImgHeight / NbScores);

			// draw names
			for (int a = 0; a < NbScores; a++)
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
			for (int a = 0; a < NbScores; a++)
			{
				NSString* score = [NSString stringWithFormat:@"%i",Scores[a]];
				
				CRect tmpRect = rc;

				UIFont* thefont = [font createFont];
#ifdef __IPHONE_8_0
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
				CGSize scoreSize;
				if([score respondsToSelector:@selector(sizeWithAttributes:)])
					scoreSize = [score sizeWithAttributes:@{NSFontAttributeName:thefont}];
				else
					scoreSize = [score sizeWithFont:thefont];
#pragma clang diagnostic pop
#else
				CGSize scoreSize = [score sizeWithFont:thefont];
#endif

				tmpRect.left = rc.right - scoreSize.width;
				tmpRect.bottom = rc.bottom-ADJ;
				[textSurface manualDrawText:[NSString stringWithFormat:@"%i",Scores[a]]	withFlags:DT_VALIGN|DT_TOP andRect:tmpRect andColor:colorref andFont:font];
				
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
			for (int a = 0; a < NbScores; a++)
			{
				[textSurface manualDrawText:[NSString stringWithFormat:@"%i",Scores[a]] withFlags:DT_TOP andRect:rc andColor:colorref andFont:font];
				rc.top += ho->hoImgHeight / NbScores;
				rc.bottom += ho->hoImgHeight / NbScores;
			}

			// Compute coordinates
			rc.left = ho->hoImgWidth / 4;
			rc.right = rc.left + ((ho->hoImgWidth / 4) * 3);
			rc.top = 0;
			rc.bottom = ho->hoImgHeight / NbScores;

			UIFont* thefont = [font createFont];

			// draw names
			for (int a = 0; a < NbScores; a++)
			{
				CRect tmpRect = rc;
				NSString* name = names[a];

#ifdef __IPHONE_8_0
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
				CGSize nameSize;
				if([name respondsToSelector:@selector(sizeWithAttributes:)])
					nameSize = [name sizeWithAttributes:@{NSFontAttributeName:thefont}];
				else
					nameSize = [name sizeWithFont:thefont];
#pragma clang diagnostic pop
#else
				CGSize nameSize = [name sizeWithFont:thefont];
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
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == 1)
	{
		[self InsertNewScore:recordedScore andName:[[NSString alloc] initWithString:[modalInput text]]];
		updated = true;
	}
	//else cancel was pressed -> No score added
	[modalInput resignTextField];
}


// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_ISPLAYER:
			return [self IsPlayerHiScore:[cnd getParamPlayer:rh withNum:0]];
		case CND_VISIBLE:
			return [self IsVisible];
	}
	return false;//won't happen
}

-(BOOL)IsPlayerHiScore:(short)player
{
	CRun* rhPtr = ho->hoAdRunHeader;
	int score = rhPtr->rhApp->scores[player];
	if ((score > Scores[NbScores - 1]) && (score != scrPlayer[player]))
	{
		scrPlayer[player] = score;
		return true;
	}
	return false;
}

-(BOOL)IsVisible
{
	return sVisible;
}

// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_ASKNAME:
			[self CheckScore:[act getParamPlayer:rh withNum:0]];
			break;
		case ACT_HIDE:
			[self Hide];
			break;
		case ACT_SHOW:
			[self Show];
			break;
		case ACT_RESET:
			[self Reset];
			break;
		case ACT_CHANGENAME:
		{
			int index = [act getParamExpression:rh withNum:0];
			NSString* name = [act getParamExpString:rh withNum:1];
			[self ChangeName:index withName:name];
			break;
		}
		case ACT_CHANGESCORE:
		{
			int index = [act getParamExpression:rh withNum:0];
			int score = [act getParamExpression:rh withNum:1];
			[self ChangeScore:index andScore:score];
			break;
		}
		case ACT_SETPOSITION:
		{
			unsigned int pos = [act getParamPosition:rh withNum:0];
			int x = POSX(pos);
			int y = POSY(pos);
			
			[self SetPositionX:x andY:y];
			break;
		}
		case ACT_SETXPOSITION:
			[self SetXPosition:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETYPOSITION:
			[self SetYPosition:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_INSERTNEWSCORE:
		{	
			int score = [act getParamExpression:rh withNum:0];
			NSString* name = [act getParamExpString:rh withNum:1];
			[self InsertNewScore:score andName:name];
			break;
		}
		case ACT_SETCURRENTFILE:
			[self SetCurrentFile:[act getParamExpString:rh withNum:0]];
			break;
	}
}

-(BOOL)CheckScore:(int)player //needed public and returns true when popup is shown
{
	CRun* rhPtr = ho->hoAdRunHeader;
	int score;
	if (player < rhPtr->rhNPlayers)
	{
		score = rhPtr->rhApp->scores[player];
		if (score > Scores[NbScores - 1])
		{
			recordedScore = score;
			NSString* title = [NSString stringWithFormat:@"New Hi-score: %i", score];
			
			if(modalInput != nil)
				[modalInput release];
			
			modalInput = [[ModalInput alloc] initStringWithTitle:title message:@"Enter your name:" delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"Save"];
			[modalInput show];
			return true;
		}
	}
	return false;
}

-(void)Hide
{
	sVisible = false;
	[ho redraw];
}

-(void)Show
{
	sVisible = true;
	[ho redraw];
}

-(void)Reset
{
	for (int a = 0; a < 20; a++)
	{
		[Names[a] release];
		Names[a] = [[NSString alloc] initWithString:originalNames[a]];
		Scores[a] = originalScores[a];
	}
	updated = true;
	[self saveHiScores];
	[ho redraw];
}

-(void)ChangeName:(int)i withName:(NSString*)name	//1based
{
	if ((i > 0) && (i <= NbScores))
	{
		[Names[i - 1] release];
		Names[i - 1] = [[NSString alloc] initWithString:name];
		updated = true;
		[self saveHiScores];
		[ho redraw];
	}
}

-(void)ChangeScore:(int)i andScore:(int)score	//1based
{
	if ((i > 0) && (i <= NbScores))
	{
		Scores[i - 1] = score;
		updated = true;
		[self saveHiScores];
		[ho redraw];
	}
}

-(void)SetPositionX:(int)x andY:(int)y
{
	[ho setPosition:x withY:y];
	if (sVisible)
	{
		[ho redraw];
	}
}

-(void)SetXPosition:(int)x
{
	[ho setX:x];
	if (sVisible)
	{
		[ho redraw];
	}
}

-(void)SetYPosition:(int)y
{
	[ho setY:y];
	if (sVisible)
	{
		[ho redraw];
	}
}

-(void)InsertNewScore:(int)pScore andName:(NSString*)pName
{
	if (pScore > Scores[NbScores - 1])
	{
		Scores[19] = pScore;
		[Names[19] release];
		Names[19] = [[NSString alloc] initWithString:pName];
		short b;
		BOOL TriOk;
		int score;
		NSString* name;
		// Sort the hi-score table ws_visible
		do
		{
			TriOk = true;
			for (b = 1; b < 20; b++)
			{
				if (Scores[b] > Scores[b - 1])
				{
					score = Scores[b - 1];
					name = Names[b - 1];
					Scores[b - 1] = Scores[b];
					Names[b - 1] = Names[b];
					Scores[b] = score;
					Names[b] = name;
					TriOk = false;
				}
			}
		} while (false == TriOk);

		updated = true;
		[ho redraw];
	}
	[self saveHiScores];
}

-(void)SetCurrentFile:(NSString*)fileName
{
	[CIni closeIni:ini];
	IniName = fileName;
	ini = [CIni getINIforFile:IniName];
}

// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_VALUE:               
			return [self GetValue:[[ho getExpParam] getInt]];
		case EXP_NAME:
			return [self GetName:[[ho getExpParam] getInt]];
		case EXP_GETXPOSITION:
			return [self GetXPosition];
		case EXP_GETYPOSITION:
			return [self GetYPosition];            
	}
	return [rh getTempValue:0];//won't happen
}

-(CValue*)GetValue:(int)i //1 based
{
	if ((i > 0) && (i <= NbScores))
	{
		return [rh getTempValue:Scores[i - 1]];
	}
	return [rh getTempValue:0];
}

-(CValue*)GetName:(int)i //1 based
{
	if ((i > 0) && (i <= NbScores))
	{
		return [rh getTempString:Names[i - 1]];
	}
	return [rh getTempString:@""];
}

-(CValue*)GetXPosition
{
	return [rh getTempValue:ho->hoX];
}

-(CValue*)GetYPosition
{
	return [rh getTempValue:ho->hoY];
}

@end
