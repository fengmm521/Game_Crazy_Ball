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
// CSPRITEGEN : Generateur de sprites
//
//----------------------------------------------------------------------------------
#import "CSpriteGen.h"
#import "CRunApp.h"
#import "CRun.h"
#import "CSprite.h"
#import "CImageBank.h"
#import "CMask.h"
#import "CRect.h"
#import "CImage.h"
#import "IDrawable.h"
#import "CArrayList.h"
#import "CBitmap.h"
#import "CPSCM.h"
#import "CServices.h"
#import "CRunFrame.h"
#import "CRenderer.h"
#import "CObject.h"
#import "CRCom.h"
#import "CLayer.h"
#include <mach/mach_time.h>

#include "CoreMath.h"

@implementation CSpriteGen

-(id)initWithBank:(CImageBank*)b andApp:(CRunApp*)a
{
	firstSprite = nil;
	lastSprite = nil;
	bank = b;
	app = a;
	
	return self;
}

-(void)setFrame:(CRunFrame*)f
{
	frame=f;
}
-(void)dealloc
{
	if (spritesBack!=nil)
	{
		[spritesBack release];
	}
	[super dealloc];
}
-(CSprite*)addSprite:(int)xSpr withY:(int)ySpr andImage:(short)iSpr andLayer:(short)wLayer andZOrder:(int)nZOrder andBackColor:(int)backSpr andFlags:(int)sFlags andObject:(CObject*)extraInfo
{
	// Verifie validite fenetre et image
	CSprite* ptSpr = nil;
		
	// Alloue de la place pour l'objet
	ptSpr = [self winAllocSprite];
	
	// Store info
	ptSpr->bank = bank;
	ptSpr->sprFlags = (sFlags | SF_REAF);
	ptSpr->sprFlags &= ~(SF_TOKILL | SF_REAFINT | SF_RECALCSURF | SF_OWNERDRAW | SF_OWNERSAVE);
	ptSpr->sprLayer = (short) (wLayer * 2);
	if ((sFlags & SF_BACKGROUND) == 0)
	{
		ptSpr->sprLayer++;
	}
	ptSpr->sprZOrder = nZOrder;
	ptSpr->sprX = ptSpr->sprXnew = xSpr;
	ptSpr->sprY = ptSpr->sprYnew = ySpr;
	ptSpr->sprImg = ptSpr->sprImgNew = (short) iSpr;
	ptSpr->sprExtraInfo = extraInfo;
	ptSpr->sprEffect = EFFECTFLAG_TRANSPARENT;
	ptSpr->sprEffectParam = 0;
	ptSpr->sprScaleX = ptSpr->sprTempScaleX = ptSpr->sprScaleY = ptSpr->sprTempScaleY = 1.0f;
	ptSpr->sprAngle = ptSpr->sprTempAngle = 0;
	ptSpr->sprTempImg = 0;
	ptSpr->sprX1z = ptSpr->sprY1z = -1;
	//	    ptSpr.sprSf = ptSpr.sprTempSf = NULL;
	//	    ptSpr.sprColMask = ptSpr.sprTempColMask = NULL;
	
	// Background color
	ptSpr->sprBackColor = 0;
	if ((sFlags & SF_FILLBACK) != 0)
	{
		ptSpr->sprBackColor = backSpr;
	}
	
	// Update bounding box
	[ptSpr updateBoundingBox];
	
	// Copy new bounding box to old
	ptSpr->sprX1 = ptSpr->sprX1new;
	ptSpr->sprY1 = ptSpr->sprY1new;
	ptSpr->sprX2 = ptSpr->sprX2new;
	ptSpr->sprY2 = ptSpr->sprY2new;
	
	// Sort sprite
	[self sortLastSprite:ptSpr];
	
	return ptSpr;
}

//------------------------------------------------------;
//   Ajout d'un sprite ownerdraw a la liste des sprites	;
//------------------------------------------------------;
-(CSprite*)addOwnerDrawSprite:(int)x1 withY1:(int)y1 andX2:(int)x2 andY2:(int)y2 andLayer:(short)wLayer andZOrder:(int)nZOrder andBackColor:(int)backSpr andFlags:(int)sFlags andObject:(CObject*)extraInfo andDrawable:(id)sprProc
{
	CSprite* ptSpr;
	ptSpr = [self winAllocSprite];
	
	// Init coord sprite
	ptSpr->sprX = ptSpr->sprXnew = x1;
	ptSpr->sprY = ptSpr->sprYnew = y1;
	ptSpr->sprX1new = ptSpr->sprX1 = x1;
	ptSpr->sprY1new = ptSpr->sprY1 = y1;
	ptSpr->sprX2new = ptSpr->sprX2 = x2;
	ptSpr->sprY2new = ptSpr->sprY2 = y2;
	ptSpr->sprX1z = ptSpr->sprY1z = -1;
	ptSpr->sprLayer = (short) (wLayer * 2);
	if ((sFlags & SF_BACKGROUND) == 0)
	{
		ptSpr->sprLayer++;
	}
	ptSpr->sprZOrder = nZOrder;
	ptSpr->sprExtraInfo = extraInfo;
	ptSpr->sprRout = sprProc;
	ptSpr->sprFlags = (sFlags | SF_REAF | SF_OWNERDRAW);
	ptSpr->sprFlags &= ~(SF_TOKILL | SF_REAFINT | SF_RECALCSURF);
	ptSpr->sprEffect = EFFECTFLAG_TRANSPARENT;
	ptSpr->sprEffectParam = 0;
	ptSpr->sprScaleX = ptSpr->sprTempScaleX = ptSpr->sprScaleY = ptSpr->sprTempScaleY = 1.0f;
	ptSpr->sprAngle = ptSpr->sprTempAngle = 0;
	ptSpr->sprTempImg = 0;
	//	ptSpr.sprSf = ptSpr.sprTempSf = NULL;
	//	ptSpr.sprColMask = ptSpr.sprTempColMask = 0;
	
	// Background color
	ptSpr->sprBackColor = 0;
	if ((sFlags & SF_FILLBACK) != 0)
	{
		ptSpr->sprBackColor = backSpr;
	}
	
	// Trier le sprite avec ses predecesseurs
	[self sortLastSprite:ptSpr];
	
	return ptSpr;
}

-(CSprite*)modifSprite:(CSprite*)ptSpr withX:(int)xSpr andY:(int)ySpr andImage:(short)iSpr
{
	// Pointer sur le sprite et son image
	if (ptSpr == nil)
		return ptSpr;
	
	// Comparison
	if (ptSpr->sprXnew != xSpr || ptSpr->sprYnew != ySpr || ptSpr->sprImgNew != iSpr)
	{
		// Recalc surface?
		if (ptSpr->sprImgNew != iSpr && (ptSpr->sprAngle != 0 || ptSpr->sprScaleX != 1.0f || ptSpr->sprScaleY != 1.0f))
		{
			ptSpr->sprFlags |= SF_RECALCSURF;
			if (ptSpr->sprSf!=nil)
			{
				[ptSpr->sprSf release];
			}
			ptSpr->sprSf = nil;
			if (ptSpr->sprColMask!=nil)
			{
				[ptSpr->sprColMask release];
			}
			ptSpr->sprColMask = nil;
		}
		
		// Change
		ptSpr->sprXnew = xSpr;
		ptSpr->sprYnew = ySpr;
		ptSpr->sprImgNew = iSpr;
		
		// Update bounding box
		[ptSpr updateBoundingBox];
		
		// Set redraw flag
		ptSpr->sprFlags |= SF_REAF;
	}
	return ptSpr;
}

