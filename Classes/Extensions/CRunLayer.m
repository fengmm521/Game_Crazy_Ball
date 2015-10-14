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
// CRUNLAYER : Objet layer
//
//----------------------------------------------------------------------------------
#import "CRunLayer.h"
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

@implementation CRunLayer


-(int)getNumberOfConditions
{
	return 12;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	wCurrentLayer = ho->hoLayer;
	return NO;
}

// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case 0:
			return [self cndAtBack:cnd];
		case 1:
			return [self cndAtFront:cnd];
		case 2:
			return [self cndAbove:cnd];
		case 3:
			return [self cndBelow:cnd];
		case 4:
			return [self cndBetween:cnd];
		case 5:
			return [self cndAtBackObj:cnd];
		case 6:
			return [self cndAtFrontObj:cnd];
		case 7:
			return [self cndAboveObj:cnd];
		case 8:
			return [self cndBelowObj:cnd];
		case 9:
			return [self cndBetweenObj:cnd];
		case 10:
			return [self cndIsLayerVisible:cnd];
		case 11:
			return [self cndIsLayerVisibleByName:cnd];
	}
	return NO;
}

-(BOOL)cndAtBack:(CCndExtension*)cnd
{
	int param1 = [cnd getParamExpression:rh withNum:0];
	return [self cndAtBackRout:param1];
}

-(BOOL)cndAtBackRout:(int)param1
{
	int nLayer = wCurrentLayer;
	
	// Dynamic objects layer
	nLayer = nLayer * 2 + 1;
	
	CSpriteGen* objAddr = ho->hoAdRunHeader->spriteGen;
	
	CSprite* sprPtr = objAddr->firstSprite;
	while (sprPtr != nil && (sprPtr->sprFlags & SF_TOKILL) != 0 && sprPtr->sprLayer < nLayer)
	{
		sprPtr = sprPtr->objNext;
	}
	
	if (sprPtr != nil && sprPtr->sprLayer == nLayer)
	{
		CObject* roPtr = sprPtr->sprExtraInfo;
		
		int FValue = (roPtr->hoCreationId << 16) + (((int) roPtr->hoNumber) & 0xFFFF);
		
		if (param1 == 0)
		{
			param1 = holdFValue;
		}
		
		// Returns TRUE if the object is the first sprite (= if it's fixed value is the same as the one of the first sprite)
		if (param1 == FValue)
		{
			return YES;
		}
	}
	return NO;
}

-(BOOL)cndAtFront:(CCndExtension*)cnd
{
	int param1 = [cnd getParamExpression:rh withNum:0];
	return [self cndAtFrontRout:param1];
}

-(BOOL)cndAtFrontRout:(int)param1
{
	int nLayer = wCurrentLayer;
	
	// Dynamic objects layer
	nLayer = nLayer * 2 + 1;
	
	CSpriteGen* objAddr = ho->hoAdRunHeader->spriteGen;
	
	CSprite* sprPtr = objAddr->lastSprite;
	while (sprPtr != nil && (sprPtr->sprFlags & SF_TOKILL) != 0 && sprPtr->sprLayer > nLayer)
	{
		sprPtr = sprPtr->objPrev;
	}
	
	if (sprPtr != nil && sprPtr->sprLayer == nLayer)
	{
		CObject* roPtr = sprPtr->sprExtraInfo;
		
		int FValue = (roPtr->hoCreationId << 16) + (((int) roPtr->hoNumber) & 0xFFFF);
		
		if (param1 == 0)
		{
			param1 = holdFValue;
		}
		
		// Returns TRUE if the object is the last sprite (= if it's fixed value is the same as the one of the last sprite)
		if (param1 == FValue)
		{
			return YES;
		}
	}
	return NO;
	
}

-(BOOL)cndAbove:(CCndExtension*)cnd
{
	int param1 = [cnd getParamExpression:rh withNum:0];
	int param2 = [cnd getParamExpression:rh withNum:1];
	return [self cndAboveRout:param1  withParam1:param2];
}

-(BOOL)cndAboveRout:(int)param1 withParam1:(int)param2
{
	CObject* roPtr1 = nil;
	CObject* roPtr2 = nil;
	
	CSprite* sprPtr1 = nil;
	CSprite* sprPtr2 = nil;
	
	int FValue1;
	int FValue2;
	
	if (param1 == 0)
	{
		param1 = holdFValue;
	}
	
	if (param2 == 0)
	{
		param2 = holdFValue;
	}
	
	int count1 = 0;
	int o1;
	for (o1 = 0; o1 < ho->hoAdRunHeader->rhNObjects; o1++)
	{
		while (ho->hoAdRunHeader->rhObjectList[count1] == nil)
		{
			count1++;
		}
		roPtr1 = ho->hoAdRunHeader->rhObjectList[count1];
		count1++;
		
		FValue1 = (roPtr1->hoCreationId << 16) + (((int) roPtr1->hoNumber) & 0xFFFF);
		if (param1 == FValue1)
		{
			int count2 = 0;
			int o2;
			sprPtr1 = roPtr1->roc->rcSprite;
			
			//We have a match, get the second object
			for (o2 = 0; o2 < ho->hoAdRunHeader->rhNObjects; o2++)
			{
				while (ho->hoAdRunHeader->rhObjectList[count2] == nil)
				{
					count2++;
				}
				roPtr2 = ho->hoAdRunHeader->rhObjectList[count2];
				count2++;
				
				FValue2 = (roPtr2->hoCreationId << 16) + (((int) roPtr2->hoNumber) & 0xFFFF);
				
				if (param2 == FValue2)
				{
					sprPtr2 = roPtr2->roc->rcSprite;
					break;
				}
			}
			
			if ((sprPtr1 != nil) && (sprPtr2 != nil))
			{
				// MMF 2
				if (sprPtr1->sprLayer != sprPtr2->sprLayer)			// Different layer?
				{
					return (sprPtr1->sprLayer > sprPtr2->sprLayer);
				}
				
				if (sprPtr1->sprZOrder > sprPtr2->sprZOrder)
				{
					return YES;
				}
			}
			break;
		}
	}
	return NO;
}

-(BOOL)cndBelow:(CCndExtension*)cnd
{
	int param1 = [cnd getParamExpression:rh withNum:0];
	int param2 = [cnd getParamExpression:rh withNum:1];
	return [self cndBelowRout:param1  withParam1:param2];
}

-(BOOL)cndBelowRout:(int)param1 withParam1:(int)param2
{
	CObject* roPtr1 = nil;
	CObject* roPtr2 = nil;
	
	CSprite* sprPtr1 = nil;
	CSprite* sprPtr2 = nil;
	
	int FValue1;
	int FValue2;
	
	if (param1 == 0)
	{
		param1 = holdFValue;
	}
	
	if (param2 == 0)
	{
		param2 = holdFValue;
	}
	
	int count1 = 0;
	int o1;
	for (o1 = 0; o1 < ho->hoAdRunHeader->rhNObjects; o1++)
	{
		while (ho->hoAdRunHeader->rhObjectList[count1] == nil)
		{
			count1++;
		}
		roPtr1 = ho->hoAdRunHeader->rhObjectList[count1];
		count1++;
		
		FValue1 = (roPtr1->hoCreationId << 16) + (((int) roPtr1->hoNumber) & 0xFFFF);
		if (param1 == FValue1)
		{
			int count2 = 0;
			int o2;
			sprPtr1 = roPtr1->roc->rcSprite;
			
			//We have a match, get the second object
			for (o2 = 0; o2 < ho->hoAdRunHeader->rhNObjects; o2++)
			{
				while (ho->hoAdRunHeader->rhObjectList[count2] == nil)
				{
					count2++;
				}
				roPtr2 = ho->hoAdRunHeader->rhObjectList[count2];
				count2++;
				
				FValue2 = (roPtr2->hoCreationId << 16) + (((int) roPtr2->hoNumber) & 0xFFFF);
				
				if (param2 == FValue2)
				{
					sprPtr2 = roPtr2->roc->rcSprite;
					break;
				}
			}
			
			if ((sprPtr1 != nil) && (sprPtr2 != nil))
			{
				// MMF 2
				if (sprPtr1->sprLayer != sprPtr2->sprLayer)			// Different layer?
				{
					return (sprPtr1->sprLayer < sprPtr2->sprLayer);
				}
				
				if (sprPtr1->sprZOrder < sprPtr2->sprZOrder)
				{
					return YES;
				}
			}
			break;
		}
	}
	return NO;
}

-(BOOL)cndBetween:(CCndExtension*)cnd
{
	int p1 = [cnd getParamExpression:rh withNum:0];
	int p2 = [cnd getParamExpression:rh withNum:1];
	int p3 = [cnd getParamExpression:rh withNum:2];
	
	CObject* roPtr1 = nil;
	CObject* roPtr2 = nil;
	
	CSprite* sprPtr1 = nil;
	CSprite* sprPtr2 = nil;
	CSprite* sprPtr3 = nil;
	
	int FValue1;
	int FValue2;
	
	if (p1 == 0)
	{
		p1 = holdFValue;
	}
	
	if (p2 == 0)
	{
		p2 = holdFValue;
	}
	
	if (p3 == 0)
	{
		p3 = holdFValue;
	}
	
	
	BOOL bFound2 = NO;
	BOOL bFound3 = NO;
	
	int count1 = 0;
	int o1;
	for (o1 = 0; o1 < ho->hoAdRunHeader->rhNObjects; o1++)
	{
		while (ho->hoAdRunHeader->rhObjectList[count1] == nil)
		{
			count1++;
		}
		roPtr1 = ho->hoAdRunHeader->rhObjectList[count1];
		count1++;
		
		FValue1 = (roPtr1->hoCreationId << 16) + (((int) roPtr1->hoNumber) & 0xFFFF);
		
		if (p1 == FValue1)
		{
			int count2 = 0;
			int o2;
			sprPtr1 = roPtr1->roc->rcSprite;
			
			//We have a match, get the second object
			for (o2 = 0; o2 < ho->hoAdRunHeader->rhNObjects; o2++)
			{
				while (ho->hoAdRunHeader->rhObjectList[count2] == nil)
				{
					count2++;
				}
				roPtr2 = ho->hoAdRunHeader->rhObjectList[count2];
				count2++;
				
				FValue2 = (roPtr2->hoCreationId << 16) + (((int) roPtr2->hoNumber) & 0xFFFF);
				
				if (p2 == FValue2)
				{
					sprPtr2 = roPtr2->roc->rcSprite;
					bFound2 = YES;
				}
				
				if (p3 == FValue2)
				{
					sprPtr3 = roPtr2->roc->rcSprite;
					bFound3 = YES;
				}
				
				if (bFound2 && bFound3)
				{
					break;
				}
			}
			
			if ((sprPtr1 != nil) && (sprPtr2 != nil) && (sprPtr3 != nil))
			{
				// MMF2
				int n1, n2, n3;
				n1 = n2 = n3 = -1;
				
				CSpriteGen* objAddr = ho->hoAdRunHeader->spriteGen;
				int i = 0;
				CSprite* pSpr = objAddr->firstSprite;
				while (pSpr != nil)
				{
					if (pSpr == sprPtr1)
					{
						n1 = i;
						if (n2 != -1 && n3 != -1)
						{
							break;
						}
					}
					else if (pSpr == sprPtr2)
					{
						n2 = i;
						if (n1 != -1 && n3 != -1)
						{
							break;
						}
					}
					else if (pSpr == sprPtr3)
					{
						n3 = i;
						if (n1 != -1 && n2 != -1)
						{
							break;
						}
					}
					pSpr = pSpr->objNext;
					i++;
				}
				if ((n3 > n1 && n1 > n2) || (n2 > n1 && n1 > n3))
				{
					return YES;
				}
			}
			break;
		}
	}
	return NO;
}

