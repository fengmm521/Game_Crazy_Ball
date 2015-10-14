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
// CRunPlatform: Platform Movement object
//
//----------------------------------------------------------------------------------
#import "CRunPlatform.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CRun.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CExtension.h"
#import "CValue.h"
#import "CObjectCommon.h"
#import "CMoveDef.h"
#import "CMoveDefExtension.h"
#import "CRCom.h"
#import "CObjectCommon.h"
#import "CMoveDefList.h"
#import "CRMvt.h"
#import "CServices.h"
#import "CSpriteGen.h"
#import "CSprite.h"
#import "CObject.h"
#import "CExtension.h"
#import "CLayer.h"
#import "CRunApp.h"
#import "CRunFrame.h"
#import "CArrayList.h"
#import "CObjInfo.h"
#import "CRVal.h"
#import "CEventProgram.h"
#import "CFile.h"

@implementation CRunPlatform

-(int)getNumberOfConditions
{
	return 7;
}

-(int)readStringNumber:(CFile*)file withLength:(int)length
{
	NSString* string=[file readAStringWithSize:length];
	int ret=[string intValue];
	[string release];
	return ret;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	[file setUnicode:NO];
	[file skipBytes:8];
	PFMove = [[PlatformMove alloc] init];
	PFMove->MaxXVelocity = [self readStringNumber:file withLength:16];
	PFMove->MaxYVelocity =  [self readStringNumber:file withLength:16];
	PFMove->XAccel =  [self readStringNumber:file withLength:16];
	PFMove->XDecel =  [self readStringNumber:file withLength:16];
	PFMove->Gravity =  [self readStringNumber:file withLength:16];
	PFMove->JumpStrength = [self readStringNumber:file withLength:16];
	PFMove->JumpHoldHeight = [self readStringNumber:file withLength:16];
	PFMove->StepUp = [self readStringNumber:file withLength:16];
	PFMove->SlopeCorrection = [self readStringNumber:file withLength:16];
	Col = [[PlatformCOL alloc] init];
	Col->JumpThroughColTop = [file readAByte] == 1 ? YES : NO;
	Col->EnableJumpThrough = [file readAByte] == 1 ? YES : NO;
	ObjFixed = 0;
	hasObject = NO;
	return YES;
}
-(void)destroyRunObject:(BOOL)bFast
{
	[Col release];
	[PFMove release];
}

-(BOOL)IsOverObstacle
{
	Col->Obstacle = NO;
	[ho generateEvent:CID_ObstacleTest withParam:[ho getEventParam]];
	return Col->Obstacle;
}

-(BOOL)IsOverJumpThrough
{
	if (!Col->EnableJumpThrough)
	{
		return NO;
	}
	Col->JumpThrough = NO;
	[ho generateEvent:CID_JumpThroughTest withParam:[ho getEventParam]];
	return Col->JumpThrough;
}