-(CSprite*)modifSpriteEx:(CSprite*)ptSpr withX:(int)xSpr andY:(int)ySpr andImage:(short)iSpr andScaleX:(float)fScaleX andScaleY:(float)fScaleY andScaleFlag:(BOOL)bResample andAngle:(float)nAngle andRotateFlag:(BOOL)bAntiA
{
	// Pointer sur le sprite et son image
	if (ptSpr == nil)
		return ptSpr;
	
	// Plus tard: autoriser les valeurs nÈgatives et faire ReverseX / ReverseY
	if (fScaleX < 0.0f)
	{
		fScaleX = 0.0f;
	}
	if (fScaleY < 0.0f)
	{
		fScaleY = 0.0f;
	}
	BOOL bOldResample = ((ptSpr->sprFlags & SF_SCALE_RESAMPLE) != 0);
	
	BOOL bOldAntiA = ((ptSpr->sprFlags & SF_ROTATE_ANTIA) != 0);
	nAngle = fmodf(nAngle, 360.0f);
	if (nAngle < 0)
	{
		nAngle += 360;
	}
	
	BOOL bRecalcSurf = NO;
	if (ptSpr->sprScaleX != fScaleX || ptSpr->sprScaleY != fScaleY || bResample != bOldResample ||
		ptSpr->sprAngle != nAngle || bOldAntiA != bAntiA)
	{
		bRecalcSurf = YES;
	}
	
	// Comparison
	if (bRecalcSurf != NO || ptSpr->sprXnew != xSpr || ptSpr->sprYnew != ySpr || ptSpr->sprImgNew != iSpr)
	{
		// Recalc surface?
		if ((bRecalcSurf != NO || ptSpr->sprImgNew != iSpr) && (ptSpr->sprAngle != 0 || ptSpr->sprScaleX != 1.0f || ptSpr->sprScaleY != 1.0f))
		{
			ptSpr->sprFlags |= SF_RECALCSURF;
			if (ptSpr->sprSf!=nil)
			{
				[ptSpr->sprSf release];
			}
			ptSpr->sprSf = nil;
			if (ptSpr->sprColMask!=nil)
			{
				[ptSpr->sprColMask release];
			}
			ptSpr->sprColMask = nil;
		}
		
		// Change
		ptSpr->sprXnew = xSpr;
		ptSpr->sprYnew = ySpr;
		ptSpr->sprImgNew = iSpr;
		
		ptSpr->sprScaleX = fScaleX;
		ptSpr->sprScaleY = fScaleY;
		ptSpr->sprAngle = nAngle;
		ptSpr->sprFlags &= ~(SF_SCALE_RESAMPLE | SF_ROTATE_ANTIA);
		if (bResample != NO)
		{
			ptSpr->sprFlags |= SF_SCALE_RESAMPLE;
		}
		if (bAntiA != NO)
		{
			ptSpr->sprFlags |= SF_ROTATE_ANTIA;
		}
		
		// Update bounding box
		[ptSpr updateBoundingBox];
		
		// Set redraw flag
		ptSpr->sprFlags |= SF_REAF;
		
		// Modification par rapport ‡ la version prÈcÈdente,
		// le ReafSpr est appelÈ seulement s'il y a changement dans les coordonnÈes ou l'image
		
		// Update colliding sprites
		if ((ptSpr->sprFlags & SF_HIDDEN) == 0 && (ptSpr->sprFlags & (SF_INACTIF | SF_REAF | SF_DISABLED)) != 0)
		{
			ptSpr->sprFlags |= SF_REAF;
		}
	}

	return ptSpr;
}

-(CSprite*)modifSpriteEffect:(CSprite*)ptSpr withInkEffect:(int)effect andInkEffectParam:(int)effectParam
{
	// Pointer sur le sprite
	if (ptSpr == nil)
		return ptSpr;
	
	ptSpr->sprEffect = effect;
	ptSpr->sprEffectParam = effectParam;

	// reafficher sprite
	ptSpr->sprFlags |= SF_REAF;
	
	return ptSpr;
}

-(CSprite*)modifOwnerDrawSprite:(CSprite*)ptSprModif withX1:(int)x1 andY1:(int)y1 andX2:(int)x2 andY2:(int)y2
{
	// Pointer sur le sprite
	if (ptSprModif == nil)
		return ptSprModif;
	
	ptSprModif->sprX1new = x1;
	ptSprModif->sprY1new = y1;
	ptSprModif->sprX2new = x2;
	ptSprModif->sprY2new = y2;
	
	// Reafficher sprite
	ptSprModif->sprFlags |= SF_REAF;

	return ptSprModif;
}

-(void)setSpriteLayer:(CSprite*)ptSpr withLayer:(int)nLayer
{
	if (ptSpr == nil)
	{
		return;
	}
	
	int nNewLayer = nLayer * 2;
	if ((ptSpr->sprFlags & SF_BACKGROUND) == 0)
	{
		nNewLayer++;
	}
	
	CSprite* pSprNext;
	CSprite* pSprPrev;	
	if (ptSpr->sprLayer != (short) nNewLayer)
	{
		int nOldLayer = ptSpr->sprLayer;
		ptSpr->sprLayer = (short) nNewLayer;
		
		if (nOldLayer < nNewLayer)
		{
			if (lastSprite != nil)
			{
				// Exchange the sprite with the next one until the end of the list or the next layer
				while (ptSpr != lastSprite)
				{
					pSprNext = ptSpr->objNext;
					if (pSprNext == nil)
					{
						break;
					}
					if (pSprNext->sprLayer > (short) nNewLayer)
					{
						break;
					}
					
					int nzo1 = ptSpr->sprZOrder;
					int nzo2 = pSprNext->sprZOrder;
					
					[self swapSprites:ptSpr withSprite:pSprNext];
					
					// Restore z-order values
					ptSpr->sprZOrder = nzo1;
					pSprNext->sprZOrder = nzo2;
				}
			}
		}
		else
		{
			if (firstSprite != nil)
			{
				// Exchange the sprite with the previous one until the beginning of the list or the previous layer
				while (ptSpr != firstSprite)
				{
					pSprPrev = ptSpr->objPrev;
					if (pSprPrev == nil)
					{
						break;
					}
					if (pSprPrev->sprLayer <= (short) nNewLayer)
					{
						break;
					}
					
					int nzo1 = ptSpr->sprZOrder;
					int nzo2 = pSprPrev->sprZOrder;
					
					[self swapSprites:pSprPrev withSprite:ptSpr];
					
					// Restore z-order values
					ptSpr->sprZOrder = nzo1;
					pSprPrev->sprZOrder = nzo2;
				}
			}
		}
		
		// Take the last zorder value plus one (but the caller must update this value after calling SetSpriteLayer)
		pSprPrev = ptSpr->objPrev;
		if (pSprPrev == nil || pSprPrev->sprLayer != ptSpr->sprLayer)
		{
			ptSpr->sprZOrder = 1;
		}
		else
		{
			ptSpr->sprZOrder = pSprPrev->sprZOrder + 1;
		}
	}
	
	ptSpr->sprFlags|=SF_REAF;
	
	// Force redraw
	if ((ptSpr->sprFlags & SF_HIDDEN) == 0)
	{
		[self activeSprite:ptSpr withFlags:AS_REDRAW andRect:CRectNil];
	}
}

-(void)setSpriteScale:(CSprite*)ptSpr withScaleX:(float)fScaleX andScaleY:(float)fScaleY andFlag:(BOOL)bResample
{
	if (ptSpr != nil)
	{
		// Autoriser les valeurs nÈgatives et faire ReverseX / ReverseY
		if (fScaleX < (float) 0.0)
		{
			fScaleX = (float) 0.0;
		}
		if (fScaleY < (float) 0.0)
		{
			fScaleY = (float) 0.0;
		}
		BOOL bOldResample = ((ptSpr->sprFlags & SF_SCALE_RESAMPLE) != 0);
		
		if (ptSpr->sprScaleX != fScaleX || ptSpr->sprScaleY != fScaleY || bResample != bOldResample)
		{
			ptSpr->sprScaleX = fScaleX;
			ptSpr->sprScaleY = fScaleY;
			ptSpr->sprFlags |= (SF_REAF | SF_RECALCSURF);
			ptSpr->sprFlags &= ~SF_SCALE_RESAMPLE;
			if (bResample)
			{
				ptSpr->sprFlags |= SF_SCALE_RESAMPLE;
			}
			if (ptSpr->sprSf!=nil)
			{
				[ptSpr->sprSf release];
			}
			ptSpr->sprSf = nil;
			if (ptSpr->sprColMask!=nil)
			{
				[ptSpr->sprColMask release];
			}
			ptSpr->sprColMask = nil;
			[ptSpr updateBoundingBox];
			
		}
	}
}

-(void)setSpriteAngle:(CSprite*)ptSpr withAngle:(float)nAngle andFlag:(BOOL)bAntiA
{
	if (ptSpr != nil)
	{
		BOOL bOldAntiA = ((ptSpr->sprFlags & SF_ROTATE_ANTIA) != 0);
		nAngle = fmodf(nAngle, 360.0f);
		if (nAngle < 0)
		{
			nAngle += 360;
		}
		if (ptSpr->sprAngle != nAngle || bOldAntiA != bAntiA)
		{
			ptSpr->sprAngle = nAngle;
			ptSpr->sprFlags &= ~SF_ROTATE_ANTIA;
			if (bAntiA)
			{
				ptSpr->sprFlags |= SF_ROTATE_ANTIA;
			}
			ptSpr->sprFlags |= (SF_REAF | SF_RECALCSURF);
			if (ptSpr->sprSf!=nil)
			{
				[ptSpr->sprSf release];
			}
			ptSpr->sprSf = nil;
			if (ptSpr->sprColMask!=nil)
			{
				[ptSpr->sprColMask release];
			}
			ptSpr->sprColMask = nil;
			
			[ptSpr updateBoundingBox];			
		}
	}
}

