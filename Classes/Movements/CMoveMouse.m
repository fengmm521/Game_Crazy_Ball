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
// CMOVEMOUSE : Mouvement souris
//
//----------------------------------------------------------------------------------
#import "CMoveMouse.h"
#import "CMove.h"
#import "CObject.h"
#import "CMoveDef.h"
#import "CRAni.h"
#import "CRMvt.h"
#import "CRCom.h"
#import "CRun.h"
#import "CMoveDefMouse.h"

static int CosSurSin32[] =
{
2599, 0, 844, 31, 479, 30, 312, 29, 210, 28, 137, 27, 78, 26, 25, 25, 0, 24
};

@implementation CMoveMouse

-(void)initMovement:(CObject*)ho withMoveDef:(CMoveDef*)mvPtr
{
	hoPtr=ho;
	
	CMoveDefMouse* mmPtr=(CMoveDefMouse*)mvPtr;
	hoPtr->roc->rcPlayer=mmPtr->mvControl;
	MM_DXMouse=mmPtr->mmDx+hoPtr->hoX;
	MM_DYMouse=mmPtr->mmDy+hoPtr->hoY;
	MM_FXMouse=mmPtr->mmFx+hoPtr->hoX;
	MM_FYMouse=mmPtr->mmFy+hoPtr->hoY;
	rmOpt=mmPtr->mvOpt;
	hoPtr->roc->rcSpeed=0;
	MM_OldSpeed=0;
	MM_Stopped=0;
	hoPtr->roc->rcMinSpeed=0;
	hoPtr->roc->rcMaxSpeed=100;
	[self moveAtStart:mvPtr];
	hoPtr->roc->rcChanged=YES;
}
-(void)move
{
	int newX=hoPtr->hoX;
	int newY=hoPtr->hoY;
	int deltaX, deltaY, flags, speed, dir, index;
	
	if (rmStopSpeed==0) 
	{
		if (hoPtr->hoAdRunHeader->rh2InputMask!=0)      // no input?
		{
			newX=hoPtr->hoAdRunHeader->rh2MouseX;						//; Coordonnee en X
			if (newX<MM_DXMouse)
				newX=MM_DXMouse;
			if (newX>MM_FXMouse)
				newX=MM_FXMouse;
			
			newY=hoPtr->hoAdRunHeader->rh2MouseY;						//; Coordonnee en Y
			if (newY<MM_DYMouse)
				newY=MM_DYMouse;
			if (newY>MM_FYMouse)
				newY=MM_FYMouse;
			
			// Calcul de la pente du mouvement pour les animations
			// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			deltaX=newX-hoPtr->hoX;
			deltaY=newY-hoPtr->hoY;
			flags=0;							//; Flags de signe
			if (deltaX<0)							//; DX negatif?
			{
				deltaX=-deltaX;
				flags|=0x01;
			}
			if (deltaY<0)							//; DY negatif?
			{
				deltaY=-deltaY;
				flags|=0x02;
			}
			speed=(deltaX+deltaY)<<2;			//; Calcul de la vitesse (approximatif)
			if (speed>250) speed=250;
			hoPtr->roc->rcSpeed=speed;
			if (speed!=0) 
			{
				deltaX<<=8;								//; * 256 pour plus de precision
				if (deltaY==0) 
					deltaY=1;
				deltaX/=deltaY;
				for (index=0; ; index+=2)
				{
					if (deltaX>=CosSurSin32[index]) 
						break;
				}		
				dir=CosSurSin32[index+1];			//; Charge la direction
				if ((flags&0x02)!=0)
				{
					dir=-dir+32;						//; R�tablir en Y
					dir&=31;
				}
				if ((flags&0x01)!=0)
				{
					dir-=8;								//; Retablir en X
					dir&=31;
					dir=-dir;
					dir&=31;
					dir+=8;
					dir&=31;
				}
				hoPtr->roc->rcDir=dir;					//; Direction finale
			}
		}
	}
	
	// Appel des animations (temporise la vitesse)
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (hoPtr->roc->rcSpeed!=0)
	{
		MM_Stopped=0;
		MM_OldSpeed=hoPtr->roc->rcSpeed;
	}
	MM_Stopped++;
	if (MM_Stopped>10)
	{
		MM_OldSpeed=0;
	}
	hoPtr->roc->rcSpeed=MM_OldSpeed;
	if (hoPtr->roa!=nil)
		[hoPtr->roa animate];;
	
	// Appel des collisions
	// ~~~~~~~~~~~~~~~~~~~~
	hoPtr->hoX=newX;					//; Les coordonnees
	hoPtr->hoY=newY;
	hoPtr->roc->rcChanged=YES;
	hoPtr->hoAdRunHeader->rh3CollisionCount++;			//; Marque l'objet pour ce cycle
	rmCollisionCount=hoPtr->hoAdRunHeader->rh3CollisionCount;
	[hoPtr->hoAdRunHeader newHandle_Collisions:hoPtr];        
}
-(void)stop
{
	// Pas de STOP si c'est le sprite courant... on contourne les obstacles
	if (rmCollisionCount==hoPtr->hoAdRunHeader->rh3CollisionCount)
	{
		[self mv_Approach:(rmOpt&MVOPT_8DIR_STICK)!=0];
		hoPtr->roc->rcSpeed=0;
		return;
	}
	hoPtr->roc->rcSpeed=0;
	rmStopSpeed=0;
}
-(void)start
{
	rmStopSpeed=0;
	hoPtr->rom->rmMoveFlag=YES;
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
