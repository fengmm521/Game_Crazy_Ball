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
// CMOVERACE : Mouvement voiture de course
//
//----------------------------------------------------------------------------------
#import "CMoveRace.h"
#import "CMove.h"
#import "CObject.h"
#import "CMoveDef.h"
#import "CRAni.h"
#import "CRMvt.h"
#import "CRCom.h"
#import "CRun.h"
#import "CMoveDefRace.h"
#import "CEventProgram.h"
#import "CRunFrame.h"
#import "CAnim.h"

// Masque des directions pour le nombre autorise movement race
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
static int RaceMask[]=
{
	0xFFFFFFF8,
	0xFFFFFFFC,
	0xFFFFFFFE,
	0xFFFFFFFF  
};

extern BOOL bMoveChanged;

@implementation CMoveRace

-(void)initMovement:(CObject*)ho withMoveDef:(CMoveDef*)mvPtr
{
	hoPtr=ho;
	
	CMoveDefRace* mrPtr=(CMoveDefRace*)mvPtr;
	
	// Vitesse / accelerateurs
	MR_Speed=0;
	hoPtr->roc->rcSpeed=0;
	MR_Bounce=0;
	MR_LastBounce=-1;
	hoPtr->roc->rcPlayer=mrPtr->mvControl;
	rmAcc=mrPtr->mrAcc;
	rmAccValue=[self getAccelerator:mrPtr->mrAcc];
	rmDec=mrPtr->mrDec;
	rmDecValue=[self getAccelerator:mrPtr->mrDec];
	hoPtr->roc->rcMaxSpeed=mrPtr->mrSpeed;
	hoPtr->roc->rcMinSpeed=0;
	MR_BounceMu=mrPtr->mrBounceMult;
	MR_OkReverse=mrPtr->mrOkReverse;
	hoPtr->rom->rmReverse=0;
	rmOpt=mrPtr->mvOpt;
	MR_OldJoy=0;
	
	// Rotations
	MR_RotMask=RaceMask[mrPtr->mrAngles];
	MR_RotSpeed=mrPtr->mrRot;
	MR_RotCpt=0;
	MR_RotPos=hoPtr->roc->rcDir;
	hoPtr->hoCalculX=0;
	hoPtr->hoCalculY=0;
	[self moveAtStart:mvPtr];
	
	hoPtr->roc->rcChanged=YES;
}    
-(void)move
{
	int j;
	int add, accel, speed, dir, speed8;
	int dSpeed;
	
	hoPtr->hoAdRunHeader->rhVBLObjet=1;
	
	if (MR_Bounce==0)
	{
		hoPtr->rom->rmBouncing=NO;								//; Gestion flag bouncing...
		
		j=hoPtr->hoAdRunHeader->rhPlayer&0x0F;
		
		// Gestion de la direction
		// ~~~~~~~~~~~~~~~~~~~~~~~
		add=0;
		if ((j&0x08)!=0)
			add=-1;
		if ((j&0x04)!=0)
			add=1;
		if (add!=0)
		{
			dSpeed=MR_RotSpeed;
			if ((hoPtr->hoAdRunHeader->rhFrame->leFlags&LEF_TIMEDMVTS)!=0)
				dSpeed=(int)(((double)dSpeed)*hoPtr->hoAdRunHeader->rh4MvtTimerCoef);                
			MR_RotCpt+=dSpeed;
			while (MR_RotCpt>100)
			{
				MR_RotCpt-=100;
				MR_RotPos+=add;
				MR_RotPos&=31;
				hoPtr->roc->rcDir=MR_RotPos&MR_RotMask;
			};
		}
		
		// Gestion de l'acceleration / ralentissement
		//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		accel=0;
		if (hoPtr->rom->rmReverse!=0)
		{
			if ((j&0x01)!=0)
				accel=1;
			if ((j&0x02)!=0)
				accel=2;
		}
		else
		{
			if ((j&0x01)!=0)
				accel=2;
			if ((j&0x02)!=0)
				accel=1;
		}
		speed=MR_Speed;
		while(true)
		{
			if ((accel&1)!=0)
			{
				// Ralenti
				if (MR_Speed==0)
				{
					if (MR_OkReverse==0) 
						break;
					if ((MR_OldJoy&0x03)!=0)
						break;
					hoPtr->rom->rmReverse^=1;
					dSpeed=rmAccValue;
					if ((hoPtr->hoAdRunHeader->rhFrame->leFlags&LEF_TIMEDMVTS)!=0)
						dSpeed=(int)(((double)dSpeed)*hoPtr->hoAdRunHeader->rh4MvtTimerCoef);
					speed+=dSpeed;
					speed8=speed>>8;
					if (speed8>hoPtr->roc->rcMaxSpeed)
					{
						speed=hoPtr->roc->rcMaxSpeed<<8;
						MR_Speed=speed;
					}
					MR_Speed=speed;
					break;
				}
				dSpeed=rmDecValue;
				if ((hoPtr->hoAdRunHeader->rhFrame->leFlags&LEF_TIMEDMVTS)!=0)
					dSpeed=(int)(((double)dSpeed)*hoPtr->hoAdRunHeader->rh4MvtTimerCoef);
				speed-=dSpeed;
				if (speed<0) 
					speed=0;
				MR_Speed=speed;
			}
			else if ((accel&2)!=0)
			{
				// Accelere
				dSpeed=rmAccValue;
				if ((hoPtr->hoAdRunHeader->rhFrame->leFlags&LEF_TIMEDMVTS)!=0)
					dSpeed=(int)(((double)dSpeed)*hoPtr->hoAdRunHeader->rh4MvtTimerCoef);
				speed+=dSpeed;
				speed8=speed>>8;
				if (speed8>hoPtr->roc->rcMaxSpeed)
				{
					speed=hoPtr->roc->rcMaxSpeed<<8;
					MR_Speed=speed;
				}
				MR_Speed=speed;
			}
			break;
		};
		MR_OldJoy=j;
		
		// Fait les animations
		// ~~~~~~~~~~~~~~~~~~~
		hoPtr->roc->rcSpeed=MR_Speed>>8;
		hoPtr->roc->rcAnim=ANIMID_WALK;
		if (hoPtr->roa!=nil)
			[hoPtr->roa animate];
		
		// Fait le mouvement
		//; ~~~~~~~~~~~~~~~~~
		dir=hoPtr->roc->rcDir;
		if (hoPtr->rom->rmReverse!=0)
		{
			dir+=16;
			dir&=31;
		}
		if ([self newMake_Move:hoPtr->roc->rcSpeed withDir:dir]==NO) 
			return;			// Fait le mouvement
		if (bMoveChanged)
		{
			return;
		}		
	}
	
	// Fait rebondir
	// ~~~~~~~~~~~~~
	do
	{
		if (MR_Bounce==0) 
			break;					//; Passe en mode rebond?
		if (hoPtr->hoAdRunHeader->rhVBLObjet==0) 
			break;						//; Encore des VBL?
		speed=MR_Speed;
		speed-=rmDecValue;
		if (speed<=0)
		{
			MR_Speed=0;							//; Stop!
			MR_Bounce=0;
			break;
		}
		MR_Speed=speed;							//; Et stocke
		speed>>=8;
		dir=hoPtr->roc->rcDir;								//; Direction du rebond
		if (MR_Bounce!=0)
		{	
			dir+=16;
			dir&=31;
		}
		if ([self newMake_Move:speed withDir:dir]==NO)
		{
			break;
		}
		if (bMoveChanged)
		{
			break;
		}
	} while(YES);
}