-(BOOL)cndAtBackObj:(CCndExtension*)cnd
{
	LPEVP param1 = [cnd getParamObject:rh withNum:0];
	return [self lyrProcessCondition:param1  withParam1:nil  andParam2:0];
}

-(BOOL)cndAtFrontObj:(CCndExtension*)cnd
{
	LPEVP param1 = [cnd getParamObject:rh withNum:0];
	return [self lyrProcessCondition:param1  withParam1:nil  andParam2:1];
}

-(BOOL)cndAboveObj:(CCndExtension*)cnd
{
	LPEVP param1 = [cnd getParamObject:rh withNum:0];
	LPEVP param2 = [cnd getParamObject:rh withNum:1];
	return [self lyrProcessCondition:param1  withParam1:param2  andParam2:2];
}

-(BOOL)cndBelowObj:(CCndExtension*)cnd
{
	LPEVP param1 = [cnd getParamObject:rh withNum:0];
	LPEVP param2 = [cnd getParamObject:rh withNum:1];
	return [self lyrProcessCondition:param1  withParam1:param2  andParam2:3];
}

-(BOOL)cndBetweenObj:(CCndExtension*)cnd
{
	BOOL IsAbove = NO;
	BOOL IsBelow = NO;
	
	LPEVP ObjectA = [cnd getParamObject:rh withNum:0];
	LPEVP ObjectB = [cnd getParamObject:rh withNum:1];
	LPEVP ObjectC = [cnd getParamObject:rh withNum:2];
	
	BOOL IsBetween = NO;
	
	// Is Object A between Object B and Object C?
	if ((IsAbove = [self lyrProcessCondition:ObjectA  withParam1:ObjectB  andParam2:2]))
	{
		if ((IsBelow = [self lyrProcessCondition:ObjectA  withParam1:ObjectC  andParam2:3]))
		{
			IsBetween = YES;
		}
	}
	
	if (!IsBetween)
	{
		IsAbove = NO;
		
		[self lyrResetEventList:[self lyrGetOILfromEVP:ObjectA]];
		if ((IsBelow = [self lyrProcessCondition:ObjectA  withParam1:ObjectB  andParam2:3]))
		{
			if ((IsAbove = [self lyrProcessCondition:ObjectA  withParam1:ObjectC  andParam2:2]))
			{
				IsBetween = YES;
			}
		}
	}
	return IsBetween;
}

-(BOOL)cndIsLayerVisible:(CCndExtension*)cnd
{
	int param1 = [cnd getParamExpression:rh withNum:0];
	if (param1 > 0 && param1 <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[param1 - 1];
		return (((pLayer->dwOptions & FLOPT_VISIBLE) != 0 && (pLayer->dwOptions & FLOPT_TOHIDE) == 0) || (pLayer->dwOptions & FLOPT_TOSHOW) != 0);
	}
	return NO;
}

// Returns index of layer (1-based) or 0 if layer not found
-(int)FindLayerByName:(NSString*)pName
{
	if (pName != nil)
	{
		int nLayer;
		for (nLayer = 0; nLayer < ho->hoAdRunHeader->rhFrame->nLayers; nLayer++)
		{
			CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer];
			if (pLayer->pName != nil && [pName caseInsensitiveCompare:pLayer->pName] == 0)
			{
				return (nLayer + 1);
			}
		}
	}
	return 0;
}

-(BOOL)cndIsLayerVisibleByName:(CCndExtension*)cnd
{
	NSString* param1 = [cnd getParamExpString:rh withNum:0];
	
	int nLayer = [self FindLayerByName:param1];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
		return (((pLayer->dwOptions & FLOPT_VISIBLE) != 0 && (pLayer->dwOptions & FLOPT_TOHIDE) == 0) || (pLayer->dwOptions & FLOPT_TOSHOW) != 0);
	}
	return NO;
}



// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case 0:
			[self actBackOne:act];
			break;
		case 1:
			[self actForwardOne:act];
			break;
		case 2:
			[self actSwap:act];
			break;
		case 3:
			[self actSetObj:act];
			break;
		case 4:
			[self actBringFront:act];
			break;
		case 5:
			[self actSendBack:act];
			break;
		case 6:
			[self actBackN:act];
			break;
		case 7:
			[self actForwardN:act];
			break;
		case 8:
			[self actReverse:act];
			break;
		case 9:
			[self actMoveAbove:act];
			break;
		case 10:
			[self actMoveBelow:act];
			break;
		case 11:
			[self actMoveToN:act];
			break;
		case 12:
			[self actSortByXUP:act];
			break;
		case 13:
			[self actSortByYUP:act];
			break;
		case 14:
			[self actSortByXDOWN:act];
			break;
		case 15:
			[self actSortByYDOWN:act];
			break;
		case 16:
			[self actBackOneObj:act];
			break;
		case 17:
			[self actForwardOneObj:act];
			break;
		case 18:
			[self actSwapObj:act];
			break;
		case 19:
			[self actBringFrontObj:act];
			break;
		case 20:
			[self actSendBackObj:act];
			break;
		case 21:
			[self actBackNObj:act];
			break;
		case 22:
			[self actForwardNObj:act];
			break;
		case 23:
			[self actMoveAboveObj:act];
			break;
		case 24:
			[self actMoveBelowObj:act];
			break;
		case 25:
			[self actMoveToNObj:act];
			break;
		case 26:
			[self actSortByALTUP:act];
			break;
		case 27:
			[self actSortByALTDOWN:act];
			break;
		case 28:
			[self actSetLayerX:act];
			break;
		case 29:
			[self actSetLayerY:act];
			break;
		case 30:
			[self actSetLayerXY:act];
			break;
		case 31:
			[self actShowLayer:act];
			break;
		case 32:
			[self actHideLayer:act];
			break;
		case 33:
			[self actSetLayerXByName:act];
			break;
		case 34:
			[self actSetLayerYByName:act];
			break;
		case 35:
			[self actSetLayerXYByName:act];
			break;
		case 36:
			[self actShowLayerByName:act];
			break;
		case 37:
			[self actHideLayerByName:act];
			break;
		case 38:
			[self actSetCurrentLayer:act];
			break;
		case 39:
			[self actSetCurrentLayerByName:act];
			break;
		case 40:
			[self actSetLayerCoefX:act];
			break;
		case 41:
			[self actSetLayerCoefY:act];
			break;
		case 42:
			[self actSetLayerCoefXByName:act];
			break;
		case 43:
			[self actSetLayerCoefYByName:act];
			break;
	}
}

-(void)actBackOne:(CActExtension*)act
{
	int param1 = [act getParamExpression:rh withNum:0];
	[self actBackOneRout:param1];
}

-(void)actBackOneRout:(int)param1
{
	CSprite* sprPtr1;
	CSprite* sprPtr2;
	if ((sprPtr1 = [self lyrGetSprite:param1]) != nil)
	{
		if ((sprPtr2 = sprPtr1->objPrev) != nil)
		{
			if (sprPtr1->sprLayer == sprPtr2->sprLayer)
			{
				[self lyrSwapThem:sprPtr1  withParam1:sprPtr2  andParam2:YES];
			}
		}
	}
}

-(void)actForwardOne:(CActExtension*)act
{
	int param1 = [act getParamExpression:rh withNum:0];
	[self actForwardOneRout:param1];
}

-(void)actForwardOneRout:(int)param1
{
	CSprite* sprPtr1;
	CSprite* sprPtr2;
	
	if ((sprPtr1 = [self lyrGetSprite:param1]) != nil)
	{
		if ((sprPtr2 = sprPtr1->objNext) != nil)
		{
			if (sprPtr1->sprLayer == sprPtr2->sprLayer)
			{
				[self lyrSwapThem:sprPtr1  withParam1:sprPtr2  andParam2:YES];
			}
		}
	}
}

-(void)actSwap:(CActExtension*)act
{
	int param1 = [act getParamExpression:rh withNum:0];
	int param2 = [act getParamExpression:rh withNum:1];
	[self actSwapRout:param1  withParam1:param2];
}

-(void)actSwapRout:(int)param1 withParam1:(int)param2
{
	CSprite* sprPtr1;
	CSprite* sprPtr2;
	
	if ((sprPtr1 = [self lyrGetSprite:param1]) != nil)
	{
		if ((sprPtr2 = [self lyrGetSprite:param2]) != nil)
		{
			if (sprPtr1->sprLayer == sprPtr2->sprLayer)
			{
				[self lyrSwapThem:sprPtr1  withParam1:sprPtr2  andParam2:YES];
			}
		}
	}
}

-(void)actSetObj:(CActExtension*)act
{
	CObject* roPtr = [act getParamObject:rh withNum:0];
	if (roPtr!=nil)
	{
		holdFValue = [self lyrGetFVfromOIL:roPtr->hoOiList];
	}
}

-(void)actBringFront:(CActExtension*)act
{
	int param1 = [act getParamExpression:rh withNum:0];
	[self actBringFrontRout:param1];
}

