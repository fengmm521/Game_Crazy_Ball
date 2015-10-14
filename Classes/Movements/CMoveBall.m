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
// CMOVEBALL : Mouvement balle
//
//----------------------------------------------------------------------------------
#import "CMoveBall.h"
#import "CMove.h"
#import "CObject.h"
#import "CMoveDef.h"
#import "CRAni.h"
#import "CRMvt.h"
#import "CRCom.h"
#import "CRun.h"
#import "CMoveDefBall.h"
#import "CEventProgram.h"
#import "CRunFrame.h"
#import "CAnim.h"

static short rebond_List[16][32]=
{
{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31},            // 0000 - bad
{30,31,0,1,4,3,2,1,0,31,30,29,28,27,26,25,24,23,22,21,20,24,25,26,27,27,28,28,28,28,29,29},         // 0001 - HG
{24,23,22,21,20,19,18,17,16,15,14,13,12,16,17,18,19,19,20,20,20,20,21,21,22,23,24,25,28,27,26,25},  // 0010 - HD
{0,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,20,21,22,22,23,24,24,24,24,25,26,27,28,29,30},   // 0011 - H
{8,7,6,5,4,8,9,10,11,11,12,12,12,12,13,13,14,15,16,17,20,19,18,17,16,15,14,13,12,11,10,9},          // 0100 - BD
{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31},            // 0101 - bad
{16,15,14,13,12,11,10,9,8,12,13,14,15,15,16,16,16,16,17,17,18,19,20,21,24,23,22,21,20,19,18,17},    // 0110 - D
{16,17,18,19,20,21,22,23,24,23,22,21,20,19,18,17,16,17,18,19,20,21,22,23,24,23,22,21,20,19,18,17},  // 0111 - CHD
{3,3,4,4,4,4,5,5,6,7,8,9,12,11,10,9,8,7,6,5,4,3,2,1,0,31,30,29,	28,0,1,2},                          // 1000 - BG
{0,0,1,1,2,3,4,5,8,7,6,5,4,3,2,1,0,31,30,29,28,27,26,25,24,28,29,30,31,31,0,0},                     // 1001 - G
{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31},            // 1010 - bad
{0,31,30,29,28,27,26,25,24,25,26,27,28,29,30,31,0,31,30,29,28,27,25,25,24,25,26,27,28,29,30,31},    // 1011 - CHG
{0,4,5,6,7,7,8,8,8,8,9,9,10,11,12,13,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1},                       // 1100 - B
{0,1,2,3,4,5,6,7,8,7,6,5,4,3,2,1,0,1,2,3,4,5,6,7,8,7,6,5,4,3,2,1},                                  // 1101 - CBG
{16,15,14,13,12,11,10,9,8,9,10,11,12,13,14,15,16,15,14,13,12,11,10,9,8,9,10,11,12,13,14,15},        // 1110 - CBD
{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31},            // 1111 - bad
};

static int MaskBounce[]={0xFFFFFFFC, 0xFFFFFFFE, 0xFFFFFFFF};
static int PlusAngles[]={-4,4,-2,2,-1,1};
static int PlusAnglesTry[]={-4,4,-4,4,-4,4};

extern int Cosinus32[];
extern int Sinus32[];

@implementation CMoveBall

-(void)initMovement:(CObject*)ho withMoveDef:(CMoveDef*)mvPtr
{
	hoPtr=ho;
	CMoveDefBall* mbPtr=(CMoveDefBall*)mvPtr;
	
	hoPtr->hoCalculX=0;
	hoPtr->hoCalculY=0;
	hoPtr->roc->rcSpeed=mbPtr->mbSpeed;
	hoPtr->roc->rcMaxSpeed=mbPtr->mbSpeed;
	hoPtr->roc->rcMinSpeed=mbPtr->mbSpeed;
	MB_Speed=mbPtr->mbSpeed<<8;
	int dec=mbPtr->mbDecelerate;						//; Deceleration
	if (dec!=0)
	{
		dec=[self getAccelerator:dec];
		hoPtr->roc->rcMinSpeed=0;							//; Vitesse mini= 0
	}
	rmDecValue=dec;
	MB_Bounce=mbPtr->mbBounce;				//; Randomizator
	MB_Angles=mbPtr->mbAngles;				//; Securite 0.100
	MB_MaskBounce=MaskBounce[MB_Angles];
	MB_Blocked=NO;
	MB_LastBounce=-1;
	
	MB_Securite=(100-mbPtr->mbSecurity)/8;
	MB_SecuCpt=MB_Securite;
	[self moveAtStart:mvPtr];
	hoPtr->roc->rcChanged=YES;	
}    

