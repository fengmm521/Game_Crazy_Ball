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
// CRMVT : Donnees de base d'un mouvement
//
//----------------------------------------------------------------------------------
#import "CRMvt.h"
#import "CObject.h"
#import "CObjectCommon.h"
#import "CCreateObjectInfo.h"
#import "CObjInfo.h"
#import "CMoveDef.h"
#import "CRun.h"
#import "CMoveStatic.h"
#import "CMoveBall.h"
#import "CMoveRace.h"
#import "CMoveBullet.h"
#import "CMoveDisappear.h"
#import "CMoveGeneric.h"
#import "CMovePlatform.h"
#import "CRCom.h"
#import "CMove.h"
#import "CMoveDefList.h"
#import "CMoveMouse.h"
#import "CMovePath.h"
#import "CMoveDefExtension.h"
#import "CRunMvtExtension.h"
#import "CMoveExtension.h"

//F01
#import "CRunMvtspaceship.h"
#import "CRunMvtpinball.h"
#import "CRunMvtclickteam_circular.h"
#import "CRunMvtclickteam_invaders.h"
#import "CRunMvtclickteam_presentation.h"
#import "CRunMvtclickteam_regpolygon.h"
#import "CRunMvtclickteam_simple_ellipse.h"
#import "CRunMvtclickteam_sinewave.h"
#import "CRunMvtclickteam_vector.h"
#import "CRunMvtclickteam_dragdrop.h"
#import "CRunMvtinandout.h"
#import "CRunMvtbox2d8directions.h"
#import "CRunMvtbox2daxial.h"
#import "CRunMvtbox2dbackground.h"
#import "CRunMvtbox2dbouncingball.h"
#import "CRunMvtbox2dplatform.h"
#import "CRunMvtbox2dracecar.h"
#import "CRunMvtbox2dspaceship.h"
#import "CRunMvtbox2dspring.h"
#import "CRunMvtbox2dstatic.h"
//F01END

@implementation CRMvt

-(id)init
{
	rmMovement=nil;
    rmMovementBackup=nil;
    return self;
}

-(void)dealloc
{
	[rmMovement release];
	if(rmMovementBackup != nil)
		[rmMovementBackup release];
	[super dealloc];
}
-(void)initMovement:(int)nMove withObject:(CObject*)hoPtr andOC:(CObjectCommon*)ocPtr andCOB:(CCreateObjectInfo*)cob andNum:(int)forcedType
{
	// Effacement du mouvement precedent
    rmMovementBackup=rmMovement;
	
	// Copie les donnees de base
	// -------------------------
	if (cob != nil)
	{
		hoPtr->roc->rcDir = cob->cobDir;					//; Directions
	}
	rmWrapping = hoPtr->hoOiList->oilWrap;				//; Flag pour wrap
	
	// Initialise les mouvements
	// -------------------------
	CMoveDef* mvPtr = nil;
	hoPtr->roc->rcMovementType = -1;
	if (ocPtr->ocMovements != nil)
	{
		if (nMove < ocPtr->ocMovements->nMovements)
		{
			mvPtr = ocPtr->ocMovements->moveList[nMove];
			rmMvtNum = nMove;
			if (forcedType == -1)
			{
				forcedType = mvPtr->mvType;
			}
			hoPtr->roc->rcMovementType = forcedType;					//; Le type
			switch (forcedType)
			{
                    // MVTYPE_STATIC
				case 0:
					rmMovement = [[CMoveStatic alloc] init];
					break;
                    // MVTYPE_MOUSE
				case 1:
					rmMovement = [[CMoveMouse alloc] init];
					break;
                    // MVTYPE_RACE
				case 2:
					rmMovement = [[CMoveRace alloc] init];
					break;
                    // MVTYPE_GENERIC
				case 3:
					rmMovement = [[CMoveGeneric alloc] init];
					break;
                    // MVTYPE_BALL
				case 4:
					rmMovement = [[CMoveBall alloc] init];
					break;
                    // MVTYPE_TAPED
				case 5:
					rmMovement = [[CMovePath alloc] init];
					break;
                    // MVTYPE_PLATFORM
				case 9:
					rmMovement = [[CMovePlatform alloc] init];
					break;
                    // MVTYPE_EXT				
				case 14:
					rmMovement = [self loadMvtExtension:hoPtr withDef:(CMoveDefExtension*)mvPtr];
					if (rmMovement == nil)
					{
						rmMovement = [[CMoveStatic alloc] init];
					}
					break;
			}
			hoPtr->roc->rcDir = [self dirAtStart:hoPtr withDirAtStart:mvPtr->mvDirAtStart andDir:hoPtr->roc->rcDir];			//; La direction par defaut
			[rmMovement initMovement:hoPtr withMoveDef:mvPtr];                              //; Init des mouvements
		}
	}
	
	if (hoPtr->roc->rcMovementType == -1)
	{
		hoPtr->roc->rcMovementType = 0;
		rmMovement = [[CMoveStatic alloc] init];
		[rmMovement initMovement:hoPtr withMoveDef:nil];
		hoPtr->roc->rcDir = 0;
	}
}