-(int)handleRunObject
{
	if(hasObject)
	{
		CObject* Object = [ho getObjectFromFixed:ObjFixed];
		// If Object is valid, do movement
		if (!PFMove->Paused && Object != nil)
		{
			if (PFMove->RightKey && !PFMove->LeftKey)
			{
				PFMove->XVelocity += PFMove->XAccel; // add to x velocity when pressing right
			}
			if (PFMove->LeftKey && !PFMove->RightKey)
			{
				PFMove->XVelocity -= PFMove->XAccel; // sub from x velocity when pressing left
			}
			if (PFMove->XVelocity != 0 && ((!PFMove->LeftKey && !PFMove->RightKey) || (PFMove->LeftKey && PFMove->RightKey)))
			{
				// slow the object down when not pressing right or left
				PFMove->XVelocity -= PFMove->XVelocity / abs(PFMove->XVelocity) * PFMove->XDecel;
				if (PFMove->XVelocity <= PFMove->XDecel && PFMove->XVelocity >= 0 - PFMove->XDecel)
				{
					PFMove->XVelocity = 0; // set x velocity to 0 when it's close to 0
				}
			}
			/////////////////////////////////////////////////////////////////////////
			// MOVEMENT LOOPS
			// set velocitities to max and min
			PFMove->XVelocity = MIN(MAX(PFMove->XVelocity, 0 - PFMove->MaxXVelocity), PFMove->MaxXVelocity);
			PFMove->YVelocity = MIN(MAX(PFMove->YVelocity + PFMove->Gravity, 0 - PFMove->MaxYVelocity), PFMove->MaxYVelocity);
			int tmpXVelocity = PFMove->XVelocity + PFMove->AddXVelocity;
			int tmpYVelocity = PFMove->YVelocity + PFMove->AddYVelocity;
			PFMove->XMoveCount += abs(tmpXVelocity);
			PFMove->YMoveCount += abs(tmpYVelocity);

			// X MOVEMENT LOOP
			while (PFMove->XMoveCount > 100)
			{
				if (![self IsOverObstacle])
				{
					Object->hoX += tmpXVelocity / abs(tmpXVelocity);
				}

				if ([self IsOverObstacle])
				{
					for (int up = 0; up < PFMove->StepUp; up++) // Step up (slopes)
					{
						Object->hoY--;
						if (![self IsOverObstacle])
						{
							break;
						}
					}
					if ([self IsOverObstacle])
					{
						Object->hoY += (short) PFMove->StepUp;
						Object->hoX -= tmpXVelocity / abs(tmpXVelocity);
						PFMove->XVelocity = PFMove->XMoveCount = 0;
					}
				}
				PFMove->XMoveCount -= 100;
				Object->roc->rcChanged = YES;
			}

			// Y MOVEMENT LOOP
			while (PFMove->YMoveCount > 100)
			{
				if (![self IsOverObstacle])
				{
					Object->hoY += tmpYVelocity / abs(tmpYVelocity);
					PFMove->OnGround = NO;
				}

				if ([self IsOverObstacle])
				{
					Object->hoY -= tmpYVelocity / abs(tmpYVelocity);
					if (tmpYVelocity > 0)
					{
						PFMove->OnGround = YES;
					}
					PFMove->YVelocity = PFMove->YMoveCount = 0;
				}

				if ([self IsOverJumpThrough] && tmpYVelocity > 0)
				{
					if (Col->JumpThroughColTop)
					{
						Object->hoY--;
						if (![self IsOverJumpThrough])
						{
							Object->hoY -= tmpYVelocity / abs(tmpYVelocity);
							PFMove->YVelocity = PFMove->YMoveCount = 0;
							PFMove->OnGround = YES;
						}
						Object->hoY++;
					}
					else
					{
						Object->hoY -= tmpYVelocity / abs(tmpYVelocity);
						PFMove->YVelocity = PFMove->YMoveCount = 0;
						PFMove->OnGround = YES;
					}
				}
				PFMove->YMoveCount -= 100;
				Object->roc->rcChanged = YES;

			}
			if (PFMove->SlopeCorrection > 0 && tmpYVelocity >= 0)
			{
				BOOL tmp = NO;
				// Slope correction
				for (int sc = 0; sc < PFMove->SlopeCorrection; sc++)
				{
					Object->hoY++;
					if ([self IsOverObstacle])
					{
						Object->hoY--;
						PFMove->OnGround = YES;
						tmp = YES;
						break;
					}
				}
				if (tmp == NO)
				{
					Object->hoY -= (short) PFMove->SlopeCorrection;
				}
			}
		}
		if(Object == nil)
		{
			hasObject = NO;
			ObjFixed = 0;
		}
	}
	// Reset values
	PFMove->RightKey = NO;
	PFMove->LeftKey = NO;
	return 0;
}

// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CID_ObstacleTest:
			return YES;
		case CID_JumpThroughTest:
			return YES;
		case CID_IsOnGround:
			return PFMove->OnGround;
		case CID_IsJumping:
			return (!PFMove->OnGround && PFMove->YVelocity <= 0);
		case CID_IsFalling:
			return (!PFMove->OnGround && PFMove->YVelocity > 0);
		case CID_IsPaused:
			return PFMove->Paused;
		case CID_IsMoving:
			return (abs(PFMove->XVelocity) > 0);
	}
	return NO;
}




// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case AID_ColObstacle:
			Col->Obstacle = YES;
			break;
		case AID_ColJumpThrough:
			Col->JumpThrough = YES;
			break;
		case AID_SetObjectP:
			[self SetObject:[act getParamObject:rh withNum:0]];
			break;
		case AID_MoveRight:
			PFMove->RightKey = YES;
			break;
		case AID_MoveLeft:
			PFMove->LeftKey = YES;
			break;
		case AID_Jump:
			PFMove->YVelocity = 0 - PFMove->JumpStrength;
			break;
		case AID_SetXVelocity:
			PFMove->XVelocity = [act getParamExpression:rh withNum:0];
			break;
		case AID_SetYVelocity:
			PFMove->YVelocity = [act getParamExpression:rh withNum:0];
			break;
		case AID_SetMaxXVelocity:
			PFMove->MaxXVelocity = [act getParamExpression:rh withNum:0];
			break;
		case AID_SetMaxYVelocity:
			PFMove->MaxYVelocity = [act getParamExpression:rh withNum:0];
			break;
		case AID_SetXAccel:
			PFMove->XAccel = [act getParamExpression:rh withNum:0];
			break;
		case AID_SetXDecel:
			PFMove->XDecel = [act getParamExpression:rh withNum:0];
			break;
		case AID_SetGravity:
			PFMove->Gravity = [act getParamExpression:rh withNum:0];
			break;
		case AID_SetJumpStrength:
			PFMove->JumpStrength = [act getParamExpression:rh withNum:0];
			break;
		case AID_SetJumpHoldHeight:
			PFMove->JumpHoldHeight = [act getParamExpression:rh withNum:0];
			break;
		case AID_SetStepUp:
			PFMove->StepUp = [act getParamExpression:rh withNum:0];
			break;
		case AID_JumpHold:
			PFMove->YVelocity -= PFMove->JumpHoldHeight;
			break;
		case AID_Pause:
			PFMove->Paused = YES;
			break;
		case AID_UnPause:
			PFMove->Paused = NO;
			break;
		case AID_SetSlopeCorrection:
			PFMove->SlopeCorrection = [act getParamExpression:rh withNum:0];
			break;
		case AID_SetAddXVelocity:
			PFMove->AddXVelocity = [act getParamExpression:rh withNum:0];
			break;
		case AID_SetAddYVelocity:
			PFMove->AddYVelocity = [act getParamExpression:rh withNum:0];
			break;
	}
}

-(void)SetObject:(CObject*)object
{
	if(object != nil)
	{
		ObjFixed = [object fixedValue];
		hasObject = YES;
	}
}



// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EID_GetXVelocity:
			return [rh getTempValue:PFMove->XVelocity];
		case EID_GetYVelocity:
			return [rh getTempValue:PFMove->YVelocity];
		case EID_GetMaxXVelocity:
			return [rh getTempValue:PFMove->MaxXVelocity];
		case EID_GetMaxYVelocity:
			return [rh getTempValue:PFMove->MaxYVelocity];
		case EID_GetXAccel:
			return [rh getTempValue:PFMove->XAccel];
		case EID_GetXDecel:
			return [rh getTempValue:PFMove->XDecel];
		case EID_GetGravity:
			return [rh getTempValue:PFMove->Gravity];
		case EID_GetJumpStrength:
			return [rh getTempValue:PFMove->JumpStrength];
		case EID_GetJumpHoldHeight:
			return [rh getTempValue:PFMove->JumpHoldHeight];
		case EID_GetStepUp:
			return [rh getTempValue:PFMove->StepUp];
		case EID_GetSlopeCorrection:
			return [rh getTempValue:PFMove->SlopeCorrection];
		case EID_GetAddXVelocity:
			return [rh getTempValue:PFMove->AddXVelocity];
		case EID_GetAddYVelocity:
			return [rh getTempValue:PFMove->AddYVelocity];
	}
	return [rh getTempValue:0];//won't be used
}

@end


// Classes accessoires ///////////////////////////////////////////////////////////////
@implementation PlatformCOL

@end

@implementation PlatformMove

@end