-(void)actBringFrontRout:(int)param1
{
	CSpriteGen* ObjAddr = ho->hoAdRunHeader->spriteGen;
	
	if (ObjAddr->lastSprite != nil)
	{
		CSprite* pSpr = [self lyrGetSprite:param1];		// (npSpr)roPtr->roc.rcSprite;
		if (pSpr != nil)
		{
			// Exchange the sprite with the next one until the end of the list
			while (pSpr != ObjAddr->lastSprite)
			{
				CSprite* pSprNext = pSpr->objNext;
				if (pSprNext == nil)
				{
					break;
				}
				
				if (pSpr->sprLayer != pSprNext->sprLayer)
				{
					break;
				}
				
				[self lyrSwapSpr:pSpr  withParam1:pSprNext];
			}
			
			// Force redraw
			if ((pSpr->sprFlags & SF_HIDDEN) == 0)
			{
				[ObjAddr activeSprite:pSpr  withFlags:AS_REDRAW  andRect:CRectNil];
			}
		}
	}
}

-(void)actSendBack:(CActExtension*)act
{
	int param1 = [act getParamExpression:rh withNum:0];
	[self actSendBackRout:param1];
}

-(void)actSendBackRout:(int)param1
{
	CSpriteGen* ObjAddr = ho->hoAdRunHeader->spriteGen;
	
	if (ObjAddr->firstSprite != nil)
	{
		CSprite* pSpr = [self lyrGetSprite:param1];		// (npSpr)roPtr->roc.rcSprite;
		if (pSpr != nil)
		{
			// Exchange the sprite with the next one until the end of the list
			while (pSpr != ObjAddr->firstSprite)
			{
				CSprite* pSprPrev = pSpr->objPrev;
				if (pSprPrev == nil)
				{
					break;
				}
				if (pSpr->sprLayer != pSprPrev->sprLayer)
				{
					break;
				}
				
				[self lyrSwapSpr:pSprPrev  withParam1:pSpr];
			}
			
			// Force redraw
			if ((pSpr->sprFlags & SF_HIDDEN) == 0)
			{
				[ObjAddr activeSprite:pSpr  withFlags:AS_REDRAW  andRect:CRectNil];
			}
		}
	}
	
}

-(void)actBackN:(CActExtension*)act
{
	int param1 = [act getParamExpression:rh withNum:0];
	int param2 = [act getParamExpression:rh withNum:1];
	[self actBackNRout:param1  withParam1:param2];
}

-(void)actBackNRout:(int)param1 withParam1:(int)param2
{
	CSprite* sprPtr1;
	CSprite* sprPtr2;
	
	if ((sprPtr1 = [self lyrGetSprite:param1]) != nil)
	{
		for (int n = 0; n < param2; n++)
		{
			if ((sprPtr2 = sprPtr1->objPrev) == nil)
			{
				break;
			}
			
			if (sprPtr1->sprLayer != sprPtr2->sprLayer)
			{
				break;
			}
			
			[self lyrSwapThem:sprPtr1  withParam1:sprPtr2  andParam2:YES];
		}
	}
}

-(void)actForwardN:(CActExtension*)act
{
	int param1 = [act getParamExpression:rh withNum:0];
	int param2 = [act getParamExpression:rh withNum:1];
	[self actForwardNRout:param1  withParam1:param2];
}

-(void)actForwardNRout:(int)param1 withParam1:(int)param2
{
	CSprite* sprPtr1;
	CSprite* sprPtr2;
	
	if ((sprPtr1 = [self lyrGetSprite:param1]) != nil)
	{
		for (int n = 0; n < param2; n++)
		{
			if ((sprPtr2 = sprPtr1->objNext) == nil)
			{
				break;
			}
			
			if (sprPtr1->sprLayer != sprPtr2->sprLayer)
			{
				break;
			}
			
			[self lyrSwapThem:sprPtr1  withParam1:sprPtr2  andParam2:YES];
		}
	}
}

-(void)actReverse:(CActExtension*)act
{
	CSprite* sprPtr1;
	CSprite* sprPtr2;
	
	CSprite* lastPrev;
	CSprite* lastNext;
	
	//Runheader for this object
	int nLayer = wCurrentLayer;
	
	// Dynamic objects layer
	nLayer = nLayer * 2 + 1;
	
	CSpriteGen* ObjAddr = ho->hoAdRunHeader->spriteGen;
	
	// Get first layer sprite
	lastNext = ObjAddr->firstSprite;
	while (lastNext != nil && (lastNext->sprFlags & SF_TOKILL) != 0 && lastNext->sprLayer < nLayer)
	{
		lastNext = lastNext->objNext;
	}
	if (lastNext == nil || lastNext->sprLayer != nLayer)
	{
		return;
	}
	
	// Get last layer sprite
	lastPrev = ObjAddr->lastSprite;
	while (lastPrev != nil && (lastPrev->sprFlags & SF_TOKILL) != 0 && lastPrev->sprLayer > nLayer)
	{
		lastPrev = lastPrev->objNext;
	}
	if (lastPrev == nil || lastPrev->sprLayer != nLayer)
	{
		return;
	}
	
	if (lastPrev == lastNext)
	{
		return;
	}
	
	do
	{
		sprPtr1 = lastNext;
		sprPtr2 = lastPrev;
		
		lastNext = sprPtr1->objNext;
		lastPrev = sprPtr2->objPrev;
		
		[self lyrSwapThem:sprPtr1  withParam1:sprPtr2  andParam2:YES];
	} while ((lastNext != lastPrev) && (lastNext != sprPtr1) && (lastNext != sprPtr2));
}

-(void)actMoveAbove:(CActExtension*)act
{
	int param1 = [act getParamExpression:rh withNum:0];
	int param2 = [act getParamExpression:rh withNum:1];
	[self actMoveAboveRout:param1  withParam1:param2];
}

-(void)actMoveAboveRout:(int)param1 withParam1:(int)param2
{
	CSprite* sprPtr1;
	CSprite* sprPtr2;
	
	if ((sprPtr1 = [self lyrGetSprite:param1]) != nil)
	{
		if ((sprPtr2 = [self lyrGetSprite:param2]) != nil)
		{
			if (sprPtr1->sprLayer == sprPtr2->sprLayer)
			{
				CSprite* pSpr = sprPtr1->objNext;
				while (pSpr != nil && pSpr != sprPtr2)
				{
					pSpr = pSpr->objNext;
				}
				if (pSpr != nil)
				{
					// Exchange the sprite with the next one until the second one is reached
					CSprite* pNextSpr;
					do
					{
						pNextSpr = sprPtr1->objNext;
						if (pNextSpr == nil)
						{
							break;
						}
						[self lyrSwapSpr:sprPtr1  withParam1:pNextSpr];
					} while (pNextSpr != sprPtr2);
					
					// Force redraw
					if ((sprPtr1->sprFlags & SF_HIDDEN) == 0)
					{
						[ho->hoAdRunHeader->spriteGen activeSprite:sprPtr1  withFlags:AS_REDRAW  andRect:CRectNil];
					}
				}
			}
		}
	}
}

-(void)actMoveBelow:(CActExtension*)act
{
	int param1 = [act getParamExpression:rh withNum:0];
	int param2 = [act getParamExpression:rh withNum:1];
	[self actMoveBelowRout:param1  withParam1:param2];
}

-(void)actMoveBelowRout:(int)param1 withParam1:(int)param2
{
	CSprite* sprPtr1;
	CSprite* sprPtr2;
	
	if ((sprPtr1 = [self lyrGetSprite:param1]) != nil)
	{
		if ((sprPtr2 = [self lyrGetSprite:param2]) != nil)
		{
			if (sprPtr1->sprLayer == sprPtr2->sprLayer)
			{
				CSprite* pSpr = sprPtr1->objPrev;
				while (pSpr != nil && pSpr != sprPtr2)
				{
					pSpr = pSpr->objPrev;
				}
				if (pSpr != nil)
				{
					// Exchange the sprite with the previous one until the second one is reached
					CSprite* pPrevSpr;	//= sprPtr1;
					do
					{
						pPrevSpr = sprPtr1->objPrev;
						if (pPrevSpr == nil)
						{
							break;
						}
						[self lyrSwapSpr:sprPtr1  withParam1:pPrevSpr];
					} while (pPrevSpr != sprPtr2);
					
					// Force redraw
					if ((sprPtr1->sprFlags & SF_HIDDEN) == 0)
					{
						[ho->hoAdRunHeader->spriteGen activeSprite:sprPtr1  withFlags:AS_REDRAW andRect:CRectNil];
					}
				}
			}
		}
	}
	
}

-(void)actMoveToN:(CActExtension*)act
{
	int param1 = [act getParamExpression:rh withNum:0];
	int param2 = [act getParamExpression:rh withNum:1];
	[self actMoveToNRout:param1  withParam1:param2];
}

-(void)actMoveToNRout:(int)param1 withParam1:(int)param2
{
	CSpriteGen* ObjAddr = ho->hoAdRunHeader->spriteGen;
	
	CSprite* sprPtr1;
	CSprite* sprPtr2;
	
	int lvlCount = 0;
	
	if ((sprPtr1 = [self lyrGetSprite:param1]) != nil)
	{
		sprPtr2 = ObjAddr->firstSprite;
		
		// Look for 1st object in the same layer
		while (sprPtr2 != nil && sprPtr1->sprLayer != sprPtr2->sprLayer)
		{
			sprPtr2 = sprPtr2->objNext;
		}
		if (sprPtr2 == nil || sprPtr1->sprLayer != sprPtr2->sprLayer)
		{
			return;
		}
		
		// Look for position N in the same layer
		while (sprPtr2 != nil && (++lvlCount != param2))
		{
			sprPtr2 = sprPtr2->objNext;
			if (sprPtr2 != nil && sprPtr1->sprLayer != sprPtr2->sprLayer)
			{
				sprPtr2 = nil;
				break;
			}
		}
		
		// Position found, swap sprites
		if ((sprPtr2 != nil) && (sprPtr1 != sprPtr2))		// MMF 1.5: sprPtr2 != NULL && (sprPtr1->sprLayer != sprPtr2->sprLayer))
		{
			// MMF 2
			CSprite* pSpr = sprPtr1->objPrev;
			while (pSpr != nil && pSpr != sprPtr2)
			{
				pSpr = pSpr->objPrev;
			}
			if (pSpr != nil)
			{
				// Exchange the sprite with the previous one until the second one is reached
				CSprite* pPrevSpr;		//= sprPtr1;
				do
				{
					pPrevSpr = sprPtr1->objPrev;
					if (pPrevSpr == nil)
					{
						break;
					}
					[self lyrSwapSpr:sprPtr1  withParam1:pPrevSpr];
				} while (pPrevSpr != sprPtr2);
				
				// Force redraw
				if ((sprPtr1->sprFlags & SF_HIDDEN) == 0)
				{
					[ObjAddr activeSprite:sprPtr1  withFlags:AS_REDRAW  andRect:CRectNil];
				}
			}
			else
			{
				// Exchange the sprite with the next one until the second one is reached
				CSprite* pNextSpr;
				do
				{
					pNextSpr = sprPtr1->objNext;
					if (pNextSpr == nil)
					{
						break;
					}
					[self lyrSwapSpr:sprPtr1  withParam1:pNextSpr];
				} while (pNextSpr != sprPtr2);
				
				// Force redraw
				if ((sprPtr1->sprFlags & SF_HIDDEN) == 0)
				{
					[ObjAddr activeSprite:sprPtr1  withFlags:AS_REDRAW  andRect:CRectNil];
				}
			}
		}
	}
}

