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
//
//  CMove.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 17/02/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import "CMove.h"
#import "CRun.h"
#import "CObject.h"
#import "CRunFrame.h"
#import "CMoveDef.h"
#import "CEventProgram.h"
#import "CObjInfo.h"
#import "CPoint.h"
#import "CRCom.h"
#import "CRMvt.h"
#import "CArrayList.h"
#import "CColMask.h"
#import "CMoveRace.h"
#import "CMovePlatform.h"
#import "CMoveGeneric.h"
#import "CMoveExtension.h"

int Cosinus32[] =
{
	256, 251, 236, 212, 181, 142, 97, 49,
	0, -49, -97, -142, -181, -212, -236, -251,
	-256, -251, -236, -212, -181, -142, -97, -49,
	0, 49, 97, 142, 181, 212, 236, 251
};
int Sinus32[] =
{
	0, -49, -97, -142, -181, -212, -236, -251,
	-256, -251, -236, -212, -181, -142, -97, -49,
	0, 49, 97, 142, 181, 212, 236, 251,
	256, 251, 236, 212, 181, 142, 97, 49
};
short accelerators[] =
{
	0x0002, 0x0003, 0x0004, 0x0006, 0x0008, 0x000a, 0x000c, 0x0010, 0x0014, 0x0018,
	0x0030, 0x0038, 0x0040, 0x0048, 0x0050, 0x0058, 0x0060, 0x0068, 0x0070, 0x0078,
	0x0090, 0x00A0, 0x00B0, 0x00c0, 0x00d0, 0x00e0, 0x00f0, 0x0100, 0x0110, 0x0120,
	0x0140, 0x0150, 0x0160, 0x0170, 0x0180, 0x0190, 0x01a0, 0x01b0, 0x01c0, 0x01e0,
	0x0200, 0x0220, 0x0230, 0x0250, 0x0270, 0x0280, 0x02a0, 0x02b0, 0x02d0, 0x02e0,
	0x0300, 0x0310, 0x0330, 0x0350, 0x0360, 0x0380, 0x03a0, 0x03b0, 0x03d0, 0x03e0,	
	0x0400, 0x0460, 0x04c0, 0x0520, 0x05a0, 0x0600, 0x0660, 0x06c0, 0x0720, 0x07a0,
	0x0800, 0x08c0, 0x0980, 0x0a80, 0x0b40, 0x0c00, 0x0cc0, 0x0d80, 0x0e80, 0x0f40,
	0x1000, 0x1990, 0x1332, 0x1460, 0x1664, 0x1800, 0x1999, 0x1b32, 0x1cc6, 0x1e64,
	0x2000, 0x266c, 0x2d98, 0x3404, 0x3a70, 0x40dc, 0x4748, 0x4db4, 0x5400, 0x6400,
	0x6400
};
char Joy2Dir[] =
{
	-1, // 0000 Static
	8, // 0001
	24, // 0010
	-1, // 0011 Static
	16, // 0100
	12, // 0101
	20, // 0110
	16, // 0111
	0, // 1000
	4, // 1001
	28, // 1010
	0, // 1011
	-1, // 1100 Static
	8, // 1101
	24, // 1110
	-1				// 1111 Static
};
int CosSurSin32[] =
{
	2599, 0, 844, 31, 479, 30, 312, 29, 210, 28, 137, 27, 78, 26, 25, 25, 0, 24
};
int mvap_TableDirs[] =
{
	0, -2, 0, 2, 0, -4, 0, 4, 0, -8, 0, 8, -4, 0, -8, 0, 0, 0, // 0
	-2, -2, 2, 2, -4, -4, 4, 4, -8, -8, 8, 8, -4, 4, -8, 8, 0, 0, // 16
	-2, 0, 2, 0, -4, 0, 4, 0, -8, 0, 8, 0, 0, 4, 0, 8, 0, 0, // 32
	-2, 2, 2, -2, -4, 4, 4, -4, -8, 8, 8, -8, 4, 4, 8, 8, 0, 0, // 48
	0, 2, 0, -2, 0, 4, 0, -4, 0, 8, 0, -8, 4, 0, 8, 0, 0, 0, // 64
	2, 2, -2, -2, 4, 4, -4, -4, 8, 8, -8, -8, 4, -4, 8, -8, 0, 0, // 80
	2, 0, -2, 0, 4, 0, -4, 0, 8, 0, -8, 0, 0, -4, 0, -8, 0, 0, // 96
	2, -2, -2, 2, 4, -4, -4, 4, 8, -8, -8, 8, -4, -4, -8, -8, 0, 0	    // 112
};