-(CMove*)loadMvtExtension:(CObject*)hoPtr withDef:(CMoveDefExtension*)mvDef
{	    	
	CRunMvtExtension* object=nil;
	
//F02			
	if ([mvDef->moduleName caseInsensitiveCompare:@"spaceship"]==0)
	{
		object=[[CRunMvtspaceship alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"pinball"]==0)
	{
		object=[[CRunMvtpinball alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"clickteam-circular"]==0)
	{
		object=[[CRunMvtclickteam_circular alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"clickteam-invaders"]==0)
	{
		object=[[CRunMvtclickteam_invaders alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"clickteam-presentation"]==0)
	{
		object=[[CRunMvtclickteam_presentation alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"clickteam-regpolygon"]==0)
	{
		object=[[CRunMvtclickteam_regpolygon alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"clickteam-simple_ellipse"]==0)
	{
		object=[[CRunMvtclickteam_simple_ellipse alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"clickteam-sinewave"]==0)
	{
		object=[[CRunMvtclickteam_sinewave alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"clickteam-vector"]==0)
	{
		object=[[CRunMvtclickteam_vector alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"clickteam-dragdrop"]==0)
	{
		object=[[CRunMvtclickteam_dragdrop alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"inandout"]==0)
	{
		object=[[CRunMvtinandout alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"box2d8directions"]==0)
	{
		object=[[CRunMvtbox2d8directions alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"box2daxial"]==0)
	{
		object=[[CRunMvtbox2daxial alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"box2dbackground"]==0)
	{
		object=[[CRunMvtbox2dbackground alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"inandout"]==0)
	{
		object=[[CRunMvtinandout alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"box2dbouncingball"]==0)
	{
		object=[[CRunMvtbox2dbouncingball alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"box2dplatform"]==0)
	{
		object=[[CRunMvtbox2dplatform alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"box2dracecar"]==0)
	{
		object=[[CRunMvtbox2dracecar alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"box2dspaceship"]==0)
	{
		object=[[CRunMvtbox2dspaceship alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"box2dspring"]==0)
	{
		object=[[CRunMvtbox2dspring alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"box2dstatic"]==0)
	{
		object=[[CRunMvtbox2dstatic alloc] init];
	}
	if ([mvDef->moduleName caseInsensitiveCompare:@"inandout"]==0)
	{
		object=[[CRunMvtinandout alloc] init];
	}
//F02END
	
	if (object!=nil)
	{
		[object setObject:hoPtr];
		CMoveExtension* mvExt=[[CMoveExtension alloc] initWithObject:object];
		return mvExt;
	}
	return nil;				
}

-(void)initSimple:(CObject*)hoPtr withType:(int)forcedType andFlag:(BOOL)bRestore
{
    rmMovementBackup=rmMovement;
	hoPtr->roc->rcMovementType = forcedType;					//; Le type
	switch (forcedType)
	{
            // MVTYPE_DISAPPEAR
		case 11:
			rmMovement = [[CMoveDisappear alloc] init];
			hoPtr->roc->rcCMoveChanged=YES;
			break;
            // MVTYPE_BULLET
		case 13:
			rmMovement = [[CMoveBullet alloc] init];
			break;
	}
	rmMovement->hoPtr = hoPtr;
	if (bRestore == NO)
	{
		[rmMovement initMovement:hoPtr withMoveDef:nil];                              //; Init des mouvements
	}
}

-(void)kill:(BOOL)bFast
{
    [rmMovement kill];
}

-(void)move
{
	[rmMovement move];
    if (rmMovementBackup!=nil)
    {
        [rmMovementBackup release];
        rmMovementBackup=nil;
    }
}

-(void)nextMovement:(CObject*)hoPtr
{
	CObjectCommon* ocPtr = hoPtr->hoCommon;
	if (ocPtr->ocMovements != nil)
	{
		if (rmMvtNum + 1 < ocPtr->ocMovements->nMovements)
		{
            [self kill:NO];
			[self initMovement:rmMvtNum + 1 withObject:hoPtr andOC:ocPtr andCOB:nil andNum:-1];
            CRunMvtPhysics* pMovement = [hoPtr->hoAdRunHeader GetPhysicMovement:hoPtr];
            if (pMovement != nil)
                pMovement->CreateBody(hoPtr);
		}
	}
}

-(void)previousMovement:(CObject*)hoPtr
{
	CObjectCommon* ocPtr = hoPtr->hoCommon;
	if (ocPtr->ocMovements != nil)
	{
		if (rmMvtNum - 1 >= 0)
		{
            [self kill:NO];
			[self initMovement:rmMvtNum - 1 withObject:hoPtr andOC:ocPtr andCOB:nil andNum:-1];
            CRunMvtPhysics* pMovement = [hoPtr->hoAdRunHeader GetPhysicMovement:hoPtr];
            if (pMovement != nil)
                pMovement->CreateBody(hoPtr);
		}
	}
}

-(void)selectMovement:(CObject*)hoPtr withNumber:(int)mvt
{
	CObjectCommon* ocPtr = hoPtr->hoCommon;
	if (ocPtr->ocMovements != nil)
	{
		if (mvt >= 0 && mvt < ocPtr->ocMovements->nMovements)
		{
            [self kill:NO];
			[self initMovement:mvt withObject:hoPtr andOC:ocPtr andCOB:nil andNum:-1];
            CRunMvtPhysics* pMovement = [hoPtr->hoAdRunHeader GetPhysicMovement:hoPtr];
            if (pMovement != nil)
                pMovement->CreateBody(hoPtr);
		}
	}
}

-(int)dirAtStart:(CObject*)hoPtr withDirAtStart:(int)dirAtStart andDir:(int)dir
{
	if (dir < 0 || dir >= 32)
	{
		// Compte le nombre de directions demandees
		int cpt = 0;
		int das = dirAtStart;
		int das2;
		for (int n = 0; n < 32; n++)
		{
			das2 = das;
			das >>= 1;
			if ((das2 & 1) != 0)
			{
				cpt++;
			}
		}
		
		// Une ou zero direction?
		if (cpt == 0)
		{
			dir = 0;
		}
		else
		{
			// Appelle le hasard pour trouver le bit
			cpt = [hoPtr->hoAdRunHeader random:(short) cpt];
			das = dirAtStart;
			for (dir = 0;; dir++)
			{
				das2 = das;
				das >>= 1;
				if ((das2 & 1) != 0)
				{
					cpt--;
					if (cpt < 0)
					{
						break;
					}
				}
			}
		}
	}
	// Direction trouvee, OUF
	return dir;
}


@end
