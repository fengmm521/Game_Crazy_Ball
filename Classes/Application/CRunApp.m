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
// CRUNAPP : objet application
//
//----------------------------------------------------------------------------------
#import "CRunApp.h"
#import "CRunView.h"
#import "CArrayList.h"
#import "CFile.h"
#import "CChunk.h"
#import "CImageBank.h"
#import "CFontBank.h"
#import "CSoundBank.h"
#import "CSoundPlayer.h"
#import "CEmbeddedFile.h"
#import "CValue.h"
#import "COIList.h"
#import "CExtLoader.h"
#import "CCCA.h"
#import "CRunFrame.h"
#import "CServices.h"
#import "CRun.h"
#import "CColMask.h"
#import "CEventProgram.h"
#import "CSpriteGen.h"
#import "CSysEventClick.h"
#import "CJoystick.h"
#import "CJoystickAcc.h"
#import "CJoystickGamePad.h"
#import "CBitmap.h"
#import "CTrans.h"
#import "CTransitionManager.h"
#import "CTransitionData.h"
#import "CRenderToTexture.h"
#import "CIAdViewController.h"
#import "MainViewController.h"
#import "MainView.h"
#import "CALPlayer.h"
#import "RuntimeIPhoneAppDelegate.h"
#import "CRenderer.h"

@implementation CRunApp

static CRunApp* sRunApp;