-(void)actSortByXUP:(CActExtension*)act
{
	[self lyrSortBy:X_UP  withParam1:0  andParam2:0];
}

-(void)actSortByYUP:(CActExtension*)act
{
	[self lyrSortBy:Y_UP  withParam1:0  andParam2:0];
}

-(void)actSortByXDOWN:(CActExtension*)act
{
	[self lyrSortBy:X_DOWN  withParam1:0  andParam2:0];
}

-(void)actSortByYDOWN:(CActExtension*)act
{
	[self lyrSortBy:Y_DOWN  withParam1:0  andParam2:0];
}

-(void)actBackOneObj:(CActExtension*)act
{
	CObject* roPtr = [act getParamObject:rh withNum:0];
	CObjInfo* oilPtr = roPtr->hoOiList;
	if (roPtr!=nil)
	{
		[self actBackOneRout:[self lyrGetFVfromOIL:oilPtr]];
	}
}
-(void)actForwardOneObj:(CActExtension*)act
{
	CObject* roPtr = [act getParamObject:rh withNum:0];
	if (roPtr!=nil)
	{
		[self actForwardOneRout:[self lyrGetFVfromOIL:roPtr->hoOiList]];
	}
}

-(void)actSwapObj:(CActExtension*)act
{
	CObject* roPtr = [act getParamObject:rh withNum:0];
	CObject* roPtr2 = [act getParamObject:rh withNum:1];
	
	if (roPtr!=nil && roPtr2!=nil)
	{
		[self actSwapRout:[self lyrGetFVfromOIL:roPtr->hoOiList]  withParam1:[self lyrGetFVfromOIL:roPtr2->hoOiList]];
	}
}

-(void)actBringFrontObj:(CActExtension*)act
{
	CObject* roPtr = [act getParamObject:rh withNum:0];
	if (roPtr!=nil)
	{
		[self actBringFrontRout:[self lyrGetFVfromOIL:roPtr->hoOiList]];
	}
}

-(void)actSendBackObj:(CActExtension*)act
{
	CObject* roPtr = [act getParamObject:rh withNum:0];
	if (roPtr!=nil)
	{
		[self actSendBackRout:[self lyrGetFVfromOIL:roPtr->hoOiList]];
	}
}

-(void)actBackNObj:(CActExtension*)act
{
	CObject* roPtr = [act getParamObject:rh withNum:0];
	int param2 = [act getParamExpression:rh withNum:1];
	if (roPtr!=nil)
	{
		[self actBackNRout:[self lyrGetFVfromOIL:roPtr->hoOiList]  withParam1:param2];
	}
}

-(void)actForwardNObj:(CActExtension*)act
{
	CObject* roPtr = [act getParamObject:rh withNum:0];
	int param2 = [act getParamExpression:rh withNum:1];
	if (roPtr!=nil)
	{
		[self actForwardNRout:[self lyrGetFVfromOIL:roPtr->hoOiList]  withParam1:param2];
	}
}

-(void)actMoveAboveObj:(CActExtension*)act
{
	CObject* roPtr = [act getParamObject:rh withNum:0];
	CObject* roPtr2 = [act getParamObject:rh withNum:1];
	if (roPtr!=nil && roPtr2!=nil)
	{
		[self actMoveAboveRout:[self lyrGetFVfromOIL:roPtr->hoOiList]  withParam1:[self lyrGetFVfromOIL:roPtr2->hoOiList]];
	}
}

-(void)actMoveBelowObj:(CActExtension*)act
{
	CObject* roPtr = [act getParamObject:rh withNum:0];
	CObject* roPtr2 = [act getParamObject:rh withNum:1];
	if (roPtr!=nil && roPtr2!=nil)
	{
		[self actMoveBelowRout:[self lyrGetFVfromOIL:roPtr->hoOiList]  withParam1:[self lyrGetFVfromOIL:roPtr2->hoOiList]];
	}
}

-(void)actMoveToNObj:(CActExtension*)act
{
	CObject* roPtr = [act getParamObject:rh withNum:0];
	int param2 = [act getParamExpression:rh withNum:1];
	if (roPtr!=nil)
	{
		[self actMoveToNRout:[self lyrGetFVfromOIL:roPtr->hoOiList]  withParam1:param2];
	}
}

-(void)actSortByALTUP:(CActExtension*)act
{
	int param1 = [act getParamAltValue:rh withNum:0];
	int param2 = [act getParamExpression:rh withNum:1];
	[self lyrSortBy:ALT_UP  withParam1:param2  andParam2:param1];
}

-(void)actSortByALTDOWN:(CActExtension*)act
{
	int param1 = [act getParamAltValue:rh withNum:0];
	int param2 = [act getParamExpression:rh withNum:1];
	[self lyrSortBy:ALT_DOWN  withParam1:param2  andParam2:param1];
}

-(void)actSetLayerX:(CActExtension*)act
{
	int param1 = [act getParamExpression:rh withNum:0];
	int param2 = [act getParamExpression:rh withNum:1];
	if (param1 > 0 && param1 <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[param1 - 1];
		int newX = -param2;
		pLayer->x = newX;
		pLayer->dwOptions |= FLOPT_REDRAW;
		ho->hoAdRunHeader->rh3Scrolling |= RH3SCROLLING_REDRAWLAYERS | RH3SCROLLING_REDRAWALL;
	}
}

-(void)actSetLayerY:(CActExtension*)act
{
	int param1 = [act getParamExpression:rh withNum:0];
	int param2 = [act getParamExpression:rh withNum:1];
	if (param1 > 0 && param1 <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[param1 - 1];
		int newY = -param2;
		pLayer->y = newY;
		pLayer->dwOptions |= FLOPT_REDRAW;
		ho->hoAdRunHeader->rh3Scrolling |= RH3SCROLLING_REDRAWLAYERS | RH3SCROLLING_REDRAWALL;
	}
}

-(void)actSetLayerXY:(CActExtension*)act
{
	int nLayer = [act getParamExpression:rh withNum:0];
	int newX = [act getParamExpression:rh withNum:1];
	int newY = [act getParamExpression:rh withNum:2];
	
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
		pLayer->x = -newX;
		pLayer->y = -newY;
		pLayer->dwOptions |= FLOPT_REDRAW;
		ho->hoAdRunHeader->rh3Scrolling |= RH3SCROLLING_REDRAWLAYERS | RH3SCROLLING_REDRAWALL;
	}
}

-(void)actShowLayer:(CActExtension*)act
{
	int param1 = [act getParamExpression:rh withNum:0];
	if (param1 > 0 && param1 <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[param1 - 1];
		if ((pLayer->dwOptions & FLOPT_VISIBLE) == 0)
		{
			pLayer->dwOptions |= (FLOPT_TOSHOW | FLOPT_REDRAW);
			pLayer->dwOptions &= ~FLOPT_TOHIDE;
			ho->hoAdRunHeader->rh3Scrolling |= RH3SCROLLING_REDRAWLAYERS;
		}
	}
}

-(void)actHideLayer:(CActExtension*)act
{
	int param1 = [act getParamExpression:rh withNum:0];
	if (param1 > 0 && param1 <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[param1 - 1];
		if ((pLayer->dwOptions & FLOPT_VISIBLE) != 0)
		{
			pLayer->dwOptions |= (FLOPT_TOHIDE | FLOPT_REDRAW);
			pLayer->dwOptions &= ~FLOPT_TOSHOW;
			ho->hoAdRunHeader->rh3Scrolling |= RH3SCROLLING_REDRAWLAYERS;
		}
	}
}

-(void)actSetLayerXByName:(CActExtension*)act
{
	NSString* param1 = [act getParamExpString:rh withNum:0];
	int param2 = [act getParamExpression:rh withNum:1];
	
	int nLayer = [self FindLayerByName:param1];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
        int newX = -param2;
        pLayer->x = newX;
        pLayer->dwOptions |= FLOPT_REDRAW;
        ho->hoAdRunHeader->rh3Scrolling |= RH3SCROLLING_REDRAWLAYERS | RH3SCROLLING_REDRAWALL;
    }
}

-(void)actSetLayerYByName:(CActExtension*)act
{
	NSString* param1 = [act getParamExpString:rh withNum:0];
	int param2 = [act getParamExpression:rh withNum:1];
	
	int nLayer = [self FindLayerByName:param1];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
        int newY = -param2;
        pLayer->y = newY;
        pLayer->dwOptions |= FLOPT_REDRAW;
        ho->hoAdRunHeader->rh3Scrolling |= RH3SCROLLING_REDRAWLAYERS | RH3SCROLLING_REDRAWALL;
	}
}

-(void)actSetLayerXYByName:(CActExtension*)act
{
	NSString* param1 = [act getParamExpString:rh withNum:0];
	int newX = [act getParamExpression:rh withNum:1];
	int newY = [act getParamExpression:rh withNum:2];
	
	int nLayer = [self FindLayerByName:param1];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
        pLayer->x = -newX;
        pLayer->y = -newY;
        pLayer->dwOptions |= FLOPT_REDRAW;
        ho->hoAdRunHeader->rh3Scrolling |= RH3SCROLLING_REDRAWLAYERS | RH3SCROLLING_REDRAWALL;
	}
}

