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
// CRUN : BOucle principale
//
//----------------------------------------------------------------------------------
#import "CRun.h"
#import "CRunApp.h"
#import "CRunFrame.h"
#import "CServices.h"
#import "CArrayList.h"
#import "CRect.h"
#import "CLO.h"
#import "COI.h"
#import "CObjectCommon.h"
#import "CSprite.h"
#import "CEventProgram.h"
#import "COI.h"
#import "COIList.h"
#import "Cvalue.h"
#import "CSpriteGen.h"
#import "COCBackground.h"
#import "COCQBackdrop.h"
#import "CSoundPlayer.h"
#import "CObjInfo.h"
#import "CBkd2.h"
#import "CLayer.h"
#import "CLO.h"
#import "CLOList.h"
#import "CObject.h"
#import "CFontInfo.h"
#import "CImage.h"
#import "CimageBank.h"
#import "CActive.h"
#import "CScore.h"
#import "CLives.h"
#import "CText.h"
#import "CQuestion.h"
#import "CCounter.h"
#import "CCreateObjectInfo.h"
#import "CRCom.h"
#import "CRAni.h"
#import "CRMvt.h"
#import "CRVal.h"
#import "CRSpr.h"
#import "CObject.h"
#import "CColMask.h"
#import "CExtension.h"
#import "CBackDrawPaste.h"
#import "CMask.h"
#import "CMove.h"
#import "CMoveDef.h"
#import "CAnim.h"
#import "CMoveBullet.h"
#import "CMovePlatform.h"
#import "CSysEvent.h"
#import "CJoystick.h"
#import "CJoystickAcc.h"
#import "CJoystickGamepad.h"
#import "CRunView.h"
#import "CMoveDefList.h"
#import "CBitmap.h"
#import "CExtStorage.h"
#import "CExtLoader.h"
#import "CRunExtension.h"
#import "CCndExtension.h"
#import "CActExtension.h"
#import "CRenderToTexture.h"
#import "CCCA.h"
#import "CIAdViewController.h"
#import "CSaveGlobal.h"
#import "ObjectSelection.h"
#import "MainView.h"
#import "CMoveDefExtension.h"
#import "CMoveExtension.h"
#import "CLoop.h"

extern CALLEXP_ROUTINE callTable_Expression[];
extern CALLOPERATOR_ROUTINE expCallOperators[];

static int CosSurSin32[] =
{
2599, 0, 844, 31, 479, 30, 312, 29, 210, 28, 137, 27, 78, 26, 25, 25, 0, 24
};
// Table d'elimination des entrees/sorties impossibles
// ---------------------------------------------------
static short Table_InOut[] =
{
0, // 0000
BORDER_LEFT, // 0001 BORDER_LEFT
BORDER_RIGHT, // 0010 BORDER_RIGHT
0, // 0011
BORDER_TOP, // 0100 BORDER_TOP
BORDER_TOP + BORDER_LEFT, // 0101
BORDER_TOP + BORDER_RIGHT, // 0110
0, // 0111
BORDER_BOTTOM, // 1000 BORDER BOTTOM
BORDER_BOTTOM + BORDER_LEFT, // 1001
BORDER_BOTTOM + BORDER_RIGHT, // 1010	
0, // 1011
0, // 1100
0, // 1101
0, // 1110
0							// 1111
};

BOOL bMoveChanged;

@implementation CRun

-(id)initWithApp:(CRunApp*)a
{
	if(self = [super init])
	{
		rhApp = a;
		for (int n=0; n<MAX_INTERMEDIATERESULTS; n++)
		{
			rh4Results[n]=[[CValue alloc] init];
		}
		rhOiList = nil;
		spriteGen=[[CSpriteGen alloc] initWithBank:rhApp->imageBank andApp:rhApp];
	}
	return self;
}
-(void)dealloc
{
	int n;
	for (n=0; n<MAX_INTERMEDIATERESULTS; n++)
	{
		[rh4Results[n] release];
	}
	if (rhTempString!=nil)
	{
		[rhTempString release];
	}
	if (rhOiList!=nil)
	{
		free(rhOiList);
	}
	if (rhTempValues!=nil)
	{
		for (n=0; n<rhMaxTempValues; n++)
		{
			if (rhTempValues[n]!=nil)
			{
				[rhTempValues[n] release];
			}	
		}
		free(rhTempValues);
	}
	if (spriteGen!=nil)
	{
		[spriteGen release];
	}
	[super dealloc];
}
-(CLoop*)addFastLoop:(NSString*)loopName withIndexPtr:(int*)indexPtr
{
    CLoop* pLoop = nil;
    int index;
    
    //Search for already existing loop with this name
    for (index=0; index<[rh4FastLoops size]; index++)
    {
        pLoop=(CLoop*)[rh4FastLoops get:index];
        if ([pLoop->name caseInsensitiveCompare:loopName]==0)
            break;
    }
    
    if (index==[rh4FastLoops size])
    {
        pLoop=[[CLoop alloc] init];
        pLoop->name=[[NSString alloc] initWithString:loopName];
        pLoop->flags=0;
        [rh4FastLoops add:pLoop];
        index=[rh4FastLoops size]-1;
    }
    if ( indexPtr != NULL )
        *indexPtr = index;
    return (CLoop*)[rh4FastLoops get:index];
    
}
-(int)allocRunHeader
{
	// L'object list
	rhFrame = rhApp->frame;
	rhMaxObjects=rhFrame->maxObjects;
	rhObjectList = (CObject**)calloc(rhFrame->maxObjects, sizeof(CObject*));
	objectSelection = [[ObjectSelection alloc] initWithRunHeader:rhApp];
	
	// Le programme d'evenements
	rhEvtProg = rhApp->events;
	[rhEvtProg setCRun:self];
	
	// Compte les objinfos
	rhMaxOI = 0;
	COI* oi;
	for (oi = [rhApp->OIList getFirstOI]; oi != nil; oi = [rhApp->OIList getNextOI])
	{
		if (oi->oiType >=OBJ_SPR)
		{
			rhMaxOI++;
		}
	}
	
	// L'OIlist
	if(rhMaxOI > 0)
		rhOiList = (CObjInfo**)calloc(rhMaxOI, sizeof(CObjInfo*));
	else
		rhOiList = NULL;
	
	// Random generator
	if (rhFrame->m_wRandomSeed == -1)
	{
		double tick = CFAbsoluteTimeGetCurrent();
		double i=floor(tick);
		tick=tick-i;
		rh3Graine = (short)(65535.0*tick);				// Fait un randomize
	}
	else
	{
		rh3Graine = rhFrame->m_wRandomSeed;			// Fixe la valeur donn�e
	}
	
	// La destroy-list
	rhDestroyList = (int*)calloc((rhFrame->maxObjects/32)+1, sizeof(int));
	
	// Les fast loops
	rh4FastLoops = [[CArrayList alloc] init];
	rh4CurrentFastLoop = [NSString string];
	
	// Le buffer d'objets
	rhMaxObjects = rhFrame->maxObjects;
	
	// INITIALISATION DU RESTE DES DONNEES
	rhNPlayers = rhEvtProg->nPlayers;
	rhWindowX = (int)rhFrame->leX;
	rhWindowY = (int)rhFrame->leY;
	rhLevelSx = (int)rhFrame->leVirtualRect.right;
	if (rhLevelSx == -1)
	{
		rhLevelSx = 0x7FFFF000;		// 2147479552
	}
	rhLevelSy = (int)rhFrame->leVirtualRect.bottom;
	if (rhLevelSy == -1)
	{
		rhLevelSy = 0x7FFFF000;		// 2147479552
	}
	rhNObjects = 0;
	rhStopFlag = 0;
	rhQuit = 0;
	rhQuitBis = 0;
	rhGameFlags &= (GAMEFLAGS_PLAY);
	rhGameFlags |= GAMEFLAGS_LIMITEDSCROLL;
	rh3Panic = 0;
	rh4FirstQuickDisplay = (short) 0x8000;
	rh4LastQuickDisplay = (short) 0x8000;
	rh4MouseXCenter = rhFrame->leEditWinWidth / 2;
	rh4MouseYCenter = rhFrame->leEditWinHeight / 2;
	rh4FrameRatePos = 0;
	rh4FrameRatePrevious = 0;
	//	CreateCoxHandleRoutines();
	rh4BackDrawRoutines = nil;
	rh4SaveFrame = 0;
	rh4SaveFrameCount = -2;
	rhEvtProg->rh2CurrentClick = -1;
    rhTempString=nil;
	rh4PosOnLoop = nil;
    rh4ComplexOnLoop = NO;
    
	rhGameFlags |= GAMEFLAGS_REALGAME;
	
	// Header valide!
	rhFrame->rhOK = true;
	rhCurTempValue=0;
	rhMaxTempValues=0;
	rhTempValues=nil;
	rhBaseTempValues=0;
	
	nSubApps=0;
	int n;
	for (n=0; n<MAX_SUBAPPS; n++)
	{
		subApps[n]=nil;
	}
	rhJoystickMask=0xFF;
	rh4MvtTimerCoef=0;
	
	evaTmp = [[CValue alloc] init];
	runtimeIsReady = NO;
	return 0;
}
-(void)freeRunHeader
{
	rhFrame->rhOK = false;
	
	// Si demo
	if (rhObjectList!=nil)
	{
		free(rhObjectList);
	}
	rhObjectList = nil;
	int n;
	if (rhOiList!=nil)
	{
		for (n=0; n<rhMaxOI; n++)
		{
			if (rhOiList[n]!=nil)
			{
				[rhOiList[n] release];
			}
		}
		free(rhOiList);
	}
	rhOiList = nil;
	if (rhDestroyList!=nil)
	{
		free(rhDestroyList);
		rhDestroyList=nil;
	}
	if (rh4PSaveFilename!=nil)
	{
		[rh4PSaveFilename release];
	}
	rh4PSaveFilename=nil;
	if (rh4CurrentFastLoop!=nil)
	{
		[rh4CurrentFastLoop release];
	}
	rh4CurrentFastLoop=nil;
	if (rh4FastLoops!=nil)
	{
		[rh4FastLoops clearRelease];
		[rh4FastLoops release];
		rh4FastLoops=nil;
	}
	if (rh4BackDrawRoutines!=nil)
	{
		[rh4BackDrawRoutines clearRelease];
		[rh4BackDrawRoutines release];
		rh4BackDrawRoutines=nil;
	}
	if (rhTempString!=nil)
	{
		[rhTempString release];
        rhTempString=nil;
	}
	if (rhTempValues!=nil)
	{
		for (n=0; n<rhMaxTempValues; n++)
		{
			if (rhTempValues[n]!=nil)
			{
				[rhTempValues[n] release];
				rhTempValues[n]=nil;
			}
		}
		free(rhTempValues);
	}
    if (rh4TimerEvents!=nil)
    {
        LPTIMEREVENT pEvent = rh4TimerEvents;
        LPTIMEREVENT pFree;
        while (pEvent!=nil)
        {
            [pEvent->name release];
            pFree = pEvent;
            pEvent = (LPTIMEREVENT)pEvent->next;
            free(pFree);
        }
    }
    if (rh4PosOnLoop != nil)
    {
        int n;
        for (n = 0; n < rh4PosOnLoop->Size(); n++)
        {
            CPosOnLoop* pLoop = (CPosOnLoop*)rh4PosOnLoop->Get(n);
            delete pLoop;
        }
        delete rh4PosOnLoop;
    }
	rhTempValues=nil;
	rhMaxTempValues=0;
	rhCurTempValue=0;
	rhBaseTempValues=0;
	[objectSelection release];
	[evaTmp release];
	rhApp->renderer->clearPruneList();
}

-(void)updateFrameDimensions:(int)width withHeight:(int)height
{
    if (width>0)
    {
        rhLevelSx=width;
        rh3WindowSx=width;
        rh3XMaximumKill=width+GAME_XBORDER;
        
        int wx=rhWindowX;
        wx+=rh3WindowSx+COLMASK_XMARGIN;
        if (wx>rhLevelSx)
            wx=rh3XMaximumKill;
        rh3XMaximum=wx;
    }
    if (height>0)
    {
        rhLevelSy=height;
        rh3WindowSy=height;
        rh3YMaximumKill=height+GAME_YBORDER;
        
        int wy=rhWindowY;
        wy+=rh3WindowSy+COLMASK_XMARGIN;
        if (wy>rhLevelSy)
            wy=rh3YMaximumKill;
        rh3YMaximum=wy;
    }
}
-(void)ensureTempValueSpace
{
	if (rhCurTempValue>=rhMaxTempValues)
	{
		int max=rhMaxTempValues+STEP_TEMPVALUES;
		CValue** temp=(CValue**)calloc(max, sizeof(CValue*));
		if (rhTempValues!=nil)
		{
			memcpy(temp, rhTempValues, rhMaxTempValues*sizeof(CValue*));
			free(rhTempValues);
		}
		rhTempValues=temp;
		rhMaxTempValues=max;
	}	
}

-(CValue*)getTempCValue:(CValue*)v
{
	[self ensureTempValueSpace];
	if (rhTempValues[rhCurTempValue]==nil)
	{
		switch(v->type)
		{
			case TYPE_INT:
				rhTempValues[rhCurTempValue]=[[CValue alloc] initWithInt:v->intValue];
				break;
			case TYPE_DOUBLE:
				rhTempValues[rhCurTempValue]=[[CValue alloc] initWithDouble:v->doubleValue];
				break;
			case TYPE_STRING:
				rhTempValues[rhCurTempValue]=[[CValue alloc] initWithString:v->stringValue];
				break;
		}
		return rhTempValues[rhCurTempValue++];
	}
	[rhTempValues[rhCurTempValue] forceValue:v];
	return rhTempValues[rhCurTempValue++];
}

-(CValue*)getTempValue:(int)v
{
	[self ensureTempValueSpace];
	if (rhTempValues[rhCurTempValue]==nil)
	{
		rhTempValues[rhCurTempValue]=[[CValue alloc] initWithInt:v];
		return rhTempValues[rhCurTempValue++];
	}
	[rhTempValues[rhCurTempValue] forceInt:v];
	return rhTempValues[rhCurTempValue++];
}

-(CValue*)getTempDouble:(double)d
{
	[self ensureTempValueSpace];
	if (rhTempValues[rhCurTempValue]==nil)
	{
		rhTempValues[rhCurTempValue]=[[CValue alloc] initWithDouble:d];
		return rhTempValues[rhCurTempValue++];
	}
	[rhTempValues[rhCurTempValue] forceDouble:d];
	return rhTempValues[rhCurTempValue++];
}

-(CValue*)getTempString:(NSString*)s
{
	[self ensureTempValueSpace];
	if (rhTempValues[rhCurTempValue]==nil)
	{
		rhTempValues[rhCurTempValue]=[[CValue alloc] initWithString:s];
		return rhTempValues[rhCurTempValue++];
	}
	[rhTempValues[rhCurTempValue] forceString:s];
	return rhTempValues[rhCurTempValue++];
}

-(void)cleanTempValues
{
	int n;
	for (n=rhCurTempValue; n<rhMaxTempValues; n++)
	{
		if (rhTempValues[n]!=nil)
		{
			[rhTempValues[n] release];
			rhTempValues[n]=nil;
		}
	}
}
-(void)cleanMemory
{
	[self cleanTempValues];
}
-(int)initRunLoop:(BOOL)bFade
{
	int error = 0;
	
	error = [self allocRunHeader];
	if (error != 0)
	{
		return error;
	}
	
	if (bFade)
	{
		rhGameFlags |= GAMEFLAGS_FIRSTLOOPFADEIN;
	}
	
	[self initAsmLoop];
	
	[self y_InitLevel];
	//      f_InitLoop();
	
	error = [self prepareFrame];
	if (error != 0)
	{
		return error;
	}
	
	error = [self createFrameObjects:bFade];
	if (error != 0)
	{
		return error;
	}
	
	[self redrawLevel:(short)(DLF_DONTUPDATE | DLF_STARTLEVEL)];


	[self loadGlobalObjectsData];
	
	[rhEvtProg prepareProgram];
	[rhEvtProg assemblePrograms];

	rhQuitParam = 0;
	[self f_InitLoop];

	//The runtime is ready and safe for objects to begin triggering important conditions
	runtimeIsReady = YES;
	[self triggerRuntimeReadyCalls];

	return 0;
}

-(void)triggerRuntimeReadyCalls
{
	for(int i=0; i<rhNObjects; ++i)
	{
		if(rhObjectList[i] != nil)
		{
			CObject* object = rhObjectList[i];
			[object runtimeIsReady];
		}
	}
}

-(int)doRunLoop
{
	// Appel du jeu
	rhApp->appRunFlags |= ARF_INGAMELOOP;
	int quit = [self f_GameLoop];
	rhApp->appRunFlags &= ~ARF_INGAMELOOP;
	
	// Appel des evenements systeme
	if ([rhApp->sysEvents size]>0)
	{
		int n;
		for (n = 0; n < [rhApp->sysEvents size]; n++)
		{
			CSysEvent* sys = (CSysEvent*)[rhApp->sysEvents get:n];
			if (sys != nil)
			{
				[sys execute:self];
			}
		}
		[rhApp->sysEvents clearRelease];
	}
	
	// Si fin de FADE IN, detruit les sprites
	if ((rhGameFlags & GAMEFLAGS_FIRSTLOOPFADEIN) != 0)
	{
		//[self f_RemoveObjects];
		rhFrame->fadeTimerDelta = CFAbsoluteTimeGetCurrent()*1000-rhTimerOld;
		rhFrame->fadeVblDelta = [rhApp newGetCptVBL] - rhVBLOld;
		[self y_KillLevel:YES];
		[rhEvtProg unBranchPrograms];
	}
	
	if (quit != 0)
	{
		switch (quit)
		{
				// Passe en pause
			case 5:		// LOOPEXIT_PAUSEGAME:
				rhQuit = 0;
				[self pause];
				quit = 0;
				break;
				
				// Redemarre la frame
			case 101:	// LOOPEXIT_RESTART:
				if (rhFrame->fade)
				{
					break;
				}
				
				// Sortie du niveau preceddent
				[rhApp->soundPlayer stopAllSounds];
				[self killFrameObjects];
				[self y_KillLevel:NO];
				[rhEvtProg unBranchPrograms];
				[self freeRunHeader];
				
				// Redemarre la frame
				rhFrame->leX = rhFrame->leLastScrlX = 0;
				rhFrame->leY = rhFrame->leLastScrlY = 0;
				[self allocRunHeader];
				[self initAsmLoop];
				[self y_InitLevel];
				[self prepareFrame];
				[self createFrameObjects:NO];
				[self redrawLevel:(short)(DLF_DONTUPDATE | DLF_RESTARTLEVEL)];
				[self loadGlobalObjectsData];
				[rhEvtProg prepareProgram];
				[rhEvtProg assemblePrograms];
				[self f_InitLoop];
				quit = 0;
				rhQuitParam = 0;
				break;
				
			case 100:	    // LOOPEXIT_QUIT:
			case -2:	    // LOOPEXIT_ENDGAME:
				[rhEvtProg handle_GlobalEvents:((-4 << 16) | 65533)];	// CNDL_QUITAPPLICATION
				break;
		}
	}
	return quit;
}
-(int)killRunLoop:(int)quit keepSounds:(BOOL)bLeaveSamples
{
	int quitParam;
	
	// Filtre les codes internes
	if (quit > 100)
	{
		quit = LOOPEXIT_ENDGAME;
	}
	quitParam = (int) rhQuitParam;
	[self saveGlobalObjectsData];
	[self killFrameObjects]; 
	[self y_KillLevel:bLeaveSamples];
	[rhEvtProg unBranchPrograms];
	[self freeRunHeader];
	
	return MAKELONG(quit, quitParam);
}
-(void)y_InitLevel
{
	[self resetFrameLayers:-1 withFlag:NO];
}
-(void)initAsmLoop
{
	if (rh3Panic == 0)
	{
		[spriteGen winSetColMode:CM_BITMAP];				// Collisions precises
		[self f_ObjMem_Init];
	}
}
-(void)f_ObjMem_Init
{
	for (int i = 0; i < rhMaxObjects; i++)
	{
		rhObjectList[i] = nil;
	}
}
-(int)prepareFrame
{
	COI* oiPtr;
	short type;
	
	// Flags de RUN
	if ((rhApp->gaFlags & GA_SPEEDINDEPENDANT) != 0 && rhFrame->fade == NO)
	{
		rhGameFlags |= GAMEFLAGS_VBLINDEP;
	}
	else
	{
		rhGameFlags &= ~GAMEFLAGS_VBLINDEP;
	}
	rhGameFlags |= GAMEFLAGS_LOADONCALL;
	rhGameFlags |= GAMEFLAGS_INITIALISING;				// Empeche les evenements...
	
	// Initialisation du programme
	rh2CreationCount = 0;
	
	// Initialise la table OiList
	CLO* loPtr;
	int count = 0;
	
	// L'OIlist
	if(rhOiList!=nil)
		free(rhOiList);
	
	rhOiList = (CObjInfo**)calloc(rhMaxOI, sizeof(CObjInfo*));
	for (oiPtr = [rhApp->OIList getFirstOI]; oiPtr != nil; oiPtr = [rhApp->OIList getNextOI])
	{
		type = oiPtr->oiType;
		if (type >= OBJ_SPR)
		{
			rhOiList[count] = [[CObjInfo alloc] init];
			[rhOiList[count] copyData:oiPtr];
			
			// Retrouve un HFII pour les objets TEXT ou QUESTIONS (PARAM_SYSCREATE)
			rhOiList[count]->oilHFII = -1;
			if (type == OBJ_TEXT || type == OBJ_QUEST)
			{
				for (loPtr = [rhFrame->LOList first_LevObj]; loPtr != nil; loPtr = [rhFrame->LOList next_LevObj])
				{
					if (loPtr->loOiHandle == rhOiList[count]->oilOi)
					{
						rhOiList[count]->oilHFII = loPtr->loHandle;
						break;
					}
				}
			}
			count++;
			
			CObjectCommon* ocPtr=(CObjectCommon*)oiPtr->oiOC;
			if ((ocPtr->ocOEFlags&OEFLAG_MOVEMENTS)!=0 && ocPtr->ocMovements!=nil)
			{
				int n;
				for (n=0; n<ocPtr->ocMovements->nMovements; n++)
				{
					CMoveDef* mvPtr=ocPtr->ocMovements->moveList[n];
					if (mvPtr->mvType==MVTYPE_MOUSE)
					{
						rhMouseUsed=1;
					}
				}
			}
		}
	}
	
	for (int i = 0; i < rhFrame->nLayers; i++)
	{
		CLayer* layer = rhFrame->layers[i];
		layer->nZOrderMax = 1;
		layer->dx = 0;
		layer->dy = 0;
		layer->xOff = 0;
		layer->yOff = 0;
	}
	return 0;
}

-(int)createFrameObjects:(BOOL)fade
{
	COI* oiPtr;
	CObjectCommon* ocPtr;
	short type;
	int n;
	short creatFlags;
	CLO* loPtr;
	
	int error = 0;
	for (n = 0, loPtr=[rhFrame->LOList first_LevObj]; loPtr!=nil; n++, loPtr = [rhFrame->LOList next_LevObj])
	{
		oiPtr = [rhApp->OIList getOIFromHandle:loPtr->loOiHandle];
		ocPtr = (CObjectCommon*) oiPtr->oiOC;
		type = oiPtr->oiType;
		
		creatFlags = COF_CREATEDATSTART;
		
		// Objet pas dans le bon mode || cree au milieu du jeu. SKIP
		if (loPtr->loParentType != PARENT_NONE)
		{
			continue;
		}
		
		// Objet texte: marque comme non destructible
		if (type == OBJ_TEXT)
		{
			creatFlags |= COF_FIRSTTEXT;
		}
		
		// Objet iconise non texte . SKIP
		if ((ocPtr->ocFlags2 & OCFLAGS2_VISIBLEATSTART) == 0)
		{
			if (type == OBJ_QUEST)
			{
				continue;
			}
			creatFlags |= COF_HIDDEN;
		}
		
		// En mode preparation de fadein, si objet extension & runbeforefadein==0 . SKIP
		if (fade)
		{
			if (type >= KPX_BASE)
			{
				if ((ocPtr->ocOEFlags & OEFLAG_RUNBEFOREFADEIN) == 0)
				{
					continue;
				}
			}
		}
		
		// Creation de l'objet                
		if ((ocPtr->ocOEFlags & OEFLAG_DONTCREATEATSTART) == 0)
		{
			[self f_CreateObject:loPtr->loHandle withOIHandle:loPtr->loOiHandle andX:0x80000000 andY:0x80000000 andDir:-1 andFlags:creatFlags andLayer:-1 andNumCreation:-1];
		}
	}
	rhGameFlags &= ~GAMEFLAGS_INITIALISING;
	return error;
}
-(void)createRemainingFrameObjects
{
	COI* oiPtr;
	CObjectCommon* ocPtr;
	short type;
	int n;
	short creatFlags;
	CLO* loPtr;
	
	rhGameFlags &= ~GAMEFLAGS_FIRSTLOOPFADEIN;
	
	[self redrawLevel:DLF_DONTUPDATE | DLF_STARTLEVEL];
	//[self F_ReInitObjects];
	
	for (n = 0, loPtr=[rhFrame->LOList first_LevObj]; loPtr!=nil; n++, loPtr = [rhFrame->LOList next_LevObj])
	{
		oiPtr = [rhApp->OIList getOIFromHandle:loPtr->loOiHandle];
		ocPtr = (CObjectCommon*) oiPtr->oiOC;
		type = oiPtr->oiType;
		
		if (type < KPX_BASE)
		{
			continue;
		}
		if ((ocPtr->ocOEFlags & OEFLAG_RUNBEFOREFADEIN) != 0)
		{
			continue;
		}
		
		creatFlags = COF_CREATEDATSTART;
		
		// Objet pas dans le bon mode || cree au milieu du jeu-> SKIP
		if (loPtr->loParentType != PARENT_NONE)
		{
			continue;
		}
		
		// Objet iconise non texte -> SKIP
		if ((ocPtr->ocFlags2 & OCFLAGS2_VISIBLEATSTART) == 0)
		{
			if (type != OBJ_TEXT)
			{
				continue;
			}
			creatFlags |= COF_HIDDEN;
		}
		
		// Creation de l'objet                
		if ((ocPtr->ocOEFlags & OEFLAG_DONTCREATEATSTART) == 0)
		{
			[self f_CreateObject:loPtr->loHandle withOIHandle:loPtr->loOiHandle andX:0x80000000 andY:0x80000000 andDir:-1 andFlags:creatFlags andLayer:-1 andNumCreation:-1];
		}
	}
	[rhEvtProg assemblePrograms];
	
	// Remet le timer
	rhTimerOld = CFAbsoluteTimeGetCurrent()*1000 - rhFrame->fadeTimerDelta;
	rhVBLOld = ([rhApp newGetCptVBL] - rhFrame->fadeVblDelta);	
}
-(void)F_ReInitObjects
{
	int count = 0;
	int no;
	for (no = 0; no < rhNObjects; no++)
	{
		while (rhObjectList[count] == nil)
		{
			count++;
		}
		CObject* hoPtr = rhObjectList[count];
		count++;
		if (hoPtr->ros != nil)
		{
			[hoPtr->ros reInit_Spr:NO];
		}
	}
}

