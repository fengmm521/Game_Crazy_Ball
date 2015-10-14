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
// CMOVEPLATFORM : Mouvement plateforme
//
//----------------------------------------------------------------------------------
#import "CMovePlatform.h"
#import "CMove.h"
#import "CObject.h"
#import "CMoveDef.h"
#import "CRAni.h"
#import "CRMvt.h"
#import "CRCom.h"
#import "CRun.h"
#import "CMoveDefPlatform.h"
#import "CEventProgram.h"
#import "CRunFrame.h"
#import "CAnim.h"
#import "CRunApp.h"
#import "CImageBank.h"
#import "CImage.h"
#import "CPoint.h"
#import "CArrayList.h"
#import "CRect.h"
#import "CColMask.h"
#import "CObjInfo.h"


extern int Cosinus32[];
extern int Sinus32[];
extern int CosSurSin32[];

extern BOOL bMoveChanged;

@implementation CMovePlatform

-(void)initMovement:(CObject*)ho withMoveDef:(CMoveDef*)mvPtr
{
	hoPtr = ho;
	CMoveDefPlatform* mpPtr = (CMoveDefPlatform*) mvPtr;
	
	hoPtr->hoCalculX = 0;
	hoPtr->hoCalculY = 0;								//; Raz pds faibles coordonnees
	MP_XSpeed = 0;
	hoPtr->roc->rcSpeed = 0;							//; Raz vitesse et coef de rebondissement
	MP_Bounce = 0;
	hoPtr->roc->rcPlayer = mvPtr->mvControl;				//; Init numero de joueur
	rmAcc = mpPtr->mpAcc;				//; Init Acceleration
	rmAccValue = [self getAccelerator:rmAcc];	//; Init valeur a ajouter a la vitesse
	rmDec = mpPtr->mpDec;				//; Init Deceleration
	rmDecValue = [self getAccelerator:rmDec];	//; Valeur a enlever a la vitesse
	hoPtr->roc->rcMaxSpeed = mpPtr->mpSpeed;			//; Vitesse maxi
	hoPtr->roc->rcMinSpeed = 0;							//; Vitesse mini
	
	MP_Gravity = mpPtr->mpGravity;		//; Gravite
	MP_Jump = mpPtr->mpJump;				//; Jump impulsion
	int jump = mpPtr->mpJumpControl;
	if (jump > 3)
	{
		jump = MPJC_DIAGO;
	}
	MP_JumpControl = jump;						//; Jump control
	MP_YSpeed = 0;								//; Current Y speed
	
	MP_JumpStopped = 0;
	MP_ObjectUnder = nil;
	
	[self moveAtStart:mvPtr];						//; Init direction
	MP_PreviousDir = hoPtr->roc->rcDir;
	hoPtr->roc->rcChanged = YES;
	MP_Type = MPTYPE_WALK;
}