@implementation CMove

-(void)kill
{    
}
-(BOOL)newMake_Move:(int)speed withDir:(int)angle
{
	hoPtr->hoAdRunHeader->rh3CollisionCount++;			//; Marque l'objet pour ce cycle
	rmCollisionCount = hoPtr->hoAdRunHeader->rh3CollisionCount;
	hoPtr->rom->rmMoveFlag = NO;
	
	// Mode de gestion du mouvement
	// ----------------------------
	if (speed == 0)
	{
		// On ne bouge pas: appel des collisions directes!
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		[hoPtr->hoAdRunHeader newHandle_Collisions:hoPtr];		//; Appel les collisions
		return NO;
	}
	
	// Fait le mouvement?
	// ~~~~~~~~~~~~~~~~~~
	int64_t x, y;
	int speedShift;
	if ((hoPtr->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
	{
		speedShift = (int) (((double) speed) * hoPtr->hoAdRunHeader->rh4MvtTimerCoef * 32.0);
	}
	else
	{
		speedShift = speed << 5;
	}
	while (speedShift > 0x0800)
	{
		x = (int64_t)hoPtr->hoX << 16 | (hoPtr->hoCalculX & 0x0000FFFF);
		y = (int64_t)hoPtr->hoY << 16 | (hoPtr->hoCalculY & 0x0000FFFF);
		x += (int64_t)Cosinus32[angle] * 0x0800;
		y += (int64_t)Sinus32[angle] * 0x0800;
		hoPtr->hoCalculX = x & 0x0000FFFF;
		hoPtr->hoX = (int) (x >> 16);
		hoPtr->hoCalculY = y & 0x0000FFFF;
		hoPtr->hoY = (int) (y >> 16);

		if ([hoPtr->hoAdRunHeader newHandle_Collisions:hoPtr])
		{
			return YES;									// CMove changed!
		}
		if (hoPtr->rom->rmMoveFlag)
		{
			break;
		}
		
		speedShift -= 0x0800;
	}
	if (!hoPtr->rom->rmMoveFlag)
	{
		x = (int64_t)hoPtr->hoX << 16 | (hoPtr->hoCalculX & 0x0000FFFF);
		y = (int64_t)hoPtr->hoY << 16 | (hoPtr->hoCalculY & 0x0000FFFF);
		x += (int64_t)Cosinus32[angle] * speedShift;
		y += (int64_t)Sinus32[angle] * speedShift;
		hoPtr->hoCalculX = x & 0x0000FFFF;
		hoPtr->hoX = (int) (x >> 16);
		hoPtr->hoCalculY = y & 0x0000FFFF;
		hoPtr->hoY = (int) (y >> 16);
		
		if ([hoPtr->hoAdRunHeader newHandle_Collisions:hoPtr])
		{
			return YES;									// CMove changed
		}
	}
	hoPtr->roc->rcChanged = YES;                                             //; Sprite bouge!
	if (!hoPtr->rom->rmMoveFlag)
	{
		hoPtr->hoAdRunHeader->rhVBLObjet = 0;			//; Stocke le VBL actuel
	}
	return hoPtr->rom->rmMoveFlag;
}

-(void)moveAtStart:(CMoveDef*)mvPtr
{
	// FRA: verifier!
	if (mvPtr->mvMoveAtStart == 0)
	{
		[self stop];
	}
}

-(int)getAccelerator:(int)acceleration
{
	if (acceleration <= 100)
	{
		return accelerators[acceleration];
	}
	return acceleration << 8;
}

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// POSITIONNE UN SPRITE EN TRAIN DE BOUGER TOUT CONTRE UN OBSTACLE, SI NECESSAIRE
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
-(void)mv_Approach:(BOOL)bStickToObjects
{
	if (bStickToObjects)
	{
		[self mb_Approach:NO];
		return;
	}
	
	BOOL flag = NO;	
	switch (hoPtr->hoAdRunHeader->rhEvtProg->rhCurCode & 0xFFFF0000)
	{
		case (-12 << 16):         // CNDL_EXTOUTPLAYFIELD:
			{
				// --------------------------------------------------------------------------------
				// Sortie du terrain...
				// --------------------------------------------------------------------------------
				// Recadre le sprite dans le terrain
				// ---------------------------------
				int x = hoPtr->hoX - hoPtr->hoImgXSpot;
				int y = hoPtr->hoY - hoPtr->hoImgYSpot;
				int dir = [hoPtr->hoAdRunHeader quadran_Out:x withY1:y andX2:x + hoPtr->hoImgWidth andY2:y + hoPtr->hoImgHeight];
				x = hoPtr->hoX;
				y = hoPtr->hoY;
				if ((dir & BORDER_LEFT) != 0)
				{
					x = hoPtr->hoImgXSpot;
				}
				if ((dir & BORDER_RIGHT) != 0)
				{
					x = hoPtr->hoAdRunHeader->rhLevelSx - hoPtr->hoImgWidth + hoPtr->hoImgXSpot;
				}
				if ((dir & BORDER_TOP) != 0)
				{
					y = hoPtr->hoImgYSpot;
				}
				if ((dir & BORDER_BOTTOM) != 0)
				{
					y = hoPtr->hoAdRunHeader->rhLevelSy - hoPtr->hoImgHeight + hoPtr->hoImgYSpot;
				}
				hoPtr->hoX = x;
				hoPtr->hoY = y;
			}
			return;
		case (-13 << 16):	    // CNDL_EXTCOLBACK:
		case (-14 << 16):	    // CNDL_EXTCOLLISION:
			{
				int index = (hoPtr->roc->rcDir >> 2)*18;
				do
				{
					if ([self tst_Position:hoPtr->hoX + mvap_TableDirs[index] withY:hoPtr->hoY + mvap_TableDirs[index + 1] andFlag:flag])
					{
						// Positionne le sprite au plus pres de la position
						// ------------------------------------------------
						
						hoPtr->hoX += mvap_TableDirs[index];
						hoPtr->hoY += mvap_TableDirs[index + 1];
						return;
					}
					index += 2;
				} while (mvap_TableDirs[index] != 0 || mvap_TableDirs[index + 1] != 0);
				
				// On arrive pas : ancienne position / ancienne animation!
				// -------------------------------------------------------
				if (flag == NO)
				{
					hoPtr->hoX = hoPtr->roc->rcOldX;
					hoPtr->hoY = hoPtr->roc->rcOldY;
					if (hoPtr->roc->rcOldImage>=0)
					{
						hoPtr->roc->rcImage = hoPtr->roc->rcOldImage;
					}
					hoPtr->roc->rcAngle = hoPtr->roc->rcOldAngle;
					return;
				}
			}
			break;
		default:
			break;
	}
}

-(void)mb_Approach:(BOOL)flag
{
	switch (hoPtr->hoAdRunHeader->rhEvtProg->rhCurCode & 0xFFFF0000)
	{
		case (-12 << 16):         // CNDL_EXTOUTPLAYFIELD:
			{
				// --------------------------------------------------------------------------------
				// Sortie du terrain...
				// --------------------------------------------------------------------------------
				// Recadre le sprite dans le terrain
				// ---------------------------------
				int x = hoPtr->hoX - hoPtr->hoImgXSpot;
				int y = hoPtr->hoY - hoPtr->hoImgYSpot;
				int dir = [hoPtr->hoAdRunHeader quadran_Out:x withY1:y andX2:x + hoPtr->hoImgWidth andY2:y + hoPtr->hoImgHeight];
				x = hoPtr->hoX;
				y = hoPtr->hoY;
				if ((dir & BORDER_LEFT) != 0)
				{
					x = hoPtr->hoImgXSpot;
				}
				if ((dir & BORDER_RIGHT) != 0)
				{
					x = hoPtr->hoAdRunHeader->rhLevelSx - hoPtr->hoImgWidth + hoPtr->hoImgXSpot;
				}
				if ((dir & BORDER_TOP) != 0)
				{
					y = hoPtr->hoImgYSpot;
				}
				if ((dir & BORDER_BOTTOM) != 0)
				{
					y = hoPtr->hoAdRunHeader->rhLevelSy - hoPtr->hoImgHeight + hoPtr->hoImgYSpot;
				}
				hoPtr->hoX = x;
				hoPtr->hoY = y;
			}
			return;
		case (-13 << 16):	    // CNDL_EXTCOLBACK:
		case (-14 << 16):	    // CNDL_EXTCOLLISION:
			{
				// --------------------------------------------------------------------------------
				// Contre un objet de decor...
				// --------------------------------------------------------------------------------
				// Essaye de sortir le sprite de la collision dans les 8 directions, avec la nouvelle image
				// ----------------------------------------------------------------------------------------
				CApproach ap = [self mbApproachSprite:hoPtr->hoX withDestY:hoPtr->hoY andMaxX:hoPtr->roc->rcOldX andMaxY:hoPtr->roc->rcOldY andFlag:flag];
				if (ap.isFound)
				{
					hoPtr->hoX = ap.point.x;
					hoPtr->hoY = ap.point.y;
					return;
				}
				int index = (hoPtr->roc->rcDir >> 2)*18;
				do
				{
					if ([self tst_Position:hoPtr->hoX + mvap_TableDirs[index] withY:hoPtr->hoY + mvap_TableDirs[index + 1] andFlag:flag])
					{
						// Positionne le sprite au plus pres de la position
						// ------------------------------------------------
						
						hoPtr->hoX += mvap_TableDirs[index];
						hoPtr->hoY += mvap_TableDirs[index + 1];
						return;
					}
					index += 2;
				} while (mvap_TableDirs[index] != 0 || mvap_TableDirs[index + 1] != 0);
				
				// On arrive pas : ancienne position / ancienne animation!
				// -------------------------------------------------------
				if (flag == NO)
				{
					hoPtr->hoX = hoPtr->roc->rcOldX;
					hoPtr->hoY = hoPtr->roc->rcOldY;
					if (hoPtr->roc->rcOldImage>=0)
					{
						hoPtr->roc->rcImage = hoPtr->roc->rcOldImage;
					}
					hoPtr->roc->rcAngle = hoPtr->roc->rcOldAngle;
					return;
				}
			}
			break;
		default:
			break;
	}
}

// ------------------------------------------------------------------------
// Verification de la position d'un sprite : prend TOUT en compte
// Bordure / Decor / Sprites interdits ...
// ------------------------------------------------------------------------
-(BOOL)tst_SpritePosition:(int)x withY:(int)y andFoot:(short)htFoot andPlane:(short)planCol andFlag:(BOOL)flag
{
	short sprOi;
	sprOi = -1;
	if (flag)
	{
		sprOi = hoPtr->hoOi;
	}
	CObjInfo* oilPtr = hoPtr->hoOiList;
	
	// Verification de la bordure
	// --------------------------
	if ((oilPtr->oilLimitFlags & 0x000F) != 0)
	{
		int xx = x - hoPtr->hoImgXSpot;
		int yy = y - hoPtr->hoImgYSpot;
		if (([hoPtr->hoAdRunHeader quadran_Out:xx withY1:yy andX2:xx + hoPtr->hoImgWidth andY2:yy + hoPtr->hoImgHeight] & oilPtr->oilLimitFlags) != 0)
		{
			return NO;
		}
	}
	
	// Verification du decor
	// ---------------------
	if ((oilPtr->oilLimitFlags & 0x0010) != 0)
	{
		if ([hoPtr->hoAdRunHeader colMask_TestObject_IXY:hoPtr withImage:hoPtr->roc->rcImage andAngle:hoPtr->roc->rcAngle andScaleX:hoPtr->roc->rcScaleX andScaleY:hoPtr->roc->rcScaleY andX:x andY:y andFoot:htFoot andPlane:planCol] != 0) // FRAROT
		{
			return NO;
		}
	}
	
	// Verification des sprites
	// ------------------------
	if (oilPtr->oilLimitList == -1)
	{
		return YES;
	}
	
	// Demande les collisions a cette position...
	CArrayList* list = [hoPtr->hoAdRunHeader objectAllCol_IXY:hoPtr withImage:hoPtr->roc->rcImage andAngle:hoPtr->roc->rcAngle andScaleX:hoPtr->roc->rcScaleX andScaleY:hoPtr->roc->rcScaleY andX:x andY:y andColList:oilPtr->oilColList];
	if (list == nil)
	{
		return YES;
	}
	
	// Exploration de la liste: recherche les sprites marque STOP pour ce sprite
	short* lb = hoPtr->hoAdRunHeader->rhEvtProg->limitBuffer;
	int index;
	for (index = 0; index < [list size]; index++)
	{
		CObject* hoSprite = (CObject*) [list get:index];		//; Le sprite en collision
		short oi = hoSprite->hoOi;
		if (oi != sprOi)						//; Ne pas tenir compte de lui-meme?
		{
			for (size_t ll = oilPtr->oilLimitList; lb[ll] >= 0; ll++)
			{
				if (lb[ll] == oi)
				{
					[list release];
					return NO;
				}
			}
		}
	}
	// On peut aller
	// -------------
	[list release];
	return YES;
}

// ------------------------------------------------------------------------
// Verification de la position d'un sprite : prend TOUT en compte
// Bordure / Decor / Sprites interdits ... CX!=0 :  ne pas tenir compte du sprite lui-meme
//	return	C set=> OK, on peut y aller
// ------------------------------------------------------------------------
-(BOOL)tst_Position:(int)x withY:(int)y andFlag:(BOOL)flag
{
	short sprOi;
	
	sprOi = -1;
	if (flag)
	{
		sprOi = hoPtr->hoOi;
	}
	CObjInfo* oilPtr = hoPtr->hoOiList;
	
	// Verification de la bordure
	// --------------------------
	if ((oilPtr->oilLimitFlags & 0x000F) != 0)
	{
		int xx = x - hoPtr->hoImgXSpot;
		int yy = y - hoPtr->hoImgYSpot;
		int dir = [hoPtr->hoAdRunHeader quadran_Out:xx withY1:yy andX2:xx + hoPtr->hoImgWidth andY2:yy + hoPtr->hoImgHeight];
		if ((dir & oilPtr->oilLimitFlags) != 0)
		{
			return NO;
		}
	}
	
	// Verification du decor
	// ---------------------
	if ((oilPtr->oilLimitFlags & 0x0010) != 0)
	{
		if ([hoPtr->hoAdRunHeader colMask_TestObject_IXY:hoPtr withImage:hoPtr->roc->rcImage andAngle:hoPtr->roc->rcAngle andScaleX:hoPtr->roc->rcScaleX andScaleY:hoPtr->roc->rcScaleY andX:x andY:y andFoot:(short)0 andPlane:CM_TEST_PLATFORM] != 0) // FRAROT
		{
			return NO;
		}
	}
	
	// Verification des sprites
	// ------------------------
	if (oilPtr->oilLimitList == -1)
	{
		return YES;
	}
	
	// Demande les collisions a cette position...
	CArrayList* list = [hoPtr->hoAdRunHeader objectAllCol_IXY:hoPtr withImage:hoPtr->roc->rcImage andAngle:hoPtr->roc->rcAngle andScaleX:hoPtr->roc->rcScaleX andScaleY:hoPtr->roc->rcScaleY andX:x andY:y andColList:oilPtr->oilColList];
	if (list == nil)
	{
		return YES;
	}
	
	// Exploration de la liste: recherche les sprites marque STOP pour ce sprite
	short* lb = hoPtr->hoAdRunHeader->rhEvtProg->limitBuffer;
	int index;
	for (index = 0; index < [list size]; index++)
	{
		CObject* hoSprite = (CObject*) [list get:index];		//; Le sprite en collision
		short oi = hoSprite->hoOi;
		if (oi != sprOi)						//; Ne pas tenir compte de lui-meme?
		{
			for (size_t ll = oilPtr->oilLimitList; lb[ll] >= 0; ll++)
			{
				if (lb[ll] == oi)
				{
					[list release];
					return NO;
				}
			}
		}
	}
	
	// On peut aller
	// -------------
	[list release];
	return YES;
}

//-----------------------------------------------------//
//	Approcher un sprite au maximum d'un obstacle       //
//-----------------------------------------------------//
// Le sprite est approche au maximum de (destX, destY) //
// et la position la plus eloignee est donnee par	   //
// (maxX, maxY). Le sprite est deplace vers maxX-Y	.  //
-(CApproach)mpApproachSprite:(int)destX withDestY:(int)destY andMaxX:(int)maxX andMaxY:(int)maxY andFoot:(short)htFoot andPlane:(short)planCol
{
	int presX = destX;
	int presY = destY;
	int loinX = maxX;
	int loinY = maxY;
	
	int x = (presX + loinX) / 2;
	int y = (presY + loinY) / 2;
	int oldX, oldY;
	CApproach ret;
	
	do
	{
		if ([self tst_SpritePosition:x withY:y andFoot:htFoot andPlane:planCol andFlag:NO])
		{
			// On peut y aller
			loinX = x;
			loinY = y;
			oldX = x;
			oldY = y;
			x = (loinX + presX) / 2;
			y = (loinY + presY) / 2;
			if (x == oldX && y == oldY)
			{
				if (loinX != presX || loinY != presY)
				{
					if ([self tst_SpritePosition:presX withY:presY andFoot:htFoot andPlane:planCol andFlag:NO])
					{
						x = presX;
						y = presY;
					}
				}
				ret.point.x = x;
				ret.point.y = y;
				ret.isFound = YES;
				return ret;
			}
		}
		else
		{
			// On ne peut pas y aller
			presX = x;
			presY = y;
			oldX = x;
			oldY = y;
			x = (loinX + presX) / 2;
			y = (loinY + presY) / 2;
			if (x == oldX && y == oldY)
			{
				if (loinX != presX || loinY != presY)
				{
					if ([self tst_SpritePosition:loinX withY:loinY andFoot:htFoot andPlane:planCol andFlag:NO])
					{
						ret.isFound = YES;
						ret.point.x = loinX;
						ret.point.y = loinY;
						return ret;
					}
				}
				ret.isFound = NO;
				ret.point.x = x;
				ret.point.y = y;
				return ret;
			}
		}
	} while (YES);
}
//-----------------------------------------------------//
//	Approcher un sprite au maximum d'un obstacle BALLE //
//-----------------------------------------------------//
// Le sprite est approche au maximum de (destX, destY) //
// et la position la plus eloignee est donnee par	   //
// (maxX, maxY). Le sprite est deplace vers maxX-Y	.  //
-(CApproach)mbApproachSprite:(int)destX withDestY:(int)destY andMaxX:(int)maxX andMaxY:(int)maxY andFlag:(BOOL)flag
{
	int presX = destX;
	int presY = destY;
	int loinX = maxX;
	int loinY = maxY;
	
	int x = (presX + loinX) / 2;
	int y = (presY + loinY) / 2;
	int oldX, oldY;
	CApproach ret;
	
	do
	{
		if ([self tst_Position:x withY:y andFlag:flag])
		{
			// On peut y aller
			loinX = x;
			loinY = y;
			oldX = x;
			oldY = y;
			x = (loinX + presX) / 2;
			y = (loinY + presY) / 2;
			if (x == oldX && y == oldY)
			{
				if (loinX != presX || loinY != presY)
				{
					if ([self tst_Position:presX withY:presY andFlag:flag])
					{
						x = presX;
						y = presY;
					}
				}
				ret.point.x = x;
				ret.point.y = y;
				ret.isFound = YES;
				return ret;
			}
		}
		else
		{
			// On ne peut pas y aller
			presX = x;
			presY = y;
			oldX = x;
			oldY = y;
			x = (loinX + presX) / 2;
			y = (loinY + presY) / 2;
			if (x == oldX && y == oldY)
			{
				if (loinX != presX || loinY != presY)
				{
					if ([self tst_Position:loinX withY:loinY andFlag:flag])
					{
						ret.point.x = x;
						ret.point.y = y;
						ret.isFound = YES;
						return ret;
					}
				}
				ret.point.x = x;
				ret.point.y = y;
				ret.isFound = NO;
				return ret;
			}
		}
	} while (true);
}

+(int)getDeltaX:(int)pente withAngle:(int)angle
{
	return (pente * Cosinus32[angle]) / 256;	//; Fois cosinus-> penteX
}

+(int)getDeltaY:(int)pente withAngle:(int)angle
{
	return (pente * Sinus32[angle]) / 256;		//; Fois sinus-> penteY
}

-(void)setAcc:(int)acc
{
	rmAcc = acc;
	rmAccValue = [self getAccelerator:acc];
	if (hoPtr->roc->rcMovementType == MVTYPE_EXT)
	{
		CMoveExtension* mvt = (CMoveExtension*)self;
		return [mvt->movement setAcc:acc];
	}
}

-(void)setDec:(int)dec
{
	rmDec = dec;
	rmDecValue = [self getAccelerator:dec];
	if (hoPtr->roc->rcMovementType == MVTYPE_EXT)
	{
		CMoveExtension* mvt = (CMoveExtension*)self;
		return [mvt->movement setDec:dec];
	}
}

-(void)setRotSpeed:(int)speed
{
	if (hoPtr->roc->rcMovementType == MVTYPE_RACE)
	{
		CMoveRace* mRace = (CMoveRace*) self;
		[mRace setRotSpeed:speed];
	}
	if (hoPtr->roc->rcMovementType == MVTYPE_EXT)
	{
		CMoveExtension* mvt = (CMoveExtension*)self;
		return [mvt->movement setRotSpeed:speed];
	}
}

-(void)set8Dirs:(int)dirs
{
	if (hoPtr->roc->rcMovementType == MVTYPE_GENERIC)
	{
		CMoveGeneric* mGeneric = (CMoveGeneric*) self;
		[mGeneric set8Dirs:dirs];
	}
	if (hoPtr->roc->rcMovementType == MVTYPE_EXT)
	{
		CMoveExtension* mvt = (CMoveExtension*)self;
		return [mvt->movement set8Dirs:dirs];
	}
}

-(void)setGravity:(int)gravity
{
	if (hoPtr->roc->rcMovementType == MVTYPE_PLATFORM)
	{
        if (gravity > 250)
            gravity = 250;
        if (gravity < 0)
            gravity = 0;
		CMovePlatform* mPlatform = (CMovePlatform*)self;
		[mPlatform setGravity:gravity];
	}
	if (hoPtr->roc->rcMovementType == MVTYPE_EXT)
	{
		CMoveExtension* mvt = (CMoveExtension*)self;
		return [mvt->movement setGravity:gravity];
	}
}

-(int)getSpeed
{
	if (hoPtr->roc->rcMovementType == MVTYPE_EXT)
	{
		CMoveExtension* mvt = (CMoveExtension*)self;
		return [mvt->movement getSpeed];
	}
	return hoPtr->roc->rcSpeed;
}

-(int)getDir
{
	if (hoPtr->roc->rcMovementType == MVTYPE_EXT)
	{
		CMoveExtension* mvt = (CMoveExtension*)self;
		return [mvt->movement getDir];
	}
	return hoPtr->roc->rcDir;
}

-(int)getAcc
{
	if (hoPtr->roc->rcMovementType == MVTYPE_EXT)
	{
		CMoveExtension* mvt = (CMoveExtension*)self;
		return [mvt->movement getAcceleration];
	}
	return rmAcc;
}

-(int)getDec
{
	if (hoPtr->roc->rcMovementType == MVTYPE_EXT)
	{
		CMoveExtension* mvt = (CMoveExtension*)self;
		return [mvt->movement getDeceleration];
	}
	return rmDec;
}

-(int)getGravity
{
	if (hoPtr->roc->rcMovementType == MVTYPE_PLATFORM)
	{
		CMovePlatform* mp = (CMovePlatform*)self;
		return mp->MP_Gravity;
	}
	if (hoPtr->roc->rcMovementType == MVTYPE_EXT)
	{
		CMoveExtension* mvt = (CMoveExtension*)self;
		return [mvt->movement getGravity];
		return 0;
	}
	return 0;
}

+(int)dummy
{
	if (YES)
	{
		return CosSurSin32[0];
	}
	if (NO)
	{
		return Joy2Dir[0];
	}
}


-(void)initMovement:(CObject*)hoPtr withMoveDef:(CMoveDef*)mvPtr
{
}

-(void)move
{
}

-(void)stop
{
}

-(void)start
{
}

-(void)bounce
{
}

-(void)reverse
{
}

-(void)setXPosition:(int)x
{
}

-(void)setYPosition:(int)u
{
}

-(void)setSpeed:(int)speed
{
}

-(void)setMaxSpeed:(int)speed
{
}

-(void)setDir:(int)dir
{
}


			
@end