// VIRE LES SPRITES EN FIN DE FADE IN
// ----------------------------------
-(void)f_RemoveObjects
{
	int count = 0;
	int no;
	for (no = 0; no < rhNObjects; no++)
	{
		while (rhObjectList[count] == nil)
		{
			count++;
		}
		CObject* hoPtr = rhObjectList[count];
		count++;
		if (hoPtr->ros != nil)
		{
			if (hoPtr->roc->rcSprite != nil)
			{
				// Save Z-order value before deleting sprite
				hoPtr->ros->rsZOrder = hoPtr->roc->rcSprite->sprZOrder;
				
				// Delete sprite
				[spriteGen delSpriteFast:hoPtr->roc->rcSprite];
			}
		}
		if ((hoPtr->hoOEFlags & OEFLAG_QUICKDISPLAY) != 0)
		{
			[self remove_QuickDisplay:hoPtr];
		}
	}
}

-(void)killFrameObjects
{
	// Arrete tous les sprites, en mode FAST
	// Kill all the objects except for the Physics Engine objects
	for (int n=0; n<rhMaxObjects && rhNObjects!=0; n++)
	{
		if(rhObjectList[n]!=nil)
		{
			CObject* pHo=rhObjectList[n];
			if (pHo->hoType<32 || pHo->hoCommon->ocIdentifier != BASEIDENTIFIER )
				[self f_KillObject:n withFast:YES];
		}
	}

	// Kill the Physics Engine objects
	for (int n=0; n<rhMaxObjects && rhNObjects!=0; n++)
	{
		if(rhObjectList[n]!=nil )
		{
			CObject* pHo = rhObjectList[n];
			if ( pHo->hoType>=32 && pHo->hoCommon->ocIdentifier == BASEIDENTIFIER )
				[self f_KillObject:n withFast:YES];
		}
	}
	rh4FirstQuickDisplay = (short) 0x8000;
}
-(void)y_KillLevel:(BOOL)bLeaveSamples
{
	// Clear ladders & additional backdrops
	[self resetFrameLayers:-1 withFlag:NO];
	
	// ++v1.03.35: stop sounds only if not GANF_SAMPLESOVERFRAMES
	if (!bLeaveSamples)
	{
		if ((rhApp->gaNewFlags & GANF_SAMPLESOVERFRAMES) == 0)
		{
			[rhApp->soundPlayer stopAllSounds];
		}
		else 
		{
			[rhApp->soundPlayer keepCurrentSounds];
		}

	}
}
-(void)resetFrameLayers:(int)nLayer withFlag:(BOOL)bDeleteFrame
{
	int i, nLayers;
	
	if (nLayer == -1)
	{
		i = 0;
		nLayers = rhFrame->nLayers;
	}
	else
	{
		i = nLayer;
		nLayers = (nLayer + 1);
	}
	
	for (; i < nLayers; i++)
	{
		CLayer* pLayer = rhFrame->layers[i];
		
		// Delete backdrop sprites
		int j;
		CLO* plo;
		int nLOs = pLayer->nBkdLOs;
		for (j = 0; j < nLOs; j++)
		{
			plo = [rhFrame->LOList getLOFromIndex:((short) (pLayer->nFirstLOIndex + j))];
			
			// Delete sprite
			for (int ns = 0; ns < 4; ns++)
			{
				if (plo->loSpr[ns] != nil)
				{
					[spriteGen delSpriteFast:plo->loSpr[ns]];
					plo->loSpr[ns] = nil;
				}
			}
		}
		
		if (pLayer->pBkd2 != nil)
		{
			for (j = 0; j < [pLayer->pBkd2 size]; j++)
			{
				CBkd2* pbkd = (CBkd2*)[pLayer->pBkd2 get:j];
				// Delete sprite
				for (int ns = 0; ns < 4; ns++)
				{
					if (pbkd->pSpr[ns] != nil)
					{
						[spriteGen delSpriteFast:pbkd->pSpr[ns]];
						pbkd->pSpr[ns] = nil;
					}
				}
			}
		}
		
		// Initialize permanent data
		pLayer->dwOptions = pLayer->backUp_dwOptions;
		pLayer->xCoef = pLayer->backUp_xCoef;
		pLayer->yCoef = pLayer->backUp_yCoef;
		pLayer->nBkdLOs = pLayer->backUp_nBkdLOs;
		pLayer->nFirstLOIndex = pLayer->backUp_nFirstLOIndex;
		
		// Initialize volatil data
		pLayer->x = pLayer->y = pLayer->dx = pLayer->dy = 0;
		
		// Free additional backdrops
		pLayer->pBkd2 = nil;
		
		// Free ladders
		pLayer->pLadders = nil;
	}
}
-(void)saveGlobalObjectsData
{
	CObject* hoPtr;
	CObjInfo* oilPtr;
	int oil, obj;
	COI* oiPtr;
	NSString* name;
	short o;
	
	for (oil = 0; oil < rhMaxOI; oil++)
	{
		oilPtr = rhOiList[oil];
		if (oilPtr==nil)
		{
			continue;
		}
		
		// Un objet defini?
		o = oilPtr->oilObject;
		if (oilPtr->oilOi != 0x7FFF && (o & 0x8000) == 0)
		{
			oiPtr = [rhApp->OIList getOIFromHandle:oilPtr->oilOi];
			
			// Un objet global?
			if ((oiPtr->oiFlags & OIF_GLOBAL) != 0)
			{
				hoPtr = rhObjectList[o];
				
				// Un objet sauvable?
				if (oilPtr->oilType != OBJ_TEXT && oilPtr->oilType != OBJ_COUNTER && hoPtr->rov == nil)
				{
					continue;
				}
				
				// Recherche un element deja defini
				name = [NSString stringWithFormat:@"%@::%i", oilPtr->oilName, oilPtr->oilType];
				
				if (rhApp->adGO == nil)
				{
					rhApp->adGO = [[CArrayList alloc] init ];
				}
				
				// Rechercher l'objet dans les objets dÈj‡ crÈÈs
				BOOL flag = NO;
				CSaveGlobal* save = nil;
				for (obj = 0; obj < [rhApp->adGO size]; obj++)
				{
					save = (CSaveGlobal*)[rhApp->adGO get:obj];
					if ([name compare:save->name] == 0)
					{
						flag = YES;
						break;
					}
				}
				if (flag==false)
				{
					save = [[CSaveGlobal alloc] init];
					save->name = [[NSString alloc] initWithString:name];
					save->objects = [[CArrayList alloc] init];
					[rhApp->adGO add:save];
				}
				else
				{
					[save->objects clearRelease];
				}
				
				// Stockage des valeurs...
				int n;
				while (YES)
				{
					hoPtr = rhObjectList[o];
					
					// Stocke
					if (oilPtr->oilType == OBJ_TEXT)
					{
						CText* text = (CText*) hoPtr;
						CSaveGlobalText* saveText = [[CSaveGlobalText alloc] init];
						saveText->pString = [[NSString alloc] initWithString:text->rsTextBuffer];
						saveText->rsMini = text->rsMini;
						[save->objects add:saveText];
					}
					else if (oilPtr->oilType == OBJ_COUNTER)
					{
						CCounter* counter = (CCounter*) hoPtr;
						CSaveGlobalCounter* saveCounter = [[CSaveGlobalCounter alloc] init];
						saveCounter->pValue = [[CValue alloc] initWithValue:counter->rsValue];
						saveCounter->rsMini = counter->rsMini;
						saveCounter->rsMaxi = counter->rsMaxi;
						saveCounter->rsMiniDouble = counter->rsMiniDouble;
						saveCounter->rsMaxiDouble = counter->rsMaxiDouble;
						[save->objects add:saveCounter];
					}
					else
					{
						CSaveGlobalValues* saveValues = [[CSaveGlobalValues alloc] init];
						saveValues->flags = hoPtr->rov->rvValueFlags;
						saveValues->rvNumberOfValues = hoPtr->rov->rvNumberOfValues;
						saveValues->pValues = (CValue**)malloc(hoPtr->rov->rvNumberOfValues*sizeof(CValue*));
						for (n = 0; n < hoPtr->rov->rvNumberOfValues; n++)
						{
							saveValues->pValues[n] = nil;
							if (hoPtr->rov->rvValues[n] != nil)
							{
								saveValues->pValues[n] = [[CValue alloc] initWithValue:hoPtr->rov->rvValues[n]];
							}
						}
						saveValues->pStrings = (NSString**)malloc(STRINGS_NUMBEROF_ALTERABLE*sizeof(NSString*));
						for (n = 0; n < STRINGS_NUMBEROF_ALTERABLE; n++)
						{
							saveValues->pStrings[n] = nil;
							if (hoPtr->rov->rvStrings[n] != nil)
							{
								saveValues->pStrings[n] = [[NSString alloc] initWithString:hoPtr->rov->rvStrings[n]];
							}
						}
						[save->objects add:saveValues];
					}
					
					// Un autre objet?
					o = hoPtr->hoNumNext;
					if ((o & 0x8000) != 0)
					{
						break;
					}
				}
			}
		}
	}
}
-(void)loadGlobalObjectsData
{
	CObject* hoPtr;
	CObjInfo* oilPtr;
	int oil, obj;
	COI* oiPtr;
	NSString* name;
	short o;
	
	if (rhApp->adGO == nil)
	{
		return;
	}
	
	for (oil = 0; oil < rhMaxOI; oil++)
	{
		oilPtr = rhOiList[oil];
		if (oilPtr==nil)
		{
			continue;
		}
		
		// Un objet defini?
		o = oilPtr->oilObject;
		if (oilPtr->oilOi != 0x7FFF && (o & 0x8000) == 0)
		{
			oiPtr = [rhApp->OIList getOIFromHandle:oilPtr->oilOi];
			
			// Un objet global?
			if ((oiPtr->oiFlags & OIF_GLOBAL) != 0)
			{
				name = [NSString stringWithFormat:@"%@::%i", oilPtr->oilName, oilPtr->oilType];
				
				// Recherche dans les headers
				for (obj = 0; obj < [rhApp->adGO size]; obj++)
				{
					CSaveGlobal* save = (CSaveGlobal*)[rhApp->adGO get:obj];
					if ([name compare:save->name] == 0)
					{
						int count = 0;
						while (true)
						{
							hoPtr = rhObjectList[o];
							
							if (oilPtr->oilType == OBJ_TEXT)
							{
								CSaveGlobalText* saveText = (CSaveGlobalText*)[save->objects get:count];
								CText* text = (CText*) hoPtr;
								if (text->rsTextBuffer!=nil)
								{
									[text->rsTextBuffer release];
								}
								text->rsTextBuffer = [[NSString alloc] initWithString:saveText->pString];
								text->rsMini = saveText->rsMini;
							}
							else if (oilPtr->oilType == OBJ_COUNTER)
							{
								CSaveGlobalCounter* saveCounter = (CSaveGlobalCounter*)[save->objects get:count];
								CCounter* counter = (CCounter*) hoPtr;
								if (counter->rsValue!=nil)
								{
									[counter->rsValue release];
								}
								counter->rsValue = [[CValue alloc] initWithValue:saveCounter->pValue];
								counter->rsMini = saveCounter->rsMini;
								counter->rsMaxi = saveCounter->rsMaxi;
								counter->rsMiniDouble = saveCounter->rsMiniDouble;
								counter->rsMaxiDouble = saveCounter->rsMaxiDouble;
							}
							else
							{
								CSaveGlobalValues* saveValues = (CSaveGlobalValues*)[save->objects get:count];
								hoPtr->rov->rvValueFlags = saveValues->flags;

								if(hoPtr->rov->rvNumberOfValues != saveValues->rvNumberOfValues)
								{
									CValue** ptr = (CValue**)realloc(hoPtr->rov->rvValues, sizeof(CValue*)*saveValues->rvNumberOfValues);
									if(saveValues->rvNumberOfValues > hoPtr->rov->rvNumberOfValues )
									{
										size_t extraspace = saveValues->rvNumberOfValues - hoPtr->rov->rvNumberOfValues;
										memset(&ptr[hoPtr->rov->rvNumberOfValues], 0, extraspace*sizeof(CValue*));
									}

									if(ptr != NULL)
									{
										hoPtr->rov->rvValues = ptr;
										hoPtr->rov->rvNumberOfValues = saveValues->rvNumberOfValues;
									}
								}

								int n;
								for (n = 0; n < hoPtr->rov->rvNumberOfValues; n++)
								{
									if (saveValues->pValues[n] != nil)
									{
										if (hoPtr->rov->rvValues[n]!=nil)
										{
											[hoPtr->rov->rvValues[n] forceValue:saveValues->pValues[n]];
										}
										else
										{
											hoPtr->rov->rvValues[n] = [[CValue alloc] initWithValue:saveValues->pValues[n]];
										}
									}
								}
								for (n = 0; n < STRINGS_NUMBEROF_ALTERABLE; n++)
								{
									if (saveValues->pStrings[n] != nil)
									{
										if (hoPtr->rov->rvStrings[n]!=nil)
										{
											[hoPtr->rov->rvStrings[n] release];
										}
										hoPtr->rov->rvStrings[n] = [[NSString alloc] initWithString:saveValues->pStrings[n]];
									}
								}
							}
							
							// Un autre objet?
							o = hoPtr->hoNumNext;
							if ((o & 0x8000) != 0)
							{
								break;
							}
							
							// Regarde si il existe un suivant...
							count++;
							if (count >= [save->objects size])
							{
								break;
							}
						}
						break;
					}
				}
			}
		}
	}
}


-(int)f_CreateObject:(short)hlo withOIHandle:(short)oi andX:(int)coordX andY:(int)coordY andDir:(int)initDir andFlags:(short)flags andLayer:(int)nLayer andNumCreation:(int)numCreation
{
	CCreateObjectInfo* cob = [[CCreateObjectInfo alloc] init];
	
	while (true)
	{		
		// Trouve l'adresse du LO	
		// ~~~~~~~~~~~~~~~~~~~~~~~~~
		CLO* loPtr = nil;
		if (hlo != -1)
		{
			loPtr = [rhFrame->LOList getLOFromHandle:hlo];
		}
		
		// Trouve l'adresse du HFRAN
		// ~~~~~~~~~~~~~~~~~~~~~~~~~
		COI* oiPtr = [rhApp->OIList getOIFromHandle:oi];
		CObjectCommon* ocPtr = (CObjectCommon*) oiPtr->oiOC;
		
		// Flag visible at start
		// --------------------
		if ((ocPtr->ocFlags2 & OCFLAGS2_VISIBLEATSTART) == 0)
		{
			flags |= COF_HIDDEN;
		}
		
		// Pas trop d'objets?
		// ~~~~~~~~~~~~~~~~~~
		if (rhNObjects >= rhMaxObjects)
		{
			break;
		}
		
		// Cree l'objet
		CObject* hoPtr = nil;
		switch (oiPtr->oiType)
		{
			case 2:         // OBJ_SPR
				hoPtr = [[CActive alloc] init];
				break;
			case 3:         // OBJ_TEXT
				hoPtr = [[CText alloc] init];
				break;
			case 4:         // OBJ_QUEST
				hoPtr = [[CQuestion alloc] init];
				break;
			case 5:         // OBJ_SCORE
				hoPtr = [[CScore alloc] init];
				break;
			case 6:         // OBJ_LIVES
				hoPtr = [[CLives alloc] init];
				break;
			case 7:         // OBJ_COUNTER
				hoPtr = [[CCounter alloc] init];
				break;
			case 9:
				hoPtr=[[CCCA alloc]init];
				break;
			default:        // Extensions
				hoPtr = [[CExtension alloc] initWithType:oiPtr->oiType andRun:self];
                if (((CExtension*)hoPtr)->ext==nil)
                {
                    [hoPtr release];
                    hoPtr=nil;
                }
				break;
		}
		if (hoPtr == nil)
		{
			break;
		}
		
		// Insere l'objet dans la liste
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		if (numCreation < 0)
		{
			for (numCreation = 0; numCreation < rhMaxObjects; numCreation++)
			{
				if (rhObjectList[numCreation] == nil)
				{
					break;
				}
			}
		}
		if (numCreation >= rhMaxObjects)
		{
			return -1;
		}
		rhObjectList[numCreation] = hoPtr;
		rhNObjects++;
		hoPtr->hoIdentifier = ocPtr->ocIdentifier;			//; L'identifier ASCII de l'objet
		hoPtr->hoOEFlags = ocPtr->ocOEFlags;
		
		// Gestion de la boucle principale
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		if (numCreation > rh4ObjectCurCreate)				// Si objet DEVANT l'objet courant
		{
			rh4ObjectAddCreate++;					// Il faut explorer encore!
		}
		//            flagPlus=1;										//; Si une erreur ensuite...
		
		// Rempli la structure headerObject
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		hoPtr->hoNumber = (short) numCreation;					  			//; Numero de l'objet
		rh2CreationCount++;
		if (rh2CreationCount == 0)					// V243 protection tour de compteur
		{
			rh2CreationCount = 1;
		}
		hoPtr->hoCreationId = rh2CreationCount;		// Numero de creation!
		hoPtr->hoOi = oi;										//; L'OI
		hoPtr->hoHFII = hlo;									//; le HLO
		hoPtr->hoType = oiPtr->oiType;					//; Le type de l'objet
		[self oi_Insert:hoPtr];									//; Branche dans la liste
		hoPtr->hoAdRunHeader = self;							//; L'adresse de rhPtr
		hoPtr->hoCallRoutine = YES;

		//Store the viewscale
		hoPtr->controlScaleX = rhApp->mainView->viewScaleX;
		hoPtr->controlScaleY = rhApp->mainView->viewScaleY;
		
		// --------------------------------------------
		// Gestion des LOADONCALL
		// --------------------------------------------
		//	if (rhGameFlags&GAMEFLAGS_LOADONCALL)
		//	{
		//            loadOnCall(Get_ObjInfo(hoPtr.hoOi));
		//	}
		
		// Adresse de l'objectsCommon
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~
		hoPtr->hoCommon = ocPtr;
		
		// Rempli la structure CreateObjectInfo (virer X et Y)
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		int x = coordX;									// X
		if (x == 0x80000000)
		{
			x = loPtr->loX;
		}
		int y = coordY;									// Y
		if (y == 0x80000000)
		{
			y = loPtr->loY;
		}

		cob->cobX = x;
		cob->cobY = y;

		// Set layer
		if (loPtr != nil)
		{
			if (nLayer == -1)
			{
				nLayer = loPtr->loLayer;
			}
		}

		cob->cobLayer = nLayer;
		hoPtr->hoLayer = nLayer;

		[hoPtr setPosition:x withY:y];
		
		// Set z-order value
		CLayer* pLayer = rhFrame->layers[nLayer];
		pLayer->nZOrderMax++;
		cob->cobZOrder = pLayer->nZOrderMax;
		
		cob->cobFlags = flags;								//; Flags creation
		cob->cobDir = initDir;								//; Direction initiale
		cob->cobLevObj = loPtr;							//; Huge levobj
		
		// --------------------------------------------
		// Gestion des Animations / Mouvements / Values
		// --------------------------------------------
		
		// Debut des structures facultatives	
		hoPtr->roc = nil;
		if ((hoPtr->hoOEFlags & (OEFLAG_ANIMATIONS | OEFLAG_MOVEMENTS | OEFLAG_SPRITES)) != 0)
		{
			hoPtr->roc = [[CRCom alloc] init];
		}
		
		// Appel des routines d'initialisation Movements
		// ---------------------------------------------
		hoPtr->rom = nil;
		if ((hoPtr->hoOEFlags & OEFLAG_MOVEMENTS) != 0)
		{
			hoPtr->rom = [[CRMvt alloc] init];
			if ((cob->cobFlags & COF_NOMOVEMENT) == 0)
			{
				[hoPtr->rom initMovement:0 withObject:hoPtr andOC:ocPtr andCOB:cob andNum:-1];
			}
		}
		
		// Appel des routines d'initialisation Animation
		// ---------------------------------------------
		hoPtr->roa = nil;
		if ((hoPtr->hoOEFlags & OEFLAG_ANIMATIONS) != 0)
		{
			hoPtr->roa = [[CRAni alloc] initWithHO:hoPtr];
			[hoPtr->roa initRAni];
		}
		
		// Appel des routines d'initialisation sprite 1
		// ---------------------------------------------
		hoPtr->ros = nil;
		if ((hoPtr->hoOEFlags & OEFLAG_SPRITES) != 0)
		{
			hoPtr->ros = [[CRSpr alloc] initWithHO:hoPtr andOC:ocPtr andCOB:cob];
		}
		
		// Appel des routines d'initialisation Values
		// ---------------------------------------------
		hoPtr->rov = nil;
		if ((hoPtr->hoOEFlags & OEFLAG_VALUES) != 0)
		{
			hoPtr->rov = [[CRVal alloc] initWithHO:hoPtr andOC:ocPtr andCOB:cob];
		}
		
		// -----------------------------------------------
		// Appel de la routine d'initialisation standard
		// -----------------------------------------------
		[hoPtr initObject:ocPtr withCOB:cob];
		
		// Appel des routines d'initialisation sprite 2
		// ---------------------------------------------
		if ((hoPtr->hoOEFlags & OEFLAG_SPRITES) != 0)
		{
			[hoPtr->ros init2];
		}
		
		[cob release];
		// Sortie sans erreur
		return numCreation;									// Retourne avec EAX=NOBJECT
	}
	[cob release];
	return -1;
}
-(void)f_KillObject:(int)nObject withFast:(BOOL)bFast
{
	// Pointe l'objet
	// ~~~~~~~~~~~~~~
	CObject* hoPtr = rhObjectList[nObject];
	if (hoPtr == nil)
	{
		return;
	}

	// V243 Si sprite a moitie effac�
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (bFast == YES && hoPtr->hoCreationId == 0)
	{
		rhObjectList[nObject] = nil;
		rhNObjects--;
		return;
	}
	
	// Vire les pointeurs dans les routines SHOOT
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	[self killShootPtr:hoPtr];
	
	// Detruit les mouvements, les values
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	BOOL bOwnerDrawRelease=NO;
	if (hoPtr->rom != nil)
	{
		[hoPtr->rom kill:bFast];
	}
	if (hoPtr->rov != nil)
	{
		[hoPtr->rov kill:bFast];
	}
	if (hoPtr->ros != nil)
	{
		bOwnerDrawRelease=[hoPtr->ros kill:YES];
	}
	if (hoPtr->roc != nil)
	{
		[hoPtr->roc kill:bFast];
	}
	if (hoPtr->roa!=nil)
	{
		[hoPtr->roa kill:bFast];
	}
	
	// Appelle la routine de destruction specifique
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	[hoPtr kill:bFast];
		
	/*	// Decremente les indicateurs de tabulation
	 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	 if (hoPtr.hoOEFlags&OEFLAG_TABSTOP && hoPtr.hoOEFlags&OEFLAG_WINDOWPROC)
	 {
	 rh4.rh4TabCounter--;
	 }
	 */
	
	// Enleve le OI (pas en mode panique!)
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	[self oi_Delete:hoPtr];
	
	// Vire les sprites si LOADONCALL et DISCARD
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	/*	if (rhGameFlags&GAMEFLAGS_LOADONCALL)
	 {
	 discardAfterUse(Get_ObjInfo(hoPtr.hoOi));
	 }
	 */
	// Vire de la liste
	// ~~~~~~~~~~~~~~~~
	hoPtr->hoCreationId = 0;
	hoPtr->hoCallRoutine = NO;
	if ((hoPtr->hoOEFlags & OEFLAG_QUICKDISPLAY) != 0)
	{
		[self remove_QuickDisplay:hoPtr];
	}	
	if (bOwnerDrawRelease==NO)
	{
		[hoPtr release];
	}
	rhObjectList[nObject] = nil;
	
	// Ajout Yves Build 242
	rhNObjects--;
}
	

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// GESTION DE LA LISTE DE DESTROY
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
-(void)destroy_Add:(int)hoNumber
{
	rhDestroyList[hoNumber / 32] |= (1 << (hoNumber & 31));
	rhDestroyPos++;
}
-(void)destroy_List
{
	if (rhDestroyPos == 0)
	{
		return;
	}
	
	int nob = 0;
	int dw;
	int count;
	while (nob < rhMaxObjects)
	{
		dw = rhDestroyList[nob / 32];
		if (dw != 0)
		{
			for (count = 0; dw != 0 && count < 32; count++)
			{
				if ((dw & 1) != 0)
				{
					// Appeler le message NO MORE OBJECT juste avant la destruction (si objet sprite!)
					CObject* pHo = rhObjectList[nob + count];
					if (pHo != nil)
					{
						if (pHo->hoOiList->oilNObjects == 1)
						{
							[rhEvtProg handle_Event:pHo withCode:(pHo->hoType| (-33 << 16))];	    // CNDL_EXTNOMOREOBJECT
						}
					}
					// Detruit l'objet!
					[self f_KillObject:nob + count withFast:NO];
					rhDestroyPos--;
				}
				dw = dw >> 1;
			}
			rhDestroyList[nob / 32] = 0;
			if (rhDestroyPos == 0)
			{
				return;
			}
		}
		nob += 32;
	}
}
// Detruit les references aux objets shoot
// ---------------------------------------
-(void)killShootPtr:(CObject*)hoSource
{
	int count = 0;
	int nObject;
	CObject* hoPtr;
	for (nObject = 0; nObject < rhNObjects; nObject++)
	{
		while (rhObjectList[count] == nil)
		{
			count++;
		}
		hoPtr = rhObjectList[count];
		count++;
		
		if (hoPtr->rom != nil)
		{
			if (hoPtr->roc->rcMovementType == MVTYPE_BULLET)
			{
				 CMoveBullet* mBullet = (CMoveBullet*) hoPtr->rom->rmMovement;
				 if (mBullet->MBul_ShootObject == hoSource && mBullet->MBul_Wait == YES)
				 {
					 [mBullet startBullet];
				 }
			}
		}
	}
}