-(void)actShowLayerByName:(CActExtension*)act
{
	NSString* param1 = [act getParamExpString:rh withNum:0];
	
	int nLayer = [self FindLayerByName:param1];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
		if ((pLayer->dwOptions & FLOPT_VISIBLE) == 0)
		{
			pLayer->dwOptions |= (FLOPT_TOSHOW | FLOPT_REDRAW);
			pLayer->dwOptions &= ~FLOPT_TOHIDE;
			ho->hoAdRunHeader->rh3Scrolling |= RH3SCROLLING_REDRAWLAYERS;
		}
	}
}

-(void)actHideLayerByName:(CActExtension*)act
{
	NSString* param1 = [act getParamExpString:rh withNum:0];
	
	int nLayer = [self FindLayerByName:param1];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
		if ((pLayer->dwOptions & FLOPT_VISIBLE) != 0)
		{
			pLayer->dwOptions |= (FLOPT_TOHIDE | FLOPT_REDRAW);
			pLayer->dwOptions &= ~FLOPT_TOSHOW;
			ho->hoAdRunHeader->rh3Scrolling |= RH3SCROLLING_REDRAWLAYERS;
		}
	}
}

-(void)actSetCurrentLayer:(CActExtension*)act
{
	int nLayer = [act getParamExpression:rh withNum:0];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		wCurrentLayer = (nLayer - 1);
	}
}

-(void)actSetCurrentLayerByName:(CActExtension*)act
{
	NSString* name = [act getParamExpString:rh withNum:0];
	int nLayer = [self FindLayerByName:name];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		wCurrentLayer = (nLayer - 1);
	}
}

-(void)actSetLayerCoefX:(CActExtension*)act
{
	int param1 = [act getParamExpression:rh withNum:0];
	float newCoef = (float) [act getParamExpDouble:rh withNum:1];
	
	if (param1 > 0 && param1 <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[param1 - 1];
		if (pLayer->xCoef != newCoef)
		{
			pLayer->xCoef = newCoef;
			pLayer->dwOptions &= ~FLOPT_XCOEF;
			if (newCoef != 1.0f)
			{
				pLayer->dwOptions |= FLOPT_XCOEF;
			}
		}
	}
}

-(void)actSetLayerCoefY:(CActExtension*)act
{
	int param1 = [act getParamExpression:rh withNum:0];
	float newCoef = (float) [act getParamExpDouble:rh withNum:1];
	
	if (param1 > 0 && param1 <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[param1 - 1];
		if (pLayer->yCoef != newCoef)
		{
			pLayer->yCoef = newCoef;
			pLayer->dwOptions &= ~FLOPT_YCOEF;
			if (newCoef != 1.0f)
			{
				pLayer->dwOptions |= FLOPT_YCOEF;
			}
		}
	}
}

-(void)actSetLayerCoefXByName:(CActExtension*)act
{
	NSString* param1 = [act getParamExpString:rh withNum:0];
	float newCoef = (float) [act getParamExpDouble:rh withNum:1];
	
	int nLayer = [self FindLayerByName:param1];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
		if (pLayer->xCoef != newCoef)
		{
			pLayer->xCoef = newCoef;
			pLayer->dwOptions &= ~FLOPT_XCOEF;
			if (newCoef != 1.0f)
			{
				pLayer->dwOptions |= FLOPT_XCOEF;
			}
		}
	}
}

-(void)actSetLayerCoefYByName:(CActExtension*)act
{
	NSString* param1 = [act getParamExpString:rh withNum:0];
	float newCoef = (float) [act getParamExpDouble:rh withNum:1];
	
	int nLayer = [self FindLayerByName:param1];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
		if (pLayer->yCoef != newCoef)
		{
			pLayer->yCoef = newCoef;
			pLayer->dwOptions &= ~FLOPT_YCOEF;
			if (newCoef != 1.0f)
			{
				pLayer->dwOptions |= FLOPT_YCOEF;
			}
		}
	}
}



// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case 0:
			return [self expGetFV];
		case 1:
			return [self expGetTopFV];
		case 2:
			return [self expGetBottomFV];
		case 3:
			return [self expGetDesc];
		case 4:
			return [self expGetDesc10];
		case 5:
			return [self expGetNumLevels];
		case 6:
			return [self expGetLevel];
		case 7:
			return [self expGetLevelFV];
		case 8:
			return [self expGetLayerX];
		case 9:
			return [self expGetLayerY];
		case 10:
			return [self expGetLayerXByName];
		case 11:
			return [self expGetLayerYByName];
		case 12:
			return [self expGetLayerCount];
		case 13:
			return [self expGetLayerName];
		case 14:
			return [self expGetLayerIndex];
		case 15:
			return [self expGetCurrentLayer];
		case 16:
			return [self expGetLayerCoefX];
		case 17:
			return [self expGetLayerCoefY];
		case 18:
			return [self expGetLayerCoefXByName];
		case 19:
			return [self expGetLayerCoefYByName];
        case 20:
        case 21:
        case 22:
        case 23:
        case 24:
        case 25:
            return [self expGetZeroOneParam];
	}
	return nil;
}

-(CValue*)expGetZeroOneParam
{
    [ho getExpParam];
    return [rh getTempValue:0];
}

-(CValue*)expGetFV
{
	CObject* roPtr;
	CObjInfo* oilPtr;
	
	CSprite* sprPtr;
	
	int FValue = 0;
	NSString* objName = [[ho getExpParam] getString];
	
	if ([objName length] == 0)
	{
		return [rh getTempValue:holdFValue];
	}
	
	int count = 0;
	int no;
	for (no = 0; no < ho->hoAdRunHeader->rhNObjects; no++)
	{
		while (ho->hoAdRunHeader->rhObjectList[count] == nil)
		{
			count++;
		}
		roPtr = ho->hoAdRunHeader->rhObjectList[count];
		count++;
		
		oilPtr = roPtr->hoOiList;
		
		if ([objName caseInsensitiveCompare:oilPtr->oilName] == 0)
		{
			FValue = (roPtr->hoCreationId << 16) + (((int) roPtr->hoNumber) & 0xFFFF);
			sprPtr = [self lyrGetSprite:FValue];
			
			if ((sprPtr->sprFlags & SF_TOKILL) == 0)
			{
				break;
			}
			else
                // Reset it for the next iteration.
			{
				FValue = 0;
			}
		}
	}
	return [rh getTempValue:FValue];
}


-(CValue*)expGetTopFV
{
	//Runheader for this object
	int nLayer = wCurrentLayer;
	
	// Dynamic objects layer
	nLayer = nLayer * 2 + 1;
	
	CSprite* sprPtr;
	CObject* roPtr;
	
	sprPtr = ho->hoAdRunHeader->spriteGen->lastSprite;
	while (sprPtr != nil)
	{
		if (sprPtr->sprLayer < nLayer)
		{
			break;
		}
		if (sprPtr->sprLayer == nLayer && (sprPtr->sprFlags & SF_TOKILL) == 0)
		{
			roPtr = sprPtr->sprExtraInfo;
			return [rh getTempValue:(roPtr->hoCreationId << 16) + (((int) roPtr->hoNumber) & 0xFFFF)];
		}
		sprPtr = sprPtr->objPrev;
	}
	return [rh getTempValue:0];
}

-(CValue*)expGetBottomFV
{
	int nLayer = wCurrentLayer;
	
	// Dynamic objects layer
	nLayer = nLayer * 2 + 1;
	
	CSprite* sprPtr;
	CObject* roPtr;
	
	sprPtr = ho->hoAdRunHeader->spriteGen->firstSprite;
	
	while (sprPtr != nil)
	{
		if (sprPtr->sprLayer > nLayer)
		{
			break;
		}
		if (sprPtr->sprLayer == nLayer && (sprPtr->sprFlags & SF_TOKILL) == 0)
		{
			roPtr = sprPtr->sprExtraInfo;
			return [rh getTempValue:(roPtr->hoCreationId << 16) + (((int) roPtr->hoNumber) & 0xFFFF)];
		}
		sprPtr = sprPtr->objNext;
	}
	return [rh getTempValue:0];
}
					
-(CValue*)expGetDesc
{
	int lvlN = [[ho getExpParam] getInt];
	NSString* ps = [self lyrGetList:lvlN  withParam1:1];
	CValue* ret=[rh getTempValue:0];
	[ret forceString:ps];
	[ps release];

	return ret;
}

-(CValue*)expGetDesc10
{
	int lvlN = [[ho getExpParam] getInt];
	NSString* ps = [self lyrGetList:lvlN  withParam1:10];
	CValue* ret=[rh getTempValue:0];
	[ret forceString:ps];
	[ps release];
	
	return ret;
}

-(CValue*)expGetNumLevels
{
	int nLayer = wCurrentLayer;
	
	// Dynamic objects layer
	nLayer = nLayer * 2 + 1;
	
	CSprite* sprPtr;
	int lvlCount = 0;
	
	sprPtr = ho->hoAdRunHeader->spriteGen->firstSprite;
	
	while (sprPtr != nil)
	{
		if (sprPtr->sprLayer > nLayer)
		{
			break;
		}
		if (sprPtr->sprLayer == nLayer && (sprPtr->sprFlags & SF_TOKILL) == 0)
		{
			lvlCount++;
		}
		sprPtr = sprPtr->objNext;
	}
	return [rh getTempValue:lvlCount];
}

-(CValue*)expGetLevel
{
	int nLayer = -1;	// rdPtr->wCurrentLayer * 2 + 1;
	
	CSprite* sprPtr;
	CObject* roPtr;
//	CObjInfo* oilPtr;
	
	int lvlCount = 1;
	int FValue = 0;
	int FindFixed = [[ho getExpParam] getInt];
	
	if (FindFixed == 0)
	{
		FindFixed = holdFValue;
	}
	
	sprPtr = ho->hoAdRunHeader->spriteGen->firstSprite;
	
	while (sprPtr != nil)
	{
		// Ignore background layers
		if ((sprPtr->sprLayer & 1) != 0)		// sprPtr->sprLayer == nLayer
		{
			// New version: look for object in all the layers
			if (nLayer != sprPtr->sprLayer)
			{
				nLayer = sprPtr->sprLayer;
				lvlCount = 1;
			}
			
			if ((sprPtr->sprFlags & SF_TOKILL) == 0)
			{
				roPtr = sprPtr->sprExtraInfo;
				//oilPtr = roPtr->hoOiList;
				FValue = (roPtr->hoCreationId << 16) + (((int) roPtr->hoNumber) & 0xFFFF);
				
				if (FindFixed == FValue)
				{
					return [rh getTempValue:lvlCount];
				}
				
				lvlCount++;
			}
		}
		sprPtr = sprPtr->objNext;
	}
	return [rh getTempValue:0];
}