-(void)sortLastSprite:(CSprite*)ptSprOrg
{
	CSprite* ptSpr = ptSprOrg;
	CSprite* ptSpr1;
	CSprite* ptSprPrev;
	CSprite* ptSprNext;
	short wLayer;
	
	//==================================================;
	//  	Tri sur les numeros de plan uniquement		;
	//==================================================;
	// On part du principe que les autres sprites sont deja tries
	//
	// On peut mieux optimiser!!! (= parcours tant que plan < et 1 seul echange a la fin...)
	
	// Look for sprite layer
	wLayer = ptSpr->sprLayer;
	ptSpr1 = ptSpr->objPrev;
	while (ptSpr1 != nil)
	{
		if (wLayer >= ptSpr1->sprLayer)			// On arrete des qu'on trouve un plan <
		{
			break;
		}
		
		// Si plan trouve >, alors on echange les sprites
		ptSprPrev = ptSpr1->objPrev;
		if (ptSprPrev == nil)
		{
			firstSprite = ptSpr;
		}
		else
		{
			ptSprPrev->objNext = ptSpr;		// Next ( Prev ( spr1 ) ) = spr
		}
		ptSprNext = ptSpr->objNext;
		if (ptSprNext == nil)
		{
			lastSprite = ptSpr1;
		}
		else
		{
			ptSprNext->objPrev = ptSpr1;		// Prev ( Next ( spr ) ) = spr1
		}
		ptSpr->objPrev = ptSpr1->objPrev;	// Prev ( spr ) = Prev ( spr1 )
		ptSpr1->objPrev = ptSpr;
		
		ptSpr1->objNext = ptSpr->objNext;	// Next ( spr1 ) = Next ( spr )
		ptSpr->objNext = ptSpr1;
		ptSpr1 = ptSpr;
		
		ptSpr1 = ptSpr1->objPrev;			// sprite precedent
	}
	
	// Same layer? sort by z-order value
	if (ptSpr1 != nil && wLayer == ptSpr1->sprLayer)
	{
		int nZOrder = ptSpr->sprZOrder;
		
		while (ptSpr1 != nil && wLayer == ptSpr1->sprLayer)
		{
			if (nZOrder >= ptSpr1->sprZOrder)			// On arrete des qu'on trouve un plan <
			{
				break;
			}
			
			// Si plan trouve >, alors on echange les sprites
			ptSprPrev = ptSpr1->objPrev;
			if (ptSprPrev == nil)
			{
				firstSprite = ptSpr;
			}
			else
			{
				ptSprPrev->objNext = ptSpr;		// Next ( Prev ( spr1 ) ) = spr
			}
			ptSprNext = ptSpr->objNext;
			if (ptSprNext == nil)
			{
				lastSprite = ptSpr1;
			}
			else
			{
				ptSprNext->objPrev = ptSpr1;		// Prev ( Next ( spr ) ) = spr1
			}
			ptSpr->objPrev = ptSpr1->objPrev;			// Prev ( spr ) = Prev ( spr1 )
			ptSpr1->objPrev = ptSpr;
			
			ptSpr1->objNext = ptSpr->objNext;			// Next ( spr1 ) = Next ( spr )
			ptSpr->objNext = ptSpr1;
			ptSpr1 = ptSpr;
			
			ptSpr1 = ptSpr1->objPrev;			// sprite precedent
		}
	}
}

-(void)swapSprites:(CSprite*)sp1 withSprite:(CSprite*)sp2
{
	// Security
	if (sp1 == sp2)
	{
		return;
	}
	
	CSprite* pPrev1 = sp1->objPrev;
	CSprite* pNext1 = sp1->objNext;
	
	CSprite* pPrev2 = sp2->objPrev;
	CSprite* pNext2 = sp2->objNext;
	
	// Exchange layers . non !
	//	WORD holdLayer = sp1.sprLayer;
	//	sp1.sprLayer = sp2.sprLayer;
	//	sp2.sprLayer = holdLayer;
	
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
			firstSprite = sp2;
		}
		if (pNext2 == nil)
		{
			lastSprite = sp1;
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
			firstSprite = sp1;	//	*ptPtsObj = (UINT)sp1;
		}
		if (pNext1 == nil)
		{
			lastSprite = sp2;	//	*(ptPtsObj+1) = (UINT)sp2;
		}
	}
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
			firstSprite = sp2;
		}
		if (pPrev2 == nil)
		{
			firstSprite = sp1;
		}
		if (pNext1 == nil)
		{
			lastSprite = sp2;
		}
		if (pNext2 == nil)
		{
			lastSprite = sp1;
		}
	}
}

-(void)moveSpriteToFront:(CSprite*)pSpr
{
	if (lastSprite != nil)
	{
		int nLayer = pSpr->sprLayer;
		
		// Exchange the sprite with the next one until the end of the list
		while (pSpr != lastSprite)
		{
			CSprite* pSprNext = pSpr->objNext;
			if (pSprNext == nil)
			{
				break;
			}
			
			if (pSprNext->sprLayer > nLayer)
			{
				break;
			}
			
			[self swapSprites:pSpr withSprite:pSprNext];
		}
		
		// Force redraw
		if ((pSpr->sprFlags & SF_HIDDEN) == 0)
		{
			[self activeSprite:pSpr withFlags:AS_REDRAW andRect:CRectNil];
		}
	}
}

-(void)moveSpriteToBack:(CSprite*)pSpr
{
	if (lastSprite != nil)
	{
		int nLayer = pSpr->sprLayer;
		
		// Exchange the sprite with the previous one until the end of the list
		while (pSpr != firstSprite)
		{
			CSprite* pSprPrev = pSpr->objPrev;
			if (pSprPrev == nil)
			{
				break;
			}
			
			if (pSprPrev->sprLayer < nLayer)
			{
				break;
			}
			
			[self swapSprites:pSprPrev withSprite:pSpr];
		}
		
		// Force redraw
		if ((pSpr->sprFlags & SF_HIDDEN) == 0)
		{
			[self activeSprite:pSpr withFlags:AS_REDRAW andRect:CRectNil];
		}
	}
}

-(void)moveSpriteBefore:(CSprite*)pSprToMove withSprite:(CSprite*)pSprDest
{
	if (pSprToMove->sprLayer == pSprDest->sprLayer)
	{
		CSprite* pSpr = pSprToMove->objPrev;
		while (pSpr != nil && pSpr != pSprDest)
		{
			pSpr = pSpr->objPrev;
		}
		if (pSpr != nil)
		{
			// Exchange the sprite with the previous one until the second one is reached
			// TODO: could be optimized (no need to loop, we only need to update 6 sprites)
			CSprite* pPrevSpr = pSprToMove;
			do
			{
				pPrevSpr = pSprToMove->objPrev;
				if (pPrevSpr == nil)
				{
					break;
				}
				
				[self swapSprites:pSprToMove withSprite:pPrevSpr];
				
			} while (pPrevSpr != pSprDest);
			
			// Force redraw
			if ((pSprToMove->sprFlags & SF_HIDDEN) == 0)
			{
				[self activeSprite:pSprToMove withFlags:AS_REDRAW andRect:CRectNil];
			}
		}
	}
}

-(void)moveSpriteAfter:(CSprite*)pSprToMove withSprite:(CSprite*)pSprDest
{
	if (pSprToMove->sprLayer == pSprDest->sprLayer)
	{
		CSprite* pSpr = pSprToMove->objNext;
		while (pSpr != nil && pSpr != pSprDest)
		{
			pSpr = pSpr->objNext;
		}
		if (pSpr != nil)
		{
			// Exchange the sprite with the next one until the second one is reached
			// TODO: could be optimized (no need to loop, we only need to update 6 sprites)
			CSprite* pNextSpr;
			do
			{
				pNextSpr = pSprToMove->objNext;
				if (pNextSpr == nil)
				{
					break;
				}
				[self swapSprites:pSprToMove withSprite:pNextSpr];
			} while (pNextSpr != pSprDest);
			
			// Force redraw
			if ((pSprToMove->sprFlags & SF_HIDDEN) == 0)
			{
				[self activeSprite:pSprToMove withFlags:AS_REDRAW andRect:CRectNil];
			}
		}
	}
}

-(BOOL)isSpriteBefore:(CSprite*)pSpr withSprite:(CSprite*)pSprDest
{
	if (pSpr->sprLayer < pSprDest->sprLayer)
	{
		return YES;
	}
	if (pSpr->sprLayer > pSprDest->sprLayer)
	{
		return NO;
	}
	if (pSpr->sprZOrder < pSprDest->sprZOrder)
	{
		return YES;
	}
	return NO;
}