// Insere l'objet [esi] dans les liste d'OI
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(void)oi_Insert:(CObject*)pHo
{
	short oi = pHo->hoOi;
	
	int num;
	for (num = 0; num < rhMaxOI; num++)
	{
		if (rhOiList[num]->oilOi == oi)
		{
			break;
		}
	}
	CObjInfo* poil = rhOiList[num];
	
	if ((poil->oilObject & 0x8000) != 0)
	{
		// N'existe pas avant
		poil->oilObject = pHo->hoNumber;
		pHo->hoNumPrev = (short) (num | 0x8000);
		pHo->hoNumNext = (short) 0x8000;
	}
	else
	{
		// Existe avant: insere en tete de liste
		CObject* pHo2 = rhObjectList[poil->oilObject];
		pHo->hoNumPrev = pHo2->hoNumPrev;
		pHo2->hoNumPrev = pHo->hoNumber;
		pHo->hoNumNext = pHo2->hoNumber;
		poil->oilObject = pHo->hoNumber;
	}
	
	// Prend les donnees contenues dans oiList
	pHo->hoEvents = (LPDWORD)((LPBYTE)rhEvtProg->rhEvents[0]+poil->oilEvents);					// Les evenements
	pHo->hoOiList = poil;							// L'adresse dans la liste OiList
	pHo->hoLimitFlags = poil->oilLimitFlags;
	if (pHo->hoHFII == -1)					// Si le HFII est mauvais, met le premier disponible
	{
		pHo->hoHFII = poil->oilHFII;
	}
	else
	{
		if (poil->oilHFII == -1)
		{
			poil->oilHFII = pHo->hoHFII;
		}
	}
	poil->oilNObjects += 1;						// Un objet de plus de meme OI
}
// Delete un OI retourne le numero de l'objet suivant en AX
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(void)oi_Delete:(CObject*)pHo
{
	// Decremente dans la liste des OI
	CObjInfo* poil = pHo->hoOiList;
	poil->oilNObjects -= 1;
	
	// Gere les precedents/suivants
	if (pHo->hoNumPrev >= 0)
	{
		CObject* pHo2 = rhObjectList[pHo->hoNumPrev];
		if (pHo->hoNumNext >= 0)
		{
			// Au milieu
			CObject* pHo3 = rhObjectList[pHo->hoNumNext];
			if (pHo2 != nil)
			{
				pHo2->hoNumNext = pHo->hoNumNext;
			}
			if (pHo3 != nil)
			{
				pHo3->hoNumPrev = pHo->hoNumPrev;
			}
		}
		else
		{
			if (pHo2 != nil)
			{
				pHo2->hoNumNext = (short) 0x8000;
			}
		}
	}
	else
	{
		// Au debut de la liste
		if (pHo->hoNumNext >= 0)
		{
			CObject* pHo2 = rhObjectList[pHo->hoNumNext];
			if (pHo2 != nil)
			{
				pHo2->hoNumPrev = pHo->hoNumPrev;
				poil->oilObject = pHo2->hoNumber;
			}
		}
		// Plus rien dans la liste!
		else
		{
			poil->oilObject = (short) 0x8000;
		}
	}
}

-(BOOL)isPaused
{
	return rh2PauseCompteur != 0;
}

/** Goes into pause mode.
 */
-(void)pause
{
	// Le compteur de sauvegarde
	// ~~~~~~~~~~~~~~~~~~~~~~~~~
	rh2PauseCompteur++;
	
	if (rh2PauseCompteur == 1)
	{
		//Pause subapps
		for (int n=0; n<MAX_SUBAPPS; n++)
		{
			if (subApps[n] != nil)
				[subApps[n] pause];
		}
		
		// Sauve le timer
		// ~~~~~~~~~~~~~~
		rh2PauseTimer = CFAbsoluteTimeGetCurrent()*1000;
		
		// Sauve le VBL
		// ~~~~~~~~~~~~
		rh2PauseVbl = [rhApp newGetCptVBL] - rhVBLOld;
		
		// Arret de tous les objets
		// ~~~~~~~~~~~~~~~~~~~~~~~~
		int count = 0;
		int no;
		for (no = 0; no < rhNObjects; no++)
		{
			while (rhObjectList[count] == nil)
			{
				count++;
			}
			CObject* hoPtr = rhObjectList[count];
			count++;
			if (hoPtr->hoType >= KPX_BASE)
			{
				CExtension* e = (CExtension*) hoPtr;
				[e->ext pauseRunObject];
			}
		}		
		// Arret des musiques et des sons
		// ------------------------------
		[rhApp->soundPlayer pause:YES];
	}
}
/** Quits the pause mode.
 */
-(void)resume
{
	// Uniquement au dernier retour
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (rh2PauseCompteur>0)
    {
        rh2PauseCompteur--;
		if (rh2PauseCompteur == 0)
        {
			//Resume subapps
			for (int n=0; n<MAX_SUBAPPS; n++)
			{
				if (subApps[n] != nil)
					[subApps[n] resume];
			}
			
            // Remet les sons
            // --------------
            [rhApp->soundPlayer resume:YES];
		
            // Remet tous les objets
            // ~~~~~~~~~~~~~~~~~~~~~
            int count = 0;
            int no;
            for (no = 0; no < rhNObjects; no++)
            {
                while (rhObjectList[count] == nil)
                {
                    count++;
                }
                CObject* hoPtr = rhObjectList[count];
                count++;
                if (hoPtr->hoType >= KPX_BASE)
                {
                    CExtension* e = (CExtension*) hoPtr;
                    [e->ext continueRunObject];
                }
            }
		
            // Remet le VBL
            // ~~~~~~~~~~~~
            rhVBLOld = [rhApp newGetCptVBL] - rh2PauseVbl;
            rh4PauseKey = 0;
		
            // Remet le timer
            // --------------
            double tick = CFAbsoluteTimeGetCurrent()*1000;
            tick -= rh2PauseTimer;
            rhTimerOld += tick;
		
            // Condition end of pause
            // ----------------------
            rh4EndOfPause=rhLoopCount;
            [rhEvtProg handle_GlobalEvents:((-8<<16)|0xFFFD)];
        }
	}
}

// Scroll frame
/** Scrolls the level.
 */
-(void)scrollLevel
{
	int xSrc, ySrc, xDest, yDest;
	BOOL flgScroll, flgScrollMask;
	int lg, ht, lgLog, htLog;
	
	// Calcul rectangles de scrolling
	lgLog = rhFrame->leEditWinWidth;
	htLog = rhFrame->leEditWinHeight;
	
	float xCoef = 1.0f;
	float yCoef = 1.0f;
	
	if (rhFrame->nLayers > 0)
	{
		CLayer* pLayer0 = rhFrame->layers[0];
		xCoef = pLayer0->xCoef;
		yCoef = pLayer0->yCoef;
	}
	
	int oX = rhFrame->leLastScrlX;
	int nX = rh3DisplayX;
	
	if (xCoef != 1.0f)
	{
		oX = (int) ((float) oX * xCoef);
		nX = (int) ((float) nX * xCoef);
	}
	
	if (nX < oX)
	{
		xSrc = 0;
		xDest = oX - nX;
		rhFrame->leLastScrlX = rh3DisplayX;
	}
	else
	{
		xSrc = nX - oX;
		xDest = 0;
		if (xSrc != 0)
		{
			rhFrame->leLastScrlX = rh3DisplayX;
		}
	}
	
	int oY = rhFrame->leLastScrlY;
	int nY = rh3DisplayY;
	
	if (yCoef != 1.0f)
	{
		oY = (int) ((float) oY * yCoef);
		nY = (int) ((float) nY * yCoef);
	}
	
	if (nY < oY)
	{
		ySrc = 0;
		yDest = oY - nY;
		
		rhFrame->leLastScrlY = rh3DisplayY;
	}
	else
	{
		ySrc = nY - oY;
		yDest = 0;
		
		if (ySrc != 0)
		{
			rhFrame->leLastScrlY = rh3DisplayY;
		}
	}
	
	lg = lgLog - xSrc - xDest;
	ht = htLog - ySrc - yDest;
	
	// Update coordinates
	rhFrame->leX = rh3DisplayX;
	rhFrame->leY = rh3DisplayY;
	
	// Clear sprites
	[spriteGen activeSprite:nil withFlags:AS_REDRAW andRect:CRectNil];		// AS_DEACTIVATE
	
	// Hide or show layers? => hide or show objects
	for (int nLayer = 0; nLayer < rhFrame->nLayers; nLayer++)
	{
		CLayer* pLayer = rhFrame->layers[nLayer];
		[pLayer scrollToX:rhFrame->leX andY:rhFrame->leY];

		if ((pLayer->dwOptions & FLOPT_TOSHOW) != 0)
		{
			[self f_ShowAllObjects:nLayer withFlag:YES];
		}
		if ((pLayer->dwOptions & FLOPT_TOHIDE) != 0)
		{
			[self f_ShowAllObjects:nLayer withFlag:NO];
		}
	}
	
	[self f_UpdateWindowPos:(int)rhFrame->leX withY:(int)rhFrame->leY];
	
	// Scrolling
	flgScroll = flgScrollMask = NO;
	
	if (lg > lgLog / 4 && ht > htLog / 4)
	{
		if (lg == lgLog && ht == htLog)
		{
			flgScroll = YES;
			flgScrollMask = YES;
		}
		else
		{
			// Scroll ecran logique
			if (lg > 0 && ht > 0)
				flgScroll = YES; 			
		}
	}
	
	// Si pas eu de scrolling, reafficher tout
	if (flgScroll == NO)
	{
		[self redrawLevel:DLF_DONTUPDATE];
	}
	
	// Si scrolling effectue, refaire un redraw clippe
	else
	{
		BOOL bRedrawDone = NO;

		if (xSrc != 0 || xDest != 0)
		{
			// Ajouter zone totale pour rafraichissement fenetre
			if (flgScrollMask != NO)
			{
				//		    ColMask_SetClip (idEditWin, &rcClipH);
				[self redrawLevel:DLF_DONTUPDATE | DLF_COLMASKCLIPPED];
			}
			else
			{
				[self redrawLevel:DLF_DONTUPDATE | DLF_DONTUPDATECOLMASK];
			}
			
			bRedrawDone = YES;
		}

		if (ySrc != 0 || yDest != 0)
		{
			// Ajouter zone totale pour rafraichissement fenetre
			if (flgScrollMask != NO)
				[self redrawLevel:DLF_DONTUPDATE | DLF_COLMASKCLIPPED];
			else
				[self redrawLevel:DLF_DONTUPDATE | DLF_DONTUPDATECOLMASK];
			
			bRedrawDone = YES;
		}
		
		// Redraw not done? redraw layers greater than 0
		if (!bRedrawDone && rhFrame->nLayers > 0)
		{
			[self redrawLevel:DLF_DONTUPDATE | DLF_DONTUPDATECOLMASK];
		}
	}
}

/** Update of level coordinates in case of a scrolling but when everything has to be redrawn   
 */
-(void)updateScrollLevelPos
{
	int xSrc, ySrc;
	
	float xCoef = (float) 1.0;
	float yCoef = (float) 1.0;
	
	if (rhFrame->nLayers > 0)
	{
		CLayer* pLayer0 = rhFrame->layers[0];
		xCoef = pLayer0->xCoef;
		yCoef = pLayer0->yCoef;
	}
	
	int oX = rhFrame->leLastScrlX;
	int nX = rh3DisplayX;
	
	if (xCoef != 1.0)
	{
		oX = (int) ((float) oX * xCoef);
		nX = (int) ((float) nX * xCoef);
	}
	
	if (nX < oX)
	{
		xSrc = 0;
		//	    xDest = oX - nX;
		rhFrame->leLastScrlX = rh3DisplayX;
	}
	else
	{
		xSrc = nX - oX;
		//	    xDest = 0;
		if (xSrc != 0)
		{
			rhFrame->leLastScrlX = rh3DisplayX;
		}
	}
	
	int oY = rhFrame->leLastScrlY;
	int nY = rh3DisplayY;
	
	if (yCoef != 1.0)
	{
		oY = (int) ((float) oY * yCoef);
		nY = (int) ((float) nY * yCoef);
	}
	
	if (nY < oY)
	{
		ySrc = 0;
		//	    yDest = oY - nY;
		
		rhFrame->leLastScrlY = rh3DisplayY;
	}
	else
	{
		ySrc = nY - oY;
		//	    yDest = 0;
		
		if (ySrc != 0)
		{
			rhFrame->leLastScrlY = rh3DisplayY;
		}
	}
	
	// Update coordinates
	rhFrame->leX = rh3DisplayX;
	rhFrame->leY = rh3DisplayY;
}


-(void)transitionDrawFrame
{
	rh3Scrolling |= RH3SCROLLING_REDRAWLAYERS;
	[self screen_Update];
}

-(void)screen_Update
{	
	rhApp->renderer->clearWithRunApp(rhApp);
	
	
	if (rh3Scrolling!=0)
	{
		if ((rh3Scrolling&RH3SCROLLING_REDRAWALL)!=0)
		{
			// Update scroll pos if scrolling
			if (rhFrame->leX != rh3DisplayX || rhFrame->leY != rh3DisplayY)
				[self updateScrollLevelPos];

			for (int nLayer = 0; nLayer < rhFrame->nLayers; nLayer++)
			{
				CLayer* pLayer = rhFrame->layers[nLayer];
				[pLayer scrollToX:rhFrame->leX andY:rhFrame->leY];
			}

			// Redraw everything 
			int flags = DLF_DRAWOBJECTS | DLF_REDRAWLAYER;
			if ((rh3Scrolling & RH3SCROLLING_REDRAWTOTALCOLMASK) == 0 && (rhFrame->leFlags & LEF_TOTALCOLMASK) != 0)
				flags |= DLF_DONTUPDATECOLMASK;
			[self redrawLevel:flags];
			
			rh3DisplayX=rhWindowX;
			rh3DisplayY=rhWindowY;		
		}
		else if ((rh3Scrolling&RH3SCROLLING_SCROLL)!=0)
		{
			// Update scroll pos if scrolling
			if (rhFrame->leX != rh3DisplayX || rhFrame->leY != rh3DisplayY)
			{
				[self scrollLevel];
			}
		}
		else
		{
			[self redrawLevel:DLF_DONTUPDATE|DLF_DRAWOBJECTS|DLF_REDRAWLAYER];
		}
	}
	
	[spriteGen spriteClear];
	[spriteGen spriteUpdate];
	[spriteGen spriteDraw:rhApp->renderer];
	[self draw_QuickDisplay:rhApp->renderer];
	rh3Scrolling=0;
}