-(CValue*)expGetLevelFV
{
	int nLayer = wCurrentLayer * 2 + 1;
	
	CSprite* sprPtr;
	CObject* roPtr;
//	CObjInfo* oilPtr;
	
	int lvlCount = 1;
	int FValue = 0;
	int FindLevel = [[ho getExpParam] getInt];
	
	sprPtr = ho->hoAdRunHeader->spriteGen->firstSprite;
	
	while (sprPtr != nil)
	{
		if (sprPtr->sprLayer > nLayer)
		{
			break;
		}
		if (sprPtr->sprLayer == nLayer)
		{
			if (FindLevel == lvlCount++)
			{
				if ((sprPtr->sprFlags & SF_TOKILL) == 0)
				{
					roPtr = sprPtr->sprExtraInfo;
					//oilPtr = roPtr->hoOiList;
					FValue = (roPtr->hoCreationId << 16) + (((int) roPtr->hoNumber) & 0xFFFF);
					break;
				}
				else
				{
					lvlCount--;
				}
			}
		}
		sprPtr = sprPtr->objNext;
	}
	return [rh getTempValue:FValue];
}

-(CValue*)expGetLayerX
{
	int nLayer = [[ho getExpParam] getInt];
	
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
		return [rh getTempValue:(int)-(pLayer->x + pLayer->dx)];
	}
	return [rh getTempValue:0];
}

-(CValue*)expGetLayerY
{
	int nLayer = [[ho getExpParam] getInt];
	
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
		return [rh getTempValue:(int)-(pLayer->y + pLayer->dy)];
	}
	return [rh getTempValue:0];
}

-(CValue*)expGetLayerXByName
{
	NSString* pName = [[ho getExpParam] getString];
	
	int nLayer = [self FindLayerByName:pName];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
		return [rh getTempValue:(int)-(pLayer->x + pLayer->dx)];
	}
	return [rh getTempValue:0];
}

-(CValue*)expGetLayerYByName
{
	NSString* pName = [[ho getExpParam] getString];
	
	int nLayer = [self FindLayerByName:pName];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
		return [rh getTempValue:(int)-(pLayer->y + pLayer->dy)];
	}
	return [rh getTempValue:0];
}

-(CValue*)expGetLayerCount
{
	return [rh getTempValue:ho->hoAdRunHeader->rhFrame->nLayers];
}

-(CValue*)expGetLayerName
{
	int nLayer = [[ho getExpParam] getInt];
	CValue* ret=[rh getTempValue:0];
	[ret forceString:@""];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
		[ret forceString:pLayer->pName];
	}
	return ret;
}

-(CValue*)expGetLayerIndex
{
	NSString* pName = [[ho getExpParam] getString];
	return [rh getTempValue:[self FindLayerByName:pName]];
}

-(CValue*)expGetCurrentLayer
{
	return [rh getTempValue:wCurrentLayer + 1];
}

-(CValue*)expGetLayerCoefX
{
	int nLayer = [[ho getExpParam] getInt];
	
	CValue* ret=[rh getTempValue:0];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
		[ret forceDouble:(double)pLayer->xCoef];
	}
	return ret;
}

-(CValue*)expGetLayerCoefY
{
	int nLayer = [[ho getExpParam] getInt];

	CValue* ret=[rh getTempValue:0];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
		[ret forceDouble:(double) pLayer->yCoef];
	}
	return ret;
}

-(CValue*)expGetLayerCoefXByName
{
	NSString* pName = [[ho getExpParam] getString];

	CValue* ret=[rh getTempValue:0];
	int nLayer = [self FindLayerByName:pName];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
		[ret forceDouble:(double) pLayer->xCoef];
	}
	return ret;
}

-(CValue*)expGetLayerCoefYByName
{
	NSString* pName = [[ho getExpParam] getString];
	CValue* ret=[rh getTempValue:0];
	int nLayer = [self FindLayerByName:pName];
	if (nLayer > 0 && nLayer <= ho->hoAdRunHeader->rhFrame->nLayers)
	{
		CLayer* pLayer = ho->hoAdRunHeader->rhFrame->layers[nLayer - 1];
		[ret forceDouble:(double) pLayer->yCoef];
	}
	return ret;
}


// SORT ROUTINES
// --------------------------------------------------------
// Exchange 2 sprites in the linked list
-(void)lyrSwapSpr:(CSprite*)sp1 withParam1:(CSprite*)sp2
{
	// Security
	if (sp1 == sp2)
	{
		return;
	}
	
	// Cannot swap sprites from different layers
	if (sp1->sprLayer != sp2->sprLayer)
	{
		return;
	}
	
	CSpriteGen* objAddr = ho->hoAdRunHeader->spriteGen;
	
	CSprite* pPrev1 = sp1->objPrev;
	CSprite* pNext1 = sp1->objNext;
	
	CSprite* pPrev2 = sp2->objPrev;
	CSprite* pNext2 = sp2->objNext;
	
	// Exchange z-order values
	int nZOrder = sp1->sprZOrder;
	sp1->sprZOrder = sp2->sprZOrder;
	sp2->sprZOrder = nZOrder;
	
	// Exchange sprites
	
	// Several cases
	//
	// 1. pPrev1, sp1, sp2, pNext2
	//
	//    pPrev1.next = sp2
	//	  sp2.prev = pPrev1;
	//	  sp2.next = sp1;
	//	  sp1.prev = sp2;
	//	  sp1.next = pNext2
	//	  pNext2.prev = sp1
	//
	if (pNext1 == sp2)
	{
		if (pPrev1 != nil)
		{
			pPrev1->objNext = sp2;
		}
		sp2->objPrev = pPrev1;
		sp2->objNext = sp1;
		sp1->objPrev = sp2;
		sp1->objNext = pNext2;
		if (pNext2 != nil)
		{
			pNext2->objPrev = sp1;
		}
		
		// Update first & last sprites
		if (pPrev1 == nil)
		{
			objAddr->firstSprite = sp2;
		}
		if (pNext2 == nil)
		{
			objAddr->lastSprite = sp1;
		}
	}
	
	// 2. pPrev2, sp2, sp1, pNext1
	//
	//    pPrev2.next = sp1
	//	  sp1.prev = pPrev2;
	//	  sp1.next = sp2;
	//	  sp2.prev = sp1;
	//	  sp2.next = pNext1
	//	  pNext1.prev = sp2
	//
	else if (pNext2 == sp1)
	{
		if (pPrev2 != nil)
		{
			pPrev2->objNext = sp1;
		}
		sp1->objPrev = pPrev2;
		sp1->objNext = sp2;
		sp2->objPrev = sp1;
		sp2->objNext = pNext1;
		if (pNext1 != nil)
		{
			pNext1->objPrev = sp2;
		}
		
		// Update first & last sprites
		if (pPrev2 == nil)
		{
			objAddr->firstSprite = sp1;	//	*ptPtsObj = (UINT)sp1;
		}
		if (pNext1 == nil)
		{
			objAddr->lastSprite = sp2;	//	*(ptPtsObj+1) = (UINT)sp2;
		}
	}
	
	// 3. pPrev1, sp1, pNext1 ... pPrev2, sp2, pNext2
	// or pPrev2, sp2, pNext2 ... pPrev1, sp1, pNext1
	//
	//	  pPrev1.next = sp2;
	//	  pNext1.prev = sp2
	//	  sp1.prev = pPrev2;
	//	  sp1.next = pNext2;
	//	  pPrev2.next = sp1;
	//	  pNext2.prev = sp1
	//	  sp2.prev = pPrev1;
	//	  sp2.next = pNext1;
	//
	else
	{
		if (pPrev1 != nil)
		{
			pPrev1->objNext = sp2;
		}
		if (pNext1 != nil)
		{
			pNext1->objPrev = sp2;
		}
		sp1->objPrev = pPrev2;
		sp1->objNext = pNext2;
		if (pPrev2 != nil)
		{
			pPrev2->objNext = sp1;
		}
		if (pNext2 != nil)
		{
			pNext2->objPrev = sp1;
		}
		sp2->objPrev = pPrev1;
		sp2->objNext = pNext1;
		
		// Update first & last sprites
		if (pPrev1 == nil)
		{
			objAddr->firstSprite = sp2;
		}
		if (pPrev2 == nil)
		{
			objAddr->firstSprite = sp1;
		}
		if (pNext1 == nil)
		{
			objAddr->lastSprite = sp2;
		}
		if (pNext2 == nil)
		{
			objAddr->lastSprite = sp1;
		}
	}
}

-(BOOL)lyrSwapThem:(CSprite*)sprPtr1 withParam1:(CSprite*)sprPtr2 andParam2:(BOOL)bRedraw
{
	// Exchange sprites
	[self lyrSwapSpr:sprPtr1  withParam1:sprPtr2];
	
	if (bRedraw)
	{
		// Force redraw
		if ((sprPtr1->sprFlags & SF_HIDDEN) == 0)
		{
			[ho->hoAdRunHeader->spriteGen activeSprite:sprPtr1  withFlags:AS_REDRAW andRect:CRectNil];
		}
		if ((sprPtr2->sprFlags & SF_HIDDEN) == 0)
		{
			[ho->hoAdRunHeader->spriteGen activeSprite:sprPtr2  withFlags:AS_REDRAW andRect:CRectNil];
		}
	}
	return YES;
}

-(CSprite*)lyrGetSprite:(int)fixedValue
{
//	CObject* roPtr;
	
	if (fixedValue == 0)
	{
		fixedValue = holdFValue;
	}
	
	int count = 0;
	int no;
	int fValue;
	for (no = 0; no < ho->hoAdRunHeader->rhNObjects; no++)
	{
		while (ho->hoAdRunHeader->rhObjectList[count] == nil)
		{
			count++;
		}
		CObject* hoPtr = ho->hoAdRunHeader->rhObjectList[count];
		count++;
		fValue = (hoPtr->hoCreationId << 16) + hoPtr->hoNumber;
		if (fixedValue == fValue)
		{
			return hoPtr->roc->rcSprite;
		}
	}
	return nil;
}