-(void)stop
{
	MR_Bounce=0;
	MR_Speed=0;	
	hoPtr->rom->rmReverse=0;								//; Plus de marche arriere
	if (rmCollisionCount==hoPtr->hoAdRunHeader->rh3CollisionCount)		//; C'est le sprite courant?
	{
		// Le sprite entre dans quelque chose...
		[self mv_Approach:(rmOpt&MVOPT_8DIR_STICK)!=0];								//; On approche au maximum, sans toucher a la vitesse
		hoPtr->rom->rmMoveFlag=YES;
	}
}

-(void)start
{
	rmStopSpeed=0;
	hoPtr->rom->rmMoveFlag=YES;					// Le flag!        
}

-(void)bounce
{
	if (rmCollisionCount==hoPtr->hoAdRunHeader->rh3CollisionCount)		//; C'est le sprite courant?
	{
		[self mv_Approach:(rmOpt&MVOPT_8DIR_STICK)!=0];
	}
	if (hoPtr->hoAdRunHeader->rhLoopCount!=MR_LastBounce)				//; Un seul bounce a chaque cycle
	{
		MR_Bounce=hoPtr->rom->rmReverse;				//; Initialise le rebond dans la bonne direction
		hoPtr->rom->rmReverse=0;									//; Plus de marche arriere
		MR_Bounce++;
		if (MR_Bounce>=16)							//; Securite si bloque
		{
			[self stop];
			return;
		}
		hoPtr->rom->rmMoveFlag=YES;
		hoPtr->rom->rmBouncing=YES;								//; Pour les evenements
	}	
}

-(void)setSpeed:(int)speed
{
	if (speed<0) speed=0;
	if (speed>250) speed=250;
	if (speed>hoPtr->roc->rcMaxSpeed)
	{
		speed=hoPtr->roc->rcMaxSpeed;
	}
	speed<<=8; 
	MR_Speed=speed;
	hoPtr->rom->rmMoveFlag=YES;        
}

-(void)setMaxSpeed:(int)speed
{
	if (speed<0) speed=0;
	if (speed>250) speed=250;
	hoPtr->roc->rcMaxSpeed=speed;
	speed<<=8;
	if (MR_Speed>speed)
	{
		MR_Speed=speed;
	}
	hoPtr->rom->rmMoveFlag=YES;
}

-(void)setRotSpeed:(int)speed
{
	MR_RotSpeed=speed;
}

-(void)setXPosition:(int)x
{        
	if (hoPtr->hoX!=x)
	{
	    hoPtr->hoX=x;
	    hoPtr->rom->rmMoveFlag=YES;
	    hoPtr->roc->rcChanged=YES;
	    hoPtr->roc->rcCheckCollides=YES;					//; Force la detection de collision
	}
}

-(void)setYPosition:(int)y
{
	if (hoPtr->hoY!=y)
	{
	    hoPtr->hoY=y;
	    hoPtr->rom->rmMoveFlag=YES;
	    hoPtr->roc->rcChanged=YES;
	    hoPtr->roc->rcCheckCollides=YES;					//; Force la detection de collision
	}
}

-(void)setDir:(int)dir
{
	MR_RotPos=dir;
	hoPtr->roc->rcDir=dir&MR_RotMask;
}

@end