-(void)redrawLevel:(int)flags
{
	int			lgEdit, htEdit;
	int			i, obst, v, cm_box, x2edit, y2edit, flgColMaskEmpty = FALSE;
	WORD		img = 0;
	CLO*		plo = nil;
	CObject*	hoPtr = nil;
	BOOL		bTotalColMask = YES;//((rhFrame->leFlags & LEF_TOTALCOLMASK) != 0);
	BOOL		bUpdateColMask = ((flags & DLF_DONTUPDATECOLMASK) == 0);
	BOOL		bSkipLayer0 = ((flags & DLF_SKIPLAYER0) != 0);
	CRect		rc;
	int			nLayer = 0;
	BOOL		bLayer0Invisible = FALSE;
	
	if (rhFrame->colMask==nil)
	{
		bUpdateColMask=NO;
	}
	
	rc.left = rc.top = 0;
	rc.right = rhFrame->leEditWinWidth;
	rc.bottom = rhFrame->leEditWinHeight;
	lgEdit = (int)rc.right;
	x2edit = lgEdit - 1;
	htEdit = (int)rc.bottom;
	y2edit = htEdit - 1;

	//Update visible rect in the layer
	for (int i = 0; i < rhFrame->nLayers; i++)
	{
		CLayer* pLayer = rhFrame->layers[i];
		[pLayer updateVisibleRect];
	}

	// Hide or show layers? => hide or show objects
	if ( (flags & (DLF_DRAWOBJECTS|DLF_STARTLEVEL|DLF_RESTARTLEVEL)) != 0 )
	{
		for (; nLayer < (int) rhFrame->nLayers; nLayer++)
		{
			CLayer* pLayer = rhFrame->layers[nLayer];
			if ( (pLayer->dwOptions & FLOPT_TOSHOW) != 0 )
				[self f_ShowAllObjects:nLayer withFlag:YES];
			if ( (pLayer->dwOptions & FLOPT_TOHIDE) != 0 )
				[self f_ShowAllObjects:nLayer withFlag:NO];
		}
	}

	// Hide background objects from layers to hide
	// Build 248 : déplacé ici avant le F_UpdateWindowPos
	nLayer = 0;
	for (; nLayer < (int)rhFrame->nLayers; nLayer++)
	{
		CLayer* pLayer = rhFrame->layers[nLayer];
		
		// Hide layer?
		if ( (pLayer->dwOptions & FLOPT_TOHIDE) != 0 )
		{
			// Delete background sprites
			int nLOs = (int)pLayer->nBkdLOs;		
			for (i=0; i<nLOs; i++)
			{
				plo = [rhFrame->LOList getLOFromIndex:pLayer->nFirstLOIndex+i];
				
				// Delete sprite
				for (int ns=0; ns<4; ns++)
				{
					if ( plo->loSpr[ns] != nil )
					{
						[spriteGen delSprite:plo->loSpr[ns]];
						plo->loSpr[ns] = nil;
					}
				}
			}
		}
	}
	
	// Clear background and update objects
	if (flags & DLF_DRAWOBJECTS)
	{
		// Redraw layer? force sprites to be cleared
		if ( (flags & DLF_REDRAWLAYER) != 0 )
		{
			// Force re-display of all the sprites
			[spriteGen activeSprite:nil withFlags:AS_REDRAW andRect:CRectNil];
		}
		
		// Update active sprites and clear background
		[self f_UpdateWindowPos:(int)rhFrame->leX withY:(int)rhFrame->leY];
		
		// Force re-display of all the sprites
		[spriteGen activeSprite:nil withFlags:AS_REDRAW andRect:CRectNil];
	}
		
	// Erase collisions bitmap
	if ( bUpdateColMask )
	{
		if ( bTotalColMask )
			[rhFrame->colMask setOrigin:0 withDY:0];
		if ( (flags & DLF_COLMASKCLIPPED) == 0 )
			[rhFrame->colMask fill:0];
		else
			[rhFrame->colMask fillRectangle:-32767 withY1:-32767 andX2:+32767 andY2:+32767 andValue:0];
		flgColMaskEmpty = TRUE;
	}
	
	int nPlayfieldWidth = rhFrame->leWidth;
	int nPlayfieldHeight = rhFrame->leHeight;
	
	nLayer = 0;
	if ( bSkipLayer0 )
		nLayer++;
	
	// Display backdrop objects
	for ( ; nLayer < rhFrame->nLayers; nLayer++)
	{
		CLayer* pLayer = rhFrame->layers[nLayer];
		
		// Show layer?
		if ( (pLayer->dwOptions & FLOPT_TOSHOW) != 0 )
			pLayer->dwOptions |= FLOPT_VISIBLE;
		
		// Invisible layer? continue
		if ( (pLayer->dwOptions & FLOPT_VISIBLE) == 0 )
		{
			if ( nLayer != 0 || bUpdateColMask == FALSE )
				continue;
			bLayer0Invisible = TRUE;
		}
		
		// Redraw layer?
		/*
		if ( (flags & DLF_REDRAWLAYER) != 0 )
		{
			if ( (pLayer->dwOptions & FLOPT_REDRAW) == 0 )
				continue;
		}
		pLayer->dwOptions &= ~FLOPT_REDRAW;
		*/
		
		// Get layer offset
		BOOL bWrapHorz = ((pLayer->dwOptions & FLOPT_WRAP_HORZ) != 0);
		BOOL bWrapVert = ((pLayer->dwOptions & FLOPT_WRAP_VERT) != 0);
		BOOL bWrap = (bWrapHorz | bWrapVert);
		
		// Reset ladders
		[self y_Ladder_Reset:nLayer];
		
		// Display Bkd LOs
		int nLOs = (int)pLayer->nBkdLOs;
//		plo = [rhFrame->LOList getLOFromIndex:pLayer->nFirstLOIndex];
		
		// Hide layer?
		if ( (pLayer->dwOptions & FLOPT_TOHIDE) != 0 )
		{
			// Layer 0 => set invisible flag and redraw it (for collision mask)
			if ( nLayer == 0 )
				bLayer0Invisible = TRUE;
		}
		
		// Display layer
		if ( (pLayer->dwOptions & FLOPT_TOHIDE) == 0 || nLayer == 0 )
		{
			BOOL bSaveBkd = ((pLayer->dwOptions & FLOPT_NOSAVEBKD) == 0);
			
			// Show layer? show all objects
			if ( (pLayer->dwOptions & FLOPT_TOSHOW) != 0 )
				pLayer->dwOptions &= ~FLOPT_TOSHOW;
			
			// Display background objects
			DWORD dwWrapFlags = 0;
			int nSprite = 0;
			
			for (i=0; i<nLOs; i++)
			{
				plo = [rhFrame->LOList getLOFromIndex:pLayer->nFirstLOIndex+i];
                int typeObj = plo->loType;
				BOOL bOut = TRUE;
				CSprite** ppSpr = &plo->loSpr[nSprite];
				
				int nCurSprite = nSprite;
				
				do
				{
					COI* poi = nil;
					COC* poc = nil;
					CObjectCommon* pOCommon;
					
					// Get object position
					if ( typeObj < OBJ_SPR )
					{
						rc.left = plo->loX;
						rc.top = plo->loY;
					}
					else
					{
						// Dynamic item => must be a background object
						poi = [rhApp->OIList getOIFromHandle:plo->loOiHandle];
						if ( poi==NULL || poi->oiOC==NULL )
						{
							dwWrapFlags = 0;
							nSprite = 0; break;
						}
						poc = poi->oiOC;
						pOCommon = (CObjectCommon*) poc;
						if ((pOCommon->ocOEFlags & OEFLAG_BACKGROUND) == 0 || (hoPtr = [self find_HeaderObject:plo->loHandle]) == nil)
						{
							dwWrapFlags = 0;
							nSprite = 0;
							break;
						}
						rc.left = hoPtr->hoX - hoPtr->hoImgXSpot;
						rc.top = hoPtr->hoY - hoPtr->hoImgYSpot;
					}
					
					// On the right of the display? next object (only if no total colmask)
					if ( !bTotalColMask && !bWrap && (rc.left >= x2edit + COLMASK_XMARGIN + 32 || rc.top >= y2edit + COLMASK_YMARGIN) )
					{
						dwWrapFlags = 0;
						nSprite = 0;
						break;
					}
					
					// Wrap horizontally
					if ( bWrapHorz )
					{
						// TODO: save shifting for totalcolmask?
						int amount = (int)floorf(pLayer->visibleRect.left/(float)nPlayfieldWidth);
						int dxw = nPlayfieldWidth * amount;
						rc.left += dxw;
					}

					// Wrap vertically
					if ( bWrapVert )
					{
						// TODO: save shifting for totalcolmask?
						int amount = (int)floorf(pLayer->visibleRect.top/(float)nPlayfieldHeight);
						int dyw = nPlayfieldHeight * amount;
						rc.top += dyw;
					}

					// Get object rectangle
					if ( typeObj < OBJ_SPR )
					{
						poi = [rhApp->OIList getOIFromHandle:plo->loOiHandle];
						if ( poi==NULL || poi->oiOC==NULL )
						{
							dwWrapFlags = 0;
							nSprite = 0; break;
						}
						poc = poi->oiOC;
						rc.right = rc.left + poc->ocCx;
						rc.bottom = rc.top + poc->ocCy;
						v = poc->ocObstacleType;
						cm_box = poc->ocColMode;
					}
					else
					{
						rc.right = rc.left + hoPtr->hoImgWidth;
						rc.bottom = rc.top + hoPtr->hoImgHeight;
						pOCommon = (CObjectCommon*)poi->oiOC;
						v = ((pOCommon->ocFlags2 & OCFLAGS2_OBSTACLEMASK) >> OCFLAGS2_OBSTACLESHIFT);
						cm_box = ((pOCommon->ocFlags2 & OCFLAGS2_COLBOX) != 0) ? 1 : 0;
					}

					// Wrap
					if ( bWrap )
					{
						switch ( nSprite ) {
								
								// Normal sprite: test if other sprites should be displayed
							case 0:
								// Wrap horizontally?
								if ( bWrapHorz && (rc.left < pLayer->visibleRect.left || rc.right > pLayer->visibleRect.right) )
								{
									// Wrap horizontally and vertically?
									if ( bWrapVert && (rc.top < pLayer->visibleRect.top || rc.bottom > pLayer->visibleRect.bottom) )
									{
										nSprite = 3;
										dwWrapFlags |= (WRAP_X | WRAP_Y | WRAP_XY);
									}
									
									// Wrap horizontally only
									else
									{
										nSprite = 1;
										dwWrapFlags |= (WRAP_X);
									}
								}
								
								// Wrap vertically?
								else if ( bWrapVert && (rc.top < pLayer->visibleRect.top || rc.bottom > pLayer->visibleRect.bottom) )
								{
									nSprite = 2;
									dwWrapFlags |= (WRAP_Y);
								}
								
								// Delete other sprites
								if ( (dwWrapFlags & WRAP_X) == 0 && plo->loSpr[1] != nil )
								{
									[spriteGen delSprite:plo->loSpr[1]];
									plo->loSpr[1] = nil;
								}
								if ( (dwWrapFlags & WRAP_Y) == 0 && plo->loSpr[2] != nil )
								{
									[spriteGen delSprite:plo->loSpr[2]];
									plo->loSpr[2] = nil;
								}
								if ( (dwWrapFlags & WRAP_XY) == 0 && plo->loSpr[3] != nil )
								{
									[spriteGen delSprite:plo->loSpr[3]];
									plo->loSpr[3] = nil;
								}
								break;
								
								// Other sprite instance: wrap horizontally
							case 1:
								
								// Wrap
								if ( rc.left < pLayer->visibleRect.left )
								{
									int dx = nPlayfieldWidth;
									rc.left += dx;
									rc.right += dx;
								}
								else if ( rc.right > pLayer->visibleRect.right )
								{
									int dx = nPlayfieldWidth;
									rc.left -= dx;
									rc.right -= dx;
								}
								
								// Remove flag
								dwWrapFlags &= ~WRAP_X;
								
								// Calculate next sprite to display
								nSprite = 0;
								if ( (dwWrapFlags & WRAP_Y) != 0 )
									nSprite = 2;
								break;
								
								// Other sprite instance: wrap vertically
							case 2:
								
								// Wrap
								if ( rc.top < pLayer->visibleRect.top )
								{
									int dy = nPlayfieldHeight;
									rc.top += dy;
									rc.bottom += dy;
								}
								else if ( rc.bottom > pLayer->visibleRect.bottom )
								{
									int dy = nPlayfieldHeight;
									rc.top -= dy;
									rc.bottom -= dy;
								}
								
								// Remove flag
								dwWrapFlags &= ~WRAP_Y;
								
								// Calculate next sprite to display
								nSprite = 0;
								if ( (dwWrapFlags & WRAP_X) != 0 )
									nSprite = 1;
								break;
								
								// Other sprite instance: wrap horizontally and vertically
							case 3:
															
								// Wrap
								if ( rc.left < pLayer->visibleRect.left )
								{
									int dx = nPlayfieldWidth;
									rc.left += dx;
									rc.right += dx;
								}
								else if ( rc.right > pLayer->visibleRect.right )
								{
									int dx = nPlayfieldWidth;
									rc.left -= dx;
									rc.right -= dx;
								}
								if ( rc.top < pLayer->visibleRect.top )
								{
									int dy = nPlayfieldHeight;
									rc.top += dy;
									rc.bottom += dy;
								}
								else if ( rc.bottom > pLayer->visibleRect.bottom )
								{
									int dy = nPlayfieldHeight;
									rc.top -= dy;
									rc.bottom -= dy;
								}
								
								// Remove flag
								dwWrapFlags &= ~WRAP_XY;
								
								// Calculate next sprite to display
								nSprite = 2;
								break;
						}
					}
					
					// Ladder?
					if ( v == OBSTACLE_LADDER )
					{
						[self y_Ladder_Add:nLayer withX1:(int)rc.left andY1:(int)rc.top andX2:(int)rc.right andY2:(int)rc.bottom];
						cm_box = 1;		// Fill rectangle in collision masque
					}
					
					// Obstacle in layer 0?
					if ( nLayer == 0 && bUpdateColMask && v != OBSTACLE_TRANSPARENT &&
						(bTotalColMask || (rc.right >= -COLMASK_XMARGIN-32 && rc.bottom >= -COLMASK_YMARGIN))
						)
					{
						CMask* pMask = nil;

						// Update collisions bitmap (meme si objet en dehors)
						obst = 0;
						if ( v == OBSTACLE_SOLID )
						{
							obst = CM_OBSTACLE | CM_PLATFORM;
							flgColMaskEmpty = NO;
						}
						
						// Ajouter le masque "obstacle"
						if ( flgColMaskEmpty == NO )
						{
							if ( cm_box!=0 )
								[rhFrame->colMask fillRectangle:(int)rc.left withY1:(int)rc.top andX2:(int)rc.right-1 andY2:(int)rc.bottom-1 andValue:obst];
							else
							{
								if ( pMask == nil )
								{
									if ( typeObj < OBJ_SPR )
									{
										img = ((COCBackground*) poc)->ocImage;
										CImage* image = [rhApp->imageBank getImageFromHandle:img];
										pMask = [image getMask:GCMF_OBSTACLE withAngle:0 andScaleX:1.0 andScaleY:1.0];
									}
									else
									{
										pMask = [hoPtr getCollisionMask:GCMF_OBSTACLE];
									}
								}
								if ( pMask == NULL )
									[rhFrame->colMask fillRectangle:(int)rc.left withY1:(int)rc.top andX2:(int)rc.right-1 andY2:(int)rc.bottom-1 andValue:obst];
								else
									[rhFrame->colMask orMask:pMask withX:(int)rc.left andY:(int)rc.top andPlane:CM_OBSTACLE|CM_PLATFORM andValue:obst];
							}
						}
						
						// Ajouter le masque plateforme
						if ( v == OBSTACLE_PLATFORM )
						{
							flgColMaskEmpty = FALSE;
							if ( cm_box!=0 )
							{
								[rhFrame->colMask fillRectangle:(int)rc.left withY1:(int)rc.top andX2:(int)rc.right-1 andY2:(MIN((int)(rc.top+HEIGHT_PLATFORM),(int)rc.bottom)-1) andValue:CM_PLATFORM];
							}
							else
							{
								if ( pMask == NULL )
								{
									if ( typeObj < OBJ_SPR )
									{
										img = ((COCBackground*) poc)->ocImage;
										CImage* image = [rhApp->imageBank getImageFromHandle:img];
										pMask = [image getMask:GCMF_OBSTACLE withAngle:0 andScaleX:1.0 andScaleY:1.0];
									}
									else
									{
										pMask = [hoPtr getCollisionMask:GCMF_OBSTACLE];
									}
								}
								if ( pMask == NULL )
									[rhFrame->colMask fillRectangle:(int)rc.left withY1:(int)rc.top andX2:(int)rc.right-1 andY2:(MIN((int)(rc.top+HEIGHT_PLATFORM),(int)rc.bottom)-1) andValue:CM_PLATFORM];
								else
									[rhFrame->colMask orPlatformMask:pMask withX:(int)rc.left andY:(int)rc.top];
							}
						}
					}
					
					// Display object?

					BOOL rcIntersects = CRectIntersects(rc, pLayer->visibleRect);
					if (rcIntersects)
					{
						// In "displayable" area
						bOut = FALSE;
						
						////////////////////////////////////////
						// Non-background layer => create sprite
						
						if ( nLayer > 0 || !bLayer0Invisible)
						{
							DWORD dwFlags = SF_BACKGROUND | SF_NOHOTSPOT | SF_INACTIF;
							if ( !bSaveBkd )
								dwFlags |= SF_NOSAVE;
							switch (v)
							{
								case OBSTACLE_SOLID:
									dwFlags |= (SF_OBSTACLE | SF_RAMBO);
									break;
								case OBSTACLE_PLATFORM:
									dwFlags |= (SF_PLATFORM | SF_RAMBO);
									break;
							}
							
							// Create sprite only if not already created
							if ( *ppSpr == nil )
							{
								switch ( typeObj ) {
										
										// QuickBackdrop: ownerdraw sprite
									case OBJ_BOX:
										*ppSpr = [spriteGen addOwnerDrawSprite:(int)rc.left withY1:(int)rc.top andX2:(int)rc.right andY2:(int)rc.bottom andLayer:plo->loLayer andZOrder:i*4+nCurSprite andBackColor:0 andFlags:(dwFlags | SF_COLBOX) andObject:nil andDrawable:poc];
										break;
										
										// Backdrop: sprite
									case OBJ_BKD:
										*ppSpr = [spriteGen addSprite:(int)rc.left withY:(int)rc.top andImage:((COCBackground*)poc)->ocImage andLayer:plo->loLayer andZOrder:i*4+nCurSprite andBackColor:0 andFlags:dwFlags andObject:hoPtr];
										[spriteGen modifSpriteEffect:*ppSpr withInkEffect:poi->oiInkEffect andInkEffectParam:poi->oiInkEffectParam];
										break;
										
										// Extension
									default:
										if ( hoPtr != NULL )
										{
											*ppSpr = [spriteGen addOwnerDrawSprite:(int)rc.left withY1:(int)rc.top andX2:(int)rc.right andY2:(int)rc.bottom andLayer:plo->loLayer andZOrder:i*4*nCurSprite andBackColor:0 andFlags:(dwFlags | SF_COLBOX | SF_NOKILLDATA) andObject:hoPtr andDrawable:hoPtr];
										}
										break;
								}
							}

							// Otherwise, if wrapping update sprite coordinates
							else if ( bWrap )
							{
								switch ( typeObj )
								{
										// QuickBackdrop: ownerdraw sprite
									case OBJ_BOX:
									{
										CRect rcSpr = [*ppSpr getSpriteRect];
										if ( rc.left != rcSpr.left || rc.top != rcSpr.top || rc.right != rcSpr.right || rc.bottom != rcSpr.bottom )
											[spriteGen modifOwnerDrawSprite:*ppSpr withX1:(int)rc.left andY1:(int)rc.top andX2:(int)rc.right andY2:(int)rc.bottom];
									}
									break;
										
										// Backdrop: sprite
									case OBJ_BKD:
										[spriteGen modifSprite:*ppSpr withX:(int)rc.left andY:(int)rc.top andImage:((COCBackground*)poc)->ocImage];
										break;
										
										// Extension:
									default:
										if ( hoPtr != NULL )
											[spriteGen modifOwnerDrawSprite:*ppSpr withX1:(int)rc.left andY1:(int)rc.top andX2:(int)rc.right andY2:(int)rc.bottom];
										break;
								}
							}

						}
					}					
				} while (FALSE);
				
				// Object out of visible area: delete sprite
				if ( bOut )
				{
					// Delete sprite
					if ( *ppSpr != nil && typeObj<KPX_BASE)
					{
						[spriteGen delSprite:*ppSpr];
						*ppSpr = nil;
					}
				}
				
				// Re-display the same object but wrapped
				if ( dwWrapFlags != 0 )
				{
					i--;
					plo = [rhFrame->LOList getLOFromIndex:pLayer->nFirstLOIndex+i];
				}
			}
		}
		
		// Display backdrop objects created at runtime
		if ( pLayer->pBkd2 != nil )
			[self displayBkd2Layer:pLayer andNLayer:nLayer andFlags:flags andX:x2edit andY:y2edit andFlag:flgColMaskEmpty];
			//DisplayBkd2Layer(pLayer, nLayer, flags, x2edit, y2edit, flgColMaskEmpty);
		
		// Hide layer?
		if ( (pLayer->dwOptions & FLOPT_TOHIDE) != 0 )
			pLayer->dwOptions &= ~(FLOPT_TOHIDE | FLOPT_VISIBLE);
	}
}




// Modification d'un objet background
// -----------------------------------
-(void)modif_RedrawLevel:(CExtension*)hoPtr
{
	// Test if we should redraw the collision mask
	BOOL bRedrawTotalColMask = NO;
	if (hoPtr != nil)
	{
		int dwColMaskFlags = hoPtr->hoCommon->ocFlags2 & OCFLAGS2_OBSTACLEMASK;
		
		// Layer 1 => redraw collision mask if no ladder
		// Layer > 1 => redraw collision mask if obstacle or platform
		if ([hoPtr getCollisionMask:-1]!=nil)
		{
			if ((hoPtr->hoLayer == 0 && dwColMaskFlags != OCFLAGS2_OBSTACLE_LADDER) || (hoPtr->hoLayer > 0 && (dwColMaskFlags == OCFLAGS2_OBSTACLE_SOLID || dwColMaskFlags == OCFLAGS2_OBSTACLE_PLATFORM)))
			{
				bRedrawTotalColMask = YES;
			}
		}
	}
	[self ohRedrawLevel:bRedrawTotalColMask];
}

// -----------------------------------------------------------------------
// TROUVE LE HO
// -----------------------------------------------------------------------
-(CObject*)find_HeaderObject:(short)hlo
{
	int count = 0;
	for (int nObjects = 0; nObjects < rhNObjects; nObjects++)
	{
		while (rhObjectList[count] == nil)
		{
			count++;
		}
		if (hlo == rhObjectList[count]->hoHFII)
		{
			return rhObjectList[count];
		}
		count++;
	}
	return nil;
}

// -----------------------------------------------------------------------
// SCROLLING DU TERRAIN, UPDATE LES POSITIONS
// -----------------------------------------------------------------------
-(void)f_UpdateWindowPos:(int)newX withY:(int)newY
{
	// Change le pointeurs dans le segment de base
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Deltas pour le C
	short noMove = 0;
	rh4WindowDeltaX = newX - rhWindowX;
	if (rh4WindowDeltaX != 0)
	{
		noMove++;
	}
	rh4WindowDeltaY = newY - rhWindowY;
	if (rh4WindowDeltaY != 0)
	{
		noMove++;
	}
	
	// Scan layers and check if dx/dy != 0
	if (noMove == 0)
	{
		for (int i = 0; i < rhFrame->nLayers; i++)
		{
			CLayer* pLayer = rhFrame->layers[i];
			if (pLayer->dx != 0 || pLayer->dy != 0)
			{
				noMove++;
				break;
			}
		}
	}
	
	// Coordonnees limites de gestion
	rhWindowX = newX;									// Minimum gestion droite
	rh3XMinimum = newX - COLMASK_XMARGIN;
	if (rh3XMinimum < 0)
	{
		rh3XMinimum = rh3XMinimumKill;
	}
	
	rhWindowY = newY;									// Minimum gestion haut
	rh3YMinimum = newY - COLMASK_YMARGIN;
	if (rh3YMinimum < 0)
	{
		rh3YMinimum = rh3YMinimumKill;
	}
	
	rh3XMaximum = newX + rh3WindowSx + COLMASK_XMARGIN;	// Maximum gestion droite
	if (rh3XMaximum > rhLevelSx)
	{
		rh3XMaximum = rh3XMaximumKill;
	}
	
	rh3YMaximum = newY + rh3WindowSy + COLMASK_YMARGIN;	// Maximum gestion bas
	if (rh3YMaximum > rhLevelSy)
	{
		rh3YMaximum = rh3YMaximumKill;
	}
	
	
	int count = 0;
	for (int nObjects = 0; nObjects < rhNObjects; nObjects++)
	{
		while (rhObjectList[count] == nil)
		{
			count++;
		}
		CObject* pHo = rhObjectList[count];
		count++;
		
		if (noMove != 0)
		{
			if ((pHo->hoOEFlags & OEFLAG_SCROLLINGINDEPENDANT) != 0)
			{
				CLayer* thisLayer = rhFrame->layers[pHo->hoLayer];

				int x = (int)thisLayer->dx;
				int y = (int)thisLayer->dy;
				
				if (pHo->rom == nil)
				{
					pHo->hoX += x;
					pHo->hoY += y;
				}
				else
				{
					x += pHo->hoX;
					y += pHo->hoY;
					[pHo->rom->rmMovement setXPosition:x];
					[pHo->rom->rmMovement setYPosition:y];
				}
			}
			
			if ((pHo->hoOEFlags & OEFLAG_BACKGROUND) == 0)					// protection ajout�e build 96: crash si Q/A object + scrolling
			{
				[pHo modif];
			}
		}
		else if ((pHo->hoOEFlags & OEFLAG_BACKGROUND) == 0)
		{
			[pHo display];
		}
	}
}



/** Shows all the objects.
 */
-(void)f_ShowAllObjects:(int)nLayer withFlag:(BOOL)bShow
{
	int count = 0;
	int nObject;
	for (nObject = 0; nObject < rhNObjects; nObject++)
	{
		while (rhObjectList[count] == nil)
		{
			count++;
		}
		CObject* hoPtr = rhObjectList[count];
		count++;
		
		if (nLayer == hoPtr->hoLayer || nLayer == LAYER_ALL)
		{
			if (hoPtr->ros != nil)
			{
				if (hoPtr->roc->rcSprite != nil)
				{
					[spriteGen activeSprite:hoPtr->roc->rcSprite withFlags:AS_REDRAW andRect:CRectNil];
				}
				
				if (bShow)
				{
					if ((hoPtr->ros->rsFlags & RSFLAG_VISIBLE) != 0)
					{
						CLayer* pLayer = rhFrame->layers[hoPtr->hoLayer];
						int dwOpt = pLayer->dwOptions;
						pLayer->dwOptions = ((pLayer->dwOptions & ~(FLOPT_TOSHOW | FLOPT_TOHIDE)) | FLOPT_VISIBLE);
					
						[hoPtr->ros obShow];
					
						pLayer->dwOptions = dwOpt;
					}
				}
				else
				{
					[hoPtr->ros obHide];
				}
				hoPtr->ros->rsFlash = 0;
			}
		}
	}
}

// Center the display in accordance with the edges
// -----------------------------------------
-(void)setDisplay:(int)x withY:(int)y andLayer:(int)nLayer andFlags:(int)flags
{
	x -= rh3WindowSx / 2;				//; Size of the display window
	y -= rh3WindowSy / 2;

	float xf = (float) x;
	float yf = (float) y;

	if (nLayer != -1 && nLayer < rhFrame->nLayers)
	{
		CLayer* pLayer = rhFrame->layers[nLayer];
		if (pLayer->xCoef > 1.0f)
		{
			float dxf = (xf - rhWindowX);
			dxf /= pLayer->xCoef;
			xf = rhWindowX + dxf;
		}
		if (pLayer->yCoef > 1.0f)
		{
			float dyf = (yf - rhWindowY);
			dyf /= pLayer->yCoef;
			yf = rhWindowY + dyf;
		}
	}
	
	x = (int) xf;
	y = (int) yf;
	
	// In game mode, is limited to the borders of the frame ...
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (x < 0)
	{
		x = 0;					// Sort � haut/gauche?
	}
	if (y < 0)
	{
		y = 0;
	}
	int x2 = x + rh3WindowSx;	// Sort a droite/bas?
	int y2 = y + rh3WindowSy;
	if (x2 > rhLevelSx)
	{
		x2 = rhLevelSx - rh3WindowSx;
		if (x2 < 0)
		{
			x2 = 0;
		}
		x = x2;
	}
	if (y2 > rhLevelSy)
	{
		y2 = rhLevelSy - rh3WindowSy;
		if (y2 < 0)
		{
			y2 = 0;
		}
		y = y2;
	}
	
	// Pour la fin de la boucle...
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if ((flags & 1) != 0)
	{
		if (x != rhWindowX)
		{
			rh3DisplayX = x;
			rh3Scrolling |= RH3SCROLLING_SCROLL;
		}
	}
	if ((flags & 2) != 0)
	{
		if (y != rhWindowY)
		{
			rh3DisplayY = y;
			rh3Scrolling |= RH3SCROLLING_SCROLL;
		}
	}
}

// Force un redessin du fond
// -------------------------
-(void)ohRedrawLevel:(BOOL)bRedrawTotalColMask
{
	rh3Scrolling |= RH3SCROLLING_REDRAWALL;
	if (bRedrawTotalColMask)
	{
		rh3Scrolling |= RH3SCROLLING_REDRAWTOTALCOLMASK;
	}
}

// -------------------------------------------------------------------------
// GESTION DES ECHELLES
// -------------------------------------------------------------------------
-(void)y_Ladder_Reset:(int)nLayer
{
	if (nLayer >= 0 && nLayer < rhFrame->nLayers)
	{
		CLayer* pLayer = rhFrame->layers[nLayer];
		if (pLayer->pLadders!=nil)
		{
			[pLayer->pLadders freeRelease];
			[pLayer->pLadders release];
			pLayer->pLadders=nil;
		}
	}
}
// Add Ladder
-(void)y_Ladder_Add:(int)nLayer withX1:(int)x1 andY1:(int)y1 andX2:(int)x2 andY2:(int)y2
{
	if (nLayer >= 0 && nLayer < rhFrame->nLayers)
	{
		CLayer* pLayer = rhFrame->layers[nLayer];
		
		CRect* rc = (CRect*)malloc(sizeof(CRect));
		rc->left = MIN(x1, x2);
		rc->top = MIN(y1, y2);
		rc->right = MAX(x1, x2);
		rc->bottom = MAX(y1, y2);
		
		if (pLayer->pLadders == nil)
		{
			pLayer->pLadders = [[CArrayList alloc] init];
		}
		[pLayer->pLadders add:rc];
	}
}
// Remove ladder
-(void)y_Ladder_Sub:(int)nLayer withX1:(int)x1 andY1:(int)y1 andX2:(int)x2 andY2:(int)y2
{
	if (nLayer >= 0 && nLayer < rhFrame->nLayers)
	{
		CLayer* pLayer = rhFrame->layers[nLayer];
		if (pLayer->pLadders != nil)
		{
			CRect rc;
			rc.left = MIN(x1, x2);
			rc.top = MIN(y1, y2);
			rc.right = MAX(x1, x2);
			rc.bottom = MAX(y1, y2);
			
			int i;
			CRect rcDst;
			for (i = 0; i < [pLayer->pLadders size]; i++)
			{
				rcDst = *(CRect*)[pLayer->pLadders get:i];
				if (CRectIntersects(rcDst, rc))
				{
					[pLayer->pLadders removeIndexRelease:i];
					i--;
				}
			}
		}
	}
}
/** Gets the ladder at given coordinates.
 */
-(CRect)y_GetLadderAt:(int)nLayer withX:(int)x andY:(int)y
{
	int nl, nLayers;
	
	if (nLayer == -1)
	{
		nl = 0;
		nLayers = rhFrame->nLayers;
	}
	else
	{
		nl = nLayer;
		nLayers = (nLayer + 1);
	}
	
	for (; nl < nLayers; nl++)
	{
		CLayer* pLayer = rhFrame->layers[nl];
		
		if (pLayer->pLadders != nil)
		{
			int i;
			CRect rc;
			for (i = 0; i < [pLayer->pLadders size]; i++)
			{
				rc = *(CRect*)[pLayer->pLadders get:i];
				if (x >= rc.left && y >= rc.top && x < rc.right && y < rc.bottom)
					return rc;
			}
		}
	}
	return CRectNil;
}
-(CRect)y_GetLadderAt_Absolute:(int)nLayer withX:(int)x andY:(int)y
{
	return [self y_GetLadderAt:nLayer withX:x andY:y];
}

// -------------------------------------------------------------------------
// COLLISION DETECTION ACCELERATION
// -------------------------------------------------------------------------