-(void)move
{
	hoPtr->rom->rmBouncing=NO;
	hoPtr->hoAdRunHeader->rhVBLObjet=1;
	
	// Faire les animations
	// ~~~~~~~~~~~~~~~~~~~~
	hoPtr->roc->rcAnim=ANIMID_WALK;
	if (hoPtr->roa!=nil)
		[hoPtr->roa animate];
	
	// Ralentir la balle?
	// ~~~~~~~~~~~~~~~~~
	if (rmDecValue!=0)
	{
		int speed=MB_Speed;
		if (speed>0)
		{
			int dSpeed=rmDecValue;
			if ((hoPtr->hoAdRunHeader->rhFrame->leFlags&LEF_TIMEDMVTS)!=0)
				dSpeed=(int)(((double)dSpeed)*hoPtr->hoAdRunHeader->rh4MvtTimerCoef);
			speed-=dSpeed;
			if (speed<0) 
				speed=0;
			MB_Speed=speed;
			speed>>=8;
			hoPtr->roc->rcSpeed=speed;
		}
	}
	
	// Va bouger la balle
	// ~~~~~~~~~~~~~~~~~~
	[self newMake_Move:hoPtr->roc->rcSpeed withDir:hoPtr->roc->rcDir];
}

-(void)stop
{
	if (rmStopSpeed==0)
	{
		rmStopSpeed=hoPtr->roc->rcSpeed|0x8000;
		hoPtr->roc->rcSpeed=0;
		MB_Speed=0;
		hoPtr->rom->rmMoveFlag=YES;
	}
}

-(void)start
{
	int speed=rmStopSpeed;
	if (speed!=0)
	{
		speed&=0x7FFF;
		hoPtr->roc->rcSpeed=speed;
		MB_Speed=speed<<8;
		rmStopSpeed=0;
		hoPtr->rom->rmMoveFlag=YES;
	}
}