-(BOOL)isSpriteAfter:(CSprite*)pSpr withSprite:(CSprite*)pSprDest
{
	if (pSpr->sprLayer > pSprDest->sprLayer)
	{
		return YES;
	}
	if (pSpr->sprLayer < pSprDest->sprLayer)
	{
		return NO;
	}
	if (pSpr->sprZOrder > pSprDest->sprZOrder)
	{
		return YES;
	}
	return NO;
}

-(CSprite*)getFirstSprite:(int)nLayer withFlags:(int)dwFlags
{
	CSprite* pSpr = nil;
	pSpr = firstSprite;
	
	// Get internal layer number
	int nIntLayer = nLayer;
	if (nLayer != -1)
	{
		nIntLayer *= 2;
		if ((dwFlags & GS_BACKGROUND) == 0)
		{
			nIntLayer++;
		}
	}
	
	// Search for first sprite in this layer
	while (pSpr != nil)
	{
		// Correct layer?
		if (nIntLayer == -1 || pSpr->sprLayer == nIntLayer)
		{
			break;
		}
		
		// Break if a greater layer is reached (means there is no sprite in the layer)
		if (pSpr->sprLayer > nIntLayer)
		{
			pSpr = nil;
			break;
		}
		
		// Next sprite
		pSpr = pSpr->objNext;
	}
	return pSpr;
}

-(CSprite*)getNextSprite:(CSprite*)pSpr withFlags:(int)dwFlags
{
	if (pSpr != nil)
	{
		int nLayer = pSpr->sprLayer;
		
		if ((dwFlags & GS_BACKGROUND) != 0)
		{
			// Look for next background sprite
			while ((pSpr = pSpr->objNext) != nil)
			{
				// Active
				if ((pSpr->sprFlags & SF_BACKGROUND) == 0)
				{
					// If only same layer, stop
					if ((dwFlags & GS_SAMELAYER) != 0)
					{
						pSpr = nil;
						break;
					}
				}
				// Background
				else
				{
					// If only same layer
					if ((dwFlags & GS_SAMELAYER) != 0)
					{
						// Different layer? end
						if (pSpr->sprLayer != nLayer)
						{
							pSpr = nil;
						}
					}
					
					// Stop
					break;
				}
			}
		}
		else
		{
			// Look for next active sprite
			while ((pSpr = pSpr->objNext) != nil)
			{
				// Background
				if ((pSpr->sprFlags & SF_BACKGROUND) != 0)
				{
					// If only same layer, stop
					if ((dwFlags & GS_SAMELAYER) != 0)
					{
						pSpr = nil;
						break;
					}
				}
				// Active
				else
				{
					// If only same layer
					if ((dwFlags & GS_SAMELAYER) != 0)
					{
						// Different layer? end
						if (pSpr->sprLayer != nLayer)
						{
							pSpr = nil;
						}
					}
					
					// Stop
					break;
				}
			}
		}
	}
	return pSpr;
}

-(CSprite*)getPrevSprite:(CSprite*)pSpr withFlags:(int)dwFlags
{
	if (pSpr != nil)
	{
		int nLayer = pSpr->sprLayer;
		
		if ((dwFlags & GS_BACKGROUND) != 0)
		{
			// Look for previous background sprite
			while ((pSpr = pSpr->objPrev) != nil)
			{
				// Active
				if ((pSpr->sprFlags & SF_BACKGROUND) == 0)
				{
					// If only same layer, stop
					if ((dwFlags & GS_SAMELAYER) != 0)
					{
						pSpr = nil;
						break;
					}
				}
				// Background
				else
				{
					// If only same layer
					if ((dwFlags & GS_SAMELAYER) != 0)
					{
						// Different layer? end
						if (pSpr->sprLayer != nLayer)
						{
							pSpr = nil;
						}
					}
					// Stop
					break;
				}
			}
		}
		else
		{
			// Look for next active sprite
			while ((pSpr = pSpr->objPrev) != nil)
			{
				// Background
				if ((pSpr->sprFlags & SF_BACKGROUND) != 0)
				{
					// If only same layer, stop
					if ((dwFlags & GS_SAMELAYER) != 0)
					{
						pSpr = nil;
						break;
					}
				}
				// Active
				else
				{
					// If only same layer
					if ((dwFlags & GS_SAMELAYER) != 0)
					{
						// Different layer? end
						if (pSpr->sprLayer != nLayer)
						{
							pSpr = nil;
						}
					}
					// Stop
					break;
				}
			}
		}
	}
	return pSpr;
}

-(void)showSprite:(CSprite*)ptSpr withFlag:(BOOL)showFlag
{
	if (ptSpr != nil)
	{
		// Show sprite
		if (showFlag)
		{
			ptSpr->sprFlags &= ~(SF_HIDDEN | SF_TOHIDE);
			if ((ptSpr->sprFlags & SF_INACTIF) != 0)
			{
				ptSpr->sprFlags |= SF_REAF;
			}
		}
		
		// Hide sprite (next loop)
		else
		{
			if ((ptSpr->sprFlags & SF_HIDDEN) == 0)
			{
				if (ptSpr->sprX1z == -1 && ptSpr->sprY1z == -1)
				{
					ptSpr->sprFlags |= SF_HIDDEN;
				}
				else
				{
					ptSpr->sprFlags |= SF_TOHIDE;
					if ((ptSpr->sprFlags & SF_INACTIF) != 0)
					{
						ptSpr->sprFlags |= SF_REAF;
					}
				}
			}
		}
	}
}


-(void)activeSprite:(CSprite*)ptSpr withFlags:(int)activeFlag andRect:(CRect)reafRect
{
	// Active only one
	if (ptSpr != nil)
	{
		switch (activeFlag)
		{
                // Deactivate
			case 0x0000:					// AS_DEACTIVATE
				ptSpr->sprFlags |= SF_INACTIF;	// Warning: no break
				
                // Redraw (= activate only for next loop)
			case 0x0001:					// AS_REDRAW:
				ptSpr->sprFlags |= SF_REAF;
				break;
				
                // Activate
			case 0x0002:					// AS_ACTIVATE:
				ptSpr->sprFlags &= ~SF_INACTIF;
				break;
				
                // Enable
			case 0x0004:					// AS_ENABLE:
				ptSpr->sprFlags &= ~SF_DISABLED;
				break;
				
                // Disable
			case 0x0008:					// AS_DISABLE:
				ptSpr->sprFlags |= SF_DISABLED;
				break;
		}
	}
	// Active all
	else
	{
		ptSpr = firstSprite;
		while (ptSpr != nil)
		{
			switch (activeFlag)
			{
                    // Deactivate
				case 0x0000:			    //AS_DEACTIVATE:
					ptSpr->sprFlags |= SF_INACTIF;
					
                    // Redraw (= activate only for next loop)
				case 0x0001:			    // AS_REDRAW:
					if ((ptSpr->sprFlags & SF_HIDDEN) == 0)
					{
						ptSpr->sprFlags |= SF_REAF;
					}
					break;
					
                    // Redraw (= activate only for next loop) - all sprites except background sprites
				case 0x0011:			    // AS_REDRAW_NOBKD:
					if ((ptSpr->sprFlags & (SF_HIDDEN | SF_BACKGROUND)) == 0)
					{
						ptSpr->sprFlags |= SF_REAF;
					}
					break;
					
                    // Activate
				case 0x0002:			    // AS_ACTIVATE:
					ptSpr->sprFlags &= ~SF_INACTIF;
					break;
					
                    // Enable
				case 0x0004:			    // AS_ENABLE:
					ptSpr->sprFlags &= ~SF_DISABLED;
					break;
					
                    // Disable
				case 0x0008:			    // AS_DISABLE:
					ptSpr->sprFlags |= SF_DISABLED;
					break;
					
				default:
					ptSpr->sprFlags &= ~SF_INACTIF;
					break;
			}
			ptSpr = ptSpr->objNext;
		}
	}
}

-(void)killSprite:(CSprite*)ptSprToKill withFast:(BOOL)bFast
{
	CSprite* ptSpr = ptSprToKill;
	
	[ptSpr killSpriteZone];
	
	// Si sprite OwnerDraw, appeler routine
	if (bFast==NO)
	{
		if ((ptSpr->sprFlags & SF_OWNERDRAW)!=0 && (ptSpr->sprFlags&SF_NOKILLDATA)==0)
		{
			[ptSpr->sprRout spriteKill:ptSpr];
		}
	}
	
	// Free object
	[self winFreeSprite:ptSpr];
}