-(void)move
{
	int x, y;
	
	hoPtr->hoAdRunHeader->rhVBLObjet = 1;
	int joyDir = hoPtr->hoAdRunHeader->rhPlayer;				//; Lire le joystick
	[self calcMBFoot];
	
	// Calcul de la vitesse en X
	// -------------------------
	int xSpeed = MP_XSpeed;
	int speed8, dSpeed;
	if (MP_JumpStopped == 0)
	{
		if (xSpeed <= 0)
		{
			if ((joyDir & 4) != 0)								// Gauche
			{
				// Accelere
				dSpeed = rmAccValue;
				if ((hoPtr->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					dSpeed = (int) (((double) dSpeed) * hoPtr->hoAdRunHeader->rh4MvtTimerCoef);
				}
				xSpeed -= dSpeed;
				speed8 = xSpeed / 256;						// Vitesse reelle
				if (speed8 < -hoPtr->roc->rcMaxSpeed)
				{
					xSpeed = -hoPtr->roc->rcMaxSpeed * 256;
				}
			}
			else if (xSpeed < 0)
			{
				// Ralenti 
				dSpeed = rmDecValue;
				if ((hoPtr->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					dSpeed = (int) (((double) dSpeed) * hoPtr->hoAdRunHeader->rh4MvtTimerCoef);
				}
				xSpeed += dSpeed;
				if (xSpeed > 0)
				{
					xSpeed = 0;
				}
			}
			if ((joyDir & 8) != 0)								// Droite
			{
				// Changement instantann� de direction
				xSpeed = -xSpeed;
			}
		}
		if (xSpeed >= 0)
		{
			if ((joyDir & 8) != 0)
			{
				dSpeed = rmAccValue;
				if ((hoPtr->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					dSpeed = (int) (((double) dSpeed) * hoPtr->hoAdRunHeader->rh4MvtTimerCoef);
				}
				xSpeed += dSpeed;
				speed8 = xSpeed / 256;						// Vitesse reelle
				if (speed8 > hoPtr->roc->rcMaxSpeed)
				{
					xSpeed = hoPtr->roc->rcMaxSpeed * 256;
				}
			}
			else if (xSpeed > 0)
			{
				// Ralenti
				dSpeed = rmDecValue;
				if ((hoPtr->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					dSpeed = (int) (((double) dSpeed) * hoPtr->hoAdRunHeader->rh4MvtTimerCoef);
				}
				xSpeed -= dSpeed;
				if (xSpeed < 0)
				{
					xSpeed = 0;
				}
			}
			if ((joyDir & 4) != 0)
			{
				// Changement brusque de direction
				xSpeed = -xSpeed;
			}
		}
		MP_XSpeed = xSpeed;
	}
	
	// Calcul de la vitesse en Y
	// -------------------------
	int ySpeed = MP_YSpeed;
	BOOL flag = NO;
	while (YES)
	{
		switch (MP_Type)
		{
			case 2:     // MPTYPE_FALL:
			case 3:     // MPTYPE_JUMP:
				dSpeed = MP_Gravity << 5;
				if ((hoPtr->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					dSpeed = (int) (((double) dSpeed) * hoPtr->hoAdRunHeader->rh4MvtTimerCoef);
				}
				ySpeed = ySpeed + dSpeed;               // GRAVITY_COEF);
				if (ySpeed > 0xFA00)
				{
					ySpeed = 0xFA00;
				}
				break;
			case 0:     // MPTYPE_WALK:
				if ((joyDir & 1) != 0)
				{
					// Si pas d'echelle sous les pieds, on ne fait rien
					if ([self check_Ladder:hoPtr->hoLayer withX:hoPtr->hoX + MP_XMB andY:hoPtr->hoY + MP_YMB - 4] == 0x80000000)
					{
						break;
					}
					MP_Type = MPTYPE_CLIMB;
					flag = YES;
					continue;
				}
				if ((joyDir & 2) != 0)
				{
					// Si pas d'echelle sous les pieds, on ne fait rien
					if ([self check_Ladder:hoPtr->hoLayer withX:hoPtr->hoX + MP_XMB andY:hoPtr->hoY + MP_YMB + 4] == 0x80000000)
					{
						break;
					}
					MP_Type = MPTYPE_CLIMB;
					flag = YES;
					continue;
				}
				break;
			case 1:         // MPTYPE_CLIMB:
				if (flag == NO)
				{
					MP_JumpStopped = 0;
					// Si pas d'echelle sous les pieds, on ne fait rien
					if ([self check_Ladder:hoPtr->hoLayer withX:hoPtr->hoX + MP_XMB andY:hoPtr->hoY + MP_YMB] == 0x80000000)
					{
						if ([self check_Ladder:hoPtr->hoLayer withX:hoPtr->hoX + MP_XMB andY:hoPtr->hoY + MP_YMB - 4] == 0x80000000)
						{
							break;
						}
					}
				}
				// Calcul de la vitesse en Y
				if (ySpeed <= 0)
				{
					if ((joyDir & 1) != 0)						// Haut
					{
						// Accelere
						dSpeed = rmAccValue;
						if ((hoPtr->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
						{
							dSpeed = (int) (((double) dSpeed) * hoPtr->hoAdRunHeader->rh4MvtTimerCoef);
						}
						ySpeed -= dSpeed;
						speed8 = ySpeed / 256;						// Vitesse reelle
						if (speed8 < -hoPtr->roc->rcMaxSpeed)
						{
							ySpeed = -hoPtr->roc->rcMaxSpeed * 256;
						}
					}
					else
					{
						// Ralenti 
						dSpeed = rmDecValue;
						if ((hoPtr->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
						{
							dSpeed = (int) (((double) dSpeed) * hoPtr->hoAdRunHeader->rh4MvtTimerCoef);
						}
						ySpeed += dSpeed;
						if (ySpeed > 0)
						{
							ySpeed = 0;
						}
					}
					if ((joyDir & 2) != 0)								// Bas
					{
						// Changement instantann� de direction
						ySpeed = -ySpeed;
					}
				}
				if (ySpeed >= 0)
				{
					if ((joyDir & 2) != 0)
					{
						dSpeed = rmAccValue;
						if ((hoPtr->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
						{
							dSpeed = (int) (((double) dSpeed) * hoPtr->hoAdRunHeader->rh4MvtTimerCoef);
						}
						ySpeed += dSpeed;
						speed8 = ySpeed / 256;						// Vitesse reelle
						if (speed8 > hoPtr->roc->rcMaxSpeed)
						{
							ySpeed = hoPtr->roc->rcMaxSpeed * 256;
						}
					}
					else
					{
						// Ralenti
						dSpeed = rmDecValue;
						if ((hoPtr->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
						{
							dSpeed = (int) (((double) dSpeed) * hoPtr->hoAdRunHeader->rh4MvtTimerCoef);
						}
						ySpeed -= dSpeed;
						if (ySpeed < 0)
						{
							ySpeed = 0;
						}
					}
					if ((joyDir & 1) != 0)
					{
						// Changement brusque de direction
						ySpeed = -ySpeed;
					}
				}
				break;
		}
		break;
	}
	MP_YSpeed = ySpeed;
	
	// Calculer la direction en fonction des vitesses en X et Y
	// --------------------------------------------------------
	int dir = 0;                  // DIRID_E;
	if (xSpeed < 0)
	{
		dir = 16;                 // DIRID_W;
	}
	int sX = xSpeed;
	int sY = ySpeed;
	if (sY != 0)
	{
		int flags = 0;							//; Flags de signe
		if (sX < 0)								//; DX negatif?
		{
			flags |= 1;
			sX = -sX;
		}
		if (sY < 0)								//; DY negatif?
		{
			flags |= 2;
			sY = -sY;
		}
		sX <<= 8;									//; * 256 pour plus de precision
		sX = sX / sY;
		int i;
		for (i = 0;; i += 2)
		{
			if (sX >= CosSurSin32[i])
			{
				break;
			}
		}
		dir = CosSurSin32[i + 1];
		if ((flags & 0x02) != 0)
		{
			dir = -dir + 32;
			dir &= 31;
		}
		if ((flags & 0x01) != 0)
		{
			dir -= 8;
			dir &= 31;
			dir = -dir;
			dir &= 31;
			dir += 8;
			dir &= 31;
		}
	}
	
	//
	// Calculer la vitesse resultante des 2 vitesses en X et en Y
	// ----------------------------------------------------------
	// Si |cos(dir)| > |sin(dir)|,
	//		|vitesse| = |speedX| / |cos(dir)|
	// Sinon,
	//		|vitesse| = |speedY| / |sin(dir)|
	//
	sX = xSpeed;
	int cosinus = Cosinus32[dir];
	int sinus = Sinus32[dir];
	if (cosinus < 0)
	{
		cosinus = -cosinus;
	}
	if (sinus < 0)
	{
		sinus = -sinus;
	}
	if (cosinus < sinus)			// vitesse = speedX / cos
	{
		cosinus = sinus;			//; vitesse = speedY / sin
		sX = ySpeed;
	}
	if (sX < 0)
	{
		sX = -sX;
	}
	sX = sX / cosinus;
	if (sX > 250)
	{
		sX = 250;
	}
	hoPtr->roc->rcSpeed = sX;		//; Valeur absolue de la vitesse
	
	// Calcule la bonne direction en fonction des mouvements
	switch (MP_Type)
	{
		case 1:         // MPTYPE_CLIMB:
			if (ySpeed < 0)
			{
				hoPtr->roc->rcDir = 8;      // DIRID_N
			}
			else if (ySpeed > 0)
			{
				hoPtr->roc->rcDir = 24;     // DIRID_S;
			}
			break;
		case 3:         // MPTYPE_FALL:
			hoPtr->roc->rcDir = dir;
			break;
		default:
			if (xSpeed < 0)
			{
				hoPtr->roc->rcDir = 16;     // DIRID_W;
			}
			else if (xSpeed > 0)
			{
				hoPtr->roc->rcDir = 0;      // DIRID_E;
			}
			break;
	}
	
	// Calcule la bonne animation en fonction des mouvements
	switch (MP_Type)
	{
		case 4:      // MPTYPE_CROUCH:
			hoPtr->roc->rcAnim = ANIMID_CROUCH;
			break;
		case 5:     // MPTYPE_UNCROUCH:
			hoPtr->roc->rcAnim = ANIMID_UNCROUCH;
			break;
		case 3:     // MPTYPE_FALL:
			hoPtr->roc->rcAnim = ANIMID_FALL;
			break;
		case 2:     // MPTYPE_JUMP:
			hoPtr->roc->rcAnim = ANIMID_JUMP;
			break;
		case 1:     // MPTYPE_CLIMB:
			hoPtr->roc->rcAnim = ANIMID_CLIMB;
			break;
		default:
			hoPtr->roc->rcAnim = ANIMID_WALK;
			break;
	}
	
	// Appel des animations
	if (hoPtr->roa != nil)
	{
		[hoPtr->roa animate];
	}
	[self calcMBFoot];
	
	// Appel des mouvements
	[self newMake_Move:hoPtr->roc->rcSpeed withDir:dir];
	if (bMoveChanged)
	{
		return;
	}
	
	// Decide de la conduite a tenir
	// -----------------------------
	if ((MP_Type == MPTYPE_WALK || MP_Type == MPTYPE_CLIMB) && MP_NoJump == NO)
	{
		// Teste le saut
		BOOL bJump = NO;
		int j = MP_JumpControl;
		if (j != 0)
		{
			j--;
			if (j == 0)
			{
				if ((joyDir & 5) == 5)
				{
					bJump = YES;							// Haut gauche
				}
				if ((joyDir & 9) == 9)
				{
					bJump = YES;							// Haut droite
				}
			}
			else
			{
				j <<= 4;
				if ((joyDir & j) != 0)
				{
					bJump = YES;
				}
			}
		}
		if (bJump)
		{
			MP_YSpeed = -MP_Jump << 8;                  // JUMP_COEF;
			MP_Type = MPTYPE_JUMP;
		}
	}
	switch (MP_Type)
	{
		case 2:         // MPTYPE_JUMP:
			// Si on arrive en haut du saut, on passe en chute
			if (MP_YSpeed >= 0)
			{
				MP_Type = MPTYPE_FALL;
			}
			break;
			
		case 3:         // MPTYPE_FALL:
			// Si un echelle sous les pieds, on s'arrete
			if ([self check_Ladder:hoPtr->hoLayer withX:hoPtr->hoX + MP_XMB andY:hoPtr->hoY + MP_YMB] != 0x80000000)
			{
				MP_YSpeed = 0;
				MP_Type = MPTYPE_CLIMB;
				hoPtr->roc->rcDir = 8;          // DIRID_N;
			}
			break;
			
		case 0:         // MPTYPE_WALK:
			// Monter / descend une echelle?
			if ((joyDir & 3) != 0 && (joyDir & 12) == 0)
			{
				if ([self check_Ladder:hoPtr->hoLayer withX:hoPtr->hoX + MP_XMB andY:hoPtr->hoY + MP_YMB] != 0x80000000)
				{
					MP_Type = MPTYPE_CLIMB;
					MP_XSpeed = 0;
					break;
				}
			}
			// Passer en crouch?
			if ((joyDir & 2) != 0)
			{
				if (hoPtr->roa != nil)
				{
					if ([hoPtr->roa anim_Exist:ANIMID_CROUCH])			//; Une animation definie?
					{
						MP_XSpeed = 0;
						MP_Type = MPTYPE_CROUCH;
					}
				}
			}
			
			// Un echelle sous les pieds du joueur?
			if ([self check_Ladder:hoPtr->hoLayer withX:hoPtr->hoX + MP_XMB andY:hoPtr->hoY + MP_YMB] != 0x80000000)
			{
				break;
			}
			
			// Test si plateforme a moins de 10 pixels du joueur
			if ([self tst_SpritePosition:hoPtr->hoX withY:hoPtr->hoY + 10 andFoot:(short) MP_HTFOOT andPlane:CM_TEST_PLATFORM andFlag:YES] == NO)
			{
				// On se rapproche du bord
				x = hoPtr->hoX;					//; Coordonnes
				y = hoPtr->hoY;
				int d = y + MP_HTFOOT - 1;						//; 15
				CApproach ap = [self mpApproachSprite:x withDestY:d andMaxX:x andMaxY:y andFoot:(short)MP_HTFOOT andPlane:CM_TEST_PLATFORM];
				
				hoPtr->hoX = ap.point.x;
				hoPtr->hoY = ap.point.y;
				MP_NoJump = NO;
			}
			else
			{
				MP_Type = MPTYPE_FALL;
			}
			break;
			
		case 1:         // MPTYPE_CLIMB:
			// Verifie la presence d'un echelle sous les pieds
			if ([self check_Ladder:hoPtr->hoLayer withX:hoPtr->hoX + MP_XMB andY:hoPtr->hoY + MP_YMB] == 0x80000000)
			{
				// Si on monte, on positionne le sprite juste au dessus de l'echelle
				if (MP_YSpeed < 0)
				{
					for (sY = 0; sY < 32; sY++)
					{
						if ([self check_Ladder:hoPtr->hoLayer withX:hoPtr->hoX + MP_XMB andY:hoPtr->hoY + MP_YMB + sY] != 0x80000000)
						{
							hoPtr->hoY += sY;
							break;
						}
					}
				}
				// Plus d'echelle, on arrete le mouvement
				MP_YSpeed = 0;
			}
			// Si on appuie sur gauche / droite on repasse en mouvement walk
			if ((joyDir & 12) != 0)
			{
				MP_Type = MPTYPE_WALK;
				MP_YSpeed = 0;
			}
			break;
			
		case 4:         // MPTYPE_CROUCH:
			if ((joyDir & 2) == 0)
			{
				if (hoPtr->roa != nil)
				{
					if ([hoPtr->roa anim_Exist:ANIMID_UNCROUCH])
					{
						MP_Type = MPTYPE_UNCROUCH;
						hoPtr->roc->rcAnim = ANIMID_UNCROUCH;
						[hoPtr->roa animate];
						hoPtr->roa->raAnimRepeat = 1;					// Force une seule boucle d'animation
						break;
					}
				}
				MP_Type = MPTYPE_WALK;
			}
			break;
			
		case 5:         // MPTYPE_UNCROUCH:
			if (hoPtr->roa != nil)
			{
				if (hoPtr->roa->raAnimNumberOfFrame == 0)
				{
					MP_Type = MPTYPE_WALK;
				}
			}
			break;
	}
	
	// Gestion marche sur un autre sprite
	if (MP_Type == MPTYPE_WALK || MP_Type == MPTYPE_CROUCH || MP_Type == MPTYPE_UNCROUCH)
	{
		CArrayList* list1=nil;
		CArrayList* list=nil;
		do
		{
			// Regarde l'objet en dessous
			list1=[hoPtr->hoAdRunHeader objectAllCol_IXY:hoPtr withImage:hoPtr->roc->rcImage andAngle:hoPtr->roc->rcAngle andScaleX:hoPtr->roc->rcScaleX andScaleY:hoPtr->roc->rcScaleY andX:hoPtr->hoX andY:hoPtr->hoY andColList:hoPtr->hoOiList->oilColList]; 
			if (list1==nil)
			{
				list = [hoPtr->hoAdRunHeader objectAllCol_IXY:hoPtr withImage:hoPtr->roc->rcImage andAngle:hoPtr->roc->rcAngle andScaleX:hoPtr->roc->rcScaleX andScaleY:hoPtr->roc->rcScaleY andX:hoPtr->hoX andY:hoPtr->hoY + 1 andColList:hoPtr->hoOiList->oilColList];
				if (list != nil && [list size] == 1)
				{
					CObject* pHo2 = (CObject*) [list get:0];
					if (MP_ObjectUnder == nil || MP_ObjectUnder != pHo2)
					{
						if (hoPtr->hoOi != pHo2->hoOi)
						{
							MP_ObjectUnder = pHo2;
							MP_XObjectUnder = pHo2->hoX;
							MP_YObjectUnder = pHo2->hoY;
							break;
						}
					}
					int dx = pHo2->hoX - MP_XObjectUnder;
					int dy = pHo2->hoY - MP_YObjectUnder;
					MP_XObjectUnder = pHo2->hoX;
					MP_YObjectUnder = pHo2->hoY;
					
					hoPtr->hoX += dx;
					hoPtr->hoY += dy;
					[hoPtr->hoAdRunHeader newHandle_Collisions:hoPtr];
					hoPtr->roc->rcChanged = YES;							//; Sprite bouge!
					break;
				}
			}
			MP_ObjectUnder = nil;
		} while (NO);
		if (list1!=nil)
		{
			[list1 release];
		}
		if (list!=nil)
		{
			[list release];
		}
	}
	else
	{
		MP_ObjectUnder = nil;
	}
}

-(void)mpStopIt
{
	hoPtr->roc->rcSpeed = 0;
	MP_XSpeed = 0;
	MP_YSpeed = 0;
}

-(void)stop
{
	MP_Bounce = 0;
	
	// Est-ce le sprite courant?
	// -------------------------
	if (rmCollisionCount != hoPtr->hoAdRunHeader->rh3CollisionCount)
	{
		[self mpStopIt];
		return;
	}
	hoPtr->rom->rmMoveFlag = YES;				// Le flag!
	int scrX = hoPtr->hoX;
	int scrY = hoPtr->hoY;
	int x, y, dir;
	
	// Qui est a l'origine de la collision?
	// ------------------------------------
	switch (hoPtr->hoAdRunHeader->rhEvtProg->rhCurCode & 0xFFFF0000)
	{
		case (-12 << 16):         // CNDL_EXTOUTPLAYFIELD:
			// SORTIE DU TERRAIN : RECENTRE LE SPRITE
			// --------------------------------------
			x = hoPtr->hoX - hoPtr->hoImgXSpot;
			y = hoPtr->hoY - hoPtr->hoImgYSpot;
			dir = [hoPtr->hoAdRunHeader quadran_Out:x withY1:y andX2:x + hoPtr->hoImgWidth andY2:y + hoPtr->hoImgHeight];
			
			x = hoPtr->hoX;
			y = hoPtr->hoY;
			if ((dir & BORDER_LEFT) != 0)
			{
				x = hoPtr->hoImgXSpot;
				MP_XSpeed = 0;
				MP_NoJump = YES;
			}
			if ((dir & BORDER_RIGHT) != 0)
			{
				x = hoPtr->hoAdRunHeader->rhLevelSx - hoPtr->hoImgWidth + hoPtr->hoImgXSpot;
				MP_XSpeed = 0;
				MP_NoJump = YES;
			}
			if ((dir & BORDER_TOP) != 0)
			{
				y = hoPtr->hoImgYSpot;
				MP_YSpeed = 0;
				MP_NoJump = NO;
			}
			if ((dir & BORDER_BOTTOM) != 0)
			{
				y = hoPtr->hoAdRunHeader->rhLevelSy - hoPtr->hoImgHeight + hoPtr->hoImgYSpot;
				MP_YSpeed = 0;
				MP_NoJump = NO;
			}
			hoPtr->hoX = x;
			hoPtr->hoY = y;
			if (MP_Type == MPTYPE_JUMP)
			{
				MP_Type = MPTYPE_FALL;
			}
			else
			{
				MP_Type = MPTYPE_WALK;
			}
			MP_JumpStopped = 0;
			return;
		case (-13 << 16):	    // CNDL_EXTCOLBACK:
		case (-14 << 16):	    // CNDL_EXTCOLLISION:
		{
			MP_NoJump = NO;
			if (MP_Type == MPTYPE_FALL)
			{
				CApproach ap = [self mpApproachSprite:scrX withDestY:scrY andMaxX:hoPtr->roc->rcOldX andMaxY:hoPtr->roc->rcOldY andFoot:(short)MP_HTFOOT andPlane:CM_TEST_PLATFORM];
				
				hoPtr->hoX = ap.point.x;
				hoPtr->hoY = ap.point.y;
				MP_Type = MPTYPE_WALK;
				hoPtr->roc->rcChanged = YES;
				
				if ([self tst_SpritePosition:hoPtr->hoX withY:hoPtr->hoY + 1 andFoot:(short)0 andPlane:CM_TEST_PLATFORM andFlag:YES])
				{
					hoPtr->roc->rcSpeed = 0;
					MP_XSpeed = 0;
				}
				else
				{
					MP_JumpStopped = 0;
					hoPtr->roc->rcSpeed = abs(MP_XSpeed / 256);
					MP_YSpeed = 0;
				}
				return;
			}
			if (MP_Type == MPTYPE_WALK)
			{
				// Si on marche on essaye de monter sur l'obstacle
				CApproach ap = [self mpApproachSprite:scrX withDestY:scrY andMaxX:scrX andMaxY:scrY - MP_HTFOOT andFoot:(short)0 andPlane:CM_TEST_PLATFORM];
				if (ap.isFound) //roPtr.rom.MP_HTFOOT
				{
					// Pas de stop, on monte juste sur l'obstacle
					hoPtr->hoX = ap.point.x;
					hoPtr->hoY = ap.point.y;
					hoPtr->roc->rcChanged = YES;
					return;
				}
				// On essaye de positionner le sprite contre l'obstacle
				ap = [self mpApproachSprite:scrX withDestY:scrY andMaxX:hoPtr->roc->rcOldX andMaxY:hoPtr->roc->rcOldY andFoot:(short)0 andPlane:CM_TEST_PLATFORM];
				if (ap.isFound)
				{
					hoPtr->hoX = ap.point.x;
					hoPtr->hoY = ap.point.y;
					hoPtr->roc->rcChanged = YES;
					[self mpStopIt];
					return;
				}
			}
			if (MP_Type == MPTYPE_JUMP)
			{
				// Si on marche on essaye de monter sur l'obstacle
				CApproach ap = [self mpApproachSprite:scrX withDestY:scrY andMaxX:scrX andMaxY:scrY - MP_HTFOOT andFoot:(short)0 andPlane:CM_TEST_PLATFORM];
				if (ap.isFound)	//roPtr.rom.MP_HTFOOT
				{
					// Pas de stop, on monte juste sur l'obstacle
					hoPtr->hoX = ap.point.x;
					hoPtr->hoY = ap.point.y;
					hoPtr->roc->rcChanged = YES;
					return;
				}
				MP_JumpStopped = 1;
				MP_XSpeed = 0;
			}
			if (MP_Type == MPTYPE_CLIMB)
			{
				// On essaye de positionner le sprite contre l'obstacle
				CApproach ap = [self mpApproachSprite:scrX withDestY:scrY andMaxX:hoPtr->roc->rcOldX andMaxY:hoPtr->roc->rcOldY andFoot:(short)0 andPlane:CM_TEST_PLATFORM];
				if (ap.isFound)
				{
					hoPtr->hoX = ap.point.x;
					hoPtr->hoY = ap.point.y;
					hoPtr->roc->rcChanged = YES;
					[self mpStopIt];
					return;
				}
			}
			// Essaye avec l'ancienne image
			hoPtr->roc->rcImage = hoPtr->roc->rcOldImage;
			hoPtr->roc->rcAngle = hoPtr->roc->rcOldAngle;
			if ([self tst_SpritePosition:hoPtr->hoX withY:hoPtr->hoY andFoot:(short)0 andPlane:CM_TEST_PLATFORM andFlag:true])
			{
				return;
			}
			
			// Rien ne marche, ancienne image, ancienne position
			hoPtr->hoX = hoPtr->roc->rcOldX;
			hoPtr->hoY = hoPtr->roc->rcOldY;
			hoPtr->roc->rcChanged = YES;
			break;
		}
	}
}

-(void)bounce
{
	[self stop];
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
	MP_XSpeed = hoPtr->roc->rcSpeed * Cosinus32[hoPtr->roc->rcDir];
	MP_YSpeed = hoPtr->roc->rcSpeed * Sinus32[hoPtr->roc->rcDir];
	hoPtr->rom->rmMoveFlag = YES;
}

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
	speed <<= 8;
	if (MP_XSpeed > speed)
	{
		MP_XSpeed = speed;
	}
	hoPtr->rom->rmMoveFlag = YES;
}

-(void)setGravity:(int)gravity
{
	MP_Gravity = gravity;
}

-(void)setDir:(int)dir
{
	hoPtr->roc->rcDir = dir;
	MP_XSpeed = hoPtr->roc->rcSpeed * Cosinus32[dir];
	MP_YSpeed = hoPtr->roc->rcSpeed * Sinus32[dir];
}

//---------------------------------------------------------------------//
//	Calculer les coordonnees des pieds et la taille du bas du sprite   //
//---------------------------------------------------------------------//
-(void)calcMBFoot
{
	if (hoPtr->roc->rcImage >= 0)
	{
		ImageInfo ifo = [hoPtr->hoAdRunHeader->rhApp->imageBank getImageInfoEx:hoPtr->roc->rcImage withAngle:hoPtr->roc->rcAngle andScaleX:hoPtr->roc->rcScaleX andScaleY:hoPtr->roc->rcScaleY];
		MP_XMB = -0;							//&; X ecran du point milieu bas (sous hot spot)
		MP_YMB = ifo.height - ifo.ySpot;	//; Y ecran du point milieu bas
		MP_HTFOOT = ((ifo.height * 2) + ifo.height) >> 3;		//; Hauteur des pieds
	}
	else
	{
		MP_XMB = -0;							//&; X ecran du point milieu bas (sous hot spot)
		MP_YMB = hoPtr->hoImgHeight - hoPtr->hoImgYSpot;	//; Y ecran du point milieu bas
		MP_HTFOOT = ((hoPtr->hoImgHeight * 2) + hoPtr->hoImgHeight) >> 3;		//; Hauteur des pieds
	}
}

//-----------------------------------------------------//
//		Tester s'il y a une echelle sous le joueur //
//-----------------------------------------------------//
-(int)check_Ladder:(int)nLayer withX:(int)x andY:(int)y
{
	CRect prc = [hoPtr->hoAdRunHeader y_GetLadderAt:nLayer withX:x andY:y];
	if (!prc.isNil())
	{
		return (int)prc.top;
	}
	return 0x80000000;
}

//-----------------------------------------------------------------------------//
//	Collisions avec le decor d'un sprite en mouvement plateforme               //
//-----------------------------------------------------------------------------//
-(void)mpHandle_Background
{
	// TEST COLLISION AVEC ECHELLES
	// ----------------------------
	[self calcMBFoot];
	if ([self check_Ladder:hoPtr->hoLayer withX:hoPtr->hoX + MP_XMB andY:hoPtr->hoY + MP_YMB] != 0x80000000)
	{
		return;	//; Si echelle juste sous les pieds, pas de collision
	}
	// TEST COLLISION AVEC OBSTACLES SEULEMENT
	// ---------------------------------------
	if ([hoPtr->hoAdRunHeader colMask_TestObject_IXY:hoPtr withImage:hoPtr->roc->rcImage andAngle:hoPtr->roc->rcAngle andScaleX:hoPtr->roc->rcScaleX andScaleY:hoPtr->roc->rcScaleY andX:hoPtr->hoX andY:hoPtr->hoY andFoot:(short)0 andPlane:CM_TEST_OBSTACLE] == 0) // FRAROT
	{
		// TEST COLLISION AVEC LES PLATEFORMES
		// -----------------------------------
		// Si anim = saut & MP_YSpeed < 0, pas de test des plateformes.
		// ------------------------------------------------------------
		if (MP_Type == MPTYPE_JUMP && MP_YSpeed < 0)
		{
			return;
		}
		
		if ([hoPtr->hoAdRunHeader colMask_TestObject_IXY:hoPtr withImage:hoPtr->roc->rcImage andAngle:hoPtr->roc->rcAngle andScaleX:hoPtr->roc->rcScaleX andScaleY:hoPtr->roc->rcScaleY andX:hoPtr->hoX andY:hoPtr->hoY andFoot:(short)MP_HTFOOT andPlane:CM_TEST_PLATFORM] == 0) // FRAROT
		{
			return;
		}
	}
	[hoPtr->hoAdRunHeader->rhEvtProg handle_Event:hoPtr withCode:(-13 << 16) | (((int) hoPtr->hoType) & 0xFFFF)];	    // CNDL_EXTCOLBACK
}


@end