-(CArrayList*)getLayerZones:(int)nLayer
{
	//ASSERT(nLayer >= 0 && nLayer < (int)pCurFrame->m_nLayers);
	
	CLayer* pLayer = rhFrame->layers[nLayer];
	CArrayList* pZones = pLayer->m_loZones;
	
	if ( pZones == nil && (rhFrame->leWidth >= OBJZONE_WIDTH * 2 || rhFrame->leHeight >= OBJZONE_HEIGHT * 2) )
	{
		int nLOs = (int)pLayer->nBkdLOs;
		CLO* plo1 = [rhFrame->LOList getLOFromIndex:pLayer->nFirstLOIndex];
		
		// Get number of zones
		int nxz = ((rhFrame->leWidth + OBJZONE_WIDTH - 1)/ OBJZONE_WIDTH) + 2;
		int nyz = ((rhFrame->leHeight + OBJZONE_HEIGHT - 1)/ OBJZONE_HEIGHT) + 2;
		int nz = nxz * nyz;
		
		pLayer->m_loZones = pZones = [[CArrayList alloc] init];
		[pZones ensureCapacity:nz];
		
		for (int i=0; i<nLOs; i++, plo1 = [rhFrame->LOList getLOFromIndex:pLayer->nFirstLOIndex+i])
		{
			CObject* hoPtr;
			CRect rc;
			
			//ASSERT(plo1->loLayer == nLayer);
						
			COI* poi = [rhApp->OIList getOIFromHandle:plo1->loOiHandle];
			
			if ( poi==nil || poi->oiOC==nil )
			{
				//ASSERT(FALSE);
				continue;
			}
			
			COC* poc = poi->oiOC;
			int typeObj = poi->oiType;
			
			// Get object position
			rc.left = plo1->loX;
			rc.top = plo1->loY;
			
			// Get object rectangle
			if ( typeObj < OBJ_SPR )
			{
				// Ladder or no obstacle? continue
				short v = poc->ocObstacleType;
				if ( v == 0 || v == OBSTACLE_LADDER || v == OBSTACLE_TRANSPARENT )
					continue;
				
				//ASSERT(((LPStatic_OC)poc)->ocCx >= 0 && ((LPStatic_OC)poc)->ocCy >= 0);		// New MMF2
				rc.right = rc.left + poc->ocCx;
				rc.bottom = rc.top + poc->ocCy;
			}
			else
			{
				CObjectCommon* ocPtr= (CObjectCommon*)poc;
				
				// Dynamic item => must be a background object
				if ( (ocPtr->ocOEFlags & OEFLAG_BACKGROUND) == 0 || (hoPtr = [self find_HeaderObject:plo1->loHandle]) == nil )
					continue;
				short v = ((ocPtr->ocFlags2 & OCFLAGS2_OBSTACLEMASK) >> OCFLAGS2_OBSTACLESHIFT);
				// Ladder or no obstacle? continue
				if ( v == 0 || v == OBSTACLE_LADDER || v == OBSTACLE_TRANSPARENT )
					continue;
				rc.left = hoPtr->hoX - hoPtr->hoImgXSpot;
				rc.top = hoPtr->hoY - hoPtr->hoImgYSpot;
				rc.right = rc.left + hoPtr->hoImgWidth;
				rc.bottom = rc.top + hoPtr->hoImgHeight;
			}
			
			// Add object zones to pZones
			int minzy = 0;
			if ( rc.top >= 0 )
				minzy = (int)MIN(rc.top / OBJZONE_HEIGHT + 1, nyz-1);
			int maxzy = 0;
			if ( rc.bottom >= 0 )
				maxzy = (int)MIN(rc.bottom / OBJZONE_HEIGHT + 1, nyz-1);
			for (int zy=minzy; zy<=maxzy; zy++)
			{
				int minzx = 0;
				if ( rc.left >= 0 )
					minzx = (int)MIN(rc.left / OBJZONE_WIDTH + 1, nxz-1);
				int maxzx = 0;
				if ( rc.right >= 0 )
					maxzx = (int)MIN(rc.right / OBJZONE_WIDTH + 1, nxz-1);
				for (int zx=minzx; zx<=maxzx; zx++)
				{
					// Add object to zone list
					int z = zy * nxz + zx;
					CArrayList* pZone = (CArrayList*)[pZones get:z];
					if ( pZone == nil )
					{
						//ASSERT(z < nz);
						pZone = [[CArrayList alloc] init];
						[pZones setAtGrow:z object:pZone];
					}
					//NSLog(@"Adding bkd to zone %i", z);
					[pZone addInt:(i+pLayer->nFirstLOIndex)];
				}
			}
		}
	}
	return pZones;
}



// -------------------------------------------------------------------------
// DESSIN DES OBJETS DANS LE DECOR
// -------------------------------------------------------------------------
-(void)activeToBackdrop:(CObject*)hoPtr withObstacle:(int)nTypeObst andFlag:(BOOL)bTrueObject
{
	CBkd2* toadd;
	toadd = [[CBkd2 alloc] initWithCRun:self];
	toadd->img = hoPtr->roc->rcImage;
	CImage* ifo = [rhApp->imageBank getImageFromHandle:toadd->img];
	toadd->loHnd = 0;
	toadd->oiHnd = 0;
	toadd->x = hoPtr->hoX;
	toadd->y = hoPtr->hoY;
	toadd->spotX = ifo->xSpot;
	toadd->spotY = ifo->ySpot;
	toadd->nLayer = (short) hoPtr->hoLayer;
	toadd->obstacleType = (short) nTypeObst;	// a voir
	toadd->colMode = CM_BITMAP;
    toadd->body = nil;
	
	if ((hoPtr->ros->rsCreaFlags & SF_COLBOX) != 0)
	{
		toadd->colMode = CM_BOX;
	}
	
	for (int ns = 0; ns < 4; ns++)
	{
		toadd->pSpr[ns] = nil;
	}
	toadd->inkEffect = hoPtr->ros->rsEffect;
	toadd->inkEffectParam = hoPtr->ros->rsEffectParam;
	[self addBackdrop2:toadd];	
}

/** Sub method of the above.
 */
-(void)addBackdrop2:(CBkd2*)toadd
{
	CBkd2* pbkd;
	int i;
	
	if (toadd->nLayer < 0 || toadd->nLayer >= rhFrame->nLayers)
	{
		return;
	}
	CLayer* pLayer = rhFrame->layers[toadd->nLayer];
	
	// Search for backdrop
	if (pLayer->pBkd2 != nil)
	{
		for (i = 0; i < [pLayer->pBkd2 size]; i++)
		{
			pbkd = (CBkd2*)[pLayer->pBkd2 get:i];
			if (pbkd->x == toadd->x && pbkd->y == toadd->y && pbkd->nLayer == toadd->nLayer && pbkd->img == toadd->img && (pbkd->inkEffect & EFFECT_MASK) == EFFECT_NONE)
			{
				if (i != [pLayer->pBkd2 size] - 1)
				{
					for (int j = 0; j < 4; j++)
					{
						if (pbkd->pSpr[j] != nil)
						{
							[spriteGen moveSpriteToFront:pbkd->pSpr[j]];
						}
					}
					[pLayer->pBkd2 removeIndex:i];
					[pLayer->pBkd2 add:pbkd];
				}
				pbkd->colMode = toadd->colMode;
				pbkd->obstacleType = toadd->obstacleType;
				
				if (pbkd->inkEffect != toadd->inkEffect || pbkd->inkEffectParam != toadd->inkEffectParam)
				{
					pbkd->inkEffect = toadd->inkEffect;
					pbkd->inkEffectParam = toadd->inkEffectParam;
					for (int j = 0; j < 4; j++)
					{
						if (pbkd->pSpr[j] != nil)
						{
							[spriteGen modifSpriteEffect:pbkd->pSpr[j] withInkEffect:pbkd->inkEffect andInkEffectParam:pbkd->inkEffectParam];
						}
					}
				}
				[toadd release];
				return;
			}
		}
		
		// Maxi
		if ([pLayer->pBkd2 size] >= rhFrame->maxObjects)
		{
			[toadd release];
			return;
		}
	}
	// Allouer m_pBkd2
	else
	{
		pLayer->pBkd2 = [[CArrayList alloc] init];
	}
	
	// Ajouter le backdrop � la fin
	int nIdx = [pLayer->pBkd2 size];
	[pLayer->pBkd2 add:toadd];
	
    // Adds backdrop to the physical world
    toadd->body = nil;
    if (toadd->obstacleType == OBSTACLE_SOLID || toadd->obstacleType == OBSTACLE_PLATFORM)
    {
        if (rh4Box2DBase != nil)
        {
            CImage* image;
            image = [rhApp->imageBank getImageFromHandle:toadd->img];
            toadd->body = rh4Box2DBase->pAddABackdrop(rh4Box2DBase, toadd->x + image->xSpot, toadd->y + image->ySpot, toadd->img, toadd->obstacleType);
        }
    }
    
	// TODO: add sprite si layer > 0 ? (attention si layer invisible)
	pbkd = toadd;
	int v;
	CRect rc;
	
	short img;
    BOOL bTotalColMask = YES;//((rhFrame->leFlags & LEF_TOTALCOLMASK) != 0);
    BOOL flgColMaskEmpty;
	
	BOOL bWrapHorz = ((pLayer->dwOptions & FLOPT_WRAP_HORZ) != 0);
	BOOL bWrapVert = ((pLayer->dwOptions & FLOPT_WRAP_VERT) != 0);
	BOOL bWrap = NO;
	if (bWrapHorz || bWrapVert)
	{
		bWrap = YES;
	}
	
	int nPlayfieldWidth = rhFrame->leWidth;
	int nPlayfieldHeight = rhFrame->leHeight;

	if ((pLayer->dwOptions & (FLOPT_TOHIDE | FLOPT_VISIBLE)) == FLOPT_VISIBLE)
	{
		BOOL bSaveBkd = ((pLayer->dwOptions & FLOPT_NOSAVEBKD) == 0);
		int dwWrapFlags = 0;
		int nSprite = 0;
		do
		{
			int nCurSprite = nSprite;
			
			rc.left = pbkd->x - pbkd->spotX;
			rc.top = pbkd->y - pbkd->spotY;
			
			int x2edit = rhFrame->leEditWinWidth - 1;
			int y2edit = rhFrame->leEditWinHeight - 1;
			
			// Calculer rectangle objet
			img = pbkd->img;
			CImage* pImg = [rhApp->imageBank getImageFromHandle:img];
			if (pImg != nil)
			{
				rc.right = rc.left + pImg->width;
				rc.bottom = rc.top + pImg->height;
			}
			else
			{
				rc.right = rc.left + 1;
				rc.bottom = rc.top + 1;
			}
			
			// Wrap
			if (bWrap)
			{
				switch (nSprite)
				{
						// Normal sprite: test if other sprites should be displayed
					case 0:
						// Wrap horizontally?
						if (bWrapHorz && (rc.left < 0 || rc.right > nPlayfieldWidth))
						{
							// Wrap horizontally and vertically?
							if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
							{
								nSprite = 3;
								dwWrapFlags |= (WRAP_X | WRAP_Y | WRAP_XY);
							}
							// Wrap horizontally only
							else
							{
								nSprite = 1;
								dwWrapFlags |= (WRAP_X);
							}
						}
						
						// Wrap vertically?
						else if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
						{
							nSprite = 2;
							dwWrapFlags |= (WRAP_Y);
						}
						
						// Delete other sprites
						if ((dwWrapFlags & WRAP_X) == 0 && pbkd->pSpr[1] != nil)
						{
							[spriteGen delSprite:pbkd->pSpr[1]];
							pbkd->pSpr[1] = nil;
						}
						if ((dwWrapFlags & WRAP_Y) == 0 && pbkd->pSpr[2] != nil)
						{
							[spriteGen delSprite:pbkd->pSpr[2]];
							pbkd->pSpr[2] = nil;
						}
						if ((dwWrapFlags & WRAP_XY) == 0 && pbkd->pSpr[3] != nil)
						{
							[spriteGen delSprite:pbkd->pSpr[3]];
							pbkd->pSpr[3] = nil;
						}
						break;
						
						// Other sprite instance: wrap horizontally
					case 1:
						// Wrap
						if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
						{
							int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
							rc.left += dx;
							rc.right += dx;
						}
						else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
						{
							int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
							rc.left -= dx;
							rc.right -= dx;
						}
						
						// Remove flag
						dwWrapFlags &= ~WRAP_X;
						
						// Calculate next sprite to display
						nSprite = 0;
						if ((dwWrapFlags & WRAP_Y) != 0)
						{
							nSprite = 2;
						}
						break;
						
						// Other sprite instance: wrap vertically
					case 2:
						// Wrap
						if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
						{
							int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
							rc.top += dy;
							rc.bottom += dy;
						}
						else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
						{
							int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
							rc.top -= dy;
							rc.bottom -= dy;
						}
						
						// Remove flag
						dwWrapFlags &= ~WRAP_Y;
						
						// Calculate next sprite to display
						nSprite = 0;
						if ((dwWrapFlags & WRAP_X) != 0)
						{
							nSprite = 1;
						}
						break;
						
						// Other sprite instance: wrap horizontally and vertically
					case 3:
						// Wrap
						if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
						{
							int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
							rc.left += dx;
							rc.right += dx;
						}
						else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
						{
							int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
							rc.left -= dx;
							rc.right -= dx;
						}
						if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
						{
							int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
							rc.top += dy;
							rc.bottom += dy;
						}
						else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
						{
							int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
							rc.top -= dy;
							rc.bottom -= dy;
						}
						
						// Remove flag
						dwWrapFlags &= ~WRAP_XY;
						
						// Calculate next sprite to display
						nSprite = 2;
						break;
				}
			}
			
			// On the right of the display? next object (only if no total colmask)
			//If the frame has a total colmask then just add it no matter what. Otherwise valid backdrops are never added
			if (bTotalColMask || (rc.left < x2edit + COLMASK_XMARGIN + 32 && rc.top < y2edit + COLMASK_YMARGIN))
			{
				// Obstacle?
				v = pbkd->obstacleType;
				
				// Ladder?
				if (v == OBSTACLE_LADDER)
				{
					[self y_Ladder_Add:pbkd->nLayer withX1:(int)rc.left andY1:(int)rc.top andX2:(int)rc.right andY2:(int)rc.bottom];
				}
				
				// Display object?
				if (CRectIntersects(rc, pLayer->visibleRect))
				{
					////////////////////////////////////////
					// Non-background layer => create sprite
					
					int dwFlags = SF_BACKGROUND | SF_INACTIF;
					if (!bSaveBkd)
					{
						dwFlags |= SF_NOSAVE;
					}
					if (v == OBSTACLE_SOLID)
					{
						dwFlags |= (SF_OBSTACLE | SF_RAMBO);
					}
					if (v == OBSTACLE_PLATFORM)
					{
						dwFlags |= (SF_PLATFORM | SF_RAMBO);
					}
					dwFlags |= toadd->spriteFlag;
					pbkd->pSpr[nCurSprite] = [spriteGen addSprite:pbkd->x withY:pbkd->y andImage:img andLayer:pbkd->nLayer andZOrder:0x10000000 + nIdx * 4 + nCurSprite andBackColor:0 andFlags:dwFlags andObject:nil];
					// voir si fixer variable interne a pbkd
					[spriteGen modifSpriteEffect:pbkd->pSpr[nCurSprite] withInkEffect:pbkd->inkEffect andInkEffectParam:pbkd->inkEffectParam];
				}

                // Obstacle in layer 0?
                if (toadd->nLayer == 0 && v != OBSTACLE_TRANSPARENT)
                {
                    // Retablir coords absolues si TOTALCOLMASK
                    // Update collisions bitmap (meme si objet en dehors)
                    int obst = 0;
                    flgColMaskEmpty=YES;
                    if (v == OBSTACLE_SOLID)
                    {
                        obst = CM_OBSTACLE | CM_PLATFORM;
                        flgColMaskEmpty = NO;
                    }
                    else if (v==OBSTACLE_NONE)
                    {
                        flgColMaskEmpty=NO;
                    }
                    
                    // Ajouter le masque "obstacle"
                    CMask* mask;
                    if (flgColMaskEmpty == NO)
                    {
                        if (toadd->colMode==CM_BOX)
                        {
                            [rhFrame->colMask fillRectangle:(int)rc.left withY1:(int)rc.top andX2:(int)rc.right andY2:(int)rc.bottom andValue:obst];
                        }
                        else
                        {
                            mask = [[rhApp->imageBank getImageFromHandle:img] getMask:GCMF_OBSTACLE withAngle:0 andScaleX:1.0 andScaleY:1.0];
                            [rhFrame->colMask orMask:mask withX:(int)rc.left andY:(int)rc.top andPlane:CM_OBSTACLE | CM_PLATFORM andValue:obst];
                        }
                    }
				
                    // Ajouter le masque plateforme
                    if (v == OBSTACLE_PLATFORM)
                    {
                        flgColMaskEmpty = NO;
                        if (toadd->colMode==CM_BOX)
                        {
                            [rhFrame->colMask fillRectangle:(int)rc.left withY1:(int)rc.top andX2:(int)rc.right andY2:MIN((int)(rc.top + HEIGHT_PLATFORM), (int)rc.bottom) andValue:CM_PLATFORM];
                        }
                        else
                        {
                            mask = [[rhApp->imageBank getImageFromHandle:img] getMask:GCMF_OBSTACLE withAngle:0 andScaleX:1.0 andScaleY:1.0];
                            [rhFrame->colMask orPlatformMask:mask withX:(int)rc.left andY:(int)rc.top];
                        }
                    }				
				}
			}

		} while (dwWrapFlags != 0);
	}
}
/** Delete all created backdrop objects from a layer
 */
-(void)deleteAllBackdrop2:(int)nLayer
{
	int i;
	CBkd2* pbkd;
	
	if (nLayer < 0 || nLayer >= rhFrame->nLayers)
	{
		return;
	}
	
	CLayer* pLayer = rhFrame->layers[nLayer];
	if (pLayer->pBkd2 != nil)
	{
		// Delete sprites
		for (i = 0; i < [pLayer->pBkd2 size]; i++)
		{
			pbkd = (CBkd2*)[pLayer->pBkd2 get:i];
			for (int ns = 0; ns < 4; ns++)
			{
				if (pbkd->pSpr[ns] != nil)
				{
					[spriteGen delSprite:pbkd->pSpr[ns]];
					pbkd->pSpr[ns] = nil;
				}
			}
			[pbkd release];
		}
        if (pbkd->body != nil)
        {
            if (rh4Box2DBase != nil)
            {
                rh4Box2DBase->pSubABackdrop(rh4Box2DBase, (b2Body*)pbkd->body);
            }
        }
		[pLayer->pBkd2 release];
		pLayer->pBkd2 = nil;
		
		// Force redraw
		pLayer->dwOptions |= FLOPT_REDRAW;
		rh3Scrolling |= RH3SCROLLING_REDRAWLAYERS;
	}
}
/** Delete created backdrop object at given coordinates
 */
-(void)deleteBackdrop2At:(int)nLayer withX:(int)x andY:(int)y andFlag:(BOOL)bFineDetection
{
	if (nLayer < 0 || nLayer >= rhFrame->nLayers)
	{
		return;
	}
	CLayer* pLayer = rhFrame->layers[nLayer];
	
	// Rechercher backdrop
	if (pLayer->pBkd2 != nil)
	{
		int i;
		CBkd2* pbkd;
		BOOL bSomethingDeleted = NO;
		
		BOOL bWrapHorz = ((pLayer->dwOptions & FLOPT_WRAP_HORZ) != 0);
		BOOL bWrapVert = ((pLayer->dwOptions & FLOPT_WRAP_VERT) != 0);
		BOOL bWrap = (bWrapHorz | bWrapVert);
		
		int nPlayfieldWidth = rhFrame->leWidth;
		int nPlayfieldHeight = rhFrame->leHeight;
		
		int dwWrapFlags = 0;
		int nSprite = 0;
		
		for (i = 0; i < [pLayer->pBkd2 size]; i++)
		{
			pbkd = (CBkd2*)[pLayer->pBkd2 get:i];
			
			if (pbkd->nLayer == nLayer)		// Heu ... c'est la peine de faire ce test?
			{
				BOOL bFound = NO;
				
				// Get object position
				CRect rc;

				BOOL cm_box = (pbkd->colMode == CM_BOX);
				rc.left = pbkd->x;
				rc.top = pbkd->y;
				
				// Get object rectangle
				CImage* pImg = [rhApp->imageBank getImageFromHandle:pbkd->img];
				if (pImg != nil)
				{
					rc.right = rc.left + pImg->width;
					rc.bottom = rc.top + pImg->height;
				}
				else
				{
					rc.right = rc.left + 1;
					rc.bottom = rc.top + 1;
				}
				
				// Wrap
				if (bWrap)
				{
					switch (nSprite)
					{
                            // Normal sprite: test if other sprites should be displayed
						case 0:
							// Wrap horizontally?
							if (bWrapHorz && (rc.left < 0 || rc.right > nPlayfieldWidth))
							{
								// Wrap horizontally and vertically?
								if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
								{
									nSprite = 3;
									dwWrapFlags |= (WRAP_X | WRAP_Y | WRAP_XY);
								}
								
								// Wrap horizontally only
								else
								{
									nSprite = 1;
									dwWrapFlags |= (WRAP_X);
								}
							}
							
							// Wrap vertically?
							else if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
							{
								nSprite = 2;
								dwWrapFlags |= (WRAP_Y);
							}
							break;
							
                            // Other sprite instance: wrap horizontally
						case 1:
							// Wrap
							if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
							{
								int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
								rc.left += dx;
								rc.right += dx;
							}
							else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
							{
								int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
								rc.left -= dx;
								rc.right -= dx;
							}
							
							// Remove flag
							dwWrapFlags &= ~WRAP_X;
							
							// Calculate next sprite to display
							nSprite = 0;
							if ((dwWrapFlags & WRAP_Y) != 0)
							{
								nSprite = 2;
							}
							break;
							
                            // Other sprite instance: wrap vertically
						case 2:
							// Wrap
							if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
							{
								int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
								rc.top += dy;
								rc.bottom += dy;
							}
							else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
							{
								int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
								rc.top -= dy;
								rc.bottom -= dy;
							}
							
							// Remove flag
							dwWrapFlags &= ~WRAP_Y;
							
							// Calculate next sprite to display
							nSprite = 0;
							if ((dwWrapFlags & WRAP_X) != 0)
							{
								nSprite = 1;
							}
							break;
							
                            // Other sprite instance: wrap horizontally and vertically
						case 3:
							// Wrap
							if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
							{
								int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
								rc.left += dx;
								rc.right += dx;
							}
							else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
							{
								int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
								rc.left -= dx;
								rc.right -= dx;
							}
							if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
							{
								int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
								rc.top += dy;
								rc.bottom += dy;
							}
							else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
							{
								int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
								rc.top -= dy;
								rc.bottom -= dy;
							}
							
							// Remove flag
							dwWrapFlags &= ~WRAP_XY;
							
							// Calculate next sprite to display
							nSprite = 2;
							break;
					}
				}
				
				do
				{
					// Point in rectangle?
					if (x < rc.left || y < rc.top)
					{
						break;
					}
					
					if (x >= rc.right || y >= rc.bottom)
					{
						break;
					}
					
					// Point in box
					if (!bFineDetection || cm_box)
					{
						bFound = YES;
						break;
					}
					
					// Test if point into image mask
					CMask* pMask = [[rhApp->imageBank getImageFromHandle:pbkd->img] getMask:GCMF_OBSTACLE withAngle:0 andScaleX:1.0 andScaleY:1.0];
					if (pMask != nil)
					{
						if ([pMask testPoint:(int)(x - rc.left) withY:(int)(y - rc.top)])
						{
							bFound = YES;
							break;
						}
					}
					
				} while (NO);
				
				// Backdrop object found? remove it
				if (bFound)
				{
					// Set flag for redraw
					bSomethingDeleted = YES;
					
					// Delete sprites
					for (int ns = 0; ns < 4; ns++)
					{
						if (pbkd->pSpr[ns] != nil)
						{
							[spriteGen delSprite:pbkd->pSpr[ns]];
							pbkd->pSpr[ns] = nil;
						}
					}
                    
                    if (pbkd->body != nil)
                    {
                        if (rh4Box2DBase != nil)
                        {
                            rh4Box2DBase->pSubABackdrop(rh4Box2DBase, (b2Body*)pbkd->body);
                        }
                    }
					
					// Overwrite bkd2 structure
					[pLayer->pBkd2 removeIndexRelease:i];
					
					// TODO : decrement image count and remove it from temp image table if doesn't exist anymore
					// not urgent...
					
					// Do not exit loop, this routine deletes all the created backdrop objects at this location
					// break;
					
					// Reset wrap flags
					dwWrapFlags = 0;
					
					// Decrement loop index
					i--;
				}
				
				// Wrapped?
				if (dwWrapFlags != 0)
				{
					i--;
				}
			}
		}
		
		// Force redraw
		if (bSomethingDeleted)
		{
			pLayer->dwOptions |= FLOPT_REDRAW;
			rh3Scrolling |= RH3SCROLLING_REDRAWLAYERS;
		}
	}
}
/** Displays the backdrop objects created at runtime
 */