-(CObject*)lyrGetROfromFV:(int)fixedValue
{
	if (fixedValue == 0)
	{
		fixedValue = holdFValue;
	}
	
	int count = 0;
	int no;
	int fValue;
	for (no = 0; no < ho->hoAdRunHeader->rhNObjects; no++)
	{
		while (ho->hoAdRunHeader->rhObjectList[count] == nil)
		{
			count++;
		}
		CObject* hoPtr = ho->hoAdRunHeader->rhObjectList[count];
		count++;
		fValue = (hoPtr->hoCreationId << 16) + (((int) hoPtr->hoNumber) & 0xFFFF);
		if (fixedValue == fValue)
		{
			return hoPtr;
		}
	}
	return nil;
}

-(BOOL)lyrSortBy:(int)flag withParam1:(int)altDefaultVal andParam2:(int)altValue
{
	int nLayer = (short) wCurrentLayer;
	
	// Dynamic objects layer
	nLayer = nLayer * 2 + 1;
	
	CSpriteGen* objAddr = ho->hoAdRunHeader->spriteGen;
	
	// Get first layer sprite
	CSprite* sprFirst = objAddr->firstSprite;
	while (sprFirst != nil && ((sprFirst->sprFlags & SF_TOKILL) != 0 || sprFirst->sprLayer < nLayer))
	{
		sprFirst = sprFirst->objNext;
	}
	if (sprFirst == nil || sprFirst->sprLayer != nLayer)
	{
		return NO;
	}
	
	// Get last layer sprite
	CSprite* sprLast = objAddr->lastSprite;
	while (sprLast != nil && ((sprLast->sprFlags & SF_TOKILL) != 0 || sprLast->sprLayer > nLayer))
	{
		sprLast = sprLast->objPrev;
	}
	if (sprLast == nil || sprLast->sprLayer != nLayer)
	{
		return NO;
	}
	
	if (sprFirst == sprLast)
	{
		return NO;
	}
	
	CSprite* pSprite = sprFirst;
	
	CArrayList* spriteList = [[CArrayList alloc] init];
	int i = 0;
	CSortData* tmp;
	while (pSprite != nil)
	{
		tmp = [[CSortData alloc] init];
		tmp->indexSprite = pSprite;
		tmp->cmpFlag = flag;
		
		// MMF2: ajoutÈ protection sur SF_TOKILL car eu un crash
		if ((pSprite->sprFlags & SF_TOKILL) == 0)
		{
			CObject* hoPtr = pSprite->sprExtraInfo;
			if(hoPtr != nil)
			{
				tmp->sprX = [hoPtr getX];
				tmp->sprY = [hoPtr getY];

				tmp->sprAlt = altDefaultVal;
				if (hoPtr->rov != nil)
				{
					if (hoPtr->rov->rvValues[altValue]!=nil)
					{
						if (hoPtr->rov->rvValues[altValue]->type == TYPE_INT)
						{
							tmp->sprAlt = hoPtr->rov->rvValues[altValue]->intValue;
						}
						else
						{
							tmp->sprAlt = (int) hoPtr->rov->rvValues[altValue]->doubleValue;
						}
					}
				}
			}
		}
		else
		{
			tmp->sprX = pSprite->sprX;
			tmp->sprY = pSprite->sprY;
			tmp->sprAlt = altDefaultVal;
		}
		[spriteList add:tmp];
				
		// Force redraw (moved here - B249)
		if ( (pSprite->sprFlags & (SF_HIDDEN|SF_TOHIDE)) == 0 )
			[objAddr activeSprite:pSprite  withFlags:AS_REDRAW  andRect:CRectNil];
		
		if (pSprite == sprLast)
		{
			break;
		}
		pSprite = pSprite->objNext;
		i++;
	}
	
	// TRI (a bulle en attendant mieux)
	int count = 0;
	int n;
	do
	{
		count = 0;
		for (n = 0; n < [spriteList size] - 1; n++)
		{
			if ([self isGreater:(CSortData*)[spriteList get:n] withParam1:(CSortData*)[spriteList get:n + 1]])
			{
				tmp = (CSortData*) [spriteList get:n + 1];
				[spriteList set:n + 1  object:(CSortData*)[spriteList get:n]];
				[spriteList set:n  object:tmp];
				count++;
			}
		}
	} while (count != 0);

	CSprite* sprPrevFirst = nil;
	if (sprFirst != objAddr->firstSprite)
	{
		sprPrevFirst = sprFirst->objPrev;
	}
	
	CSprite* sprNextLast = nil;
	if (sprLast != objAddr->lastSprite)
	{
		sprNextLast = sprLast->objNext;
	}
	
	CSprite* sprTemp=nil;
	for (n = 0; n < [spriteList size]; n++)
	{
		sprTemp = ((CSortData*)[spriteList get:n])->indexSprite;
		
		if (n == 0)
		{
			if (sprPrevFirst == nil)
			{
				//This is the first of the list
				objAddr->firstSprite = sprTemp;
				sprTemp->objPrev = nil;
				sprTemp->objNext = ((CSortData*)[spriteList get:n + 1])->indexSprite;
			}
			else
			{
				sprTemp->objPrev = sprPrevFirst;
				sprPrevFirst->objNext = sprTemp;
				sprTemp->objNext = ((CSortData*)[spriteList get:n + 1])->indexSprite;
			}
		}
		else
		{
			sprTemp->objPrev = ((CSortData*)[spriteList get:n - 1])->indexSprite;
			if (n + 1 == [spriteList size])
			{
				if (sprNextLast == nil)
				{
					sprTemp->objNext = nil;
					objAddr->lastSprite = ((CSortData*)[spriteList get:n])->indexSprite;
				}
				else
				{
					sprTemp->objNext = sprNextLast;
					sprNextLast->objPrev = sprTemp;
				}
			}
			else
			{
				sprTemp->objNext = ((CSortData*)[spriteList get:n + 1])->indexSprite;
			}
		}
	}
	[spriteList clearRelease];
	[spriteList release];
	
	return NO;
}

-(BOOL)isGreater:(CSortData*)item1 withParam1:(CSortData*)item2
{
	// MMF2
	CSprite* p1 = item1->indexSprite;
	CSprite* p2 = item2->indexSprite;
	if (p1->sprLayer != p2->sprLayer)
	{
		return (p1->sprLayer > p2->sprLayer);
	}
	switch (item1->cmpFlag)
	{
		case 0:     // X_UP
			return item1->sprX < item2->sprX;
		case 1:     // X_DOWN
			return item1->sprX > item2->sprX;
		case 2:     // Y_UP:
			return item1->sprY < item2->sprY;
		case 3:     // Y_DOWN:
			return item1->sprY > item2->sprY;
		case 4:     // ALT_UP:
			return item1->sprAlt < item2->sprAlt;
		case 5:     // ALT_DOWN:
			return item1->sprAlt > item2->sprAlt;
	}
	return NO;
}

-(NSString*)lyrGetList:(int)lvlStart withParam1:(int)iteration
{
	NSString* szList = [[NSString alloc] initWithString:@"Lvl\tName\tFV\n\n"];
	int nLayer = wCurrentLayer;
	
	// Dynamic objects layer
	nLayer = nLayer * 2 + 1;
	
	//Runheader for this object
	CSpriteGen* objAddr = ho->hoAdRunHeader->spriteGen;
	
	CSprite* sprPtr;
	CObject* hoPtr;
	CObjInfo* oilPtr;
	
	int fValue = 0;
	int lvlCount = 0;
	
	sprPtr = objAddr->firstSprite;
	
	// Get first layer sprite
	while (sprPtr != nil && (sprPtr->sprFlags & SF_TOKILL) != 0 && sprPtr->sprLayer < nLayer)
	{
		sprPtr = sprPtr->objNext;
	}
	if (sprPtr != nil && sprPtr->sprLayer == nLayer)
	{
		while ((sprPtr != nil) && (sprPtr->sprLayer == nLayer) && (++lvlCount < (lvlStart + iteration)))
		{
			if (lvlCount >= lvlStart)
			{
				if ((sprPtr->sprFlags & SF_TOKILL) == 0)
				{
					hoPtr = sprPtr->sprExtraInfo;
					oilPtr = hoPtr->hoOiList;
					fValue = (hoPtr->hoCreationId << 16) + (((int) hoPtr->hoNumber) & 0xFFFF);
					NSString* buffer =@"\t";
					buffer=[buffer stringByAppendingString:oilPtr->oilName];
					buffer=[buffer stringByAppendingString:@"\t"];
					buffer=[buffer stringByAppendingFormat:@"%i", fValue];
					buffer=[buffer stringByAppendingString:@"\n"];
					[szList release];
					szList = [[NSString alloc] initWithString:buffer];
					}
				else
				{
					lvlCount--;
				}
			}
			sprPtr = sprPtr->objNext;
		}
	}
	return szList;
}

-(int)lyrGetFVfromEVP:(LPEVP)evp
{
	CObjInfo* oilPtr = ho->hoAdRunHeader->rhOiList[evp->evp.evpW.evpW0];
	
	CObject* hoPtr;
	if (oilPtr->oilCurrentOi != -1)
	{
		hoPtr = ho->hoAdRunHeader->rhObjectList[oilPtr->oilCurrentOi];
	}
	else
	{
		if (oilPtr->oilObject >= 0)
		{
			hoPtr = ho->hoAdRunHeader->rhObjectList[oilPtr->oilObject];
		}
		else
		{
			return 0;
		}
	}
	return ((hoPtr->hoCreationId << 16) + (((int) hoPtr->hoNumber) & 0xFFFF));
}

-(CObject*)lyrGetROfromEVP:(LPEVP)evp
{
	CObjInfo* oilPtr = ho->hoAdRunHeader->rhOiList[evp->evp.evpW.evpW0];
	
	if (oilPtr->oilEventCount == ho->hoAdRunHeader->rhEvtProg->rh2EventCount)
	{
		return ho->hoAdRunHeader->rhObjectList[oilPtr->oilListSelected];
	}
	else
	{
		if (oilPtr->oilObject >= 0)
		{
			return ho->hoAdRunHeader->rhObjectList[oilPtr->oilObject];
		}
		else
		{
			return nil;
		}
	}
}