-(void)delSprite:(CSprite*)ptSprToDel
{
	if (ptSprToDel != nil)
	{
		CSprite* ptSpr = ptSprToDel;
		
		ptSpr->sprFlags &= ~SF_RAMBO;
		ptSpr->sprFlags |= SF_TOKILL | SF_REAF;
		if ((ptSpr->sprFlags & SF_HIDDEN) == 0 && (ptSpr->sprFlags & SF_INACTIF) != 0)
		{
			ptSpr->sprFlags &= ~SF_INACTIF;
		}
	}
}

-(void)delSpriteFast:(CSprite*)ptSpr
{
	[self killSprite:ptSpr withFast:YES];
}

////////////////////////////////////////////////
//
// Recalc sprite surface (rotation or stretch)
//
-(void)recalcSpriteSurface:(CSprite*)ptSpr
{
	// Free collision mask
	if (ptSpr->sprColMask!=nil)
	{
		[ptSpr->sprColMask release];
	}
	ptSpr->sprColMask = nil;
	
	// Original image?
	if (ptSpr->sprAngle == 0 && ptSpr->sprScaleX == 1.0f && ptSpr->sprScaleY == 1.0f)
	{
		ptSpr->sprSf = nil;
	}
	// Stretched or rotated image
	else
	{
		// Already calculated?
		if (ptSpr->sprTempSf != nil &&
			ptSpr->sprImgNew == ptSpr->sprTempImg &&
			ptSpr->sprAngle == ptSpr->sprTempAngle &&
			ptSpr->sprScaleX == ptSpr->sprTempScaleX &&
			ptSpr->sprScaleY == ptSpr->sprTempScaleY)
		{
			ptSpr->sprSf = ptSpr->sprTempSf;
			ptSpr->sprTempSf = nil;
			
			ptSpr->sprColMask = ptSpr->sprTempColMask;
			ptSpr->sprTempColMask = nil;
			return;
		}
		
		// Get image surface
		CImage* ptei;
		ptei = [bank getImageFromHandle:ptSpr->sprImgNew];
		if (ptei == nil)
		{
			if (ptSpr->sprSf!=nil)
			{
				[ptSpr->sprSf release];
			}
			ptSpr->sprSf = nil;
			return;
		}
		
		// Create or resize surface
		int w = ptSpr->sprX2new - ptSpr->sprX1new;
		int h = ptSpr->sprY2new - ptSpr->sprY1new;
		if (w <= 0)
		{
			w = 1;
		}
		if (h <= 0)
		{
			h = 1;
		}

	}
}

////////////////////////////////////////////////
//
// Recalc temp sprite surface (rotation or stretch)
//
-(void)recalcTempSpriteSurface:(CSprite*)ptSpr withWidth:(int)newWidth andHeight:(int)newHeight
{
	// Original image?
	if (ptSpr->sprTempAngle == 0 && ptSpr->sprTempScaleX == 1.0f && ptSpr->sprTempScaleY == 1.0f)
	{
	}
	// Stretched or rotated image
	else
	{
		// Get image surface
		CImage* ptei = ptei = [bank getImageFromHandle:ptSpr->sprTempImg];
		if (ptei == nil)
		{
			if (ptSpr->sprTempSf!=nil)
			{
				[ptSpr->sprTempSf release];
			}
			ptSpr->sprTempSf = nil;
			return;
		}
		
		// Create or resize surface
		int w = newWidth;
		int h = newHeight;
		if (w <= 0)
		{
			w = 1;
		}
		if (h <= 0)
		{
			h = 1;
		}

	}
}

-(CMask*)getSpriteMask:(CSprite*)ptSpr withImage:(short)newImg andFlags:(int)nFlags andAngle:(float)newAngle andScaleX:(double)newScaleX andScaleY:(double)newScaleY
{
	if (ptSpr != nil)
	{
		if ((ptSpr->sprFlags & SF_OWNERDRAW) == 0)
		{
			short nImg = newImg;
			if (nImg == -1)
			{
				nImg = ptSpr->sprImg;
			}
			if (nImg != -1)
			{
				CImage* pImage = [bank getImageFromHandle:nImg];
				return [pImage getMask:nFlags withAngle:newAngle andScaleX:newScaleX andScaleY:newScaleY];
			}
		}
		else
		{
			return [ptSpr->sprRout spriteGetMask];
		}
	}
	return nil;
	
}

-(CMask*)getSpriteMask:(CSprite*)ptSpr withImage:(short)newImg andFlags:(int)nFlags
{
	if (ptSpr != nil)
	{
		if ((ptSpr->sprFlags & SF_OWNERDRAW) == 0)
		{
			short nImg = newImg;
			if (nImg == -1)
			{
				nImg = ptSpr->sprImg;
			}
			if (nImg != -1)
			{
				CImage* pImage = [bank getImageFromHandle:nImg];
				return [pImage getMask:nFlags];
			}
		}
		else
		{
			return [ptSpr->sprRout spriteGetMask];
		}
	}
	return nil;
	
}

-(void)spriteUpdate
{
	CSprite* ptSpr;
	
	// Parcours table des sprites
	ptSpr = firstSprite;
	while (ptSpr != nil)
	{
		// Mise a jour nouvelles caracteristiques sprite
		if ((ptSpr->sprFlags & SF_REAF) != 0)
		{
			ptSpr->sprX = ptSpr->sprXnew;
			ptSpr->sprY = ptSpr->sprYnew;
			ptSpr->sprX1 = ptSpr->sprX1new;
			ptSpr->sprY1 = ptSpr->sprY1new;
			ptSpr->sprX2 = ptSpr->sprX2new;
			ptSpr->sprY2 = ptSpr->sprY2new;
			if ((ptSpr->sprFlags & SF_OWNERDRAW) == 0)
			{
				ptSpr->sprImg = ptSpr->sprImgNew;
			}
		}
		
		// Recalculate surface
		if ((ptSpr->sprFlags & SF_RECALCSURF) != 0)
		{
			ptSpr->sprFlags &= ~SF_RECALCSURF;
			[self recalcSpriteSurface:ptSpr];
		}
		
		// Next sprite
		ptSpr = ptSpr->objNext;
	}
}

-(void)spriteClear
{
	CSprite* ptSpr;
	CSprite* ptSprNext;
	
	do
	{
		ptSpr = firstSprite;
		//[self sprite_Intersect:frame->leEditWinWidth withHeight:frame->leEditWinHeight];
		
		// Parcours table des sprites
		while (ptSpr != nil)
		{
			// Tester si sprite a virer ou a cacher
			if ((ptSpr->sprFlags & SF_TOHIDE) != 0)
			{
				[ptSpr killSpriteZone];
				ptSpr->sprFlags &= ~SF_TOHIDE;
				ptSpr->sprFlags |= SF_HIDDEN;
				ptSpr->sprX1z = ptSpr->sprY1z = -1;
			}
			if ((ptSpr->sprFlags & SF_TOKILL) != 0)
			{
				ptSprNext = ptSpr->objNext;
				[self killSprite:ptSpr withFast:NO];
				ptSpr = ptSprNext;
			}
			else
			{
				ptSpr = ptSpr->objNext;
			}
		}
	} while (NO);
}


-(void)pasteSpriteEffect:(CRenderer*)renderer withImage:(short)iNum andX:(int)iX andY:(int)iY andFlags:(int)flags andInkEffect:(int)effect andInkEffectParam:(int)effectParam
{
	int x1, y1;
	CImage* ptei;
	

	// Calcul adresse image et coordonnees
	ptei = [bank getImageFromHandle:iNum];
	if (ptei == nil)
	{
		return;
	}
	
	x1 = iX;
	if ((flags & PSF_HOTSPOT) != 0)
	{
		x1 -= ptei->xSpot;
	}
	
	y1 = iY;
	if ((flags & PSF_HOTSPOT) != 0)
	{
		y1 -= ptei->ySpot;
	}
	
	// Blit
	renderer->renderImage(ptei, x1, y1, ptei->width, ptei->height, effect, effectParam);
}

