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
// CMOVEGENERIC : Mouvement joystick
//
//----------------------------------------------------------------------------------
#import "CMoveGeneric.h"
#import "CMove.h"
#import "CObject.h"
#import "CMoveDef.h"
#import "CRAni.h"
#import "CRMvt.h"
#import "CRCom.h"
#import "CRun.h"
#import "CMoveDefGeneric.h"
#import "CEventProgram.h"
#import "CRunFrame.h"
#import "CAnim.h"

extern char Joy2Dir[];
extern BOOL bMoveChanged;

@implementation CMoveGeneric

-(void)initMovement:(CObject*)ho withMoveDef:(CMoveDef*)mvPtr
{
	hoPtr = ho;
	
	CMoveDefGeneric* mgPtr = (CMoveDefGeneric*) mvPtr;
	
	hoPtr->hoCalculX = 0;
	hoPtr->hoCalculY = 0;
	MG_Speed = 0;
	hoPtr->roc->rcSpeed = 0;
	MG_Bounce = 0;
	MG_LastBounce = -1;
	hoPtr->roc->rcPlayer = mvPtr->mvControl;
	rmAcc = mgPtr->mgAcc;
	rmAccValue = [self getAccelerator:rmAcc];
	rmDec = mgPtr->mgDec;
	rmDecValue = [self getAccelerator:rmDec];
	hoPtr->roc->rcMaxSpeed = mgPtr->mgSpeed;
	hoPtr->roc->rcMinSpeed = 0;
	MG_BounceMu = mgPtr->mgBounceMult;
	MG_OkDirs = mgPtr->mgDir;
	rmOpt=mgPtr->mvOpt;
	hoPtr->roc->rcChanged = YES;
}
-(void)move
{
	int direction;
	int autorise;
	int speed, speed8, dir;
	
	hoPtr->hoAdRunHeader->rhVBLObjet = 1;
	
	direction = hoPtr->roc->rcDir;							// Sauve la direction precedente
	hoPtr->roc->rcOldDir = direction;
	
	if (MG_Bounce == 0)
	{
		hoPtr->rom->rmBouncing = NO;							//; Flag rebond a zero...
		
		// Lecture du baton de joie
		autorise = 0;
		{
			int j = hoPtr->hoAdRunHeader->rhPlayer&15;
			if (j != 0)
			{
				dir = Joy2Dir[j];
				if (dir != -1)
				{
					int flag = 1 << dir;
					if ((flag & MG_OkDirs) != 0)
					{
						autorise = 1;
						direction = dir;
					}
				}
			}
		}
		
		// Gestion de l'acceleration / ralentissement
		int dSpeed;
		speed = MG_Speed;
		if (autorise == 0)
		{
			if (speed != 0)
			{
				dSpeed = rmDecValue;
				if ((hoPtr->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					dSpeed = (int) (((double) dSpeed) * hoPtr->hoAdRunHeader->rh4MvtTimerCoef);
				}
				speed -= dSpeed;
				if (speed <= 0)
				{
					speed = 0;
				}
			}
		}
		else
		{
			speed8 = speed >> 8;							//; Partie utile de la vitesse
			if (speed8 < hoPtr->roc->rcMaxSpeed)
			{
				dSpeed = rmAccValue;
				if ((hoPtr->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					dSpeed = (int) (((double) dSpeed) * hoPtr->hoAdRunHeader->rh4MvtTimerCoef);
				}
				speed += dSpeed;
				speed8 = speed >> 8;
				if (speed8 > hoPtr->roc->rcMaxSpeed)
				{
					speed = hoPtr->roc->rcMaxSpeed << 8;
				}
			}
		}
		MG_Speed = speed;						//; Retrouve la vitesse virgule
		hoPtr->roc->rcSpeed = speed >> 8;					//; Vitesse normale
		
		// Gestion de la direction
		hoPtr->roc->rcDir = direction;						//; C'est bon, change la direction
		
		// Calcul de la nouvelle image
		hoPtr->roc->rcAnim = ANIMID_WALK;					//; Nouvelle image avec nouvelle animation
		if (hoPtr->roa != nil)
		{
			[hoPtr->roa animate];
		}
		
		// Calcul de la nouvelle position
		if ([self newMake_Move:hoPtr->roc->rcSpeed withDir:hoPtr->roc->rcDir] == NO)
		{
			return;
		}
		if (bMoveChanged)
		{
			return;
		}
		
		if (hoPtr->roc->rcSpeed == 0)						//; Bloque?
		{
			speed = MG_Speed;					//; Pas vraiment?
			if (speed == 0)
			{
				return;
			}
			if (hoPtr->roc->rcOldDir == hoPtr->roc->rcDir)
			{
				return;
			}
			hoPtr->roc->rcSpeed = speed >> 8;				//; Remet la vitesse
			hoPtr->roc->rcDir = hoPtr->roc->rcOldDir;		//; Remet la direction
			if ([self newMake_Move:hoPtr->roc->rcSpeed withDir:hoPtr->roc->rcDir] == NO)
			{
				return;			//; Essaye de nouveau!!!
			}
			if (bMoveChanged)
			{
				return;
			}
		}
	}
				
	// Gestion du rebond
	while (YES)
	{
		if (MG_Bounce == 0)
		{
			return;			//; Passe en mode rebond?
		}
		if (hoPtr->hoAdRunHeader->rhVBLObjet == 0)
		{
			return;					//; Encore des VBL?
		}
		speed = MG_Speed;
		speed -= rmDecValue;
		if (speed > 0)
		{
			MG_Speed = speed;					//; Et stocke
			speed >>= 8;
			hoPtr->roc->rcSpeed = speed;
			dir = hoPtr->roc->rcDir;						//; Direction du rebond
			if (MG_Bounce != 0)
			{
				dir += 16;
				dir &= 31;
			}
			if ([self newMake_Move:speed withDir:dir] == NO)
			{
				return;
			}
			if (bMoveChanged)
			{
				return;
			}
			continue;
		}
		else
		{
			MG_Speed = 0;
			hoPtr->roc->rcSpeed = 0;
			MG_Bounce = 0;
		}			
		break;
	}	
}

// Fait rebondir
// -------------
-(void)bounce
{
	if (rmCollisionCount == hoPtr->hoAdRunHeader->rh3CollisionCount)		//; C'est le sprite courant?
	{
		[self mv_Approach:(rmOpt&MVOPT_8DIR_STICK)!=0];
	}
	if (hoPtr->hoAdRunHeader->rhLoopCount == MG_LastBounce)
	{
		return;				//; Un seul bounce a chaque cycle
	}
	MG_LastBounce = hoPtr->hoAdRunHeader->rhLoopCount;
	MG_Bounce++;
	if (MG_Bounce >= 12)								//; Securite si bloque
	{
		[self stop];
		return;
	}
	hoPtr->rom->rmBouncing = YES;
	hoPtr->rom->rmMoveFlag = YES;							//; Le flag!
}

// Arret brusque
// -------------
-(void)stop
{
	hoPtr->roc->rcSpeed = 0;
	MG_Bounce = 0;
	MG_Speed = 0;
	hoPtr->rom->rmMoveFlag = YES;
	if (rmCollisionCount == hoPtr->hoAdRunHeader->rh3CollisionCount)		//; C'est le sprite courant?
	{
		// Le sprite entre dans quelque chose...
		[self mv_Approach:(rmOpt&MVOPT_8DIR_STICK)!=0];						//; On approche au maximum, sans toucher a la vitesse
		MG_Bounce = 0;
	}
}

// Redemarrage brusque
// ~~~~~~~~~~~~~~~~~~~
-(void)start
{
	hoPtr->rom->rmMoveFlag = YES;
	rmStopSpeed = 0;
}

// Force la vitesse maximum (AX= nouvelle vitesse)
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(void)setMaxSpeed:(int)speed
{
	if (speed < 0)
	{
		speed = 0;
	}
	if (speed > 250)
	{
		speed = 250;
	}
	hoPtr->roc->rcMaxSpeed = speed;
	if (hoPtr->roc->rcSpeed > speed)
	{
		hoPtr->roc->rcSpeed = speed;
		MG_Speed = speed << 8;
	}
	hoPtr->rom->rmMoveFlag = YES;
}

// Force la vitesse courante (AX= nouvelle vitesse)
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(void)setSpeed:(int)speed
{
	if (speed < 0)
	{
		speed = 0;
	}
	if (speed > 250)
	{
		speed = 250;
	}
	if (speed > hoPtr->roc->rcMaxSpeed)
	{
		speed = hoPtr->roc->rcMaxSpeed;
	}
	hoPtr->roc->rcSpeed = speed;
	MG_Speed = speed << 8;
	hoPtr->rom->rmMoveFlag = YES;
}

-(void)setXPosition:(int)x
{
	if (hoPtr->hoX != x)
	{
		hoPtr->hoX = x;
		hoPtr->rom->rmMoveFlag = YES;
		hoPtr->roc->rcChanged = YES;
		hoPtr->roc->rcCheckCollides = YES;					//; Force la detection de collision
	}
}

-(void)setYPosition:(int)y
{
	if (hoPtr->hoY != y)
	{
		hoPtr->hoY = y;
		hoPtr->rom->rmMoveFlag = YES;
		hoPtr->roc->rcChanged = YES;
		hoPtr->roc->rcCheckCollides = YES;					//; Force la detection de collision
	}
}

-(void)set8Dirs:(int)dirs
{
	MG_OkDirs = dirs;
}

@end