-(void)clear
{
    frameOffsets=nil;
    framePasswords=nil;
    appName=nil;
    globalValuesInitTypes=nil;
    globalValuesInit=nil;
    globalStringsInit=nil;
    OIList=nil;
    imageBank=nil;
    fontBank=nil;
    soundBank=nil;
    soundPlayer=nil;
    ALPlayer=nil;
    gValues=nil;
    gStrings=nil;
    tempGValue=nil;
    parentApp=nil;
	subApp=nil;
    run=nil;
    frameHandleToIndex=nil;
    adGO=nil;
    sysEvents=nil;
    extLoader=nil;
    extensionStorage=nil;
    embeddedFiles=nil;
    transitionManager=nil;
	oldFrameImage=nil;
	iAdViewController=nil;
	frameMaxIndex=0;
	startFrame=0;
	appRunFlags=0;
	quit=NO;
	debug=0;
	bUnicode=NO;
	displayType=0;
	bStatusBar=NO;
	appDelegate=nil;
	modalSubapp=nil;
	scScaleX = scScaleY = scScale = 1.0f;
	scXDest = scYDest = 0.0f;
	scXSpot = scYSpot = 0.0f;
	orientation = actualOrientation = ORIENTATION_PORTRAIT;
	lastInteraction = CGRectMake(0, 0, 1, 1);
	window=nil;
	viewMode=0;
	
	for (int n=0; n<MAX_VIEWTOUCHES; n++)
		cancelledTouches[n]=nil;

	joystickGamepad = [[CJoystickGamepad alloc] initWithApp:self];
}
-(id)initWithPath:(NSString*)path
{
	if(self = [super init])
	{
		[self clear];
		file=[[CFile alloc] initWithMemoryMappedFile:path];
	}
	return self;
}
-(id)initWithFile:(CFile*)f
{
	if(self = [super init])
	{
		[self clear];
		file=f;
		[file setFilePointer:0];
	}
	return self;
}
-(id)initAsSubApp:(CRunApp*)app
{
	if(self = [super init])
	{
		[self clear];
		file=app->file;
		parentApp = app;
		mainView = app->mainView;
		[file setFilePointer:0];
	}
	return self;
}	
-(void)setView:(CRunView*)pView
{
	runView=pView;
	renderer = runView->renderer;
}
-(void)dealloc
{
	[super dealloc];
}
-(void)setParentView:(CRunView*)view startFrame:(int)sFrame options:(int)options width:(int)sx height:(int)sy
{
	parentOptions = options;
	startFrame = sFrame;
	[self setView:view];
	gaCxWin = MIN(sx, parentApp->gaCxWin);
	gaCyWin = MIN(sy, parentApp->gaCyWin);
	parentWidth = parentApp->gaCxWin;
	parentHeight = parentApp->gaCyWin;
}
-(void)setIAdViewController:(CIAdViewController*)pCont
{
	iAdViewController=pCont;
}
-(void)setMainViewController:(MainViewController*)pCont
{
	mainViewController=pCont;
	mainView = (MainView*)mainViewController.view;
}
-(BOOL)load
{	
	// Charge le mini-header
	char* name = (char*)malloc(4);
	[file readACharBuffer:name withLength:4];		    // gaType
	BOOL bOK=NO;
	if (name[0]=='P' && name[1]=='A' && name[2]=='M' && name[3]=='E')
	{
		bOK=true;
		bUnicode=false;
	}
	if (name[0]=='P' && name[1]=='A' && name[2]=='M' && name[3]=='U')
	{
		bOK=true;
		bUnicode=true;
	}
	free(name);
	if (!bOK)
	{
		NSLog(@"Invalid CCI file format");
		return NO;
	}
	
	[file setUnicode:bUnicode];
	
	short s = [file readAShort];	    // gaVersion
	if (s != RUNTIME_VERSION)
	{
		return NO;
	}
	
	[file readAShort];		    // gaSubversion
	[file readAInt];		    // gaPrdVersion
	[file skipBytes:4];		    // gaPrdBuild
		
	// Reserve les objets
	OIList = [[COIList alloc] init];
	imageBank = [[CImageBank alloc] initWithApp:self];
	fontBank = [[CFontBank alloc] initWithApp:self];
	soundBank = [[CSoundBank alloc] initWithApp:self];
	
	if(parentApp == nil){
		soundPlayer = [[CSoundPlayer alloc] initWithApp:self];
		ALPlayer = [[CALPlayer alloc] init];
	}
	else{
		soundPlayer = [[CSoundPlayer alloc] initWithApp:self andSoundPlayer:parentApp->soundPlayer];
		ALPlayer = [[CALPlayer alloc] initWithPlayer:parentApp->ALPlayer];
	}
	
	// Lis les chunks
	CChunk* chk = [[CChunk alloc] init];
	NSUInteger posEnd;
	int nbPass = 0, n;
    NSString* tempString;
	while (chk->chID != CHUNK_LAST)
	{
		[chk readHeader:file];
		if (chk->chSize == 0)
		{
			continue;
		}
		posEnd = [file getFilePointer] + chk->chSize;
		
		switch (chk->chID)
		{
			case CHUNK_APPHEADER:
				[self loadAppHeader];
				// Buffer pour les offsets frame
				frameOffsets = (NSUInteger*)malloc(gaNbFrames*sizeof(NSUInteger));
				// Pour les password
				framePasswords = (NSString**)malloc(gaNbFrames*sizeof(NSString*));
				for (n = 0; n < gaNbFrames; n++)
				{
					framePasswords[n] = nil;
				}
				break;			
			case CHUNK_APPHEADER2:
				[self loadAppHeader2];
				break;
			case CHUNK_APPNAME:
				appName = [file readAString];
				break;
			case CHUNK_GLOBALVALUES:
				[self loadGlobalValues];
				break;
			case CHUNK_GLOBALSTRINGS:
				[self loadGlobalStrings];
				break;
			case CHUNK_FRAMEITEMS:
			case CHUNK_FRAMEITEMS_2:
				[OIList preLoad:file];
				break;
			case CHUNK_FRAMEHANDLES:
				[self loadFrameHandles:chk->chSize];
				break;
            case CHUNK_APPEDITORFILENAME:
                tempString=[file readAString];
                appEditorPathname=[tempString stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
                appEditorPathname=[appEditorPathname uppercaseString];
                appEditorPathname=[self getParent:appEditorPathname];
                appEditorPathname=[[NSString alloc] initWithString:appEditorPathname];
                [tempString release];
                break;
            case CHUNK_APPTARGETFILENAME:
                tempString=[file readAString];
                appTargetPathname=[tempString stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
                appTargetPathname=[appTargetPathname uppercaseString];
                appTargetPathname=[self getParent:appTargetPathname];
                appTargetPathname=[[NSString alloc] initWithString:appTargetPathname];
                [tempString release];
                break;
			case CHUNK_FRAME:
			{
				// Repere les positions des frames dans le fichier
				frameOffsets[frameMaxIndex] = [file getFilePointer];
				CChunk* frChk = [[CChunk alloc] init];
				while (frChk->chID != 0x7F7F)		// CHUNK_LAST
				{
					[frChk readHeader:file];
					if (frChk->chSize == 0)
					{
						continue;
					}
					NSUInteger frPosEnd = [file getFilePointer] + frChk->chSize;
					
					switch (frChk->chID)
					{
						case CHUNK_FRAMEHEADER:
							break;
						case CHUNK_FRAMEPASSWORD:
							framePasswords[frameMaxIndex] = [file readAString];
							nbPass++;
							break;
					}
					[file seek:frPosEnd];
				}
				frameMaxIndex++;
				[frChk release];	
				break;
			}
		
			case CHUNK_EXTENSIONS2:
				extLoader = [[CExtLoader alloc] initWithApp:self];
				[extLoader loadList];
				break;
			case CHUNK_BINARYFILES:
			{
				int nFiles = [file readAInt];
				embeddedFiles = [[CArrayList alloc] init];
				for (n = 0; n < nFiles; n++)
				{
					CEmbeddedFile* pEmb=[[CEmbeddedFile alloc] initWithApp:self];
					[embeddedFiles add:pEmb];
					[pEmb preLoad];
				}
				break;
			}
			case CHUNK_IMAGES:
				[imageBank preLoad];
				break;
			case CHUNK_FONTS:
				[fontBank preLoad];
				break;
			case CHUNK_SOUNDS:
				[soundBank preLoad];
				break;
		
		}
		
		// Positionne a la fin du chunk
		[file seek:posEnd];
	}
	[chk release];
	
	// Fixe le flags multiple samples
	[soundPlayer setMultipleSounds:((gaFlags & GA_MIX)!=0)];
	
	
	
	//Adjust screen size according to the properties
	CGSize screenSize = [self screenSize];
	CGSize windowSize = [self windowSize];
	CGSize app = CGSizeMake(gaCxWin, gaCyWin);
	
	float appAspect = app.width/app.height;
	float screenAspect = screenSize.width/screenSize.height;
	
	switch(viewMode)
	{
		case VIEWMODE_ADJUSTWINDOW:
		{
			gaCxWin = screenSize.width;
			gaCyWin = screenSize.height;
			break;
		}
		case VIEWMODE_FITINSIDE_ADJUSTWINDOW:
		{
			if(appAspect < screenAspect)
				gaCxWin = app.height * screenAspect;
			else
				gaCyWin = app.width / screenAspect;
			break;
		}
		case VIEWMODE_FITOUTSIDE:
		{
			if(appAspect < screenAspect)
				gaCyWin = app.width / screenAspect;
			else
				gaCxWin = app.height * screenAspect;
			break;
		}
	}
	
	screenRect = CGRectMake(0, 0, windowSize.width, windowSize.height);
	return YES;
}

// Lancement de l'application
-(BOOL)startApplication
{
	// Init RUN LOOP
	run = [[CRun alloc] initWithApp:self];
	events = [[CEventProgram alloc] initWithApp:self];
	
	// Initialisation des events
	sysEvents = [[CArrayList alloc] init];
	
	appRunningState = 0;	    // SL_RESTART
	currentFrame = -2;
	displayType = -1;
	return YES;
}
	 
-(void)createDisplay
{
	sxView=(int)runView.bounds.size.width;
	syView=(int)runView.bounds.size.height;
	xOffset=0;
	yOffset=0;
}		

// Fait fonctionner l'application
-(BOOL)playApplication:(BOOL)bOnlyRestartApp
{
	int error = 0;
	BOOL bLoop = YES;
	BOOL bContinue = YES;
	
	//Update position of application (if subapp)
	parentX = parentY = 0;
	CRunApp* cApp = self;
	while(cApp->parentApp != nil)
	{
		parentX += cApp->subApp->hoRect.left;
		parentY += cApp->subApp->hoRect.top;
		cApp = cApp->parentApp;
	}
	
	VBLCount++;
	do
	{
		switch (appRunningState)
		{
                // SL_RESTART
			case 0:
				[self initGlobal];
				nextFrame = startFrame;
				appRunningState = 1;
				[self killGlobalData];
				// reInitMenu();
				// Build 248 : only restart application?
				if (bOnlyRestartApp)
				{
					// Used in Sub-Applications, initializes application global data and exit
					// (= don't execute the first frame loop now, it will be executed at the end
					// of the first loop of the parent frame as usual)
					bLoop = false;
					break;
				}
                // SL_STARTFRAME
			case 1:
				error = [self startTheFrame];
				break;
                // SL_FRAMEFADEINLOOP
			case 2:
				if ([self loopFrameFadeIn] == NO)
				{
					[self endFrameFadeIn];
					if (appRunningState == SL_QUIT || appRunningState == SL_RESTART)
					{
						[self endFrame];
					}
				}
				else
				{
					bLoop = false;
				}
				break;
                // SL_FRAMELOOP
			case 3:
				if ([self loopFrame] == NO)
				{
					if ([self startFrameFadeOut:oldFrameImage])
					{
						appRunningState=SL_FRAMEFADEOUTLOOP;
					}
					else
					{
						[self endFrame];
					}
				}
				else
				{
					bLoop = NO;
				}
				break;
                // SL_FRAMEFADEOUTLOOP
			case 4:
				if ([self loopFrameFadeOut]==NO)
				{
					[self endFrameFadeOut];
					if (appRunningState == SL_QUIT || appRunningState == SL_RESTART)
					{
						[self endFrame];
					}
				}
				else
				{
					bLoop = NO;
				}
				break;
                // SL_ENDFRAME
			case 5:
				[self endFrame];
				break;
			default:
				bLoop = NO;
				break;
		}
	} while (bLoop == YES && error == 0 && quit == NO);
	
	// Error?
	if (error != 0)
	{
		appRunningState = SL_QUIT;
	}
	
	// Quit ?
	if (appRunningState == SL_QUIT)
	{
		bContinue = NO;
	}
	
	// RAZ souris
	mouseClick=0;
	
	// Continue?
	return bContinue;
}

// End application
-(void)endApplication
{
	if (parentApp==nil)
	{
		[runView endApplication];
		[file release];
	}
	else
	{
		[subApp endApp];
	}
	
	// Stop sounds
	if (soundPlayer != nil)
	{
		[soundPlayer stopAllSounds];
	}
	
	[imageBank release];
	[fontBank release];
	[soundBank release];
	[soundPlayer release];
    [ALPlayer release];
    
	[OIList release];
	
    if (appEditorPathname!=nil)
        [appEditorPathname release];
    if (appTargetPathname!=nil)
        [appTargetPathname release];
    
	if (embeddedFiles!=nil)
	{
		[embeddedFiles clearRelease];
		[embeddedFiles release];
	}
	
	[sysEvents clearRelease];
	[sysEvents release];
	[self killGlobalData];
	
	free(frameOffsets);
	if (frameHandleToIndex!=nil)
	{
		free(frameHandleToIndex);
	}
	
	int n;
	for (n=0; n<gaNbFrames; n++)
	{
		if (framePasswords[n]!=nil)
		{
			[framePasswords[n] release];
		}
	}
	
	if (globalValuesInit!=nil)
	{
		free(globalValuesInit);
	}
	if (globalStringsInit!=nil)
	{
		for (n=0; n<nGlobalStringsInit; n++)
		{
			[globalStringsInit[n] release];
		}
		free(globalStringsInit);
	}
	if (gValues!=nil)
	{
		[gValues clearRelease];
		[gValues release];
	}
	if (gStrings!=nil)
	{
		[gStrings clearRelease];
		[gStrings release];
	}
	if (run!=nil)
	{
		[run release];
	}
	if (frame!=nil)
	{
		[frame release];
	}
	if (events!=nil)
	{
		[events release];
	}
	if (extensionStorage!=nil)
	{
		[extensionStorage clearRelease];
		[extensionStorage release];
	}
	if (transitionManager!=nil)
	{
		[transitionManager release];
	}
	if (joystickAcc!=nil)
	{
		[joystickAcc release];
	}
	if (joystick!=nil)
	{
		[joystick release];
	}
	if(oldFrameImage!=nil)
	{
		[oldFrameImage release];
	}
}

// Change dimensions of application
-(void)changeWindowDimensions:(int)width withHeight:(int)height
{
    if (width>=0)
        gaCxWin=width;
    if (height>0)
        gaCyWin=height;
    if (frame!=nil)
    {
        if (width>0)
        {
            frame->leEditWinWidth=width;
            frame->leVirtualRect.right=width;
            frame->leWidth=width;
        }
        if (height>0)
        {
            frame->leEditWinHeight=height;
            frame->leVirtualRect.bottom=height;
            frame->leHeight=height;
        }
    }
    if (run!=nil)
    {
        [run updateFrameDimensions:width withHeight:height];
    }
}

// Memory warning
-(void)cleanMemory
{
	if (run!=nil)
	{
		[run cleanMemory];
	}
	if (imageBank!=nil)
	{
		[imageBank cleanMemory];
	}
	if (soundBank!=nil)
	{
		[soundBank cleanMemory];
	}
	if (renderer != nil)
	{
		renderer->cleanMemory();
	}
}

// Charge la frame
-(int)startTheFrame
{	
	int error = 0;
	//CBitmap* pOldSurf = nil;
	
	do
	{
        iOSObject=nil;

		// Charge la frame
		if (nextFrame != currentFrame)
		{
			if (frame!=nil)
			{
				[frame release];
			}
			frame = [[CRunFrame alloc] initWithApp:self];
			if ([frame loadFullFrame:nextFrame]==NO)
			{
				error = -1;
				break;
			}
			currentFrame = nextFrame;
		}
		
		// Init runtime variables
		frame->leX = frame->leY = 0;
		frame->leLastScrlX = frame->leLastScrlY = 0;
		frame->rhOK = NO;
		frame->levelQuit = 0;
		
		// Creates logical screen
		int cxLog = MIN(gaCxWin, frame->leWidth);
		int cyLog = MIN(gaCyWin, frame->leHeight);
		frame->leEditWinWidth = cxLog;
		frame->leEditWinHeight = cyLog;
		
	
		// Calculate maximum number of sprites (add max. number of bkd sprites)
//		int nMaxSprite = frame->maxObjects * 2;		    // * 2 for background objects created as sprites
//		for (short i = 0; i < frame->LOList->nIndex; i++)
//		{
//			CLO* lo = [frame->LOList getLOFromIndex:i];
//			if (lo->loLayer > 0)
//			{
//				COI* oi = [OIList getOIFromHandle:lo->loOiHandle];
//				if (oi->oiType < COI.OBJ_SPR)
//				{
//					nMaxSprite++;
//				}
//			}
//		}
		
		// Create collision mask
		int flags = [events getCollisionFlags];
		flags |= [frame getMaskBits];
		frame->leFlags |= LEF_TOTALCOLMASK;
		if (frame->colMask!=nil)
		{
			[frame->colMask release];			
			frame->colMask = nil;
		}
		if ((frame->leFlags & LEF_TOTALCOLMASK) != 0)
		{
			if ((flags & (CM_OBSTACLE | CM_PLATFORM)) != 0)
			{
				frame->colMask = [CColMask create:-COLMASK_XMARGIN withY1:-COLMASK_YMARGIN andX2:frame->leWidth + COLMASK_XMARGIN andY2:frame->leHeight + COLMASK_YMARGIN andFlags:flags];
			}
		}
		
		if (displayType < 0)
		{
			// Taille de la fenetre
			if (parentApp != nil)
			{
				if ((parentOptions & CCAF_CUSTOMSIZE) != 0)
				{
					gaCxWin = parentWidth;
					gaCyWin = parentHeight;
				}
				else
				{
					if (parentHeight > 0)
					{
						gaCxWin = parentWidth;
					}
					if (parentWidth > 0)
					{
						gaCyWin = parentHeight;
					}
				}
				if ((parentOptions & CCAF_STRETCH) != 0)
				{
					gaFlags |= GA_STRETCH;
				}
				displayType=1;
			}
			
			// Creation de la fenetre
			[self createDisplay];
		}
		
		[run->spriteGen setFrame:frame];
		renderer->forgetCachedState();
		renderer->setProjectionMatrix(renderer->topLeft.x, renderer->topLeft.y, renderer->currentRenderState.contentSize.x, renderer->currentRenderState.contentSize.y);
	}
	while (false);
			
	// Init runloop
	firstMask=nil;
	secondMask=nil;
		
	[run initRunLoop:(frame->fadeIn!=nil)];
	
	// Sets idle timer
	[[UIApplication sharedApplication] setIdleTimerDisabled:(frame->iPhoneOptions&IPHONEOPT_SCREENLOCKING)!=0];
    
	// Set app running state
	if (frame->fadeIn != nil)
	{
		// Do 1st loop
		if ([self loopFrame]==NO)
		{
			appRunningState = SL_ENDFRAME;
		}
		else
		{
			if(oldFrameImage == nil)
			{
				oldFrameImage = [[CRenderToTexture alloc] initWithWidth:runView->renderer->backingWidth andHeight:runView->renderer->backingHeight andRunApp:self];
			}
			
			if ([self startFrameFadeIn:oldFrameImage]==NO)
			{
				appRunningState = SL_FRAMELOOP;
			}
		}
	}
	else
	{
		appRunningState = SL_FRAMELOOP;
		
		if (oldFrameImage!=nil)
		{
			[oldFrameImage release];
			oldFrameImage = nil;
		}
	}	
	
	if (error != 0)
	{
		appRunningState = SL_QUIT;
	}
	return error;
}

// Un tour de boucle
-(BOOL)loopFrame
{
	if (frame->levelQuit == 0)
	{
		// One frame loop
		frame->levelQuit = [run doRunLoop];
	}
	return (frame->levelQuit == 0);
}

// Sortie d'une boucle
-(void)endFrame
{
	int ul;
	
	// Fin de la boucle => renvoyer code de sortie
	ul = [run killRunLoop:frame->levelQuit keepSounds:NO];
	
	[runView clearPostponedInput];
	
	// Run Frame?
	if ((gaNewFlags & GANF_RUNFRAME) != 0)
	{
		appRunningState = SL_QUIT;
	}
	// Calculer event en fonction du code de sortie
	else
	{
		switch (LOWORD(ul))
		{
                // Next frame
			case 1:				// LOOPEXIT_NEXTLEVEL
				nextFrame = currentFrame + 1;
				appRunningState = SL_STARTFRAME;
				break;
						
                // Previous frame
			case 2:				// LOOPEXIT_PREVLEVEL:
				nextFrame = MAX(0, currentFrame-1);
				appRunningState = SL_STARTFRAME;
				break;
				
                // Jump to frame
			case 3:				// LOOPEXIT_GOTOLEVEL:
				appRunningState = SL_STARTFRAME;
				if ((HIWORD(ul) & 0x8000) != 0)			// Si flag 0x8000, numero de cellule direct
				{
					nextFrame = HIWORD(ul) & 0x7FFF;
					if (nextFrame >= gaNbFrames)
					{
						nextFrame = gaNbFrames - 1;
					}
					if (nextFrame < 0)
					{
						nextFrame = 0;
					}
				}
				else											// Sinon, HCELL
				{
					if (HIWORD(ul)<frameMaxHandle)
					{
						nextFrame = frameHandleToIndex[HIWORD(ul)];
						if (nextFrame == -1)
						{
							nextFrame = currentFrame + 1;
						}
					}
					else
					{
						nextFrame = currentFrame + 1;
					}
				}
				break;
				
                // Restart application
			case 4:				// LOOPEXIT_NEWGAME:
				// Restart application
				appRunningState = SL_RESTART;
				nextFrame = startFrame;
				break;
				
                // Quit
			default:
				appRunningState = SL_QUIT;
				break;
		}
	}
	
	if (appRunningState == SL_STARTFRAME)
	{
		// If invalid frame number, quit current game
		if (nextFrame < 0 || nextFrame >= gaNbFrames)
		{
			appRunningState = SL_QUIT;
		}
	}
	
	// Unload current frame if frame change
	if (appRunningState != SL_STARTFRAME || nextFrame != currentFrame)
	{		
		// Reset current frame
		currentFrame = -1;
	}
}

// RAZ des donnes objets globaux
-(void)killGlobalData
{
	if (adGO!=nil)
	{
		[adGO release];
		adGO = nil;
	}
}

// Transitions
-(CTransitionManager*)getTransitionManager
{
	if (transitionManager==nil)
	{
		transitionManager=[[CTransitionManager alloc] initWithApp:self];
	}
	return transitionManager;
}

// Gestion du fade in
-(BOOL)startFrameFadeIn:(CRenderToTexture*)oldImage
{
	CTransitionData* pData=frame->fadeIn;

	if (pData!=nil)
	{
		CRenderToTexture* newImage = [[CRenderToTexture alloc] initWithWidth:runView->renderer->backingWidth andHeight:runView->renderer->backingHeight andRunApp:self];
		
		//Render into the new frame buffer
		[newImage bindFrameBuffer];
		renderer->updateViewport();
		[run transitionDrawFrame];
		[newImage unbindFrameBuffer];
		[newImage clearAlphaChannel:1.0f];
		
		// Fill source surface
		if ((pData->transFlags&TRFLAG_COLOR)!=0)
			[oldImage fillWithColor:pData->transColor];		

		renderer->flush();
		
		// Starts the transition
		frame->pTrans=[[self getTransitionManager] createTransition:pData withRenderer:renderer andStart:oldImage andEnd:newImage andType:0];
		if (frame->pTrans!=nil)
		{
			appRunningState=SL_FRAMEFADEINLOOP;
			return YES;
		}
	}

	[run createRemainingFrameObjects];
	[self endFrameFadeIn];
	return NO;		
}
-(BOOL)loopFrameFadeIn
{
	if (frame->pTrans!=nil)
	{
		if ([frame->pTrans isCompleted])
		{
			[self endFrameFadeIn];
			return NO;
		}
		renderer->setOrigin(0, 0);
		renderer->setCurrentLayer(nil);
		[frame->pTrans stepDraw:TRFLAG_FADEIN];
		return YES;
	}
	return NO;
}
-(BOOL)endFrameFadeIn
{
	if (frame->pTrans!=nil)
	{
		[frame->pTrans end];
		[frame->pTrans release];
		frame->pTrans=nil;
		if (appRunningState==SL_FRAMEFADEINLOOP)
		{
			appRunningState=SL_FRAMELOOP;
		}
		[run createRemainingFrameObjects];
	}
	return YES;
}

// Gestion du fade out
-(BOOL)startFrameFadeOut:(CRenderToTexture*)oldImage
{
	CTransitionData* pData=frame->fadeOut;
	 	
	if (pData!=nil)
	{
		CRenderToTexture* targetImage = [[CRenderToTexture alloc] initWithWidth:runView->renderer->backingWidth andHeight:runView->renderer->backingHeight andRunApp:self];
				
		if ((pData->transFlags&TRFLAG_COLOR)!=0)
			[targetImage fillWithColor:pData->transColor];
		else
			[targetImage fillWithColor:0];
		
		[oldImage clearAlphaChannel:1.0f];
		
		// Starts transition
		frame->pTrans=[[self getTransitionManager] createTransition:pData withRenderer:renderer andStart:oldImage andEnd:targetImage andType:0];
		if (frame->pTrans!=nil)
		{
			appRunningState=SL_FRAMEFADEOUTLOOP;
			return YES;
		}
	}
	[self endFrameFadeOut];

	return NO;
}
-(BOOL)loopFrameFadeOut
{
	if (frame->pTrans!=nil)
	{
		if ([frame->pTrans isCompleted])
		{
			[self endFrameFadeOut];
			return NO;
		}
		renderer->setOrigin(0,0);
		renderer->setCurrentLayer(nil);
		[frame->pTrans stepDraw:TRFLAG_FADEOUT];
		return YES;
	}
	return NO;
}
-(BOOL)endFrameFadeOut
{
	if (frame->pTrans!=nil)
	{
		[frame->pTrans end];
		[frame->pTrans release];
		frame->pTrans=nil;
		if (appRunningState==SL_FRAMEFADEOUTLOOP)
		{
			appRunningState=SL_ENDFRAME;
		}
	}
	return YES;
}

// Initialise les variables globales
-(void)initGlobal
{
	int n;
	
	// Vies et score
	if (parentApp == nil || (parentApp != nil && (parentOptions & CCAF_SHARE_LIVES) == 0))
	{
		for (n = 0; n < MAX_PLAYER; n++)
		{
			lives[n] = gaLivesInit ^ 0xFFFFFFFF;
		}
		bLivesExternal=NO;
	}
	else
	{
		bLivesExternal=YES;
	}
	
	if (parentApp == nil || (parentApp != nil && (parentOptions & CCAF_SHARE_SCORES) == 0))
	{
		for (n = 0; n < MAX_PLAYER; n++)
		{
			scores[n] = gaScoreInit ^ 0xFFFFFFFF;
		}
		bScoresExternal=NO;
	}
	else
	{
		bScoresExternal=YES;
	}

	for (n = 0; n < MAX_PLAYER; n++)
	{
		playerNames[n] = [[NSString alloc] init];
	}

	// Global values
	if (parentApp == nil || (parentApp != nil && (parentOptions & CCAF_SHARE_GLOBALVALUES) == 0) )
	{
		gValues = [[CArrayList alloc] init];
		for (n = 0; n < nGlobalValuesInit; n++)
		{
			[gValues add:[[CValue alloc] initWithInt:globalValuesInit[n]]];
		}
	}
	else
	{
		gValues = nil;
	}
	tempGValue = [[CValue alloc] init];

	// Global strings
	if (parentApp == nil || (parentApp != nil && (parentOptions & CCAF_SHARE_GLOBALVALUES) == 0) )
	{
		gStrings = [[CArrayList alloc] init];
		for (n = 0; n < nGlobalStringsInit; n++)
		{
			[gStrings add:[[NSString alloc] initWithString:globalStringsInit[n]]];
		}
	}
	else
	{
		gStrings = nil;
	}
}
			
// Retourne les vies et les scores
-(int*)getLives
{
	CRunApp* app = self;
	while (app->bLivesExternal==YES)
	{
		app = app->parentApp;
	}
	return app->lives;
}

-(int*)getScores
{
	CRunApp* app = self;
	while (app->bScoresExternal==YES)
	{
		app = app->parentApp;
	}
	return app->scores;
}

// Recherche les global values dans les parents
-(CArrayList*)getGlobalValues
{
	CRunApp* app = self;
	while (app->gValues==nil)
	{
		app = app->parentApp;
	}
	return app->gValues;
}

-(int)getNGlobalValues
{
	if (gValues != nil)
	{
		return (int)[gValues size];
	}
	return 0;
}

-(CArrayList*)getGlobalStrings
{
	CRunApp* app = self;
	while (app->gStrings == nil)
	{
		app = app->parentApp;
	}
	return app->gStrings;
}

-(int)getNGlobalStrings
{
	if (gStrings != nil)
	{
		return (int)[gStrings size];
	}
	return 0;
}

-(CArrayList*)checkGlobalValue:(int)num
{
	CArrayList*values = [self getGlobalValues];
	
	if (num < 0 || num > 1000)
	{
		return nil;
	}
	NSUInteger oldSize = [values size];
	if (num >= oldSize)
	{
		[values ensureCapacity:num];
		for (NSUInteger n = oldSize; n <= num; n++)
		{
			[values add:[[CValue alloc] init]];
		}
	}
	return values;
}

-(CValue*)getGlobalValueAt:(int)num
{
	CArrayList* values = [self checkGlobalValue:num];
	if (values != nil)
	{
		return (CValue*)[values get:num];
	}
	return tempGValue;
}

-(void)setGlobalValueAt:(int)num value:(CValue*)value
{
	CArrayList* values = [self checkGlobalValue:num];
	if (values != nil)
	{
		[ ((CValue*)[values get:num]) forceValue:value];
	}
}

-(CArrayList*)checkGlobalString:(int)num
{
	CArrayList* strings = [self getGlobalStrings];
	
	if (num < 0 || num > 1000)
	{
		return nil;
	}
	NSUInteger oldSize = [strings size];
	if (num >= oldSize)
	{
		[strings ensureCapacity:num];
		for (NSUInteger n = oldSize; n <= num; n++)
		{
			[strings add:[[NSString alloc] init]];
		}
	}
	return strings;
}

-(NSString*)getGlobalStringAt:(int)num
{
	CArrayList* strings = [self checkGlobalString:num];
	if (strings != nil)
	{
		return (NSString*)[strings get:num];
	}
	return @"";
}

-(void) setGlobalStringAt:(int)num string:(NSString*)value
{
	CArrayList* strings = [self checkGlobalString:num];
	if (strings != nil)
	{
		NSString* s=(NSString*)[strings get:num];
		if (s!=nil)
		{
			[s release];
		}
		s=[[NSString alloc] initWithString:value];
		[strings set:num object:s];
	}
}

// Charge le header de l'application
-(void)loadAppHeader
{
	[file skipBytes:4];			// Structure size
	gaFlags = [file readAShort];   		// Flags
	gaNewFlags = [file readAShort];		// New flags
	gaMode = [file readAShort];		// graphic mode
	gaOtherFlags = [file readAShort];		// Other Flags
	gaCxWin = [file readAShort];		// Window x-size
	gaCyWin = [file readAShort];		// Window y-size
	gaScoreInit = [file readAInt];		// Initial score
	gaLivesInit = [file readAInt];		// Initial number of lives
	[file skipBytes:MAX_PLAYER*sizeof(short)]; // Control type
	[file skipBytes:MAX_PLAYER*MAX_KEY*sizeof(short)];
	gaBorderColour = [file readAColor];	// Border colour
	gaNbFrames = [file readAInt];		// Number of frames
	gaFrameRate = [file readAInt];		// Number of frames per second
	[file skipBytes:4];
}

// Charge le header de l'application
-(void)loadAppHeader2
{
	hdr2Options=[file readAInt];
	[file skipBytes:10];
	orientation = actualOrientation = [file readAShort];
	viewMode = [file readAShort];
	
	UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
	UIInterfaceOrientation uiOrientation = [UIApplication sharedApplication].statusBarOrientation;
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	{
		switch (uiOrientation) {
			default:
			case UIInterfaceOrientationPortrait:
				deviceOrientation = UIDeviceOrientationPortrait;
				break;
			case UIInterfaceOrientationLandscapeLeft:
				deviceOrientation = UIDeviceOrientationLandscapeLeft;
				break;
			case UIInterfaceOrientationLandscapeRight:
				deviceOrientation = UIDeviceOrientationLandscapeRight;
				break;
			case UIInterfaceOrientationPortraitUpsideDown:
				deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
				break;
		}
	}

	if (actualOrientation==ORIENTATION_AUTOLANDSCAPE)
	{
		BOOL isLandscapeRight = (deviceOrientation == UIDeviceOrientationLandscapeRight);
		actualOrientation = isLandscapeRight ? ORIENTATION_LANDSCAPELEFT : ORIENTATION_LANDSCAPERIGHT;
		uiOrientation = isLandscapeRight ? UIInterfaceOrientationLandscapeLeft : UIInterfaceOrientationLandscapeRight;
	}
	if(actualOrientation==ORIENTATION_AUTOPORTRAIT)
	{
		BOOL isUpsideDown = (deviceOrientation != UIDeviceOrientationPortraitUpsideDown);
		actualOrientation = isUpsideDown ? ORIENTATION_PORTRAIT : ORIENTATION_PORTRAITUPSIDEDOWN;
		uiOrientation = isUpsideDown ? UIInterfaceOrientationPortrait : UIInterfaceOrientationPortraitUpsideDown;
	}
	if(hdr2Options&AH2OPT_STATUSLINE)
		bStatusBar = YES;
	
	[[UIApplication sharedApplication] setStatusBarOrientation:uiOrientation animated:NO];
	[runView layoutSubviews];
}
	
// Charge le chunk GlobalValues
-(void)loadGlobalValues
{
	nGlobalValuesInit = [file readAShort];
	globalValuesInit = (int*)malloc(nGlobalValuesInit*sizeof(int));
	globalValuesInitTypes = (char*)malloc(nGlobalValuesInit*sizeof(char));
	int n;
	for (n = 0; n < nGlobalValuesInit; n++)
	{
		globalValuesInit[n] = [file readAInt];
	}
	[file readACharBuffer:globalValuesInitTypes withLength:nGlobalValuesInit];
}

// Charge le chunk GlobalStrings
-(void)loadGlobalStrings
{
	nGlobalStringsInit = [file readAInt];
	globalStringsInit = (NSString**)malloc(nGlobalStringsInit*sizeof(NSString*));
	int n;
	for (n = 0; n < nGlobalStringsInit; n++)
	{
		globalStringsInit[n] = [file readAString];
	}
}

// Charge le chunk Frame handles
-(void) loadFrameHandles:(int)size
{
	frameMaxHandle = (short) (size / 2);
	frameHandleToIndex = (short*)malloc(frameMaxHandle*sizeof(short));
	
	int n;
	for (n = 0; n < frameMaxHandle; n++)
	{
		frameHandleToIndex[n] = [file readAShort];
	}
}

// Transformation d'un HCELL en numero de cellule
-(short)HCellToNCell:(short)hCell
{
	if (frameHandleToIndex == nil || hCell == -1 || hCell >= frameMaxHandle)
	{
		return -1;
	}
	return frameHandleToIndex[hCell];
}
-(int)newGetCptVBL
{
	return VBLCount;
}

-(void)setFrameRate:(int)rate
{
	if (parentApp==nil)
	{
		gaFrameRate=rate;
		[runView resetFrameRate];
	}
}

// GESTION SOURIS ///////////////////////////////////////////////////////////////
-(void)mouseMoved:(int)x withY:(int)y
{
	mouseX=x;
	mouseY=y;
	if (run!=nil)
		[run getMouseCoords];
}
-(void)mouseClicked:(int)numTap
{
	mouseClick=numTap;
	if (run!=nil)
	{
		CSysEventClick* click=[[CSysEventClick alloc] initWithClick:numTap];
		[sysEvents add:click];
	}
}
-(void)mouseDown:(BOOL)bFlag
{
	bMouseDown=bFlag;
}

// GESTION JOYSTICK ////////////////////////////////////////////////////////////
-(void)createJoystick:(BOOL)bCreate withFlags:(int)flags
{
	if (bCreate)
	{		
		if (joystick==nil)
		{
			joystick=[[CJoystick alloc] initWithApp:self];
		}
		[joystick reset:flags];
	}
	else
	{
		if (joystick!=nil)
		{
			[joystick release];
			joystick=nil;
		}
	}
}
-(void)createJoystickAcc:(BOOL)bCreate
{
	if (bCreate)
	{		
		if (joystickAcc==nil)
		{
			joystickAcc=[[CJoystickAcc alloc] initWithApp:self];
		}
	}
	else
	{
		if (joystickAcc!=nil)
		{
			[joystickAcc release];
			joystickAcc=nil;
		}
	}
}
+(CRunApp*)getRunApp
{
	return sRunApp;
}

+(void)setRunApp:(CRunApp*)app
{
	sRunApp = app;
}

-(BOOL)frameIsOutsideVisibleArea:(CGRect)rect
{
	if(CGRectIsEmpty(rect))
		return false;
	return !CGRectIntersectsRect(rect, runView.bounds);
}
-(void)positionUIElement:(UIView*)view withObject:(CObject*)ho
{
	if(view.hidden)
		return;

	int plusX = 0, plusY = 0;
	float scaleX = ho->controlScaleX;
	float scaleY = ho->controlScaleY;
	float width = ho->hoImgWidth*scaleX;
	float height = ho->hoImgHeight*scaleY;
	
	for(CRunApp* app = self; app != nil; app = app->parentApp)
	{
		if(app->subApp != nil){
			plusX += app->subApp->hoX;
			plusY += app->subApp->hoY;
		}
		plusX -= app->run->rhWindowX;
		plusY -= app->run->rhWindowY;
	}

	CGRect newFrame = CGRectMake(ho->hoX+plusX, ho->hoY+plusY, width, height);
	CGAffineTransform newScale = CGAffineTransformMakeScale(1/scaleX, 1/scaleY);

	//Optimization: Avoid moving the control if it is outside of the visible frame (both before and after transform)
	if( [self frameIsOutsideVisibleArea:view.frame] && [self frameIsOutsideVisibleArea:newFrame])
		return;

	//Ensure UI controls are sized in iOS points, not MMF2 pixels.
	view.layer.anchorPoint = CGPointMake(0, 0);
	view.autoresizesSubviews = NO;
	view.transform = CGAffineTransformIdentity;
	view.frame = newFrame;
	view.transform = newScale;
}

-(CGPoint)adjustPoint:(CGPoint)point
{
	int plusX = 0, plusY = 0;
	for(CRunApp* app = self; app != nil; app = app->parentApp)
	{
		plusX -= app->run->rhWindowX;
		plusY -= app->run->rhWindowY;
	}
	return CGPointMake(point.x - plusX, point.y - plusY);
}

-(void)touchesBegan:(NSSet *)touchesA withEvent:(UIEvent *)event
{
	if(modalSubapp == nil)
		[run resume];

	UITouch* touch = [touchesA anyObject];
	CGPoint touchPosition = [touch locationInView:runView];
	
	//Check if touch is over any subapp
	BOOL isOverSubapp = NO;
	if(run != nil && run->nSubApps > 0)
	{
		for(int i=0; i<MAX_SUBAPPS; ++i)
		{
			CCCA* subapp = run->subApps[i];
			if(subapp == nil)
				continue;

			if(subapp->bVisible == NO)
				break;
			if(touchPosition.x >= subapp->hoRect.left && touchPosition.x < subapp->hoRect.right
			   && touchPosition.y >= subapp->hoRect.top && touchPosition.y < subapp->hoRect.bottom)
			{
				isOverSubapp = YES;
				break;
			}
		}
	}
	if (currentTouch==nil)
	{
		[self mouseMoved:touchPosition.x withY:touchPosition.y];
		currentTouch=touch;
	}
	NSInteger firstTouchTapCount = -1;
	
	BOOL bFlag=NO;
	NSEnumerator *enumerator = [touchesA objectEnumerator];
	while ((touch = [enumerator nextObject])) 
	{
		if(firstTouchTapCount == -1)
			firstTouchTapCount = [touch tapCount];
		
		BOOL bFlagLocal=NO;
		if (joystick!=nil)
		{
			id<ITouches>oc = joystick;
			bFlagLocal=[oc touchBegan:touch];
			if (bFlagLocal)
				bFlag=YES;
		}
		if (touches!=nil)
		{
			if (bFlagLocal==NO)
			{					
				id<ITouches>oc = touches;
				[oc touchBegan:touch];
			}
		}
		if (bFlagLocal)
		{
			for (int n=0; n<MAX_VIEWTOUCHES; n++)
			{
				if (cancelledTouches[n]==nil)
				{
					cancelledTouches[n]=touch;
					break;
				}
			}
		}
	}	
	
	if (!bFlag)
	{
		[self mouseDown:YES];
		if(!isOverSubapp)
			[self mouseClicked:(int)firstTouchTapCount];
	}

	//Recursively call through subapps
	if(run != nil && run->nSubApps > 0)
	{
		for(int i=0; i<MAX_SUBAPPS; ++i)
		{
			CCCA* subapp = run->subApps[i];
			if(subapp == nil)
				continue;

			CRunApp* subRunApp = subapp->subApp;
			[subRunApp touchesBegan:touchesA withEvent:event];
		}
	}
}


-(void)touchesMoved:(NSSet *)touchesA withEvent:(UIEvent *)event
{
	UITouch* touch = [touchesA anyObject];
		
	NSEnumerator *enumerator = [touchesA objectEnumerator];
	while ((touch = [enumerator nextObject])) 
	{
        if (touch==currentTouch)
        {
            CGPoint touchPosition = [touch locationInView:runView];
            [self mouseMoved:touchPosition.x withY:touchPosition.y];            
        }
		BOOL bFlagLocal=NO;
		if (joystick!=nil)
		{
			id<ITouches>oc = joystick;
			[oc touchMoved:touch];
		}
		for (int n=0; n<MAX_VIEWTOUCHES; n++)
		{
			if (cancelledTouches[n]==touch)
			{
				bFlagLocal=YES;
				break;
			}
		}
		if (touches!=nil)
		{
			if (bFlagLocal==NO)
			{
				id<ITouches>oc = touches;
				[oc touchMoved:touch];
			}
		}
	}
	
	//Recursively call through subapps
	if(run != nil && run->nSubApps > 0)
	{
		for(int i=0; i<MAX_SUBAPPS; ++i)
		{
			CCCA* subapp = run->subApps[i];
			if(subapp == nil)
				continue;

			CRunApp* subRunApp = subapp->subApp;
			[subRunApp touchesMoved:touchesA withEvent:event];
		}
	}
}

-(void)touchesEnded:(NSSet *)touchesA withEvent:(UIEvent *)event
{
	NSEnumerator *enumerator = [touchesA objectEnumerator];
	UITouch* touch = [touchesA anyObject];
	
	BOOL bFlag=NO;
	while ((touch = [enumerator nextObject])) 
	{
        if (touch==currentTouch)
        {
            CGPoint touchPosition = [touch locationInView:runView];
            [self mouseMoved:touchPosition.x withY:touchPosition.y];
            currentTouch=nil;
        }
        
		BOOL bFlagLocal=NO;
		if (joystick!=nil)
		{
			id<ITouches>oc = joystick;
			[oc touchEnded:touch];
		}
		for (int n=0; n<MAX_VIEWTOUCHES; n++)
		{
			if (cancelledTouches[n]==touch)
			{
				cancelledTouches[n]=nil;
				bFlagLocal=YES;
				bFlag=YES;
				break;
			}
		}			
		if (touches!=nil)
		{
			if (bFlagLocal==NO)
			{
				id<ITouches>oc = touches;				
				[oc touchEnded:touch];
			}
		}
	}		
	
	if (bFlag==NO)
	{	
		[self mouseDown:NO];
	}
	
	//Recursively call through subapps
	if(run != nil && run->nSubApps > 0)
	{
		for(int i=0; i<MAX_SUBAPPS; ++i)
		{
			CCCA* subapp = run->subApps[i];
			if(subapp == nil)
				continue;

			CRunApp* subRunApp = subapp->subApp;
			[subRunApp touchesEnded:touchesA withEvent:event];
		}
	}
}

-(void)touchesCancelled:(NSSet *)touchesA withEvent:(UIEvent *)event
{
	NSEnumerator *enumerator = [touchesA objectEnumerator];
	UITouch* touch;
	
	while ((touch = [enumerator nextObject])) 
	{
        if (touch==currentTouch)
        {
            currentTouch=nil;
        }
		if (joystick!=nil)
		{
			id<ITouches>oc = joystick;
			[oc touchCancelled:touch];
		}
		for (int n=0; n<MAX_VIEWTOUCHES; n++)
		{
			if (cancelledTouches[n]==touch)
			{
				cancelledTouches[n]=nil;
				break;
			}
		}			
		if (touches!=nil)
		{
			id<ITouches>oc = touches;
			[oc touchCancelled:touch];
		}
	}		
	[self mouseDown:NO];
	
	//Recursively call through subapps
	if(run != nil && run->nSubApps > 0)
	{
		for(int i=0; i<MAX_SUBAPPS; ++i)
		{
			CCCA* subapp = run->subApps[i];
			if(subapp == nil)
				continue;

			CRunApp* subRunApp = subapp->subApp;
			[subRunApp touchesCancelled:touchesA withEvent:event];
		}
	}
}

//Fix bug where a touch-cancelled event is not fired when a modal popup is shown. We must cancel the touches manually.
-(void)resetTouches
{
	currentTouch = nil;
	[self mouseDown:NO];
	
	if (touches!=nil)
	{
		id<ITouches>oc = touches;
		[oc resetTouches];
	}
	
	//Recursively call through subapps
	if(run != nil && run->nSubApps > 0)
	{
		for(int i=0; i<MAX_SUBAPPS; ++i)
		{
			CCCA* subapp = run->subApps[i];
			if(subapp == nil)
				continue;

			CRunApp* subRunApp = subapp->subApp;
			[subRunApp resetTouches];
		}
	}
}

-(BOOL)supportsOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	switch (orientation)
	{
		default:
		case ORIENTATION_PORTRAIT:
			return (interfaceOrientation == UIInterfaceOrientationPortrait);
		case ORIENTATION_LANDSCAPERIGHT:
			return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
		case ORIENTATION_LANDSCAPELEFT:
			return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
		case ORIENTATION_AUTOPORTRAIT:
			return (interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
		case ORIENTATION_AUTOLANDSCAPE:
			return (interfaceOrientation == UIInterfaceOrientationLandscapeRight) || (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
	}
}

-(NSUInteger)supportedOrientations
{
#ifdef __IPHONE_6_0
	switch (orientation)
	{
		default:
		case ORIENTATION_PORTRAIT:
			return UIInterfaceOrientationMaskPortrait;
		case ORIENTATION_LANDSCAPERIGHT:
			return UIInterfaceOrientationMaskLandscapeRight;
		case ORIENTATION_LANDSCAPELEFT:
			return UIInterfaceOrientationMaskLandscapeLeft;
		case ORIENTATION_AUTOPORTRAIT:
			return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
		case ORIENTATION_AUTOLANDSCAPE:
			return UIInterfaceOrientationMaskLandscape;
	}
#endif
	return 0;
}

-(void)registerForiOSEvents:(id<UIApplicationDelegate>)object
{
	[appDelegate->eventSubscribers add:(void*)object];
}

-(void)unregisterForiOSEvents:(id<UIApplicationDelegate>)object
{
	[appDelegate->eventSubscribers removeObject:(void*)object];
}

-(NSString*)getRelativePath:(NSString*)path
{
	NSUInteger pathLength = [path length];
	path = [path stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
	NSString* pathUpper=[path uppercaseString];
    
	//Check if the path is already relative
	if(pathLength<2 || ([path characterAtIndex:1]!=':' && ![path hasPrefix:@"//"]))
		return path;

	//It is relative to the application path (same folder or subfolder)
	NSUInteger appPathLength = [appEditorPathname length];
	if([pathUpper hasPrefix:appEditorPathname])
		return [path substringFromIndex:appPathLength+1];
	appPathLength = [appTargetPathname length];
	if([pathUpper hasPrefix:appTargetPathname])
		return [path substringFromIndex:appPathLength+1];
	
	//It is still an absolute windows path, remove any path information old-fashion-style.
	if([path characterAtIndex:1] == ':' || [path hasPrefix:@"//"])
	{
		NSRange searchRange = NSMakeRange(0, [path length]);
		NSRange index=[path rangeOfString:@"/" options:NSBackwardsSearch range:searchRange];
		if (index.location != NSNotFound)
			return [path substringFromIndex:index.location+1];
	}
	
	return path;
}

-(NSString*)getParent:(NSString*)path
{
    NSRange searchRange = NSMakeRange(0, [path length]);
    NSRange index=[path rangeOfString:@"/" options:NSBackwardsSearch range:searchRange];
    if (index.location != NSNotFound)
        return [path substringToIndex:index.location];
    return path;
}

-(NSString*)getPathForWriting:(NSString*)path
{
	path = [self getRelativePath:path];
	NSString* documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString* finalPath = [documentsDirectory stringByAppendingPathComponent:path];

	//Ensure folder exists before writing to it
	NSError* error = nil;
	NSString* folderPath = [finalPath stringByDeletingLastPathComponent];
	BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:folderPath
											 withIntermediateDirectories:YES
															  attributes:nil
																   error:&error];
	if(!success || error != nil)
		NSLog(@"Could not create the directory for writing: %@", path);
	
	return finalPath;
}

-(NSData*)loadResourceData:(NSString*)path
{
	//The NSData object returned from this function should not be released unless retained by the receiver.
	//Routine will first search in local files, then in the app resources and finally in MMF2 data-elements.
	
	path = [self getRelativePath:path];
	
	//Check in Documents folder
	NSString* documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString* documentsPath = [documentsDirectory stringByAppendingPathComponent:path];
	if([[NSFileManager defaultManager] fileExistsAtPath:documentsPath])
		return [NSData dataWithContentsOfFile:documentsPath];
	
	//Cache directory
	NSString* cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString* cachePath = [cacheDirectory stringByAppendingPathComponent:path];
	if([[NSFileManager defaultManager] fileExistsAtPath:cachePath])
		return [NSData dataWithContentsOfFile:cachePath];
	
	//App Resources
	NSString* fileName = [path stringByDeletingPathExtension];
	NSString* fileExtension = [path pathExtension];
	NSString* resourcePath = [[NSBundle mainBundle] pathForResource:fileName ofType:fileExtension];
	if(resourcePath != nil)
		return [NSData dataWithContentsOfFile:resourcePath];
	
	//Data elements from MMF2
	if(embeddedFiles != nil)
	{
		NSUInteger embLen = [embeddedFiles size];
		for(NSUInteger i=0; i<embLen; ++i)
		{
			CEmbeddedFile* embFile = (CEmbeddedFile*)[embeddedFiles get:i];
			if([path isEqualToString:embFile->path])
				return [embFile open];
		}
	}
	
	NSLog(@"Could not open the file: %@", path);
	return nil;
}

-(BOOL)resourceFileExists:(NSString*)path
{
	path = [self getRelativePath:path];
	
	//Check in Documents folder
	NSString* documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString* documentsPath = [documentsDirectory stringByAppendingPathComponent:path];
	if([[NSFileManager defaultManager] fileExistsAtPath:documentsPath])
		return YES;
	
	//Cache directory
	NSString* cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString* cachePath = [cacheDirectory stringByAppendingPathComponent:path];
	if([[NSFileManager defaultManager] fileExistsAtPath:cachePath])
		return YES;
	
	//App Resources
	NSString* resourcePath = [[NSBundle mainBundle] pathForResource:[path stringByDeletingPathExtension] ofType:[path pathExtension]];
	if(resourcePath != nil)
		return YES;
	
	//Data elements from MMF2
	if(embeddedFiles != nil){
		NSUInteger embLen = [embeddedFiles size];
		for(NSUInteger i=0; i<embLen; ++i){
			CEmbeddedFile* embFile = (CEmbeddedFile*)[embeddedFiles get:i];
			if([path isEqualToString:embFile->path])
				return YES;
		}
	}
	return NO;
}

-(NSString*)stringGuessingEncoding:(NSData*)data
{
	//Routine will "guess" the encoding of the data by brute-forcing through different encodings until it finds a valid one according to NSString's specifications.
	NSString* guess = nil;

	//UTF8
	guess = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	if(guess != nil) return [guess stringByReplacingOccurrencesOfString:@"\r" withString:@""];

	//Latin 1
	guess = [[[NSString alloc] initWithData:data encoding:NSWindowsCP1252StringEncoding] autorelease];
	if(guess != nil) return [guess stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	
	//ASCII
	guess = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
	if(guess != nil) return [guess stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	
	//Greek
	guess = [[[NSString alloc] initWithData:data encoding:NSWindowsCP1253StringEncoding] autorelease];
	if(guess != nil) return [guess stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	
	//Turkish
	guess = [[[NSString alloc] initWithData:data encoding:NSWindowsCP1254StringEncoding] autorelease];
	if(guess != nil) return [guess stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	
	//Latin 2
	guess = [[[NSString alloc] initWithData:data encoding:NSWindowsCP1250StringEncoding] autorelease];
	if(guess != nil) return [guess stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	
	//Cyrillic
	guess = [[[NSString alloc] initWithData:data encoding:NSWindowsCP1251StringEncoding] autorelease];
	return [guess stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	//Will be nil if nothing has been found
}

-(CGSize)windowSize
{
	CGSize screen = [[UIScreen mainScreen] bounds].size;
	CGSize portrait = CGSizeMake(MIN(screen.width, screen.height), MAX(screen.width, screen.height));
	if(actualOrientation == ORIENTATION_LANDSCAPELEFT || actualOrientation == ORIENTATION_LANDSCAPERIGHT || actualOrientation == ORIENTATION_AUTOLANDSCAPE)
		portrait = CGSizeMake(portrait.height, portrait.width);
	return portrait;
}

-(CGSize)screenSize
{
	float scale = [[UIScreen mainScreen] scale];
	CGSize screenBounds = [[UIScreen mainScreen] bounds].size;
	CGSize portrait = CGSizeMake(MIN(screenBounds.width, screenBounds.height), MAX(screenBounds.width, screenBounds.height));
	CGSize screen = CGSizeMake(portrait.width*scale, portrait.height*scale);
	if(actualOrientation == ORIENTATION_LANDSCAPELEFT || actualOrientation == ORIENTATION_LANDSCAPERIGHT || actualOrientation == ORIENTATION_AUTOLANDSCAPE)
		screen = CGSizeMake(screen.height, screen.width);
	return screen;
}

@end