-(void)displayBkd2Layer:(CLayer*)pLayer andNLayer:(int)nLayer andFlags:(int) flags andX:(int)x2edit andY:(int)y2edit andFlag:(BOOL)flgColMaskEmpty
{
	CBkd2* pbkd;
	int i, obst, v;
	CRect rc;
	
	short img;
	BOOL bTotalColMask = YES;//((rhFrame->leFlags & LEF_TOTALCOLMASK) != 0);
	BOOL bUpdateColMask = ((flags & DLF_DONTUPDATECOLMASK) == 0);
	
	BOOL bWrapHorz = ((pLayer->dwOptions & FLOPT_WRAP_HORZ) != 0);
	BOOL bWrapVert = ((pLayer->dwOptions & FLOPT_WRAP_VERT) != 0);
	BOOL bWrap = (bWrapHorz | bWrapVert);
	
	int nPlayfieldWidth = rhFrame->leWidth;
	int nPlayfieldHeight = rhFrame->leHeight;
	
	// Hide layer?
	if ((pLayer->dwOptions & FLOPT_TOHIDE) != 0)
	{
		for (i = 0; i < [pLayer->pBkd2 size]; i++)
		{
			pbkd = (CBkd2*) [pLayer->pBkd2 get:i];
			
			// Delete sprite
			for (int ns = 0; ns < 4; ns++)
			{
				if (pbkd->pSpr[ns] != nil)
				{
					[spriteGen delSprite:pbkd->pSpr[ns]];
					pbkd->pSpr[ns] = nil;
				}
			}
		}
	}
	
	// Display layer
	if ((pLayer->dwOptions & FLOPT_TOHIDE) == 0)
	{
		BOOL bSaveBkd = ((pLayer->dwOptions & FLOPT_NOSAVEBKD) == 0);
		int dwWrapFlags = 0;
		int nSprite = 0;
		
		for (i = 0; i < [pLayer->pBkd2 size]; i++)
		{
			pbkd = (CBkd2*)[pLayer->pBkd2 get:i];
			
			int nCurSprite = nSprite;
			
			//Actual sprite position (hotspot position)
			int screenPosX = pbkd->x;
			int screenPosY = pbkd->y;
			
			//Sprite is initially located at the backdrop's position.
			rc.left = screenPosX;
			rc.top = screenPosY;
			
			img = pbkd->img;
			CImage* pImg = [rhApp->imageBank getImageFromHandle:img];
			if(pImg != nil)
			{
				if((pbkd->spriteFlag & SF_NOHOTSPOT) == 0)
				{
					//Adjust bounding rectangle for hotspot
					rc.left -= pImg->xSpot;
					rc.top -= pImg->ySpot;
				}
				
				// Calculer rectangle objet
				rc.right = rc.left + pImg->width;
				rc.bottom = rc.top + pImg->height;
			}
			else
			{
				rc.right = rc.left + 1;
				rc.bottom = rc.top + 1;
			}
			
			// On the right of the display? next object (only if no total colmask)
			if (!bTotalColMask && !bWrap && (rc.left >= x2edit + COLMASK_XMARGIN + 32 || rc.top >= y2edit + COLMASK_YMARGIN))
			{
				// Out of visible area: delete sprite
				{
					// Delete sprite
					if (pbkd->pSpr[nCurSprite] != nil)
					{
						[spriteGen delSprite:pbkd->pSpr[nCurSprite]];
						pbkd->pSpr[nCurSprite] = nil;
					}
				}
				continue;
			}
			
			// Wrap
			if (bWrap)
			{
				switch (nSprite)
				{
                        // Normal sprite: test if other sprites should be displayed
					case 0:
						// Wrap horizontally?
						if (bWrapHorz && (rc.left < 0 || rc.right > nPlayfieldWidth))
						{
							// Wrap horizontally and vertically?
							if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
							{
								nSprite = 3;
								dwWrapFlags |= (WRAP_X | WRAP_Y | WRAP_XY);
							}
							
							// Wrap horizontally only
							else
							{
								nSprite = 1;
								dwWrapFlags |= (WRAP_X);
							}
						}
						
						// Wrap vertically?
						else if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
						{
							nSprite = 2;
							dwWrapFlags |= (WRAP_Y);
						}
						
						// Delete other sprites
						if ((dwWrapFlags & WRAP_X) == 0 && pbkd->pSpr[1] != nil)
						{
							[spriteGen delSprite:pbkd->pSpr[1]];
							pbkd->pSpr[1] = nil;
						}
						if ((dwWrapFlags & WRAP_Y) == 0 && pbkd->pSpr[2] != nil)
						{
							[spriteGen delSprite:pbkd->pSpr[2]];
							pbkd->pSpr[2] = nil;
						}
						if ((dwWrapFlags & WRAP_XY) == 0 && pbkd->pSpr[3] != nil)
						{
							[spriteGen delSprite:pbkd->pSpr[3]];
							pbkd->pSpr[3] = nil;
						}
						break;
						
                        // Other sprite instance: wrap horizontally
					case 1:
						// Wrap
						if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
						{
							int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
							rc.left += dx;
							rc.right += dx;
						}
						else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
						{
							int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
							rc.left -= dx;
							rc.right -= dx;
						}
						
						// Remove flag
						dwWrapFlags &= ~WRAP_X;
						
						// Calculate next sprite to display
						nSprite = 0;
						if ((dwWrapFlags & WRAP_Y) != 0)
						{
							nSprite = 2;
						}
						break;
						
                        // Other sprite instance: wrap vertically
					case 2:
						// Wrap
						if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
						{
							int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
							rc.top += dy;
							rc.bottom += dy;
						}
						else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
						{
							int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
							rc.top -= dy;
							rc.bottom -= dy;
						}
						
						// Remove flag
						dwWrapFlags &= ~WRAP_Y;
						
						// Calculate next sprite to display
						nSprite = 0;
						if ((dwWrapFlags & WRAP_X) != 0)
						{
							nSprite = 1;
						}
						break;
						
                        // Other sprite instance: wrap horizontally and vertically
					case 3:
						// Wrap
						if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
						{
							int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
							rc.left += dx;
							rc.right += dx;
						}
						else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
						{
							int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
							rc.left -= dx;
							rc.right -= dx;
						}
						if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
						{
							int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
							rc.top += dy;
							rc.bottom += dy;
						}
						else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
						{
							int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
							rc.top -= dy;
							rc.bottom -= dy;
						}
						
						// Remove flag
						dwWrapFlags &= ~WRAP_XY;
						
						// Calculate next sprite to display
						nSprite = 2;
						break;
				}
			}
			
			v = pbkd->obstacleType;
			BOOL cm_box = (pbkd->colMode == CM_BOX);
			
			// Ladder?
			if (v == OBSTACLE_LADDER)
			{
				[self y_Ladder_Add:nLayer withX1:(int)rc.left andY1:(int)rc.top andX2:(int)rc.right andY2:(int)rc.bottom];
				cm_box = YES;		// Fill rectangle in collision masque
			}
			
			// Obstacle in layer 0?
			if (nLayer == 0 && bUpdateColMask && v != OBSTACLE_TRANSPARENT &&
				(bTotalColMask || (rc.right >= -COLMASK_XMARGIN - 32 && rc.bottom >= -COLMASK_YMARGIN)))
			{
				// Update collisions bitmap (meme si objet en dehors)
				obst = 0;
				if (v == OBSTACLE_SOLID)
				{
					obst = CM_OBSTACLE | CM_PLATFORM;
					flgColMaskEmpty = NO;
				}
				
				// Ajouter le masque "obstacle"
				CMask* mask;
				if (flgColMaskEmpty == NO)
				{
					if (cm_box)
					{
						[rhFrame->colMask fillRectangle:(int)rc.left withY1:(int)rc.top andX2:(int)rc.right andY2:(int)rc.bottom andValue:obst];
					}
					else
					{
						mask = [[rhApp->imageBank getImageFromHandle:img] getMask:GCMF_OBSTACLE withAngle:0 andScaleX:1.0 andScaleY:1.0];
						[rhFrame->colMask orMask:mask withX:(int)rc.left andY:(int)rc.top andPlane:CM_OBSTACLE | CM_PLATFORM andValue:obst];
					}
				}
				
				// Ajouter le masque plateforme
				if (v == OBSTACLE_PLATFORM)
				{
					flgColMaskEmpty = NO;
					if (cm_box)
					{
						[rhFrame->colMask fillRectangle:(int)rc.left withY1:(int)rc.top andX2:(int)rc.right andY2:MIN((int)(rc.top + HEIGHT_PLATFORM), (int)rc.bottom) andValue:CM_PLATFORM];
					}
					else
					{
						mask = [[rhApp->imageBank getImageFromHandle:img] getMask:GCMF_OBSTACLE withAngle:0 andScaleX:1.0 andScaleY:1.0];
						[rhFrame->colMask orPlatformMask:mask withX:(int)rc.left andY:(int)rc.top];
					}
				}
			}
			
			// Display object?
			if (CRectIntersects(rc, pLayer->visibleRect))
			{
				////////////////////////////////////////
				// Non-background layer => create sprite				
				int dwFlags = SF_BACKGROUND | SF_INACTIF;
				if (!bSaveBkd)
				{
					dwFlags |= SF_NOSAVE;
				}
				if (v == OBSTACLE_SOLID)
				{
					dwFlags |= (SF_OBSTACLE | SF_RAMBO);
				}
				if (v == OBSTACLE_PLATFORM)
				{
					dwFlags |= (SF_PLATFORM | SF_RAMBO);
				}
				
				// Create sprite only if not already created
				if (pbkd->pSpr[nCurSprite] == nil)
				{
					pbkd->pSpr[nCurSprite] = [spriteGen addSprite:screenPosX withY:screenPosY andImage:img andLayer:pbkd->nLayer andZOrder:0x10000000 + i * 4 + nCurSprite andBackColor:0 andFlags:dwFlags andObject:nil];
					// mettre spriteextra � (DWORD)pbkd
					[spriteGen modifSpriteEffect:pbkd->pSpr[nCurSprite] withInkEffect:pbkd->inkEffect andInkEffectParam:pbkd->inkEffectParam];
				}
				
				// Otherwise update sprite coordinates
				else
				{
					[spriteGen modifSprite:pbkd->pSpr[nCurSprite] withX:screenPosX andY:screenPosY andImage:img];
				}
			}
			
			// Object out of visible area: delete sprite
			else
			{
				{
					// Delete sprite
					if (pbkd->pSpr[nCurSprite] != nil)
					{
						[spriteGen delSprite:pbkd->pSpr[nCurSprite]];
						pbkd->pSpr[nCurSprite] = nil;
					}
				}
			}
			
			// Wrapped? re-display the same object
			if (dwWrapFlags != 0)
			{
				i--;
			}
		}
	}
}


// -------------------------------------------------------------------------    
// MAIN LOOP
// -------------------------------------------------------------------------
/** Initialisation of the main loop.
 */
-(void)f_InitLoop
{
	
	rhLoopCount = 0;
	//	rh2PushedEvents=0;
	
	rhQuit = 0;						// On ne sort pas!
	rhQuitBis = 0;
	rhDestroyPos = 0;				// Destroy list
	
	for (int n = 0; n < (rhMaxObjects + 31) / 32; n++)		// Yves: ajout du +31: il faut aussi modifier la routine d'allocation
	{
		rhDestroyList[n] = 0;
	}
	
	// Taille de la fenetre
	rh3WindowSx = rhFrame->leEditWinWidth;
	rh3WindowSy = rhFrame->leEditWinHeight;
	
	// Position de KILL des objets loin du terrain
	rh3XMinimumKill = -GAME_XBORDER;		// Les bordures externes
	rh3YMinimumKill = -GAME_YBORDER;
	rh3XMaximumKill = rhLevelSx + GAME_XBORDER;
	rh3YMaximumKill = rhLevelSy + GAME_YBORDER;
	
	// Coordonnees limites de gestion
	int dx = rhWindowX;
	rh3DisplayX = dx;				// Minimum gestion gauche
	dx -= COLMASK_XMARGIN;
	if (dx < 0)
	{
		dx = rh3XMinimumKill;
	}
	rh3XMinimum = dx;
	
	int dy = rhWindowY;			// Minimum gestion haute
	rh3DisplayY = dy;
	dy -= COLMASK_YMARGIN;
	if (dy < 0)
	{
		dy = rh3YMinimumKill;
	}
	rh3YMinimum = dy;
	
	int wx = rhWindowX;			// Maximum gestion droite
	wx += rh3WindowSx + COLMASK_XMARGIN;
	if (wx > rhLevelSx)
	{
		wx = rh3XMaximumKill;
	}
	rh3XMaximum = wx;
	
	int wy = rhWindowY;			// Maximum gestion bas
	wy += rh3WindowSy + COLMASK_YMARGIN;
	if (wy > rhLevelSy)
	{
		wy = rh3YMaximumKill;
	}
	rh3YMaximum = wy;
	
	// Inits diverses
	rh3Scrolling = 0;				// Pas de scrolling
	rh4DoUpdate = 0;				// Premier tour de jeu non affiche...
	rh4EventCount = 0;			// Compteur pour les evenements
	rh4TimeOut = 0;				// Time Out a zero
	
	// Init compteur de sauvegarde des PAUSES
	rh2PauseCompteur = 0;
	
	// Toutes les entrees sont selectionnees
	rh4FakeKey = 0;
	rhPlayer = 0;
	rh2OldPlayer = 0;
	rh2InputMask = (unsigned char) 0xFF;
	rh2MouseKeys = 0;
	
	// RAZ flags actions
	rhEvtProg->rh2ActionEndRoutine = NO;
	rh4OnCloseCount = -1;
	rh4EndOfPause = -1;
	rh4LoadCount = -1;
	rhEvtProg->rh4CheckDoneInstart = NO;
	rh4PauseKey = 0;
    bBodiesCreated = NO;
    rh4Box2DBase = nil;
    rh4Box2DSearched = NO;
    rh4TimerEvents = nil;
    rh4ForEachs = nil;
    rh4CurrentForEach = nil;
    rh4CurrentForEach2 = nil;
    rhEvtProg->bEndForEach = NO;
	
	// RAZ du buffer de calcul du framerate
	int n;
	for (n = 0; n < MAX_FRAMERATE; n++)
	{
		rh4FrameRateArray[n] = 20;				// initialisation � 1/50eme de seconde
	}
	rh4FrameRatePos = 0;
	
	[rhApp->soundPlayer reset];

	// Multitouch
	BOOL bMulti=NO;
	if ((rhFrame->iPhoneOptions&IPHONEOPT_MULTITOUCH)!=0)
	{
		bMulti=YES;
	}
	[rhApp->runView setMultiTouch:bMulti];

	// Sets automatic sleep time
	if([rhApp->runView hasActiveGameControllerConnected])
		[UIApplication sharedApplication].idleTimerDisabled = YES;
	else
		[UIApplication sharedApplication].idleTimerDisabled=(rhFrame->iPhoneOptions&IPHONEOPT_SCREENLOCKING)!=0?YES:NO;
		
	// Joystick creation
	if (rhApp->parentApp==nil)
	{
		if (rhFrame->joystick==JOYSTICK_EXT)
		{
			[rhApp createJoystick:NO withFlags:0];
			[rhApp createJoystickAcc:NO];
		}
		else 
		{
			int flags=0;
			if ((rhFrame->iPhoneOptions&IPHONEOPT_JOYSTICK_FIRE1)!=0)
			{
				flags=JFLAG_FIRE1;
			}
			if ((rhFrame->iPhoneOptions&IPHONEOPT_JOYSTICK_FIRE2)!=0)
			{
				flags|=JFLAG_FIRE2;
			}
			if ((rhFrame->iPhoneOptions&IPHONEOPT_JOYSTICK_LEFTHAND)!=0)
			{
				flags|=JFLAG_LEFTHANDED;
			}
			if (rhFrame->joystick==JOYSTICK_TOUCH)
			{
				flags|=JFLAG_JOYSTICK;
			}
			if ((flags&(JFLAG_FIRE1|JFLAG_FIRE2|JFLAG_JOYSTICK))!=0)
			{
				[rhApp createJoystick:YES withFlags:flags];
			}
			else
			{
				[rhApp createJoystick:NO withFlags:0];
			}
		
			// Accelerometer joystick
			if (rhFrame->joystick==JOYSTICK_ACCELEROMETER)
			{
				[rhApp createJoystickAcc:YES];
			}
			else
			{
				[rhApp createJoystickAcc:NO];
			}
		}
	}
	
	// IAD
	if (rhApp->iAdViewController!=nil)
	{
		[rhApp->iAdViewController setAdAuthorised:(rhFrame->iPhoneOptions&IPHONEOPT_IPHONEFRAMEIAD)!=0];
	}

	double tick = CFAbsoluteTimeGetCurrent()*1000;
	rhTimerOld = tick;
	rhTimer = 0;
}
-(int)f_GameLoop
{ 
	if(rhFrame == nil)
		return 0;

	if(rhApp->modalSubapp != nil)
	{
		[rhApp->modalSubapp handle];
		[self screen_Update];
		return 0;
	}

	// On est en pause?
	// ~~~~~~~~~~~~~~~~
	if (rh2PauseCompteur != 0)
	{
		[self screen_Update];
		return 0;
	}

    // Box2D
    // -----
    if (!bBodiesCreated)
    {
        bBodiesCreated = YES;
        [self CreateBodies];
    }
    
	// Check end of sounds
    // -------------------
    [rhApp->soundPlayer checkPlaying];
    
	// Recupere l'horloge, le nombre de loops
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	double timerBase = CFAbsoluteTimeGetCurrent()*1000;
	double delta = timerBase - rhTimerOld;
	double oldtimer = rhTimer;
	rhTimer = delta;
	delta -= oldtimer;
	rhTimerDelta = (int) delta;				// Delta a la boucle precedente
	rh4TimeOut += delta;			// Compteur time-out.
	rhLoopCount += 1;
	rh4MvtTimerCoef = (rhTimerDelta) * ((double) rhFrame->m_dwMvtTimerBase) / 1000.0;
	rhBaseTempValues=0;
	
	// Gestion du framerate
	rh4FrameRateArray[rh4FrameRatePos] = (int) delta;
	rh4FrameRatePos++;
	if (rh4FrameRatePos >= MAX_FRAMERATE)
	{
		rh4FrameRatePos = 0;
	}
	
	// La souris, si un mouvement souris est defini
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (rhMouseUsed != 0)
	{
		// Retrouve les touches de la souris 
		rh2MouseKeys = 0;
		
		if (rhApp->bMouseDown)
		 {
			 rh2MouseKeys |= 0x10;				//00010000B;
		 }
	}
	
	// Appel des messages JOYSTICK PRESSED pour chaque joueur
	rh2OldPlayer=rhPlayer;
	rhPlayer=0;
    CRunApp* application=rhApp;
    while(application->parentApp!=nil)
    {
        application=application->parentApp;
    }
    if (rhMouseUsed!=0)
    {
        rhPlayer = rh2MouseKeys;
    }
	rhPlayer = 0;
	if(application->joystickGamepad != nil)
		rhPlayer = [application->joystickGamepad getJoystick];
    if (application->joystick!=nil)
        rhPlayer |= [application->joystick getJoystick];
    if (application->joystickAcc!=nil)
        rhPlayer = (rhPlayer&0xF0)|[application->joystickAcc getJoystick];
	rhPlayer&=rhJoystickMask;
    rhPlayer&=rh2InputMask;
		
	unsigned char b;
	b=rhPlayer;
	b &= rh2InputMask;
	b ^= rh2OldPlayer;
	rh2NewPlayer = b;
	if (b != 0)
	{
		b &= rhPlayer;
		if ((b & 0xF0) != 0)
		{
			// Message bloquant pour les touches FEU seules
			rhEvtProg->rhCurOi = 0;
			b = rh2NewPlayer;
			if ((b & 0xF0) != 0)
			{
				rhEvtProg->rhCurParam[0] = b;
				[rhEvtProg handle_GlobalEvents:((-4 << 16) | 0xFFF9)];	// CNDL_JOYPRESSED);
			}
			// Les autres touches...
			if ((b & 0x0F) != 0)
			{
				rhEvtProg->rhCurParam[0] = b;
				[rhEvtProg handle_GlobalEvents:((-4 << 16) | 0xFFF9)];	// CNDL_JOYPRESSED);
			}
		}
		else
		{
			LPDWORD pEvent=rhEvtProg->rhEvents[-OBJ_PLAYER];
			DWORD dw=*(pEvent-NUM_JOYPRESSED);
			if (dw!=0)
			{
				LPDWORD pev=(LPDWORD)((LPBYTE)rhEvtProg->eventPointers+dw);
				[rhEvtProg computeEventList:pev withObject:nil];
			}
		}
	}
	
	// Boucle de gestion des objets
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (rhNObjects != 0)					// Nombre d'objets
	{
		int cptObject = rhNObjects;
		int count = 0;
		do
		{
			rh4ObjectAddCreate = 0;
			while (rhObjectList[count] == nil)
			{
				count++;
			}
			CObject* pObject = rhObjectList[count];
			
			if (pObject->hoPrevNoRepeat!=nil)
			{
				[pObject->hoPrevNoRepeat release];
			}
			pObject->hoPrevNoRepeat = pObject->hoBaseNoRepeat;	// Echange les buffers no repeat
			pObject->hoBaseNoRepeat = nil;							// RAZ du buffer actuel
			if (pObject->hoCallRoutine)
			{
				rh4ObjectCurCreate = count;		// En cas de create object
				[pObject handle];
			}
			
			cptObject += rh4ObjectAddCreate;	 	// Un objet nouveau DEVANT le courant
			count++;
			cptObject--;
		} while (cptObject != 0);
	}
	rh3CollisionCount++; 			// Pour la gestion des evenements: on est plus dans la boucle!
	
	// Appel de tous les evenements
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	rhBaseTempValues=0;
	[rhEvtProg compute_TimerEvents];			// Evenements timer normaux
    [rhEvtProg handle_TimerEvents];
	if (rhEvtProg->rhEventAlways!=0)				// Les evenements ALWAYS
	{
		if ((rhGameFlags & GAMEFLAGS_FIRSTLOOPFADEIN) == 0)
		{
			rhBaseTempValues=0;
			[rhEvtProg computeEventList:rhEvtProg->rhEventAlways withObject:nil];
		}
	 }

	// Effectue les evenements pousses
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	[rhEvtProg handle_PushedEvents];
	
	// Modif les objets bouges par les evenements
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	[self modif_ChangedObjects];
	
	// Detruit les objets marques
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~
	[self destroy_List];
	
	// RAZ du click
	// ~~~~~~~~~~~~
	rhEvtProg->rh2CurrentClick = -1;
	rh4EventCount++;
	rh4FakeKey = 0;
	//	rh4DroppedFlag=0;
	
	// Affiche l'ecran eventuellement
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	if((rhGameFlags & GAMEFLAGS_FIRSTLOOPFADEIN) == 0)
	{
		if (rhApp->parentApp==nil)
		{
			[self screen_Update];
		}
	}
	
	// C'est fini!
	// ~~~~~~~~~~~
	if (rhQuit == 0)
	{
		return rhQuitBis;
	}
	
	// Appel eventuel des evenements fin de niveau
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (rhQuit == LOOPEXIT_NEXTLEVEL ||
		rhQuit == LOOPEXIT_PREVLEVEL ||
		rhQuit == LOOPEXIT_ENDGAME ||
		rhQuit == LOOPEXIT_GOTOLEVEL ||
		rhQuit == LOOPEXIT_QUIT ||
		rhQuit == LOOPEXIT_NEWGAME)
	{
		if (rhApp->parentApp==nil)
		{
			// Renders to the 'oldFrameImage' texture
			if(rhApp->oldFrameImage != nil)
			{
				[rhApp->oldFrameImage release];
				rhApp->oldFrameImage = nil;
			}
			rhApp->oldFrameImage = [[CRenderToTexture alloc] initWithWidth:rhApp->renderer->currentRenderState.framebufferSize.x andHeight:rhApp->renderer->currentRenderState.framebufferSize.y andRunApp:rhApp];
		
			[rhApp->oldFrameImage bindFrameBuffer];
			[self transitionDrawFrame];
			[rhApp->oldFrameImage unbindFrameBuffer];
		}
		
		[rhEvtProg handle_GlobalEvents:(-2 << 16) | 0xFFFD];
	}
	return rhQuit;
}

// Bouge les objets changes par les evenements
// -------------------------------------------
-(void)modif_ChangedObjects
{
	int count = 0;
	for (int no = 0; no < rhNObjects; no++)		// Des objets � voir?
	{
		while (rhObjectList[count] == nil)
		{
			count++;
		}
		CObject* pHo = rhObjectList[count];
		count++;
		
		if ((pHo->hoOEFlags & (OEFLAG_ANIMATIONS | OEFLAG_MOVEMENTS | OEFLAG_SPRITES)) != 0)
		{
			if (pHo->roc->rcChanged)
			{
				[pHo modif];
				pHo->roc->rcChanged = NO;
			}
		}
	}
}

-(void)getMouseCoords
{
	//TODO Fix mouse coordinates
	rh2MouseX = (rhApp->mouseX + rhWindowX) - rhApp->parentX;
	rh2MouseY = (rhApp->mouseY + rhWindowY) - rhApp->parentY;
}