-(int)getNSprites
{
	int nSprites=0;
	CSprite* ptSpr;
	for (ptSpr = firstSprite; ptSpr != nil; ptSpr = ptSpr->objNext)
	{
		nSprites++;
	}
	return nSprites;
}
-(void)winDrawSprites:(CRenderer*)renderer
{
//	uint64_t start = mach_absolute_time();

	CSprite* ptSpr;
	CSprite* ptFirstSpr;
	
	//	BlitMode		bm;
	//	BlitOp			bo;
	
	ptFirstSpr = firstSprite;
	if (ptFirstSpr == nil)
	{
		return;
	}

	int currentLayer = -1;

	// Inkeffects: rajouter blitmodes
	// Scan sprite table
	for (ptSpr = ptFirstSpr; ptSpr != nil; ptSpr = ptSpr->objNext)
	{
		// Si sprite inactif et pas SF_REAF, pas d'affichage
		if ((ptSpr->sprFlags & (SF_HIDDEN | SF_DISABLED)) != 0)
		{
			continue;
		}

		//Update the layer transformation matrix?
		if(ptSpr->sprLayer != currentLayer)
		{
			currentLayer = ptSpr->sprLayer/2;
			CLayer* layer = frame->layers[currentLayer];
			renderer->setCurrentLayer(layer);
		}
		
		// Sprite ownerdraw
		if ((ptSpr->sprFlags & SF_OWNERDRAW) != 0 && ptSpr->sprRout != nil)
		{
			[ptSpr->sprRout spriteDraw:renderer withSprite:ptSpr andImageBank:bank andX:ptSpr->sprX1 andY:ptSpr->sprY1];
		}
		
		// Normal sprite
		else
		{
			[ptSpr draw:renderer];
		}
		ptSpr->sprFlags &= ~(SF_REAF | SF_REAFINT);
	}

/*
	mach_timebase_info_data_t info;
	mach_timebase_info(&info);
	uint64_t end = ((mach_absolute_time()-start)*info.numer) / info.denom;
	double elapsed = end / 1000000000.0;
	NSLog(@"Time taken: %f   second: %f", (float)elapsed, (float)elapsed * 60);
	*/
}

-(void)drawSprite:(CSprite*)sprite withRenderer:(CRenderer*)renderer
{
	// Sprite ownerdraw
	if ((sprite->sprFlags & SF_OWNERDRAW) != 0 && sprite->sprRout != nil)
		[sprite->sprRout spriteDraw:renderer withSprite:sprite andImageBank:bank andX:sprite->sprX1 andY:sprite->sprY1];
	// Normal sprite
	else
		[sprite draw:renderer];
}

//------------------------------;
//	  Affichage des sprites	    ;
//------------------------------;
-(void)spriteDraw:(CRenderer*)renderer
{
	[self winDrawSprites:renderer];
}

-(CSprite*)getLastSprite:(int)nLayer withFlags:(int)dwFlags
{
	CSprite* pSpr = lastSprite;
	
	// Get internal layer number
	int nIntLayer = nLayer;
	if (nLayer != -1)
	{
		nIntLayer *= 2;
		if ((dwFlags & GS_BACKGROUND) == 0)
		{
			nIntLayer++;
		}
	}
	
	// Search for first sprite in this layer
	while (pSpr != nil)
	{
		// Correct layer?
		if (nIntLayer == -1 || pSpr->sprLayer == nIntLayer)
		{
			break;
		}
		
		// Break if a greater layer is reached (means there is no sprite in the layer)
		if (pSpr->sprLayer < nIntLayer)
		{
			pSpr = nil;
			break;
		}
		
		// Next sprite
		pSpr = pSpr->objPrev;
	}
	return pSpr;
}

-(CSprite*)winAllocSprite
{
	CSprite* spr = [[CSprite alloc] initWithBank:bank];
	if (firstSprite == nil)
	{
		firstSprite = spr;
		lastSprite = spr;
		spr->objPrev = nil;
		spr->objNext = nil;
		return spr;
	}
	CSprite* previous = lastSprite;
	previous->objNext = spr;
	spr->objPrev = previous;
	spr->objNext = nil;
	lastSprite = spr;
	return spr;
}

-(void)winFreeSprite:(CSprite*)spr
{
	if (spr->objPrev == nil)
	{
		firstSprite = spr->objNext;
	}
	else
	{
		spr->objPrev->objNext = spr->objNext;
	}
	if (spr->objNext != nil)
	{
		spr->objNext->objPrev = spr->objPrev;
	}
	else
	{
		lastSprite = spr->objPrev;
	}
	[spr release];
	spr = nil;
}

-(void)winSetColMode:(short)c
{
	colMode = c;
}

-(CSprite*)spriteCol_TestPoint:(CSprite*)firstSpr withLayer:(short)nLayer andX:(int)xp andY:(int)yp andFlags:(int)dwFlags
{
	CSprite* ptSpr = firstSpr;
	if (ptSpr == nil)
	{
		ptSpr = firstSprite;
	}
	else
	{
		ptSpr = ptSpr->objNext;
	}

	BOOL bAllLayers = (nLayer == LAYER_ALL);
	BOOL bEvenNoCol = ((dwFlags & SCF_EVENNOCOL) != 0);
	short wAllLayerBit;
	if ((dwFlags & SCF_BACKGROUND) != 0)
	{
		wAllLayerBit = 0;
		if (nLayer != LAYER_ALL)
		{
			nLayer = (short) (nLayer * 2);
		}
	}
	else
	{
		wAllLayerBit = 1;
		if (nLayer != LAYER_ALL)
		{
			nLayer = (short) (nLayer * 2 + 1);
		}
	}


	
	// Recherche des autres sprites
	for (; ptSpr != nil; ptSpr = ptSpr->objNext)
	{
		if (!bAllLayers)	// todo: optimisation: faire une boucle diff�rente pour le mode all layers et une autre pour skipper les 1ers layers
		{
			if (ptSpr->sprLayer < nLayer)
			{
				continue;
			}
			if (ptSpr->sprLayer > nLayer)
			{
				break;
			}
		}
		else if ((ptSpr->sprLayer & 1) != wAllLayerBit)
		{
			continue;
		}
		
		// Can test collision with this one?
		if (bEvenNoCol || (ptSpr->sprFlags & SF_RAMBO) != 0)
		{
			CLayer* layer = frame->layers[ptSpr->sprLayer/2];
			int windowX = app->run->rhWindowX;
			int windowY = app->run->rhWindowY;
			int lx = (xp-windowX) + windowX*layer->xCoef + layer->x;
			int ly = (yp-windowY) + windowY*layer->yCoef + layer->y;

			if (lx >= ptSpr->sprX1 && lx < ptSpr->sprX2 && ly >= ptSpr->sprY1 && ly < ptSpr->sprY2)
			{
				int nGetColMaskFlag = GCMF_OBSTACLE;
				
				// Collides => test background flags
				if ((dwFlags & SCF_BACKGROUND) != 0)
				{
					// Platform? no collision if we check collisions with obstacles
					if ((ptSpr->sprFlags & SF_PLATFORM) != 0)
					{
						if ((dwFlags & SCF_OBSTACLE) != 0)
						{
							continue;
						}
						
						// Platform and check collisions with platforms => get platform collision mask
						nGetColMaskFlag = GCMF_PLATFORM;
					}
				}
			
				// Box collision mode
				if (colMode == CM_BOX || (ptSpr->sprFlags & SF_COLBOX) != 0)
				{
					return ptSpr;
				}
					
				// Fine collision mode, test bit image
				CMask* pMask = [self getSpriteMask:ptSpr withImage:(short)-1 andFlags:nGetColMaskFlag];
				if(pMask != nil)
				{
					ImageInfo info = [bank getImageInfoEx:ptSpr->sprImg withAngle:0 andScaleX:1 andScaleY:1];
					Vec2f position = Vec2f(ptSpr->sprX, ptSpr->sprY);
					Vec2f hotspot = Vec2f(info.xSpot, info.ySpot);
					Vec2f scale = Vec2f(ptSpr->sprScaleX, ptSpr->sprScaleY);
					Mat3f worldToMask = Mat3f::worldspaceToMaskspace(position, hotspot, scale, ptSpr->sprAngle);
					Vec2f maskCoord = worldToMask.transformPoint(Vec2f(lx,ly));
					int dx = (int)maskCoord.x;
					int dy = (int)maskCoord.y;
					
					if(dx >= 0 && dx < pMask->width && dy >= 0 && dy < pMask->height)
					{
						int offset = dy*pMask->lineWidth + dx / 16;
						short m = (short) (0x8000 >> (dx & 15));							
						if ((pMask->mask[offset] & m) != 0)
							return ptSpr;
					}
				}
			}
		}
	}
	return nil;
}
-(BOOL)spriteCol_TestPointOne:(CSprite*)firstSpr withLayer:(short)nLayer andX:(int)xp andY:(int)yp andFlags:(int)dwFlags
{
	//Fix crash when firstSpr is nil
	if(firstSpr == nil)
		return NO;

	CSprite* ptSpr = firstSpr;
	BOOL bAllLayers = (nLayer == LAYER_ALL);
	BOOL bEvenNoCol = ((dwFlags & SCF_EVENNOCOL) != 0);
	short wAllLayerBit;
	if ((dwFlags & SCF_BACKGROUND) != 0)
	{
		wAllLayerBit = 0;
		if (nLayer != LAYER_ALL)
		{
			nLayer = (short) (nLayer * 2);
		}
	}
	else
	{
		wAllLayerBit = 1;
		if (nLayer != LAYER_ALL)
		{
			nLayer = (short) (nLayer * 2 + 1);
		}
	}
	
	// Recherche des autres sprites
    if (!bAllLayers)
    {
        if (ptSpr->sprLayer < nLayer)
            return NO;
        if (ptSpr->sprLayer > nLayer)
            return NO;
    }
    else if ((ptSpr->sprLayer & 1) != wAllLayerBit)
        return NO;

    // Can test collision with this one?
    if (bEvenNoCol || (ptSpr->sprFlags & SF_RAMBO) != 0)
    {
		CLayer* layer = frame->layers[ptSpr->sprLayer/2];
		int windowX = app->run->rhWindowX;
		int windowY = app->run->rhWindowY;
		int lx = (xp-windowX) + windowX*layer->xCoef + layer->x;
		int ly = (yp-windowY) + windowY*layer->yCoef + layer->y;

        if (lx >= ptSpr->sprX1 && lx < ptSpr->sprX2 && ly >= ptSpr->sprY1 && ly < ptSpr->sprY2)
        {
            int nGetColMaskFlag = GCMF_OBSTACLE;
            
            // Collides => test background flags
            if ((dwFlags & SCF_BACKGROUND) != 0)
            {
                // Platform? no collision if we check collisions with obstacles
                if ((ptSpr->sprFlags & SF_PLATFORM) != 0)
                {
                    if ((dwFlags & SCF_OBSTACLE) != 0)
                    {
                        return NO;
                    }
                    
                    // Platform and check collisions with platforms => get platform collision mask
                    nGetColMaskFlag = GCMF_PLATFORM;
                }
            }
            
            // Box collision mode
            if (colMode == CM_BOX || (ptSpr->sprFlags & SF_COLBOX) != 0)
            {
                return YES;
            }
            
            // Fine collision mode, test bit image
            CMask* pMask = [self getSpriteMask:ptSpr withImage:(short)-1 andFlags:nGetColMaskFlag];
            if(pMask != nil)
            {
                ImageInfo info = [bank getImageInfoEx:ptSpr->sprImg withAngle:0 andScaleX:1 andScaleY:1];
                Vec2f position = Vec2f(ptSpr->sprX, ptSpr->sprY);
                Vec2f hotspot = Vec2f(info.xSpot, info.ySpot);
                Vec2f scale = Vec2f(ptSpr->sprScaleX, ptSpr->sprScaleY);
                Mat3f worldToMask = Mat3f::worldspaceToMaskspace(position, hotspot, scale, ptSpr->sprAngle);
                Vec2f maskCoord = worldToMask.transformPoint(Vec2f(lx,ly));
                int dx = (int)maskCoord.x;
                int dy = (int)maskCoord.y;
                
                if(dx >= 0 && dx < pMask->width && dy >= 0 && dy < pMask->height)
                {
                    int offset = dy*pMask->lineWidth + dx / 16;
                    short m = (short) (0x8000 >> (dx & 15));
                    if ((pMask->mask[offset] & m) != 0)
                        return YES;
                }
            }
        }
    }
	return NO;
}

