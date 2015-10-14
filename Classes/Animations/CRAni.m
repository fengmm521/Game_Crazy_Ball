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
// CRANI gestion des animations
//
//----------------------------------------------------------------------------------
#import "CRAni.h"
#import "CAnim.h"
#import "CAnimDir.h"
#import "CAnimHeader.h"
#import "CObject.h"
#import "CRCom.h"
#import "CObjectCommon.h"
#import "CImage.h"
#import "CImageBank.h"
#import "CRunApp.h"
#import "CRunFrame.h"
#import "CRun.h"
#import "CEventProgram.h"

@implementation CRAni

// -------------------------------------------------
// Initialisation de la partie ANIMATIONS d'un objet
// -------------------------------------------------
static short anim_Defined[] =
{
	ANIMID_STOP,
	ANIMID_WALK,
	ANIMID_RUN,
	ANIMID_BOUNCE,
	ANIMID_SHOOT,
	ANIMID_JUMP,
	ANIMID_FALL,
	ANIMID_CLIMB,
	ANIMID_CROUCH,
	ANIMID_UNCROUCH,
	12,
	13,
	14,
	15,
	-1
};

-(id)initWithHO:(CObject*)ho
{
	self=[super init];
	hoPtr=ho;
	return self;
}
-(void)kill:(BOOL)bFast
{
}
-(void)initRAni
{
	// Init de l'animation normale
	// ---------------------------
	raRoutineAnimation = -1;
	[self init_Animation:ANIMID_WALK];
	raRoutineAnimation = 0;
	
	// Animation APPEAR au debut?
	// --------------------------
	if ([self anim_Exist:ANIMID_APPEAR])
	{
		raRoutineAnimation = -1;
		[self animation_Force:ANIMID_APPEAR];
		[self animation_OneLoop];
		[self animations];
        raRoutineAnimation = 1;
	}
	else
	{
		// Si pas d'autre anims que disappear : on fait un disappear!
		// ----------------------------------------------------------
		int i;
		for (i = 0; anim_Defined[i] >= 0; i++)
		{
			if ([self anim_Exist:anim_Defined[i]])
			{
				break;
			}
		}
		if (anim_Defined[i] < 0)
		{
			if ([self anim_Exist:ANIMID_DISAPPEAR])
			{
				raRoutineAnimation = -1;
				[self animation_Force:ANIMID_DISAPPEAR];
				[self animation_OneLoop];
				[self animations];
                raRoutineAnimation = 2;
			}
		}
	}
}

// ---------------------------------------------------------------------------
// Initialisation d'un animation
// ---------------------------------------------------------------------------
-(void)init_Animation:(int)anim
{
	hoPtr->roc->rcAnim = anim;
	raAnimStopped = NO;
	raAnimForced = 0;
	raAnimDirForced = 0;
	raAnimSpeedForced = 0;
	raAnimFrameForced = 0;
	raAnimCounter = 0;
	raAnimFrame = 0;
	raAnimOffset = nil;
	raAnimDirOffset = nil;
	raAnimOn = -1;
	raAnimMinSpeed = -1;
	raAnimPreviousDir = -1;
	[self animations];
}

// ---------------------------------------------------------------------------
// VERIFICATION D'UNE DIRECTION: ro.roAnim, ro.roDir
// ---------------------------------------------------------------------------
-(void)check_Animate
{
	[self animIn:0];
}

// ---------------------------------------------------------------------------
// ANIMATION ENTREE POUR LES EXTENSIONS MOVEMENT 
// ---------------------------------------------------------------------------
-(void)extAnimations:(int)anim
{
	hoPtr->roc->rcAnim = anim;
	[self animate];
}

// ---------------------------------------------------------------------------
// ENTREE DES ANIMATIONS
// ---------------------------------------------------------------------------
-(BOOL)animate
{
	switch (raRoutineAnimation)
	{
		case 0:
			return [self animations];
		case 1:
			[self anim_Appear];
			return NO;
		case 2:
			[self anim_Disappear];
			return NO;
	}
	return NO;
}