// -----------------------------------------------------------------------
// DETECTION DE COLLISIONS 
// -----------------------------------------------------------------------
-(BOOL)newHandle_Collisions:(CObject*)pHo
{
	pHo->roc->rcCMoveChanged=NO;
	pHo->rom->rmMoveFlag = NO;
		
	// Raz des flags pour le mouvement
	pHo->rom->rmEventFlags = 0;
	 
	// ENTREE /SORTIE DU TERRAIN?
	// ---------------------------------------------------------------------------
	if ((pHo->hoLimitFlags & OILIMITFLAGS_QUICKBORDER) != 0)
	{
		// Regarde si on ENTRE dans le terrain
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		int cadran1 = [self quadran_In:pHo->roc->rcOldX1 withY1:pHo->roc->rcOldY1 andX2:pHo->roc->rcOldX2 andY2:pHo->roc->rcOldY2];
		if (cadran1 != 0)		// Si deja dedans, on ne teste pas
		{
			int cadran2 = [self quadran_In:pHo->hoX - pHo->hoImgXSpot withY1:pHo->hoY - pHo->hoImgYSpot andX2:pHo->hoX - pHo->hoImgXSpot + pHo->hoImgWidth andY2:pHo->hoY - pHo->hoImgYSpot + pHo->hoImgHeight];
			if (cadran2 == 0)		// Teste si entre!
			{
				int chgDir = (cadran1 ^ cadran2);	// Les directions qui ont change!
				if (chgDir != 0)
				{
					pHo->rom->rmEventFlags |= EF_GOESINPLAYFIELD;
					rhEvtProg->rhCurParam[0] = chgDir;
					[rhEvtProg handle_Event:pHo withCode:(-11 << 16) | (((int) pHo->hoType) & 0xFFFF)];  // CNDL_EXTINPLAYFIELD
				}
			}
		}
	
		 // Gestion des flags WRAP
		 // ~~~~~~~~~~~~~~~~~~~~~~
		int cadran = [self quadran_In:pHo->hoX - pHo->hoImgXSpot withY1:pHo->hoY - pHo->hoImgYSpot andX2:pHo->hoX - pHo->hoImgXSpot + pHo->hoImgWidth andY2:pHo->hoY - pHo->hoImgYSpot + pHo->hoImgHeight];
		if ((cadran & pHo->rom->rmWrapping) != 0)
		{
			if ((cadran & BORDER_LEFT) != 0)
			{
				[pHo->rom->rmMovement setXPosition:pHo->hoX + rhLevelSx];	// Sort a gauche
			}
			else if ((cadran & BORDER_RIGHT) != 0)
			{
				[pHo->rom->rmMovement setXPosition:pHo->hoX - rhLevelSx];	// Sort a droite
			}
			if ((cadran & BORDER_TOP) != 0)
			{
				[pHo->rom->rmMovement setYPosition:pHo->hoY + rhLevelSy];		// Sort en haut
			}
			else if ((cadran & BORDER_BOTTOM) != 0)
			{
				[pHo->rom->rmMovement setYPosition:pHo->hoY - rhLevelSy];		// Sort en bas
			}
		}
		
		 // Regarde si on SORT du le terrain
		 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		cadran1 = [self quadran_Out:pHo->roc->rcOldX1 withY1:pHo->roc->rcOldY1 andX2:pHo->roc->rcOldX2 andY2:pHo->roc->rcOldY2];
		if (cadran1 != BORDER_ALL)		// Si deja completement dehors, on ne teste pas
		{
			int cadran2 = [self quadran_Out:pHo->hoX - pHo->hoImgXSpot withY1:pHo->hoY - pHo->hoImgYSpot andX2:pHo->hoX - pHo->hoImgXSpot + pHo->hoImgWidth andY2:pHo->hoY - pHo->hoImgYSpot + pHo->hoImgHeight];
		 
			int chgDir = (~cadran1 & cadran2);
			if (chgDir != 0)
			{
				pHo->rom->rmEventFlags |= EF_GOESOUTPLAYFIELD;
				rhEvtProg->rhCurParam[0] = chgDir;		// ou LOWORD?
				[rhEvtProg handle_Event:pHo withCode:(-12 << 16) | (((int) pHo->hoType) & 0xFFFF)];  // CNDL_EXTOUTPLAYFIELD
			}
		 }
	 }

	 // COLLISION AVEC DES ELEMENTS DE DECOR
	 // ---------------------------------------------------------------------------
	 if ((pHo->hoLimitFlags & OILIMITFLAGS_QUICKBACK) != 0)
	 {
		 // Si movement platforme, YVES!
		 if (pHo->roc->rcMovementType == MVTYPE_PLATFORM)
		 {
			 CMovePlatform* platform = (CMovePlatform*) pHo->rom->rmMovement;
			 [platform mpHandle_Background];
		 }
		 // Autres mouvements
		 // ~~~~~~~~~~~~~~~~~
		 else
		 {
			 int cond = [self colMask_TestObject_IXY:pHo withImage:pHo->roc->rcImage andAngle:pHo->roc->rcAngle andScaleX:pHo->roc->rcScaleX andScaleY:pHo->roc->rcScaleY andX:pHo->hoX andY:pHo->hoY andFoot:0 andPlane:CM_TEST_PLATFORM]; // FRAROT
			 if (cond != 0)
			 {
				 [rhEvtProg handle_Event:pHo withCode:cond];
			 }
		 }
	 }
	 
	 // COLLISION AVEC DES AUTRES SPRITES
	 // ---------------------------------------------------------------------------
	 if ((pHo->hoLimitFlags & OILIMITFLAGS_ONCOLLIDE) != 0)
	 {
		 CArrayList* cnt = [self objectAllCol_IXY:pHo withImage:pHo->roc->rcImage andAngle:pHo->roc->rcAngle andScaleX:pHo->roc->rcScaleX andScaleY:pHo->roc->rcScaleY andX:pHo->hoX andY:pHo->hoY andColList:pHo->hoOiList->oilColList];
		 if (cnt != nil)
		 {
			 int obj;
			 for (obj = 0; obj < [cnt size]; obj++)
			 {
				 CObject* pHox = (CObject*) [cnt get:obj];
				 if ((pHox->hoFlags & HOF_DESTROYED) == 0)	// Detruit au cycle precedent?
				 {
					 // Genere la collision, TOUJOURS sur le type de l'objet inferieur
					 short type = pHo->hoType;
					 CObject* pHo_esi = pHo;
					 CObject* pHo_ebx = pHox;
					 if (pHo_esi->hoType > pHo_ebx->hoType)
					 {
						 pHo_esi = pHox;
						 pHo_ebx = pHo;
						 type = pHo_esi->hoType;
					 }
					 rhEvtProg->rhCurParam[0] = pHo_ebx->hoOi;
					 rhEvtProg->rh1stObjectNumber = pHo_ebx->hoNumber;
					 [rhEvtProg handle_Event:pHo_esi withCode:(-14 << 16) | (((int) type) & 0xFFFF)];	// CNDL_EXTCOLLISION
				 }
			 }
			 [cnt release];
		 }
	 }
	bMoveChanged=pHo->roc->rcCMoveChanged;
	return pHo->roc->rcCMoveChanged;
}