-(CObjInfo*)lyrGetOILfromEVP:(LPEVP)evp
{
	if (evp->evp.evpW.evpW0<0)
	{
		return nil;
	}
	return ho->hoAdRunHeader->rhOiList[evp->evp.evpW.evpW0];
}

-(int)lyrGetFVfromOIL:(CObjInfo*)oilPtr
{
	CObject* hoPtr;
	
	if (oilPtr->oilEventCount == ho->hoAdRunHeader->rhEvtProg->rh2EventCount)
	{
		hoPtr = ho->hoAdRunHeader->rhObjectList[oilPtr->oilListSelected];
	}
	else
	{
		if (oilPtr->oilObject >= 0)
		{
			hoPtr = ho->hoAdRunHeader->rhObjectList[oilPtr->oilObject];
		}
		else
		{
			return 0;
		}
	}
	return ((hoPtr->hoCreationId << 16) + (((int) hoPtr->hoNumber) & 0xFFFF));
}

-(void)lyrResetEventList:(CObjInfo*)oilPtr
{
	if (oilPtr->oilEventCount == ho->hoAdRunHeader->rhEvtProg->rh2EventCount)
	{
		oilPtr->oilEventCount = -1;
	}
	return;
}

-(BOOL)lyrProcessCondition:(LPEVP)param1 withParam1:(LPEVP)param2 andParam2:(int)cond
{
	BOOL lReturn;
	
	CObjInfo* oilPtr1 = [self lyrGetOILfromEVP:param1];
	if (oilPtr1 == nil)
	{
		return NO;
	}
	CObject* roPtr1;
	if ((roPtr1 = [self lyrGetROfromEVP:param1]) == nil)
	{
		return NO;
	}
	
	CObjInfo* oilPtr2 = nil;
	CObject* roPtr2 = nil;
	
	if (param2 != nil)
	{
		oilPtr2 = [self lyrGetOILfromEVP:param2];
		if ((roPtr2 = [self lyrGetROfromEVP:param2]) == nil)
		{
			return NO;
		}
	}
	
	//We only build a list for the primary parameter (param1)
	//Save the first object
	//Save the number selected
	short RootObj = -1;
	short NumCount = 0;
	BOOL bMatch;
	
	int FValue1 = -1;
	int FValue2 = -1;
	
	BOOL bPassed = NO;
	
	CObject* roTempPtr;
	short roTempNumber = 0;
	short i, j;
	int Loop2;
	if (oilPtr1->oilEventCount == ho->hoAdRunHeader->rhEvtProg->rh2EventCount)
	{
		if (param2 != nil)
		{
			FValue1 = [self lyrGetFVfromOIL:[self lyrGetOILfromEVP:param1]];
			for (i = 1; i <= oilPtr1->oilNumOfSelected; i++)
			{
				bMatch = NO;
				
				FValue2 = [self lyrGetFVfromOIL:[self lyrGetOILfromEVP:param2]];
				
				BOOL DoLevel2;
				
				if (oilPtr2->oilEventCount == ho->hoAdRunHeader->rhEvtProg->rh2EventCount)
				{
					Loop2 = oilPtr2->oilNumOfSelected;
					DoLevel2 = YES;
				}
				else
				{
					Loop2 = oilPtr2->oilNObjects;
					DoLevel2 = NO;
				}
				
				for (j = 1; j <= Loop2; j++)
				{
					lReturn = [self doCondition:cond  withParam1:FValue1  andParam2:FValue2];
					if (lReturn)
					{
						bMatch = YES;
					}
					
					if (DoLevel2)
					{
						if (roPtr2->hoNextSelected > -1)
						{
							roPtr2 = ho->hoAdRunHeader->rhObjectList[roPtr2->hoNextSelected];
							FValue2 = (roPtr2->hoCreationId << 16) + (((int) roPtr2->hoNumber) & 0xFFFF);
						}
					}
					else
					{
						if (roPtr2->hoNumNext > -1)
						{
							roPtr2 = ho->hoAdRunHeader->rhObjectList[roPtr2->hoNumNext];
							FValue2 = (roPtr2->hoCreationId << 16) + (((int) roPtr2->hoNumber) & 0xFFFF);
						}
					}
				}
				
				if (bMatch)
				{
					bPassed = YES;
					NumCount++;
					
					if (RootObj == -1)
					{
						RootObj = roPtr1->hoNumber;
					}
					else
					{
						roTempPtr = ho->hoAdRunHeader->rhObjectList[roTempNumber];
						roTempPtr->hoNextSelected = roPtr1->hoNumber;
					}
					roTempNumber = roPtr1->hoNumber;
				}
				
				if (roPtr1->hoNextSelected > -1)
				{
					roPtr1 = ho->hoAdRunHeader->rhObjectList[roPtr1->hoNextSelected];
					FValue1 = (roPtr1->hoCreationId << 16) + (((int) roPtr1->hoNumber) & 0xFFFF);
				}
			}
		}
		else
		{
			FValue1 = [self lyrGetFVfromOIL:[self lyrGetOILfromEVP:param1]];
			for (i = 1; i <= oilPtr1->oilNumOfSelected; i++)
			{
				//bMatch = NO;
				
				lReturn = [self doCondition:cond  withParam1:FValue1  andParam2:FValue2];
				if (lReturn)
				{
					bPassed = YES;
					NumCount++;
					if (RootObj == -1)
					{
						RootObj = roPtr1->hoNumber;
					}
					else
					{
						roTempPtr = ho->hoAdRunHeader->rhObjectList[roTempNumber];
						roTempPtr->hoNextSelected = roPtr1->hoNumber;
					}
					
					roTempNumber = roPtr1->hoNumber;
				}
				
				if (roPtr1->hoNextSelected > -1)
				{
					roPtr1 = ho->hoAdRunHeader->rhObjectList[roPtr1->hoNextSelected];
					FValue1 = (roPtr1->hoCreationId << 16) + (((int) roPtr1->hoNumber) & 0xFFFF);
				}
			}
		}
	}
	else
	{
		if (param2 != nil)
		{
			FValue1 = [self lyrGetFVfromOIL:[self lyrGetOILfromEVP:param1]];
			for (i = 1; i <= oilPtr1->oilNObjects; i++)
			{
				bMatch = NO;
				
				FValue2 = [self lyrGetFVfromOIL:[self lyrGetOILfromEVP:param2]];
				
				BOOL DoLevel2;
				
				if (oilPtr2->oilEventCount == ho->hoAdRunHeader->rhEvtProg->rh2EventCount)
				{
					Loop2 = oilPtr2->oilNumOfSelected;
					DoLevel2 = YES;
				}
				else
				{
					Loop2 = oilPtr2->oilNObjects;
					DoLevel2 = NO;
				}
				
				for (j = 1; j <= Loop2; j++)
				{
					lReturn = [self doCondition:cond  withParam1:FValue1  andParam2:FValue2];
					if (lReturn)
					{
						bMatch = YES;
					}
					
					if (DoLevel2)
					{
						if (roPtr2->hoNextSelected > -1)
						{
							roPtr2 = ho->hoAdRunHeader->rhObjectList[roPtr2->hoNextSelected];
							FValue2 = (roPtr2->hoCreationId << 16) + (((int) roPtr2->hoNumber) & 0xFFFF);
						}
					}
					else
					{
						if (roPtr2->hoNumNext > -1)
						{
							roPtr2 = ho->hoAdRunHeader->rhObjectList[roPtr2->hoNumNext];
							FValue2 = (roPtr2->hoCreationId << 16) + (((int) roPtr2->hoNumber) & 0xFFFF);
						}
					}
				}
				
				if (bMatch)
				{
					bPassed = YES;
					NumCount++;
					if (RootObj == -1)
					{
						RootObj = roPtr1->hoNumber;
					}
					else
					{
						roTempPtr = ho->hoAdRunHeader->rhObjectList[roTempNumber];
						roTempPtr->hoNextSelected = roPtr1->hoNumber;
					}
					roTempNumber = roPtr1->hoNumber;
				}
				
				if (roPtr1->hoNumNext > -1)
				{
					roPtr1 = ho->hoAdRunHeader->rhObjectList[roPtr1->hoNumNext];
					FValue1 = (roPtr1->hoCreationId << 16) + roPtr1->hoNumber;
				}
			}
		}
		else
		{
			FValue1 = [self lyrGetFVfromOIL:[self lyrGetOILfromEVP:param1]];
			for (i = 1; i <= oilPtr1->oilNObjects; i++)
			{
				//bMatch = NO;
				
				lReturn = [self doCondition:cond  withParam1:FValue1  andParam2:FValue2];
				if (lReturn)
				{
					bPassed = YES;
					NumCount++;
					if (RootObj == -1)
					{
						RootObj = roPtr1->hoNumber;
					}
					else
					{
						roTempPtr = ho->hoAdRunHeader->rhObjectList[roTempNumber];
						roTempPtr->hoNextSelected = roPtr1->hoNumber;
					}
					roTempNumber = roPtr1->hoNumber;
				}
				
				if (roPtr1->hoNumNext > -1)
				{
					roPtr1 = ho->hoAdRunHeader->rhObjectList[roPtr1->hoNumNext];
					FValue1 = (roPtr1->hoCreationId << 16) + (((int) roPtr1->hoNumber) & 0xFFFF);
				}
			}
		}
	}
	
	oilPtr1->oilListSelected = RootObj;
	oilPtr1->oilNumOfSelected = NumCount;
	
	if (bPassed)
	{
		oilPtr1->oilEventCount = ho->hoAdRunHeader->rhEvtProg->rh2EventCount;
		roTempPtr = ho->hoAdRunHeader->rhObjectList[roTempNumber];
		roTempPtr->hoNextSelected = -32768;
	}
	return bPassed;
}

-(BOOL)doCondition:(int)cond withParam1:(int)param1 andParam2:(int)param2
{
	switch (cond)
	{
		case 0:
			return [self cndAtBackRout:param1];
		case 1:
			return [self cndAtFrontRout:param1];
		case 2:
			return [self cndAboveRout:param1  withParam1:param2];
		case 3:
			return [self cndBelowRout:param1  withParam1:param2];
	}
	return NO;
}

@end

// Petite class pour le tri
@implementation CSortData

@end



				