// ---------------------------------------------------------------------------
// ANIMATION D'UN OBJET: ro.roAnim, ro.roSpeed, ro.roDir
// ---------------------------------------------------------------------------
-(BOOL)animations
{
	int x = hoPtr->hoX;									// Stocke la zone exacte du sprite actuel
	hoPtr->roc->rcOldX = x;
	x -= hoPtr->hoImgXSpot;
	hoPtr->roc->rcOldX1 = x;
	x += hoPtr->hoImgWidth;
	hoPtr->roc->rcOldX2 = x;
	
	int y = hoPtr->hoY;
	hoPtr->roc->rcOldY = y;
	y -= hoPtr->hoImgYSpot;
	hoPtr->roc->rcOldY1 = y;
	y += hoPtr->hoImgHeight;
	hoPtr->roc->rcOldY2 = y;
	
	hoPtr->roc->rcOldImage = hoPtr->roc->rcImage;			// Stocke l'ancienne image
	hoPtr->roc->rcOldAngle = hoPtr->roc->rcAngle;
	
	return [self animIn:1];
}

-(BOOL)animIn:(int)vbl
{
	CObjectCommon* ocPtr = hoPtr->hoCommon;
	
	int speed = hoPtr->roc->rcSpeed;
	int anim = hoPtr->roc->rcAnim;								//; L'animation voulue
	
	// Brancher une nouvelle animation?
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (raAnimSpeedForced != 0)						//; Une vitesse forcee?
	{
		speed = raAnimSpeedForced - 1;
	}
	if (anim == ANIMID_WALK)									//; Si marcher, courir?
	{
		if (speed == 0)
		{
			anim = ANIMID_STOP;
		}
		if (speed >= 75)
		{
			anim = ANIMID_RUN;
		}
	}
	if (raAnimForced != 0)								//; Une animation forcee?
	{
		anim = raAnimForced - 1;
	}
	if (anim != raAnimOn)								//; La meme?
	{
		raAnimOn = anim;
		if (anim >= ocPtr->ocAnimations->ahAnimMax)
		{
			anim = ocPtr->ocAnimations->ahAnimMax - 1;
		}
		CAnim* anPtr = ocPtr->ocAnimations->ahAnims[anim];
		if (anPtr != raAnimOffset)
		{
			raAnimOffset = anPtr;
			raAnimDir = -1;					//; Force le recalcul de la direction
			raAnimFrame = 0;					//; Repointe l'image 0
		}
	}
	
	// Brancher une nouvelle direction?
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	int dir = hoPtr->roc->rcDir % 32;				//; Une modification?
	if(dir < 0)
		dir += 32;
	
	BOOL bAngle=NO;
	if (raAnimDirForced != 0)						//; Une direction forcee?
	{
		dir = raAnimDirForced - 1;
	}
	CAnimDir* adPtr;
	if (raAnimDir != dir)
	{
		raAnimDir = dir;
		
		// Trouve le sens d'exploration des approximations
		adPtr = raAnimOffset->anDirs[dir];
		if (adPtr == nil)
		{
			// De quel cote est t'on le plus proche?
			if ((raAnimOffset->anAntiTrigo[dir] & 0x40) != 0)
			{
				dir = raAnimOffset->anAntiTrigo[dir] & 0x3F;
			}
			else if ((raAnimOffset->anTrigo[dir] & 0x40) != 0)
			{
				dir = raAnimOffset->anTrigo[dir] & 0x3F;
			}
			else
			{   int offset=dir;
                if (raAnimPreviousDir<0)
                {
                    dir=raAnimOffset->anTrigo[dir]&0x3F;
                }
                else
                {
                    dir-=raAnimPreviousDir;
                    dir&=31;
                    if (dir>15)
                    {
                        dir=raAnimOffset->anTrigo[offset]&0x3F;
                    }
                    else
                    {
                        dir=raAnimOffset->anAntiTrigo[offset]&0x3F;
                    }
                }
			}
			adPtr = raAnimOffset->anDirs[dir];
		}
		else
		{
			raAnimPreviousDir = dir;
			adPtr = raAnimOffset->anDirs[dir];
		}
		
		// Rotations automatiques?
		if (raAnimOffset->anDirs[0]!=nil && (hoPtr->hoCommon->ocFlags2&OCFLAGS2_AUTOMATICROTATION)!=0)
		{
			hoPtr->roc->rcAngle=(raAnimDir*360)/32;
			adPtr=raAnimOffset->anDirs[0];
			raAnimDirOffset=nil;
			bAngle=YES;
		}
		
		if (raAnimDirOffset != adPtr)
		{
			raAnimDirOffset = adPtr;
			raAnimRepeat = adPtr->adRepeat;			//; Nombre de repeat
			raAnimRepeatLoop = adPtr->adRepeatFrame;	//; Image du repeat
			
			int minSpeed = adPtr->adMinSpeed;
			int maxSpeed = adPtr->adMaxSpeed;
			
			if (minSpeed != raAnimMinSpeed || maxSpeed != raAnimMaxSpeed)		//; Calcul de la nouvelle vitesse
			{
				raAnimMinSpeed = minSpeed;
				raAnimMaxSpeed = maxSpeed;
				maxSpeed -= minSpeed;
				raAnimDeltaSpeed = maxSpeed;
				raAnimDelta = minSpeed;
				raAnimSpeed = -1;
			}
			
			raAnimNumberOfFrame = adPtr->adNumberOfFrame;
			if (raAnimFrameForced != 0 && raAnimFrameForced - 1 >= raAnimNumberOfFrame)
			{
				raAnimFrameForced = 0;
			}
			if (raAnimFrame >= raAnimNumberOfFrame)		//; Charge l'image
			{
				raAnimFrame = 0;
			}
			short frame = adPtr->adFrames[raAnimFrame];
			if (raAnimStopped == NO)
			{
				hoPtr->roc->rcImage = frame;
				if (frame<0)
				{
					return NO;						//; Securite pour jeu casses!
				}
				ImageInfo ifo = [hoPtr->hoAdRunHeader->rhApp->imageBank getImageInfoEx:frame withAngle:hoPtr->roc->rcAngle andScaleX:hoPtr->roc->rcScaleX andScaleY:hoPtr->roc->rcScaleY];
				hoPtr->hoImgWidth = ifo.width;
				hoPtr->hoImgHeight = ifo.height;
				hoPtr->hoImgXSpot = ifo.xSpot;
				hoPtr->hoImgYSpot = ifo.ySpot;
				hoPtr->roc->rcChanged = YES;
				hoPtr->roc->rcCheckCollides = YES;
			}
			if (raAnimNumberOfFrame == 1)				//; Si une seule image : on la met directement!
			{
				if (raAnimMinSpeed == 0)				//; Si vitesse mini non nulle, on anime
				{
					raAnimNumberOfFrame = 0;			//; Sinon, rien a faire!
				}
				frame = hoPtr->roc->rcImage;					//; Recupere taille
				if (frame<0)
				{
					return NO;						//; Securite pour jeu casses!
				}
				ImageInfo ifo = [hoPtr->hoAdRunHeader->rhApp->imageBank getImageInfoEx:frame withAngle:hoPtr->roc->rcAngle andScaleX:hoPtr->roc->rcScaleX andScaleY:hoPtr->roc->rcScaleY];
				hoPtr->hoImgWidth = ifo.width;
				hoPtr->hoImgHeight = ifo.height;
				hoPtr->hoImgXSpot = ifo.xSpot;
				hoPtr->hoImgYSpot = ifo.ySpot;
				hoPtr->roc->rcChanged = YES;
				hoPtr->roc->rcCheckCollides = YES;
				return NO;
			}
		}
	}
	
	// Si objet non anime : on s'en va!
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (vbl == 0 && raAnimFrameForced == 0)
	{
		return NO;	//; Des VBL a faire?
	}
	if (bAngle==NO && raAnimNumberOfFrame == 0)
	{
		return NO;			//; Une seule frame?
	}
	// Calcul de la vitesse relative au deplacement
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	int delta = raAnimDeltaSpeed;					// Des calculs a faire?
	if (speed != raAnimSpeed)
	{
		raAnimSpeed = speed;
		
		if (delta == 0)
		{
			raAnimDelta = raAnimMinSpeed;
			if (raAnimSpeedForced != 0)			//; Une vitesse forcee?
			{
				raAnimDelta = raAnimSpeedForced - 1;
			}
		}
		else
		{
			int deltaSpeed = hoPtr->roc->rcMaxSpeed - hoPtr->roc->rcMinSpeed;		//; Vitesse mini et maxi pour le mouvement
			if (deltaSpeed == 0)
			{
                if (raAnimSpeedForced!=0)
                {
                    delta*=speed;
                    delta/=100;
                    delta+=raAnimMinSpeed;
                    if (delta>raAnimMaxSpeed)
                    {
                        delta=raAnimMaxSpeed;
                    }
                    raAnimDelta=delta;                                        
                }
                else
                {
                    delta /= 2;
                    delta += raAnimMinSpeed;
                    raAnimDelta = delta;					//; Valeur finale!
                }
			}
			else
			{
				delta *= speed;								//; Calcule la nouvelle vitesse
				delta /= deltaSpeed;
				delta += raAnimMinSpeed;
				if (delta > raAnimMaxSpeed)
				{
					delta = raAnimMaxSpeed;
				}
				raAnimDelta = delta;					//; Valeur finale!
			}
		}
	}
	
	// Fait l'animation...
	// ~~~~~~~~~~~~~~~~~~~
	adPtr = raAnimDirOffset;
	int frame = raAnimFrameForced;
	int counter;
	if (frame == 0)
	{
		if (raAnimDelta == 0)
		{
			return NO;					//; Si vitesse nulle : pas d'anim
		}
		if (raAnimStopped)
		{
			return NO;					//; Si animation arretee
		}
		counter = raAnimCounter;
		frame = raAnimFrame;
		int aDelta = raAnimDelta;
		if ((hoPtr->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
		{
			aDelta = (int) (((double) aDelta) * hoPtr->hoAdRunHeader->rh4MvtTimerCoef);
		}
		counter += aDelta;
		while (counter > 100)
		{
			counter -= 100;
			frame++;
			if (frame >= raAnimNumberOfFrame)
			{
				frame = raAnimRepeatLoop;				//; Image ou reboucler
				if (raAnimRepeat != 0)					//; On boucle?
				{
					raAnimRepeat--;
					if (raAnimRepeat == 0)
					{
						raAnimFrame = raAnimNumberOfFrame;
						
						// Pas de boucle : envoie un message
						raAnimNumberOfFrame = 0;
						// Si animation forcee, la deforce pour la prochaine fois
						if (raAnimForced != 0)
						{
							raAnimForced = 0;
							raAnimDirForced = 0;
							raAnimSpeedForced = 0;
						}
						if ((hoPtr->hoAdRunHeader->rhGameFlags & GAMEFLAGS_INITIALISING) != 0)
						{
							return NO;
						}
						
                        int cond = (-2 << 16);	    // CNDL_EXTANIMENDOF;
                        cond |= (((int) hoPtr->hoType) & 0xFFFF);
                        if (raRoutineAnimation>=0)
                        {
                            hoPtr->hoAdRunHeader->rhEvtProg->rhCurParam[0] = hoPtr->roa->raAnimOn;
                            return [hoPtr->hoAdRunHeader->rhEvtProg handle_Event:hoPtr withCode:cond];
                        }
                        else
                        {
                            [hoPtr->hoAdRunHeader->rhEvtProg push_Event:1 withCode:cond andParam:hoPtr->roa->raAnimOn andObject:hoPtr andOI:hoPtr->hoOi];
                        }
					}
				}
			}
		}
		raAnimCounter = counter;
	}
	else
	{
		frame--;
	}
	raAnimFrame = frame;
    hoPtr->roc->rcChanged = YES;
    hoPtr->roc->rcCheckCollides = YES;
	short image = adPtr->adFrames[frame];
	if (hoPtr->roc->rcImage != image || raOldAngle!=hoPtr->roc->rcAngle)
	{
		hoPtr->roc->rcImage = image;
		raOldAngle=hoPtr->roc->rcAngle;
		if (image<0)
		{
			return NO;								//; Securite pour jeux casses
		}
		ImageInfo ifo = [hoPtr->hoAdRunHeader->rhApp->imageBank getImageInfoEx:image withAngle:hoPtr->roc->rcAngle andScaleX:hoPtr->roc->rcScaleX andScaleY:hoPtr->roc->rcScaleY];
		hoPtr->hoImgWidth = ifo.width;
		hoPtr->hoImgHeight = ifo.height;
		hoPtr->hoImgXSpot = ifo.xSpot;
		hoPtr->hoImgYSpot = ifo.ySpot;
	}
	return NO;
}

// ---------------------------------------------------------------------------
// Verifie qu'une animation existe bien pour l'objet [esi]
// ---------------------------------------------------------------------------
-(BOOL)anim_Exist:(int)animId
{
	CAnimHeader* ahPtr = hoPtr->hoCommon->ocAnimations;                 // Pointe AnimHeader
	if (ahPtr->ahAnimExists[animId] == 0)
	{
		return NO;
	}
	return YES;
}

// ---------------------------------------------------------------------------
// MET L'ANIMATION EN ONE LOOP
// ---------------------------------------------------------------------------
-(void)animation_OneLoop
{
	if (raAnimRepeat == 0)
	{
		raAnimRepeat = 1;								// Force un seul tour
	}
}

// ---------------------------------------------------------------------------
// FORCE ANIMATION, ax=animation
// ---------------------------------------------------------------------------
-(void)animation_Force:(int)anim
{
	raAnimForced = anim + 1;
/*  if (anim!=raAnimOn)
    {
        raAnimFrame=0;
        raAnimCounter=0;
    }
*/ 
	[self animIn:0];
}

// ---------------------------------------------------------------------------
// RESTORE ANIMATION
// ---------------------------------------------------------------------------
-(void)animation_Restore
{
	raAnimForced = 0;
	[self animIn:0];
}

// ---------------------------------------------------------------------------
// FORCE DIRECTION, ax=direction
// ---------------------------------------------------------------------------
-(void)animDir_Force:(int)dir
{
	dir &= 31;
	raAnimDirForced = dir + 1;
	[self animIn:0];
}

// ---------------------------------------------------------------------------
// RESTORE DIRECTION
// ---------------------------------------------------------------------------
-(void)animDir_Restore
{
	raAnimDirForced = 0;
	[self animIn:0];
}

// ---------------------------------------------------------------------------
// FORCE SPEED, ax=speed
// ---------------------------------------------------------------------------
-(void)animSpeed_Force:(int)speed
{
	if (speed < 0)
	{
		speed = 0;
	}
	if (speed > 100)
	{
		speed = 100;
	}
	raAnimSpeedForced = speed + 1;
	[self animIn:0];
}

// ---------------------------------------------------------------------------
// RESTORE SPEED
// ---------------------------------------------------------------------------
-(void)animSpeed_Restore
{
	raAnimSpeedForced = 0;
	[self animIn:0];
}

// ---------------------------------------------------------------------------
// RESTART ANIMATION
// ---------------------------------------------------------------------------
-(void)anim_Restart
{
	raAnimOn=-1;
	[self animIn:0];
}   

// ---------------------------------------------------------------------------
// FORCE FRAME, ax=frame
// ---------------------------------------------------------------------------
-(void)animFrame_Force:(int)frame
{
	if (frame >= raAnimNumberOfFrame)
	{
		frame = raAnimNumberOfFrame - 1;
	}
	if (frame < 0)
	{
		frame = 0;
	}
	raAnimFrameForced = frame + 1;
	[self animIn:0];
}

// ---------------------------------------------------------------------------
// RESTORE FRAME
// ---------------------------------------------------------------------------
-(void)animFrame_Restore
{
	raAnimFrameForced = 0;
	[self animIn:0];
}

//  --------------------------------------------------------------------------
//	ANIMATION APPEAR
//  --------------------------------------------------------------------------
-(void)anim_Appear
{
	[self animIn:1];
	
	// Attend la fin de l'apparition
	if (raAnimForced != ANIMID_APPEAR + 1)
	{
		// Regarde si existe des animations STOP/WALK/RUN, sinon fait un DISAPPEAR
		if ([self anim_Exist:ANIMID_STOP] || [self anim_Exist:ANIMID_WALK] || [self anim_Exist:ANIMID_RUN])
		{
			// Initialise le vrai mouvement de l'objet
			raRoutineAnimation = 0;
			[self animation_Restore];
		}
		else
		{
			raRoutineAnimation = 2;
			[hoPtr->hoAdRunHeader init_Disappear:hoPtr];
		}
	}
}

//  --------------------------------------------------------------------------
//	ANIMATION DISAPPEAR
//  --------------------------------------------------------------------------
-(void)anim_Disappear
{
	[self animIn:1];									// Un cran d'animations
	if (raAnimForced != ANIMID_DISAPPEAR + 1)
	{
		[hoPtr->hoAdRunHeader destroy_Add:hoPtr->hoNumber];
	}
}


@end