// ----------------------------------------------
// Teste les collisions de tous les objets
// ----------------------------------------------
// Renvoie le nombre de collisions
-(CArrayList*)objectAllCol_IXY:(CObject*)pHo withImage:(short) newImg andAngle:(float)newAngle andScaleX:(float)newScaleX andScaleY:(float)newScaleY andX:(int)newX andY:(int)newY andColList:(short*)pOiColList
{    
    CArrayList* list=nil;

    int rectX1= newX - pHo->hoImgXSpot;
    int rectX2= rectX1 + pHo->hoImgWidth;
    int rectY1= newY - pHo->hoImgYSpot;
    int rectY2= rectY1 + pHo->hoImgHeight;
    
    CMask* pMask2;
    CImage* image2;
    if ((pHo->hoFlags&HOF_NOCOLLISION)!=0)
    {
        return list;
    }
    
    bool bMask1=NO;
    CMask* pMask1=nil;
    CImage* image;
    int nLayer=-1;
    CSprite* sprite1=nil;
    if (pHo->hoType==OBJ_SPR)
    {
        sprite1=pHo->roc->rcSprite;
        if (sprite1!=nil)
        {
            if ((sprite1->sprFlags&SF_COLBOX)==0)
            {
                bMask1=YES;
            }
        }
        nLayer = pHo->ros->rsLayer;
    }
    
    short oldHoFlags = pHo->hoFlags;
    pHo->hoFlags |= HOF_NOCOLLISION;
    int count=0;
    int i;
    CObject* pHox;
    int xHox, yHox;
    CSprite* sprite2;
    if (pOiColList!=nil)
    {
        for (; *pOiColList!=-1; pOiColList+=2)
        {
            CObjInfo* pOil=rhOiList[*(pOiColList+1)];
            int nObject=pOil->oilObject;
            while(nObject>=0)
            {
                pHox=rhObjectList[nObject];
                nObject=pHox->hoNumNext;
                
                if ((pHox->hoFlags&HOF_NOCOLLISION)==0)
                {
					Vec2i objPos = [pHox getPosition];
                    xHox = objPos.x - pHox->hoImgXSpot;
                    yHox = objPos.y - pHox->hoImgYSpot;
                    if ( xHox < rectX2 && 
                        xHox + pHox->hoImgWidth > rectX1 && 
                        yHox < rectY2 && 
                        yHox + pHox->hoImgHeight > rectY1 )
                    {
                        switch(pHox->hoType)
                        {
                            case OBJ_SPR:
                                if (nLayer<0 || (nLayer>=0 && nLayer==pHox->ros->rsLayer))
                                {
                                    sprite2=pHox->roc->rcSprite;
                                    if (sprite2!=nil)
                                    {
                                        if ((sprite2->sprFlags&SF_RAMBO)!=0)
                                        {
                                            if (bMask1==NO || (sprite2->sprFlags&SF_COLBOX)!=0)
                                            {
                                                if (list==nil)
                                                {
                                                    list=[[CArrayList alloc] init];
                                                }
                                                [list add:pHox];
                                                break;
                                            }
                                            if (pMask1==nil)
                                            {
                                                image=[rhApp->imageBank getImageFromHandle:newImg];
                                                if (image!=nil)
                                                {
                                                    pMask1=[image getMask:0 withAngle:newAngle andScaleX:newScaleX andScaleY:newScaleY];
													[pMask1 retain];
                                                }
                                            }
                                            pMask2 = nil;
                                            image2=[rhApp->imageBank getImageFromHandle:pHox->roc->rcImage];
                                            if (image2!=nil)
                                            {
                                                pMask2=[image2 getMask:0 withAngle:pHox->roc->rcAngle andScaleX:pHox->roc->rcScaleX andScaleY:pHox->roc->rcScaleY];
                                            }
                                            if (pMask1!=nil && pMask2!=nil)
                                            {
                                                if ([pMask1 testMask:0 withX1:rectX1 andY1:rectY1 andMask:pMask2 andYBase:0 andX2:xHox andY2:yHox])
                                                {
                                                    if (list==nil)
                                                    {
                                                        list=[[CArrayList alloc] init];
                                                    }
                                                    [list add:pHox];
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                }
                                break;
                            case OBJ_TEXT:
                            case OBJ_COUNTER:
                            case OBJ_LIVES:
                            case OBJ_SCORE:
                            case OBJ_CCA:
                                if (list==nil)
                                {
                                    list=[[CArrayList alloc] init];
                                }
                                [list add:pHox];
                                break;
                            default:
                                if (list==nil)
                                {
                                    list=[[CArrayList alloc] init];
                                }
                                [list add:pHox];
                                break;
                        }
                    }
                }									
            }
        }
    }
    else
    {
        for (i=0; i<rhNObjects; i++)
        {
            while(rhObjectList[count]==nil)
                count++;
            pHox=rhObjectList[count];
            count++;
            
            if ((pHox->hoFlags&HOF_NOCOLLISION)==0)
            {
				Vec2i objPos = [pHox getPosition];
                xHox = objPos.x - pHox->hoImgXSpot;
                yHox = objPos.y - pHox->hoImgYSpot;
                if ( xHox < rectX2 && 
                    xHox + pHox->hoImgWidth > rectX1 && 
                    yHox < rectY2 && 
                    yHox + pHox->hoImgHeight > rectY1 )
                {
                    switch(pHox->hoType)
                    {
                        case OBJ_SPR:
                            if (nLayer<0 || (nLayer>=0 && nLayer==pHox->ros->rsLayer))
                            {
                                sprite2=pHox->roc->rcSprite;
                                if (sprite2!=nil)
                                {
                                    if ((sprite2->sprFlags&SF_RAMBO)!=0)
                                    {
                                        if (bMask1==NO || (sprite2->sprFlags&SF_COLBOX)!=0)
                                        {
                                            if (list==nil)
                                            {
                                                list=[[CArrayList alloc] init];
                                            }
                                            [list add:pHox];
                                            break;
                                        }
                                        if (pMask1==nil)
                                        {
                                            image=[rhApp->imageBank getImageFromHandle:newImg];
                                            if (image!=nil)
                                            {
                                                pMask1=[image getMask:0 withAngle:newAngle andScaleX:newScaleX andScaleY:newScaleY];
                                                [pMask1 retain]; 
                                            }
                                        }
                                        pMask2 = nil;
                                        image2=[rhApp->imageBank getImageFromHandle:pHox->roc->rcImage];
                                        if (image2!=nil)
                                        {
                                            pMask2=[image2 getMask:0 withAngle:pHox->roc->rcAngle andScaleX:pHox->roc->rcScaleX andScaleY:pHox->roc->rcScaleY];
                                        }
                                        if (pMask1!=nil && pMask2!=nil)
                                        {									
                                            if ([pMask1 testMask:0 withX1:rectX1 andY1:rectY1 andMask:pMask2 andYBase:0 andX2:xHox andY2:yHox])
                                            {
                                                if (list==nil)
                                                {
                                                    list=[[CArrayList alloc] init];
                                                }
                                                [list add:pHox];
                                                break;
                                            }
                                        }									
                                    }
                                }
                            }
                            break;
                        case OBJ_TEXT:
                        case OBJ_COUNTER:
                        case OBJ_LIVES:
                        case OBJ_SCORE:
                        case OBJ_CCA:
                            if (list==nil)
                            {
                                list=[[CArrayList alloc] init];
                            }
                            [list add:pHox];
                            break;
                        default:
                            if (list==nil)
                            {
                                list=[[CArrayList alloc] init];
                            }
                            [list add:pHox];
                            break;
                    }
                }
            }									
        }
    }
    
    // Frees the retained mask
    if (pMask1!=nil)
        [pMask1 release];
    
    // Remettre anciens flags
    pHo->hoFlags = oldHoFlags; 
    return list;
}
/*
-(CArrayList*)objectAllCol_IXY:(CObject*)pHo withImage:(short) newImg andAngle:(int)newAngle andScaleX:(float)newScaleX andScaleY:(float)newScaleY andX:(int)newX andY:(int)newY
{
	CArrayList* list = nil;
	
	// Les collisions d'un objet sprite
	// --------------------------------
	CObject* pHox;
	int count, i;
	int rectX1, rectX2, rectY1, rectY2;
	if ((pHo->hoFlags & (HOF_REALSPRITE | HOF_OWNERDRAW)) != 0)
	{
		// Les collisions avec les autres sprites
		// --------------------------------------
		if (pHo->roc->rcSprite != nil)
		{
			list = [spriteGen spriteCol_TestSprite_All:pHo->roc->rcSprite withImage:newImg andX:newX - rhWindowX andY:newY - rhWindowY andAngle:newAngle andScaleX:newScaleX andScaleY:newScaleY andFlags:0];
		}
		
		// Les collisions avec des objets d'extension non sprites
		// ------------------------------------------------------
		if ((pHo->hoLimitFlags & OILIMITFLAGS_QUICKEXT) != 0)
		{
			short oldHoFlags = pHo->hoFlags;
			pHo->hoFlags |= HOF_NOCOLLISION;
			
			rectX1 = newX - pHo->hoImgXSpot;
			rectX2 = rectX1 + pHo->hoImgWidth;
			rectY1 = newY - pHo->hoImgYSpot;
			rectY2 = rectY1 + pHo->hoImgHeight;
			
			count = 0;
			for (i = 0; i < rhNObjects; i++)
			{
				while (rhObjectList[count] == nil)
				{
					count++;
				}
				pHox = rhObjectList[count];
				count++;
				
				// YVES: ajout HOF_OWNERDRAW car les sprites ownerdraw sont g�r�s dans les collisions
				if ((pHox->hoFlags & (HOF_REALSPRITE | HOF_OWNERDRAW | HOF_NOCOLLISION)) == 0)
				{
					if (pHox->hoX - pHox->hoImgXSpot <= rectX2 &&
						pHox->hoX - pHox->hoImgXSpot + pHox->hoImgWidth >= rectX1 &&
						pHox->hoY - pHox->hoImgYSpot <= rectY2 &&
						pHox->hoY - pHox->hoImgYSpot + pHox->hoImgHeight >= rectY1)
					{
						if (list == nil)
						{
							list = [[CArrayList alloc] init];
						}
						[list add:pHox];
					}
				}
			}
			// Remettre anciens flags
			pHo->hoFlags = oldHoFlags;
		}
	}
	// Les collisions d'un objet non sprite
	// ------------------------------------
	else
	{
		if ((pHo->hoFlags & HOF_NOCOLLISION) == 0)
		{
			short oldHoFlags = pHo->hoFlags;
			pHo->hoFlags |= HOF_NOCOLLISION;
			
			rectX1 = newX - pHo->hoImgXSpot;
			rectX2 = rectX1 + pHo->hoImgWidth;
			rectY1 = newY - pHo->hoImgYSpot;
			rectY2 = rectY1 + pHo->hoImgHeight;
			
			count = 0;
			for (i = 0; i < rhNObjects; i++)
			{
				while (rhObjectList[count] == nil)
				{
					count++;
				}
				pHox = rhObjectList[count];
				count++;
				
				if ((pHox->hoFlags & HOF_NOCOLLISION) == 0)
				{
					// ??? Remplacement de QUICKEXT par QUICKCOL pour corriger pb collisions avec objet FLI
					// ??? A verifier!!!!!
					if ((pHox->hoLimitFlags & OILIMITFLAGS_QUICKCOL) != 0)
					{
						if (pHox->hoX - pHox->hoImgXSpot <= rectX2 &&
							pHox->hoX - pHox->hoImgXSpot + pHox->hoImgWidth >= rectX1 &&
							pHox->hoY - pHox->hoImgYSpot <= rectY2 &&
							pHox->hoY - pHox->hoImgYSpot + pHox->hoImgHeight >= rectY1)
						{
							if (list == nil)
							{
								list = [[CArrayList alloc] init];
							}
							[list add:pHox];
						}
					}
				}
			}
			// Remettre anciens flags
			pHo->hoFlags = oldHoFlags;
		}
	}
	return list;
}
*/

// ----------------------------------------------
// Teste les collisions d'un objet avec le decor
// Si collision, retourne la condition COLBACK
// ----------------------------------------------
-(int)colMask_TestObject_IXY:(CObject*)pHo withImage:(short)newImg andAngle:(float)newAngle andScaleX:(float)newScaleX andScaleY:(float)newScaleY andX:(int)newX andY:(int)newY andFoot:(int)htfoot andPlane:(int)plan
{
	int res = 0;
	int x = newX;
	int y = newY;
	
	BOOL bSprite = NO;
	
	if ((pHo->hoFlags & (HOF_REALSPRITE | HOF_OWNERDRAW)) != 0)
	{
		if ((pHo->ros->rsCreaFlags & SF_COLBOX) == 0)
		{
			bSprite = YES;
		}
	}
	
	if (bSprite)
	{
		// UN OBJET SPRITE
		CSprite* pSpr = pHo->roc->rcSprite;
		if (pSpr != nil)
		{
			if ([rhFrame bkdCol_TestSprite:pSpr withImage:newImg andX:x andY:y andAngle:newAngle andScaleX:newScaleX andScaleY:newScaleY andFoot:htfoot andPlane:plan])
			{
				res = ((-13 << 16) | (((int) pHo->hoType) & 0xFFFF));	    // CNDL_EXTCOLBACK
			}
		}
	}
	else
	{
		x -= pHo->hoImgXSpot;
		y -= pHo->hoImgYSpot;
		
		// UN OBJET EXTENSION
		if (htfoot != 0)
		{
			y += pHo->hoImgHeight;
			y -= htfoot;
			if ([rhFrame bkdCol_TestRect:x withY:y andWidth:pHo->hoImgWidth andHeight:htfoot andLayer:pHo->hoLayer andPlane:plan])
			{
				res = ((-13 << 16) | (((int) pHo->hoType) & 0xFFFF));	    // CNDL_EXTCOLBACK
			}
		}
		else
		{
			if ([rhFrame bkdCol_TestRect:x withY:y andWidth:pHo->hoImgWidth andHeight:pHo->hoImgHeight andLayer:pHo->hoLayer andPlane:plan])
			{
				res = ((-13 << 16) | (((int) pHo->hoType) & 0xFFFF));	    // CNDL_EXTCOLBACK
			}
		}
	}
	return res;
}

// ---------------------------------------------------------------------------
// Routine: retourne le quadran pointe par AX/BX lors de la sortie d'un sprite
// ---------------------------------------------------------------------------
-(int)quadran_Out:(int)x1 withY1:(int)y1 andX2:(int)x2 andY2:(int)y2
{
	int cadran = 0;
	if (x1 < 0)
	{
		cadran |= BORDER_LEFT;
	}
	if (y1 < 0)
	{
		cadran |= BORDER_TOP;
	}
	if (x2 > rhLevelSx)
	{
		cadran |= BORDER_RIGHT;
	}
	if (y2 > rhLevelSy)
	{
		cadran |= BORDER_BOTTOM;
	}
	return Table_InOut[cadran];
}
// ---------------------------------------------------------------------------
// Routine: retourne le quadran pointe par AX/BX lors de l'entree d'un sprite 
// ---------------------------------------------------------------------------
-(int)quadran_In:(int)x1 withY1:(int)y1 andX2:(int)x2 andY2:(int)y2
{
	int cadran = 15;
	if (x1 < rhLevelSx)
	{
		cadran &= ~BORDER_RIGHT;
	}
	if (y1 < rhLevelSy)
	{
		cadran &= ~BORDER_BOTTOM;
	}
	if (x2 > 0)
	{
		cadran &= ~BORDER_LEFT;
	}
	if (y2 > 0)
	{
		cadran &= ~BORDER_TOP;
	}
	return Table_InOut[cadran];
}

// ---------------------------------------------------------------------------
// Generateur aleatoire, entree AX= chiffre maxi
// ---------------------------------------------------------------------------
-(unsigned short)random:(unsigned short)wMax
{
	/*unsigned short wBX = wMax;
	rh3Graine = LOWORD((int)rh3Graine * 31415) + 1;
	return HIWORD((int)rh3Graine * wBX);
	 */
	
	int calcul = (int) rh3Graine * 31415 + 1;
	rh3Graine = (short) calcul;
	calcul &= 0x0000FFFF;
	return (short) ((calcul * wMax) >> 16);
}

// ----------------------------------
// Interprete un parametre DIRECTION
// ----------------------------------
-(int)get_Direction:(int)dir
{
	if (dir == 0 || dir == -1)
	{
		// Au hasard parmi les 32
		// ~~~~~~~~~~~~~~~~~~~~~~
		return [self random:32];
	}
	
	// Compte le nombre de directions demandees
	int loop;
	int found = 0;
	int count = 0;
	int dirShift = dir;
	for (loop = 0; loop < 32; loop++)
	{
		if ((dirShift & 1) != 0)
		{
			count++;
			found = loop;
		}
		dirShift >>= 1;
	}
	
	// Une direction?
	// ~~~~~~~~~~~~~~
	if (count == 1)
	{
		return found;
	}
	
	// Au hasard
	// ~~~~~~~~~
	count = [self random:(short)count];
	dirShift = dir;
	for (loop = 0; loop < 32; loop++)
	{
		if ((dirShift & 1) != 0)
		{
			count--;
			if (count < 0)
			{
				return loop;
			}
		}
		dirShift >>= 1;
	}
	return 0;
}


// ------------------------------------------------------------------------
// MISE A JOUR DES OBJETS PLAYER
// ------------------------------------------------------------------------
-(void)update_PlayerObjects:(int)joueur withType:(short)type andValue:(int)value
{
	joueur++;
	
	int count = 0;
	for (int no = 0; no < rhNObjects; no++)
	{
		while (rhObjectList[count] == nil)
		{
			count++;
		}
		CObject* pHo = rhObjectList[count];
		if (pHo->hoType == type)
		{
			switch (type)
			{
				case 5:	// OBJ_SCORE
				{
					CScore* pScore = (CScore*) pHo;
					if (pScore->rsPlayer == joueur)
					{
						[pScore->rsValue forceInt:value];
					}
					break;
				}
				case 6:	// OBJ_LIVES
				{
					CLives* pLife = (CLives*) pHo;
					if (pLife->rsPlayer == joueur)
					{
						[pLife->rsValue forceInt:value];
					}
					break;
				}
			}
			pHo->roc->rcChanged = YES;
			[pHo modif];
		}
		count++;
	}
}

// Termine les vies, genere les evenements PLUS DE VIE
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(void)actPla_FinishLives:(int)joueur withLive:(int)live
{
	int* lives = [rhApp getLives];
	if (live == lives[joueur])
	{
		return;
	}
	
	// Nouvelle vie=0?
	if (live == 0)
	{
		if (lives[joueur] != 0)
		{
			[rhEvtProg push_Event:0 withCode:((-5 << 16) | 0xFFF9) andParam:0 andObject:nil andOI:(short)joueur];
		}
	}
	
	// Change les objets...
	lives[joueur] = live;
	[self update_PlayerObjects:joueur withType:OBJ_LIVES andValue:live];
}

// -----------------------------------
// CONDITION: mouse lays on objects
// -----------------------------------
-(BOOL)getMouseOnObjectsEDX:(short)oiList withNegation:(BOOL)nega
{
	 // Des objets a voir?
	 // ------------------
	CObject* pHo = [rhEvtProg evt_FirstObject:oiList];
	if (pHo == nil)
		return nega;

	int cpt = rhEvtProg->evtNSelectedObjects;
	 
	// Demande les collisions des sprites
	// ----------------------------------
	int x = rh2MouseX;
	int y = rh2MouseY;
	CArrayList* list = [[[CArrayList alloc] init] autorelease];
	CSprite* curSpr = [spriteGen spriteCol_TestPoint:nil withLayer:LAYER_ALL andX:x andY:y andFlags:0];
	CObject* pHoFound;
	while (curSpr != nil)
	{
		pHoFound = curSpr->sprExtraInfo;
		if ((pHoFound->hoFlags & HOF_DESTROYED) == 0)		//; Detruit au cycle precedent?
		{
			[list add:pHoFound];
		}
		curSpr = [spriteGen spriteCol_TestPoint:curSpr withLayer:LAYER_ALL andX:x andY:y andFlags:0];
	}
	 
	// Demande les collisions des autres objets
	// ----------------------------------------
	int count = 0;
	int no;
	for (no = 0; no < rhNObjects; no++)		// Des objets � voir?
	{
		while (rhObjectList[count] == nil)
		{
			count++;
		}
		pHoFound = rhObjectList[count];
		count++;
		if ((pHoFound->hoFlags & (HOF_REALSPRITE | HOF_NOCOLLISION)) == 0)
		{
			int x1 = pHoFound->hoX - pHoFound->hoImgXSpot;
			int x2 = x1 + pHoFound->hoImgWidth;
			int y1 = pHoFound->hoY - pHoFound->hoImgYSpot;
			int y2 = y1 + pHoFound->hoImgHeight;
			if (x >= x1 && x < x2 && y >= y1 && y < y2)
			{
				if ((pHoFound->hoFlags & HOF_DESTROYED) == 0)		//; Detruit au cycle precedent?
				{
					[list add:pHoFound];
				}
			}
		}
	}
	 
	// Demande les objets selectionnes
	// -------------------------------
	if ([list size] == 0)
		return nega;
	 
	if (nega == NO)
	{
		do
		{
			for (count = 0; count < [list size]; count++)
			{
				pHoFound = (CObject*) [list get:count];
				if (pHoFound == pHo)
					break;
			}
			if (count == [list size])
			{
				cpt--;						//; Pas trouve dans la liste-> on le vire
				[rhEvtProg evt_DeleteCurrentObject];
			}
			pHo = [rhEvtProg evt_NextObject];
		} while (pHo != nil);
		return cpt != 0;
	}
	else
	{
		// Avec negation
		do
		{
			for (count = 0; count < [list size]; count++)
			{
				pHoFound = (CObject*) [list get:count];
				if (pHoFound == pHo)
					return NO;
			}
			pHo = [rhEvtProg evt_NextObject];
		} while (pHo != nil);
		return YES;
	}
	return NO;
}


// Gestion generique fontes / objets
+(CFontInfo*)getObjectFont:(CObject*)hoPtr
{
	CFontInfo* info = nil;
	
	if (hoPtr->hoType >= KPX_BASE)
	{
		CExtension* e = (CExtension*) hoPtr;
		info = [e-> ext getRunObjectFont];
	}
	else
	{
		switch (hoPtr->hoType)
		{
			case 3:		// OBJ_TEXT:
			{
				CText* pText = (CText*) hoPtr;
				info = [pText getFont];
				break;
			}
			case 5:		// OBJ_SCORE:
			{
				CScore* pScore = (CScore*) hoPtr;
				info = [pScore getFont];
				break;
			}
			case 6:		// OBJ_LIVES:
			{
				CLives* pLives = (CLives*) hoPtr;
				info = [pLives getFont];
				break;
			}
			case 7:		// OBJ_COUNTER:
			{
				CCounter* pCounter = (CCounter*) hoPtr;
				info = [pCounter getFont];
				break;
			}
		}
	}
	if (info == nil)
	{
		info = [[CFontInfo alloc] init];
		return info;
	}
	CFontInfo* info2=[[CFontInfo alloc] init];
	[info2 copy:info];
	return info2;
}

/** Sets an object font.
 */
+(void)setObjectFont:(CObject*)hoPtr withFontInfo:(CFontInfo*)pLf andRect:(CRect)pNewSize
{
	if (hoPtr->hoType >= KPX_BASE)
	{
		CExtension* e = (CExtension*) hoPtr;
		[e->ext setRunObjectFont:pLf withRect:pNewSize];
	}
	else
	{
		switch (hoPtr->hoType)
		{
			case 3:		// OBJ_TEXT:
			{
				CText* pText = (CText*) hoPtr;
				[pText setFont:pLf withRect:pNewSize];
				break;
			}
			case 5:		// OBJ_SCORE:
			{
				CScore* pScore = (CScore*) hoPtr;
				[pScore setFont:pLf withRect:pNewSize];
				break;
			}
			case 6:		// OBJ_LIVES:
			{
				CLives* pLives = (CLives*) hoPtr;
				[pLives setFont:pLf withRect:pNewSize];
				break;
			}
			case 7:		// OBJ_COUNTER:
			{
				CCounter* pCounter = (CCounter*) hoPtr;
				[pCounter setFont:pLf withRect:pNewSize];
				break;
			}
		}
	}
}

/** Returns an object's color.
 */
+(int)getObjectTextColor:(CObject*)hoPtr
{
	if (hoPtr->hoType >= KPX_BASE)
	{
		CExtension* e = (CExtension*) hoPtr;
		return [e->ext getRunObjectTextColor];
	}
	switch (hoPtr->hoType)
	{
		case 3:		// OBJ_TEXT:
		{
			CText* pText = (CText*) hoPtr;
			return [pText getFontColor];
		}
		case 5:		// OBJ_SCORE:
		{
			CScore* pScore = (CScore*) hoPtr;
			return [pScore getFontColor];
		}
		case 6:		// OBJ_LIVES:
		{
			CLives* pLives = (CLives*) hoPtr;
			return [pLives getFontColor];
		}
		case 7:		// OBJ_COUNTER:
		{
			CCounter* pCounter = (CCounter*) hoPtr;
			return [pCounter getFontColor];
		}
	}
	return 0;
}
/** Sets an object font color.
 */
+(void)setObjectTextColor:(CObject*)hoPtr withColor:(int)rgb
{
	if (hoPtr->hoType >= KPX_BASE)
	{
		CExtension* e = (CExtension*) hoPtr;
		[e->ext setRunObjectTextColor:rgb];
	}
	else
	{
		switch (hoPtr->hoType)
		{
			case 3:		// OBJ_TEXT:
			{
				CText* pText = (CText*) hoPtr;
				[pText setFontColor:rgb];
				break;
			}
			case 5:		// OBJ_SCORE:
			{
				CScore* pScore = (CScore*) hoPtr;
				[pScore setFontColor:rgb];
				break;
			}
			case 6:		// OBJ_LIVES:
			{
				CLives* pLives = (CLives*) hoPtr;
				[pLives setFontColor:rgb];
				break;
			}
			case 7:		// OBJ_COUNTER:
			{
				CCounter* pCounter = (CCounter*) hoPtr;
				[pCounter setFontColor:rgb];
				break;
			}
		}
	}
}


//; Trouve une direction � partir d'une pente AX/BX -> AX
// -----------------------------------------------------
+(int)get_DirFromPente:(int)x withY:(int)y
{
	if (x == 0)							// Si nul en X
	{
		if (y >= 0)
		{
			return 24;	    // DIRID_S;
		}
		return 8;			    // DIRID_N;
	}
	if (y == 0)							// Si nul en Y
	{
		if (x >= 0)
		{
			return 0;		    // DIRID_E;
		}
		return 16;			    // DIRID_W;
	}
	
	int dir;
	BOOL flagX = NO, flagY = NO;		// Flags de signe
	if (x < 0)							// DX negatif?
	{
		flagX = YES;
		x = -x;
	}
	if (y < 0)							// DX negatif?
	{
		flagY = YES;
		y = -y;
	}
	
	int d = (x * 256) / y;					// Calcul de la pente *256 pour plus de precision
	int index;
	for (index = 0;; index += 2)
	{
		if (d >= CosSurSin32[index])
		{
			break;
		}
	}
	dir = CosSurSin32[index + 1];			//; Charge la direction
	
	if (flagY)
	{
		dir = -dir + 32;						//; R�tablir en Y
		dir &= 31;
	}
	if (flagX)
	{
		dir -= 8;								//; Retablir en X
		dir &= 31;
		dir = -dir;
		dir &= 31;
		dir += 8;
		dir &= 31;
	}
	return dir;
}

// -----------------------------------------------------------------------
// SPRITES OWNER DRAW QUICK DISPLAY 
// -----------------------------------------------------------------------

-(void)add_QuickDisplay:(CObject*)hoPtr
{
	if (rh4FirstQuickDisplay<0)			
	{
		rh4FirstQuickDisplay=hoPtr->hoNumber;
		hoPtr->hoPreviousQuickDisplay=0x8000;
	}
	else
	{
		if (rh4LastQuickDisplay>=0)
		{
			CObject* hoLast=rhObjectList[rh4LastQuickDisplay];
			hoLast->hoNextQuickDisplay=hoPtr->hoNumber;
			hoPtr->hoPreviousQuickDisplay=hoLast->hoNumber;
		}
	}
	rh4LastQuickDisplay=hoPtr->hoNumber;
	hoPtr->hoNextQuickDisplay=0x8000;
}

-(void)draw_QuickDisplay:(CRenderer*)renderer
{
	int nObject = rh4FirstQuickDisplay;
	while (nObject >= 0)
	{
		CObject* hoPtr = rhObjectList[nObject];
		
		if ((hoPtr->ros->rsFlags & (RSFLAG_SLEEPING | RSFLAG_HIDDEN)) == 0)	// Afficher le sprite?
		{
			[hoPtr draw:renderer];
		}
		nObject = hoPtr->hoNextQuickDisplay;
	}
}

-(void)remove_QuickDisplay:(CObject*)hoPtr
{
	CObject* hoPrevious;
	CObject* hoNext;
	
	short next=hoPtr->hoNextQuickDisplay;
	short prev=hoPtr->hoPreviousQuickDisplay;

	if (prev>=0)
	{
		hoPrevious=rhObjectList[prev];
		if(hoPrevious != nil)
			hoPrevious->hoNextQuickDisplay=next; //Francois: Why would it crash here? (hoPrevious is nil in an example file I have). I have prevented it from crashing temporarily (above line).
	}
	else 
	{
		rh4FirstQuickDisplay=next;
	}
	if (next>=0)
	{
		hoNext=rhObjectList[next];
		hoNext->hoPreviousQuickDisplay=prev;
	}
	else
	{
		rh4LastQuickDisplay=prev;		
	}
}


//  --------------------------------------------------------------------------
//	ANIMATION DISAPPEAR
//  --------------------------------------------------------------------------
-(void)init_Disappear:(CObject*)hoPtr
{
	BOOL bFlag = NO;
	int dw = 0;
	
	if ((hoPtr->hoFlags & HOF_FADEIN) == 0)				// Le sprite est-il encore en fade-in?
	{
		if ([hoPtr->ros createFadeSprite:YES]==NO)
		{
			if ((hoPtr->hoOEFlags & OEFLAG_ANIMATIONS) != 0)
			{
				if ([hoPtr->roa anim_Exist:ANIMID_DISAPPEAR])
				{
					dw = 1;								// Une animation presente?
				}
			}
		}
		if ((hoPtr->hoFlags & HOF_FADEOUT) != 0)
		{
			dw |= 2;							// Ou un fade?
		}
		if (dw == 0)
		{
			bFlag = YES;
		}
	}
	else
	{
		bFlag = YES;
	}
	
	// Rien du tout-> on detruit le sprite!
	if (bFlag)
	{
		hoPtr->hoCallRoutine = NO;
		[self destroy_Add:hoPtr->hoNumber];
		return;
	}
	
	// Branche la fausse routine de mouvement
	if (hoPtr->roc->rcSprite != nil)
	{
		[hoPtr->roc->rcSprite setSpriteColFlag:0];
	}
	if (hoPtr->rom != nil)
	{
        [hoPtr->rom kill:NO];
		[hoPtr->rom initSimple:hoPtr withType:MVTYPE_DISAPPEAR andFlag:NO];
		hoPtr->roc->rcSpeed = 0;
	}
	if ((dw & 1) != 0)
	{
		[hoPtr->roa animation_Force:ANIMID_DISAPPEAR];
		[hoPtr->roa animation_OneLoop];
	}
}

// -------------------------------------------------------------------------
// Conditions en +
// -------------------------------------------------------------------------
+(void)objectHide:(CObject*)pHo
{
	if (pHo->ros != nil)
	{
		[pHo->ros obHide];
		pHo->ros->rsFlags &= ~RSFLAG_VISIBLE;
		pHo->ros->rsFlash = 0;
	}
}

+(void)objectShow:(CObject*)pHo
{
	if (pHo->ros != nil)
	{
		[pHo->ros obShow];
		pHo->ros->rsFlags |= RSFLAG_VISIBLE;
		pHo->ros->rsFlash = 0;
	}
}


// -------------------------------------------------------------------------
// CALCUL DU FRAMERATE
// -------------------------------------------------------------------------    
-(int)getFrameRate
{
	int total=0;	
	for (int n=0; n<MAX_FRAMERATE; n++)
	{
		total+=rh4FrameRateArray[n];
	}
	return (1000*MAX_FRAMERATE)/total;
}

// -------------------------------------------------------------------------
// STOCKAGE GLOBAL POUR LES EXTENSIONS
// -------------------------------------------------------------------------    
-(CExtStorage*)getStorage:(int)id
{
	if (rhApp->extensionStorage != nil)
	{
		for (int n = 0; n < [rhApp->extensionStorage size]; n++)
		{
			CExtStorage* e = (CExtStorage*)[rhApp->extensionStorage get:n];
			if (e->sid == id)
			{
				return e;
			}
		}
	}
	return nil;
}

-(void)delStorage:(int)sid
{
	if (rhApp->extensionStorage != nil)
	{
		int count = [rhApp->extensionStorage size];
		for (int n=0; n<count; n++)
		{
			CExtStorage* e = (CExtStorage*)[rhApp->extensionStorage get:n];
			if (e->sid == sid)
			{
				[rhApp->extensionStorage removeIndex:n];
				break;
			}
		}
	}
}

-(void)addStorage:(CExtStorage*)data withID:(int)sid
{
	CExtStorage* e = [self getStorage:sid];
	if (e == nil)
	{
		if (rhApp->extensionStorage == nil)
		{
			rhApp->extensionStorage = [[CArrayList alloc] init];
		}
		data->sid = sid;
		[rhApp->extensionStorage add:data];
	}
}

// -----------------------------------------------------------------------
// Sub applications
// -----------------------------------------------------------------------
-(void)addSubApp:(CCCA*)pSubApp
{
	for (int n=0; n<MAX_SUBAPPS; n++)
	{
		if (subApps[n]==nil)
		{
			subApps[n]=pSubApp;
			nSubApps++;
			break;
		}
	}
}
-(void)removeSubApp:(CCCA*)pSubApp
{
	for (int n=0; n<MAX_SUBAPPS; n++)
	{
		if (subApps[n]==pSubApp)
		{
			subApps[n]=nil;
			nSubApps--;
			break;
		}
	}
}

// -----------------------------------------------------------------------
// EVALUATION D'EXPRESSION
// -----------------------------------------------------------------------

-(CValue*)get_EventExpressionAny:(LPEVP)evpPtr
{
	rh4ExpToken=(LPEXP)&evpPtr->evp.evpW.evpW1;
	rh4CurToken = 0;
	return [self getTempCValue:[self getExpression]];
}

-(CValue*)get_EventExpressionAnyNoCopy:(LPEVP)evpPtr
{
	rh4ExpToken=(LPEXP)&evpPtr->evp.evpW.evpW1;
	rh4CurToken = 0;
	return [self getExpression];
}

-(int)get_EventExpressionInt:(LPEVP)evpPtr
{
	rh4ExpToken=(LPEXP)&evpPtr->evp.evpW.evpW1;
	rh4CurToken=0;
	CValue* exp = [self getExpression];
	switch (exp->type)
	{
		case 0:
			return exp->intValue;
		case 1:
			return (int)exp->doubleValue;
	}
	return 0;
}

-(double)get_EventExpressionDouble:(LPEVP)evpPtr
{
	rh4ExpToken=(LPEXP)&evpPtr->evp.evpW.evpW1;
	rh4CurToken=0;
	CValue* exp = [self getExpression];

	switch (exp->type)
	{
		case 0:
			return (double) exp->intValue;
		case 1:
			return exp->doubleValue;
	}
	return 0;
}

-(NSString*)get_EventExpressionString:(LPEVP)evpPtr
{
	rh4ExpToken=(LPEXP)&evpPtr->evp.evpW.evpW1;
	rh4CurToken=0;
	CValue* ret=[self getTempString:[[self getExpression] getString]];
	return [ret getString];
}

-(NSString*)get_EventExpressionStringNoCopy:(LPEVP)evpPtr
{
	rh4ExpToken=(LPEXP)&evpPtr->evp.evpW.evpW1;
	rh4CurToken=0;
	return [[self getExpression] getString];
}

-(int)get_ExpressionInt
{
	return [[self getExpression] getInt];
}

-(double)get_ExpressionDouble
{
	return [[self getExpression] getDouble];
}

-(NSString*)get_ExpressionString
{
	CValue* ret=[self getTempString:[[self getExpression] getString]];
	return [ret getString];
}

-(NSString*)get_ExpressionStringNoCopy
{
	return [[self getExpression] getString];
}

-(CValue*)get_ExpressionAny
{
	return [self getTempCValue:[self getExpression]];
}

-(CValue*)get_ExpressionAnyNoCopy
{
	return [self getExpression];
}

-(CValue*)getExpression
{
	int ope;
	int pileStart=rh4PosPile;
	rh4Operators[rh4PosPile]=0;
	
	do
	{
		rh4PosPile++;
		
		callTable_Expression[rh4ExpToken->expCode.expSCode.expType+NUMBEROF_SYSTEMTYPES](self);
		rh4ExpToken=(LPEXP)((LPBYTE)rh4ExpToken+rh4ExpToken->expSize);
		
		// Regarde l'opÈrateur
		do
		{
			ope=rh4ExpToken->expCode.expLCode.expCode;
			if (ope>OPERATOR_START && ope<OPERATOR_END)
			{
				if (ope>rh4Operators[rh4PosPile-1])
				{
					rh4Operators[rh4PosPile]=ope;
					rh4ExpToken=(LPEXP)((LPBYTE)rh4ExpToken+rh4ExpToken->expSize);			
					rh4PosPile++;
					callTable_Expression[rh4ExpToken->expCode.expSCode.expType+NUMBEROF_SYSTEMTYPES](self);
					rh4ExpToken=(LPEXP)((LPBYTE)rh4ExpToken+rh4ExpToken->expSize);
				}
				else
				{
					rh4PosPile--;
					expCallOperators[rh4Operators[rh4PosPile]>>17](self);
				}
			}
			else
			{
				rh4PosPile--;
				if (rh4PosPile==pileStart) break;
				expCallOperators[rh4Operators[rh4PosPile]>>17](self);
			}
		}while(YES);
	}while(rh4PosPile>pileStart+1);
	
	return rh4Results[pileStart+1];
}

// Push event for ios object
// -----------------------------------------------------------
-(void)callEventExtension:(CExtension*)hoPtr withCode:(int)code andParam:(int)param
{
	if (rh2PauseCompteur == 0)
	{
        int p0 = rhEvtProg->rhCurParam[0];
        rhEvtProg->rhCurParam[0] = param;                    
        code = (-(code + EVENTS_EXTBASE + 1) << 16);
        code |= (((int) hoPtr->hoType) & 0xFFFF);
        [rhEvtProg handle_Event:hoPtr withCode:code];                    
        rhEvtProg->rhCurParam[0] = p0;
	}
}

-(NSString*)description
{
	if(rhFrame != nil)
		return [rhFrame description];
	return @"";
}

-(int)getDir:(CObject*) pHo
{
    if (pHo->rom != nil)
        return [pHo->rom->rmMovement getDir];
    return pHo->roc->rcDir;
}

// BOX2D INTERFACE
// ------------------------------------------------------------
-(LPRDATABASE)GetBase
{
    if (rh4Box2DSearched == NO)
    {
        rh4Box2DSearched = YES;
        rh4Box2DBase = nil;
        
        int pOL = 0;
        int nObjects;
        for (nObjects = 0; nObjects < rhNObjects; pOL++, nObjects++)
        {
            while (rhObjectList[pOL] == nil) pOL++;
            CObject* pHo = rhObjectList[pOL];
            if (pHo->hoType >= 32)
            {
                if (pHo->hoCommon->ocIdentifier == BASEIDENTIFIER)
                {
                    rh4Box2DBase = (LPRDATABASE)((CRunBox2DParent*)((CExtension*)pHo)->ext)->m_object;
                    break;
                }
            }
        }
    }
    return rh4Box2DBase;
}

-(void)CreateBodies
{
    LPRDATABASE pBase = [self GetBase];
    if (pBase == nil)
        return;
    
    int pOL=0;
    int nObjects;
    for (nObjects=0; nObjects<rhNObjects; pOL++, nObjects++)
    {
        while(rhObjectList[pOL]==nil) pOL++;
        CObject* pHo=rhObjectList[pOL];
        if (pHo->hoType>=32)
        {
            if (pHo->hoCommon->ocIdentifier==FANIDENTIFIER
                || pHo->hoCommon->ocIdentifier==TREADMILLIDENTIFIER
                || pHo->hoCommon->ocIdentifier == PARTICULESIDENTIFIER
                || pHo->hoCommon->ocIdentifier == ROPEANDCHAINIDENTIFIER
                || pHo->hoCommon->ocIdentifier == MAGNETIDENTIFIER
                )
            {
                RUNDATABOX2DPARENT* pBaseParent = (RUNDATABOX2DPARENT*)((CRunBox2DParent*)((CExtension*)pHo)->ext)->m_object;
                pBaseParent->pStartObject(pBaseParent);
            }
            else if (pHo->hoCommon->ocIdentifier==BASEIDENTIFIER)
            {
                RUNDATABASE* pBaseParent = (RUNDATABASE*)((CRunBox2DParent*)((CExtension*)pHo)->ext)->m_object;
                pBaseParent->pStartObject(pBaseParent);
            }
        }
    }
    pOL=0;
    for (nObjects=0; nObjects<rhNObjects; pOL++, nObjects++)
    {
        while(rhObjectList[pOL]==nil) pOL++;
        CObject* pHo=rhObjectList[pOL];
        if (pHo->rom != nil)
        {
            BOOL flag = NO;
            if (pHo->roc->rcMovementType==MVTYPE_EXT)
            {
                CMoveDefExtension* mvPtr = (CMoveDefExtension*)pHo->hoCommon->ocMovements->moveList[pHo->rom->rmMvtNum];
                if ([mvPtr->moduleName caseInsensitiveCompare:@"box2d8directions"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dspring"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dspaceship"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dstatic"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dracecar"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2daxial"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dplatform"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dbouncingball"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dbackground"] == 0
                    )
                {
                    CRunMvtBox2D* pBase=(CRunMvtBox2D*) ((CMoveExtension*)pHo->rom->rmMovement)->movement;
                    CRunMvtPhysics* pPhysics = pBase->m_movement;
                    pPhysics->CreateBody(pHo);
                    flag = YES;
                }
            }
            if (flag == NO && pHo->hoType == 2)
            {
                pBase->pAddNormalObject(pBase, pHo);
            }
        }
    }
    pOL=0;
    for (nObjects=0; nObjects<rhNObjects; pOL++, nObjects++)
    {
        while(rhObjectList[pOL]==nil) pOL++;
        CObject* pHo=rhObjectList[pOL];
        if (pHo->rom != nil)
        {
            if (pHo->roc->rcMovementType==MVTYPE_EXT)
            {
                CMoveDefExtension* mvPtr = (CMoveDefExtension*)pHo->hoCommon->ocMovements->moveList[pHo->rom->rmMvtNum];
                if ([mvPtr->moduleName caseInsensitiveCompare:@"box2d8directions"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dspring"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dspaceship"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dstatic"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dracecar"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2daxial"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dplatform"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dbouncingball"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dbackground"] == 0
                    )
                {
                    CRunMvtBox2D* pBase=(CRunMvtBox2D*) ((CMoveExtension*)pHo->rom->rmMovement)->movement;
                    CRunMvtPhysics* pPhysics = pBase->m_movement;
                    pPhysics->CreateJoint(pHo);
                }
            }
        }
    }
}

-(CRunMBase*)GetMBase:(CObject*)pHo
{
    if (pHo != nil && (pHo->hoFlags & HOF_DESTROYED) == 0)
    {
        if (pHo->rom != nil)
        {
            if (pHo->roc->rcMovementType == MVTYPE_EXT)
            {
                CMoveDefExtension* mvPtr = (CMoveDefExtension*)pHo->hoCommon->ocMovements->moveList[pHo->rom->rmMvtNum];
                if ([mvPtr->moduleName caseInsensitiveCompare:@"box2d8directions"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dspring"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dspaceship"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dstatic"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dracecar"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2daxial"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dplatform"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dbouncingball"] == 0
                    || [mvPtr->moduleName caseInsensitiveCompare:@"box2dbackground"] == 0
                    )
                {
                    CRunMvtBox2D* pBase=(CRunMvtBox2D*) ((CMoveExtension*)pHo->rom->rmMovement)->movement;
                    return pBase->m_movement->m_mBase;
                }
            }
        }
    }
    return nil;
}

-(CRunMvtPhysics*)GetPhysicMovement:(CObject*)pHo
{
    if (pHo->rom == nil)
        return nil;
    
    if (pHo->roc->rcMovementType == MVTYPE_EXT)
    {
        CMoveDefExtension* mvPtr = (CMoveDefExtension*)pHo->hoCommon->ocMovements->moveList[pHo->rom->rmMvtNum];
        if ([mvPtr->moduleName caseInsensitiveCompare:@"box2d8directions"] == 0
            || [mvPtr->moduleName caseInsensitiveCompare:@"box2dspring"] == 0
            || [mvPtr->moduleName caseInsensitiveCompare:@"box2dspaceship"] == 0
            || [mvPtr->moduleName caseInsensitiveCompare:@"box2dstatic"] == 0
            || [mvPtr->moduleName caseInsensitiveCompare:@"box2dracecar"] == 0
            || [mvPtr->moduleName caseInsensitiveCompare:@"box2daxial"] == 0
            || [mvPtr->moduleName caseInsensitiveCompare:@"box2dplatform"] == 0
            || [mvPtr->moduleName caseInsensitiveCompare:@"box2dbouncingball"] == 0
            || [mvPtr->moduleName caseInsensitiveCompare:@"box2dbackground"] == 0
            )
        {
            CRunMvtBox2D* pBase=(CRunMvtBox2D*) ((CMoveExtension*)pHo->rom->rmMovement)->movement;
            return pBase->m_movement;
        }
    }
    return nil;
}


@end
