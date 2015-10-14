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
// CMOVEBULLET : mouvement shoot
//
//----------------------------------------------------------------------------------
#import "CMoveBullet.h"
#import "CMove.h"
#import "CObject.h"
#import "CMoveDef.h"
#import "CRAni.h"
#import "CRMvt.h"
#import "CRCom.h"
#import "CRun.h"
#import "CEventProgram.h"
#import "CRunFrame.h"
#import "CAnim.h"
#import "CSprite.h"
#import "CRSpr.h"
#import "CRAni.h"
#import "CAnim.h"

extern BOOL bMoveChanged;
@implementation CMoveBullet

-(void)initMovement:(CObject*)ho withMoveDef:(CMoveDef*)mvPtr
{
	hoPtr=ho;
	if (hoPtr->roc->rcSprite!=nil)						// Est-il active?
	{
	    [hoPtr->roc->rcSprite setSpriteColFlag:0];		//; Pas dans les collisions
	}
	if ( hoPtr->ros!=nil )
	{
	    hoPtr->ros->rsFlags&=~RSFLAG_VISIBLE;
	    [hoPtr->ros obHide];									//; Cache pour le moment
	}
	MBul_Wait=YES;
    MBul_Body = nil;
    MBul_MBase = nil;
	hoPtr->hoCalculX=0;
	hoPtr->hoCalculY=0;
	if (hoPtr->roa!=nil)
	{
	    [hoPtr->roa init_Animation:ANIMID_WALK];
	}
	hoPtr->roc->rcSpeed=0;
	hoPtr->roc->rcCheckCollides=YES;			//; Force la detection de collision
	hoPtr->roc->rcChanged=YES;
}

-(void)init2:(CObject*)parent
{
	hoPtr->roc->rcMaxSpeed=hoPtr->roc->rcSpeed;
	hoPtr->roc->rcMinSpeed=hoPtr->roc->rcSpeed;				
	MBul_ShootObject=parent;			// Met l'objet source	
}
-(void)kill
{
    if (MBul_Body != nil)
    {
        hoPtr->hoAdRunHeader->rh4Box2DBase->pDestroyBody(hoPtr->hoAdRunHeader->rh4Box2DBase, MBul_Body);
        MBul_Body = nil;
    }
    if (MBul_MBase != nil)
    {
        delete MBul_MBase;
        MBul_MBase = nil;
    }
}
-(void)move
{
	if (MBul_Wait)
	{
	    // Attend la fin du mouvement d'origine
	    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	    if (MBul_ShootObject->roa!=nil)
	    {
			if (MBul_ShootObject->roa->raAnimOn==ANIMID_SHOOT) 
				return;
	    }
	    [self startBullet];
	}
	
	// Fait fonctionner la balle
	// ~~~~~~~~~~~~~~~~~~~~~~~~~
	if (hoPtr->roa!=nil)
	{
		[hoPtr->roa animate];
	}
	if (MBul_Body!=nil)
	{
		LPRDATABASE pBase=(LPRDATABASE)hoPtr->hoAdRunHeader->rh4Box2DBase;
        
		int x, y;
		float angle;
		pBase->pGetBodyPosition(pBase, MBul_Body, &x, &y, &angle);
		hoPtr->hoX=x;
		hoPtr->hoY=y;
        hoPtr->roc->rcAngle = angle;
        hoPtr->roc->rcDir = 0;
		hoPtr->roc->rcChanged=YES;
	}
	else
    {
        [self newMake_Move:hoPtr->roc->rcSpeed withDir:hoPtr->roc->rcDir];
        if (bMoveChanged)
            return;
    }
	
	// Verifie que la balle ne sort pas du terrain (assez loin des bords!)
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (hoPtr->hoX<-64 || hoPtr->hoX>hoPtr->hoAdRunHeader->rhLevelSx+64 || hoPtr->hoY<-64 || hoPtr->hoY>hoPtr->hoAdRunHeader->rhLevelSy+64)
	{
	    // Detruit la balle, sans explosion!
	    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	    hoPtr->hoCallRoutine=NO;
	    [hoPtr->hoAdRunHeader destroy_Add:hoPtr->hoNumber];
	}	
	if (hoPtr->roc->rcCheckCollides)			//; Faut-il tester les collisions?
	{
		hoPtr->roc->rcCheckCollides=NO;		//; Va tester une fois!
		[hoPtr->hoAdRunHeader newHandle_Collisions:hoPtr];
	}        
}

-(void)startBullet
{
	// Fait demarrer la balle
	// ~~~~~~~~~~~~~~~~~~~~~~
	if (hoPtr->roc->rcSprite!=nil)				//; Est-il active?
	{
	    [hoPtr->roc->rcSprite setSpriteColFlag:SF_RAMBO];
	}
	if ( hoPtr->ros!=nil )
	{
	    hoPtr->ros->rsFlags|=RSFLAG_VISIBLE;
	    [hoPtr->ros obShow];					//; Plus cache
	}
    
    CRun* rhPtr = hoPtr->hoAdRunHeader;
    if (rhPtr->rh4Box2DBase!=nil)
    {
        CObject* hoParent=MBul_ShootObject;
        CRunMBase* pMovement=[rhPtr GetMBase:hoParent];
		if (pMovement!=nil)
		{
			LPRDATABASE pBase=(LPRDATABASE)rhPtr->rh4Box2DBase;
			MBul_MBase = new CRunMBase(pBase, hoPtr, MTYPE_FAKEOBJECT);
			MBul_MBase->m_identifier=pBase->identifier;
			MBul_Body=pBase->pCreateBullet(pBase, pMovement->m_currentAngle, ((float)hoPtr->roc->rcSpeed)/250.f*50.0f, MBul_MBase);
			MBul_MBase->m_body = MBul_Body;
            if (MBul_Body==nil)
			{
				delete MBul_MBase;
				MBul_MBase=nil;
			}
		}
    }
	MBul_Wait=NO; 					//; On y va!
	MBul_ShootObject=nil;
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