-(void)bounce
{
	if (rmStopSpeed!=0)
		return;
	
	// Un seul BOUNCE a chaque cycle...
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (hoPtr->hoAdRunHeader->rhLoopCount==MB_LastBounce) 
		return;
	MB_LastBounce=hoPtr->hoAdRunHeader->rhLoopCount;
	
	// Si sprite courant, le positionne tout contre l'obstacle
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (rmCollisionCount==hoPtr->hoAdRunHeader->rh3CollisionCount)	//; C'est le sprite courant?
	{
		[self mb_Approach:MB_Blocked];
	}
	
	// Essaie de trouver la forme de l'obstacle >>> quatre essais autour de la balle
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	int x=hoPtr->hoX;
	int y=hoPtr->hoY;
	int rebond=0;
	x-=8;
	y-=8;
	if ([self tst_Position:x withY:y andFlag:MB_Blocked]==NO)
		rebond|=0x01;
	x+=16;
	if ([self tst_Position:x withY:y andFlag:MB_Blocked]==NO)
		rebond|=0x02;
	y+=16;
	if ([self tst_Position:x withY:y andFlag:MB_Blocked]==NO)
		rebond|=0x04;
	x-=16;
	if ([self tst_Position:x withY:y andFlag:MB_Blocked]==NO)
		rebond|=0x08;
	
	// Prend la bonne table de rebond
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	int dir=rebond_List[rebond][hoPtr->roc->rcDir];
	dir&=MB_MaskBounce;
	if (![self mvb_Test:dir]) 			//; On peut aller?
	{
		// Essaye de trouver une direction approchante...
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		int angles=PlusAnglesTry[MB_Angles*2+1];	//; Nombre d'angles
		int angles2=angles;
		BOOL bFlag=false;
		do 
		{
			dir-=angles;								//; Essaie dans une direction
			dir&=31;
			if ([self mvb_Test:dir]) 
			{
				bFlag=YES;
				break;
			}
			dir+=2*angles;								//; Essaie dans l'autre
			dir&=31;
			if ([self mvb_Test:dir]) 
			{
				bFlag=YES;
				break;
			}
			dir-=angles;
			dir&=31;
			angles+=angles2;							//; Un cran plus loin..
		} while(angles<=16);
		
		if (bFlag==NO)
		{
			// Ya rien qui marche: re-essaye avec diverses options
			// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			MB_Blocked=YES;
			hoPtr->roc->rcDir=[hoPtr->hoAdRunHeader random:(short)32]&MB_MaskBounce;
			hoPtr->rom->rmBouncing=YES;
			hoPtr->rom->rmMoveFlag=YES;
			return;
		}
	}
	
	// Rajoute un peu de hasard au rebond
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	MB_Blocked=NO;
	hoPtr->roc->rcDir=dir;
	int rnd=[hoPtr->hoAdRunHeader random:(short)100];
	if (rnd<MB_Bounce)						//; Si > a setup, on fait pas
	{
		rnd>>=2;										//; /4= Nombre d'angles
		if (rnd<25)
		{
			rnd-=12;
			rnd&=31;
			rnd&=MB_MaskBounce;
			if ([self mvb_Test:rnd])					//; Va essayer
			{
				hoPtr->roc->rcDir=rnd;					//; C'est bon, l'angle idiot!
				hoPtr->rom->rmBouncing=YES;
				hoPtr->rom->rmMoveFlag=YES;
				return;
			}
		}
	}
	
	// Securite pour les mouvements droits: les detourne au bout d'un moment
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	dir=hoPtr->roc->rcDir&0x0007;							//; Un direction droite? (0-8-16-24)
	if (MB_SecuCpt!=12)							// 12, valeur maximale
	{
		if (dir==0)
		{
			MB_SecuCpt--;
			if (MB_SecuCpt<0)
			{
				// Additionne un angle a droite ou a gauche
				dir=hoPtr->roc->rcDir+PlusAngles[[hoPtr->hoAdRunHeader random:(short)2]+MB_Angles*2];
				dir &= 31;
				if ([self mvb_Test:dir])
				{
					hoPtr->roc->rcDir=dir;					//; C'est bon, angle change
					MB_SecuCpt=MB_Securite;
				}
			}
		}
		else
		{
			MB_SecuCpt=MB_Securite;
		}
	}
	hoPtr->rom->rmBouncing=YES;
	hoPtr->rom->rmMoveFlag=YES;
}

// Teste une position de la balle
// AX=direction d'essai
// ----------------------------------------------
-(BOOL)mvb_Test:(int)dir
{
	int calculX=hoPtr->hoX<<16|(hoPtr->hoCalculX&0x0000FFFF);
	int calculY=hoPtr->hoY<<16|(hoPtr->hoCalculY&0x0000FFFF);
	int x=(Cosinus32[dir]<<11)+calculX;
	int y=(Sinus32[dir]<<11)+calculY;
	x=(x>>16)&0xFFFF;
	y=(y>>16)&0xFFFF;
	return [self tst_Position:x withY:y andFlag:NO];
}

-(void)setSpeed:(int)speed
{
	if (speed<0) 
		speed=0;
	if (speed>250) 
		speed=250;
	hoPtr->roc->rcSpeed=speed;
	MB_Speed=speed<<8;
	rmStopSpeed=0;						//; Demarre l'objet
	hoPtr->rom->rmMoveFlag=YES;
}

-(void)setMaxSpeed:(int)speed
{
	[self setSpeed:speed];
}

-(void)reverse
{        
	if (rmStopSpeed==0)
	{
		hoPtr->rom->rmMoveFlag=YES;
		hoPtr->roc->rcDir+=16;
		hoPtr->roc->rcDir&=31;
	}
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

@end