//--------------------------------------------------------------------------------------//
//	Test collision entre 1 sprite et les autres en changeant les coords du 1er	    //
//--------------------------------------------------------------------------------------//
-(CArrayList*)spriteCol_TestSprite_All:(CSprite*)ptSpr withImage:(short)newImg andX:(int)newX andY:(int)newY andAngle:(float)newAngle andScaleX:(float)newScaleX andScaleY:(float)newScaleY andFlags:(int)dwFlags
{
	int nLayer;
	int cm = colMode;
	CArrayList* list = nil;
	
	if (ptSpr == nil)
	{
		return nil;
	}
	if ((ptSpr->sprFlags & SF_COLBOX) != 0)
	{
		cm = CM_BOX;
	}
	
	nLayer = ptSpr->sprLayer;		// collisions always in the same layer
	
	// Flags to test
	if ((dwFlags & SCF_BACKGROUND) != 0)
	{
		// Test with background sprites => even layer
		nLayer &= ~1;
	}
	else
	{
		// Test with active sprites => collisions must be enabled
		if ((ptSpr->sprFlags & SF_RAMBO) == 0)
		{
			return nil;
		}
		
		// Test with active sprites => odd layer
		nLayer |= 1;
	}
	
	int x1 = newX;
	int y1 = newY;
	int x2 = x1;
	int y2 = y1;
	
	CMask* pMask = nil;
	
	// Si angle = 0 et coefs = 1.0f, ou si ownerdraw
	//		=> m�thode normale
	//
	// Si angle != 0 ou coefs != 1.0f
	//		=> appeler PrepareSpriteColMask pour calculer la bounding box et r�cup�rer le masque si d�j� calcul�
	//		=> puis r�cup�rer le masque avec CompleteSpriteColMask quand on en a besoin
	
	// Get sprite mask
	if (ptSpr->sprFlags&SF_OWNERDRAW)
	{
		x2+=ptSpr->sprX2-ptSpr->sprX1;
		y2+=ptSpr->sprY2-ptSpr->sprY1;
	}
	else
	{
		ImageInfo ifo=[bank getImageInfoEx:newImg withAngle:newAngle andScaleX:newScaleX andScaleY:newScaleY];
		if ((ptSpr->sprFlags & SF_NOHOTSPOT) == 0)
		{
			x1 -= ifo.xSpot;
			y1 -= ifo.ySpot;
		}
		x2 = x1 + ifo.width;
		y2 = y1 + ifo.height;	
	}
	CSprite* ptSpr1;
	CMask* pMask2;
	for (ptSpr1 = firstSprite; ptSpr1 != nil; ptSpr1 = ptSpr1->objNext)
	{
		// Same layer?
		if (ptSpr1->sprLayer < nLayer)
		{
			continue;
		}
		if (ptSpr1->sprLayer > nLayer)
		{
			break;
		}
		
		// Collision flags?
		if ((ptSpr1->sprFlags & SF_RAMBO) == 0)
		{
			continue;
		}
		
		// Collides?
		if (x1 < ptSpr1->sprX2 && x2 > ptSpr1->sprX1 && y1 < ptSpr1->sprY2 && y2 > ptSpr1->sprY1)
		{
			if (ptSpr1 == ptSpr)
			{
				continue;
			}

			// The sprite must not be deleted
			int nGetColMaskFlag = GCMF_OBSTACLE;
			
			// Collides => test background flags
			if ((dwFlags & SCF_BACKGROUND) != 0)
			{
				// Platform? no collision if we check collisions with obstacles
				if ((ptSpr1->sprFlags & SF_PLATFORM) != 0)
				{
					if ((dwFlags & SCF_OBSTACLE) != 0)
					{
						continue;
					}
					// Platform and check collisions with platforms => get platform collision mask
					nGetColMaskFlag = GCMF_PLATFORM;
				}
			}
			
			// Box mode?
			if (cm == CM_BOX || (ptSpr1->sprFlags & SF_COLBOX) != 0)
			{
				if (list == nil)
				{
					list = [[CArrayList alloc] init];
				}
				[list add:ptSpr1->sprExtraInfo];
			}		
			// Fine collision mode
			else
			{
				// Calculate mask?
				if (pMask == nil)
				{
					pMask = [self getSpriteMask:ptSpr withImage:newImg andFlags:GCMF_OBSTACLE andAngle:newAngle andScaleX:newScaleX andScaleY:newScaleY];
					if (pMask==nil)
					{
						if (list == nil)
						{
							list = [[CArrayList alloc] init];
						}
						[list add:ptSpr1->sprExtraInfo];
						continue;
					}
				}
				// Test collision with second sprite
				pMask2 = [self getSpriteMask:ptSpr1 withImage:-1 andFlags:nGetColMaskFlag andAngle:ptSpr1->sprAngle andScaleX:ptSpr1->sprScaleX andScaleY:ptSpr1->sprScaleY];
				if (pMask2 != nil)
				{
					if ([pMask testMask:0 withX1:x1 andY1:y1 andMask:pMask2 andYBase:0 andX2:ptSpr1->sprX1 andY2:ptSpr1->sprY1])
					{
						if (list == nil)
						{
							list = [[CArrayList alloc] init];
						}
						[list add:ptSpr1->sprExtraInfo];
					}
				}
			}
		}
	}
	return list;
}

///////////////////////////////////////////////
//
// Get first sprite colliding with another one
//
-(CSprite*)spriteCol_TestSprite:(CSprite*)ptSpr withImage:(short)newImg andX:(int)newX andY:(int)newY andAngle:(float)newAngle andScaleX:(float)newScaleX andScaleY:(float)newScaleY andFoot:(int)subHt andFlags:(int)dwFlags
{
	int nLayer;
	
	if (ptSpr == nil)
	{
		return nil;
	}
	if ((ptSpr->sprFlags & SF_COLBOX) != 0)
	{
		colMode = CM_BOX;
	}
	
	nLayer = ptSpr->sprLayer;		// collisions always in the same layer
	
	// Flags to test
	if ((dwFlags & SCF_BACKGROUND) != 0)
	{
		// Test with background sprites => even layer
		nLayer &= ~1;
	}
	else
	{
		// Test with active sprites => collisions must be enabled
		if ((ptSpr->sprFlags & SF_RAMBO) == 0)
		{
			return nil;
		}
		
		// Test with active sprites => odd layer
		nLayer |= 1;
	}
	
	int x1 = newX;
	int y1 = newY;
	int x2 = x1;
	int y2 = y1;
	
	CMask* pMask = nil;
	
	// Si angle = 0 et coefs = 1.0f, ou si ownerdraw
	//		=> m�thode normale
	//
	// Si angle != 0 ou coefs != 1.0f
	//		=> appeler PrepareSpriteColMask pour calculer la bounding box et r�cup�rer le masque si d�j� calcul�
	//		=> puis r�cup�rer le masque avec CompleteSpriteColMask quand on en a besoin
	
	// Image sprite not stretched and not rotated, or owner draw sprite?
	// Get sprite mask
	if (ptSpr->sprFlags&SF_OWNERDRAW)
	{
		x2+=ptSpr->sprX2-ptSpr->sprX1;
		y2+=ptSpr->sprY2-ptSpr->sprY1;
	}
	else
	{		
		ImageInfo ifo=[bank getImageInfoEx:newImg withAngle:newAngle andScaleX:newScaleX andScaleY:newScaleY];
		if ((ptSpr->sprFlags & SF_NOHOTSPOT) == 0)
		{
			x1 -= ifo.xSpot;
			y1 -= ifo.ySpot;
		}
		x2 = x1 + ifo.width;
		y2 = y1 + ifo.height;
	}
	
	// Take subHt into account
	if (subHt != 0)
	{
		int nHeight = (y2 - y1);
		if (subHt > nHeight)
		{
			subHt = nHeight;
		}
		y1 += nHeight - subHt;
	}
	
	// Compare sprite box with current box
	CSprite* ptSpr1;
	for (ptSpr1 = firstSprite; ptSpr1 != nil; ptSpr1 = ptSpr1->objNext)
	{
		// Same layer?
		if (ptSpr1->sprLayer < nLayer)
		{
			continue;
		}
		if (ptSpr1->sprLayer > nLayer)
		{
			break;
		}
		
		// Collision flags?
		if ((ptSpr1->sprFlags & SF_RAMBO) == 0)
		{
			continue;
		}
		
		// Collides?
		if (x1 < ptSpr1->sprX2 && x2 > ptSpr1->sprX1 && y1 < ptSpr1->sprY2 && y2 > ptSpr1->sprY1)
		{
			if (ptSpr1 == ptSpr)
			{
				continue;
			}
			
			// The sprite must not be deleted
			if ((ptSpr1->sprFlags & SF_TOKILL) == 0)	// Securit�?
			{
				int nGetColMaskFlag = GCMF_OBSTACLE;
				
				// Collides => test background flags
				if ((dwFlags & SCF_BACKGROUND) != 0)
				{
					// Platform? no collision if we check collisions with obstacles
					if ((ptSpr1->sprFlags & SF_PLATFORM) != 0)
					{
						if ((dwFlags & SCF_OBSTACLE) != 0)
						{
							continue;
						}
						
						// Platform and check collisions with platforms => get platform collision mask
						nGetColMaskFlag = GCMF_PLATFORM;
					}
				}
				
				// Box mode?
				if (colMode == CM_BOX || (ptSpr1->sprFlags & SF_COLBOX) != 0)
				{
					return ptSpr1;
				}
				// Fine collision mode
				else
				{
					// Calculate mask?
					if (pMask == nil)
					{
						pMask = [self getSpriteMask:ptSpr withImage:newImg andFlags:GCMF_OBSTACLE andAngle:newAngle andScaleX:newScaleX andScaleY:newScaleY];
						if (pMask==nil)
						{							
							return ptSpr1;
						}
					}
					
					// Take subHt into account
					int yMaskBits = 0;
					int nMaskHeight = pMask->height;
					if (subHt != 0)
					{
						if (subHt > nMaskHeight)
						{
							subHt = nMaskHeight;
						}
						yMaskBits = nMaskHeight - subHt;
						nMaskHeight = subHt;
					}
					
					// Test collision with second sprite
					CMask* pMask2 = [self getSpriteMask:ptSpr1 withImage:-1 andFlags:nGetColMaskFlag andAngle:ptSpr1->sprAngle andScaleX:ptSpr1->sprScaleX andScaleY:ptSpr1->sprScaleY];
					if (pMask2 != nil)
					{
						if ([pMask testMask:yMaskBits withX1:x1 andY1:y1 andMask:pMask2 andYBase:0 andX2:ptSpr1->sprX1 andY2:ptSpr1->sprY1])
						{
							return ptSpr1;
						}
					}
				}
			}
		}
	}
	return nil;
}

//--------------------------------------------------------------//
// Test collision entre 1 rectangle et les sprites sauf 1	//
//--------------------------------------------------------------//
-(CSprite*)spriteCol_TestRect:(CSprite*)firstSpr withLayer:(int)nLayer andX:(int)xp andY:(int)yp andWidth:(int)wp andHeight:(int)hp andFlags:(int)dwFlags
{
	CSprite* ptSpr = firstSpr;
	if (ptSpr == nil)
	{
		ptSpr = firstSprite;
	}
	else
	{
		ptSpr = ptSpr->objNext;
	}
	
	BOOL bAllLayers = (nLayer == LAYER_ALL);
	BOOL bEvenNoCol = ((dwFlags & SCF_EVENNOCOL) != 0);
	short wAllLayerBit;
	if ((dwFlags & SCF_BACKGROUND) != 0)
	{
		wAllLayerBit = 0;
		if (nLayer != LAYER_ALL)
		{
			nLayer = nLayer * 2;
		}
	}
	else
	{
		wAllLayerBit = 1;
		if (nLayer != LAYER_ALL)
		{
			nLayer = nLayer * 2 + 1;
		}
	}
	
	// Recherche des autres sprites
	for (; ptSpr != nil; ptSpr = ptSpr->objNext)
	{
		if (!bAllLayers)	// todo: optimisation: faire une boucle diff�rente pour le mode all layers et une autre pour skipper les 1ers layers
		{
			if (ptSpr->sprLayer < nLayer)
			{
				continue;
			}
			if (ptSpr->sprLayer > nLayer)
			{
				break;
			}
		}
		else if ((ptSpr->sprLayer & 1) != wAllLayerBit)
		{
			continue;
		}
		
		// Can test collision with this one?
		if (bEvenNoCol || (ptSpr->sprFlags & SF_RAMBO) != 0)
		{
			if (xp <= ptSpr->sprX2 && xp + wp > ptSpr->sprX1 && yp <= ptSpr->sprY2 && yp + hp > ptSpr->sprY1)
			{
				if ((ptSpr->sprFlags & SF_TOKILL) == 0)	// should never happen
				{
					int nGetColMaskFlag = GCMF_OBSTACLE;
					
					// Collides => test background flags
					if ((dwFlags & SCF_BACKGROUND) != 0)
					{
						// Platform? no collision if we check collisions with obstacles
						if ((ptSpr->sprFlags & SF_PLATFORM) != 0)
						{
							if ((dwFlags & SCF_OBSTACLE) != 0)
							{
								continue;
							}
							// Platform and check collisions with platforms => get platform collision mask
							nGetColMaskFlag = GCMF_PLATFORM;
						}
					}
					
					// Box collision mode
					if (colMode == CM_BOX || (ptSpr->sprFlags & SF_COLBOX) != 0)
					{
						return ptSpr;
					}
					
					// Fine collision mode, test bit image
					CMask* pMask = [self getSpriteMask:ptSpr withImage:-1 andFlags:nGetColMaskFlag andAngle:ptSpr->sprAngle andScaleX:ptSpr->sprScaleX andScaleY:ptSpr->sprScaleY];
					if (pMask != nil)
					{
						if ([pMask testRect:0 withX:xp - ptSpr->sprX1 andY:yp - ptSpr->sprY1 andWidth:wp andHeight:hp])
						{
							return ptSpr;
						}
					}
				}
			}
		}
	}
	return nil;
}

@end
