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
// CRSPR : Gestion des objets sprites
//
//----------------------------------------------------------------------------------
#import "CRSpr.h"
#import "CObject.h"
#import "CObjectCommon.h"
#import "CCreateObjectInfo.h"
#import "CObjInfo.h"
#import "CRun.h"
#import "COI.h"
#import "CMoveDef.h"
#import "CSpriteGen.h"
#import "CSprite.h"
#import "CLayer.h"
#import "CRunFrame.h"
#import "CRCom.h"
#import "CRMvt.h"
#import "CRect.h"
#import "CSprite.h"
#import "CRunApp.h"
#import "CTrans.h"
#import "CFadeSprite.h"
#import "CTransitionManager.h"

@implementation CRSpr

-(void)dealloc
{
	if (fadeSprite!=nil)
	{
		[fadeSprite release];
	}
	[super dealloc];
}
-(id)initWithHO:(CObject*)ho andOC:(CObjectCommon*)ocPtr andCOB:(CCreateObjectInfo*)cobPtr
{
	hoPtr=ho;
	spriteGen=ho->hoAdRunHeader->spriteGen;
	
	rsLayer = (short)cobPtr->cobLayer;					// Layer
	rsZOrder = cobPtr->cobZOrder;				// Creation z-order
	
	rsCreaFlags=SF_RAMBO;
	if ((hoPtr->hoLimitFlags&OILIMITFLAGS_QUICKCOL)==0)
		rsCreaFlags&=~SF_RAMBO;
	
	rsBackColor=0;							// Couleur de sauvegarde du fond
	if ( (hoPtr->hoOEFlags&OEFLAG_BACKSAVE)==0 || (hoPtr->hoOiList->oilOCFlags2&OCFLAGS2_DONTSAVEBKD)!=0)
	{
		hoPtr->hoOEFlags&=~OEFLAG_BACKSAVE;
		rsCreaFlags|=SF_NOSAVE;				//; pas de sauvegarde
		if ((hoPtr->hoOiList->oilOCFlags2&OCFLAGS2_SOLIDBKD)!=0)
		{
			rsBackColor=hoPtr->hoOiList->oilBackColor;
			rsCreaFlags|=SF_FILLBACK;		//; Effacement avec couleur pleine
		}
	}
	if ((hoPtr->hoOEFlags&OEFLAG_INTERNALBACKSAVE)!=0)
		rsCreaFlags|=SF_OWNERSAVE;
	if ((hoPtr->hoOiList->oilOCFlags2&OCFLAGS2_COLBOX)!=0)		//; Collision en mode box?
		rsCreaFlags|=SF_COLBOX;
	
	if ((cobPtr->cobFlags&COF_HIDDEN)!=0)				//; Faut-il le cacher a l'ouverture?
	{
		rsCreaFlags|=SF_HIDDEN;
		rsFlags=RSFLAG_HIDDEN;
		if (hoPtr->hoType==OBJ_TEXT)
			hoPtr->hoFlags|=HOF_NOCOLLISION;		//; Cas particulier pour cette merde d'objet texte
	}
	else
	{
		rsFlags|=RSFLAG_VISIBLE;
	}
	rsEffect=hoPtr->hoOiList->oilInkEffect;
	rsEffectParam=hoPtr->hoOiList->oilEffectParam;	//; Le parametre de l'ink effect
	
	//	cmp	   	[esi].RunObject.roc.rcNMovement,MVTYPE_STATIC*4	
	if (hoPtr->roc->rcMovementType==MVTYPE_STATIC)		// Sprite inactif, si pas de mouvement
	{
		rsFlags|=RSFLAG_INACTIVE;
		rsCreaFlags|=SF_INACTIF;
	}
	
	rsFadeCreaFlags=(short)rsCreaFlags;		//; Correction bug collision absentes quand fadein + fade sprite	

	return self;
}
-(void)init2
{
	if ([self createFadeSprite:NO])
	{
		return;
	}
	[self createSprite:nil];
}

// Routine de display 
// ------------------
-(void)displayRoutine
{
	switch(rsSpriteType)
	{
		case 0:         // SPRTYPE_TRUESPRITE
			if (hoPtr->roc->rcSprite!=nil)
			{
				[spriteGen modifSpriteEx:hoPtr->roc->rcSprite withX:hoPtr->hoX andY:hoPtr->hoY andImage:hoPtr->roc->rcImage andScaleX:hoPtr->roc->rcScaleX andScaleY:hoPtr->roc->rcScaleY andScaleFlag:(hoPtr->ros->rsFlags&RSFLAG_SCALE_RESAMPLE)!=0 andAngle:hoPtr->roc->rcAngle andRotateFlag:(hoPtr->ros->rsFlags&RSFLAG_ROTATE_ANTIA)!=0];			
			}
			break;
		case 1:         // SPRTYPE_OWNERDRAW
			if (hoPtr->roc->rcSprite!=nil)
			{
				[spriteGen activeSprite:hoPtr->roc->rcSprite withFlags:AS_REDRAW andRect:CRectNil];
			}
			break;
		case 2:         // SPRTYPE_QUICKDISPLAY
//			[hoPtr->hoAdRunHeader display_OwnerQuickDisplay:hoPtr];
			break;
	}
}

// -------------------------------------------------------------------
// GESTION D'UN OBJET SPRITE
// -------------------------------------------------------------------
-(void)handle
{
	CRun* rhPtr=hoPtr->hoAdRunHeader;
	CLayer* layer = rhPtr->rhFrame->layers[hoPtr->hoLayer];
	CRect handleRect	= layer->handleRect;
	CRect objRect		= CRectCreateAtPosition(hoPtr->hoX-hoPtr->hoImgXSpot, hoPtr->hoY-hoPtr->hoImgYSpot, hoPtr->hoImgWidth, hoPtr->hoImgHeight);

	// En marche ou pas?
	// -----------------
	if ((rsFlags&RSFLAG_SLEEPING)==0)
	{
		// Verification de fin de fade in/out
		// ----------------------------------
		if([self checkEndFadeIn] || [self checkEndFadeOut])
			return;
		
		// Gestion du flash
		// ----------------
		if (rsFlash!=0)
		{
			rsFlashCpt-=rhPtr->rhTimerDelta;
			if (rsFlashCpt<0)
			{
				rsFlashCpt=rsFlash;
				if ((rsFlags&RSFLAG_VISIBLE)==0)
				{
					rsFlags|=RSFLAG_VISIBLE;
					[self obShow];
				}
				else
				{
					rsFlags&=~RSFLAG_VISIBLE;
					[self obHide];
				}
			}
		}
		
		// Appel de la routine de mouvement	
		// --------------------------------
		if (hoPtr->rom!=nil)
			[hoPtr->rom move];
		
		// Verifie que l'objet n'est pas trop en dehors du terrain
		// -------------------------------------------------------
		if (hoPtr->roc->rcPlayer!=0) 
			return;			//; Seulement les objets de l'ordinateur
		if ((hoPtr->hoOEFlags&OEFLAG_NEVERSLEEP)!=0) 
			return;

		// Faire disparaitre le sprite?
		if(CRectIntersects(objRect, handleRect))
			return;

		// Detruit/Faire disparaitre l'objet
		// ---------------------------------
		if(CRectIntersects(objRect, layer->killRect))
		{
			// Simplement faire disparaitre
			rsFlags|=RSFLAG_SLEEPING;
			if (hoPtr->roc->rcSprite!=nil)
			{
				// Save Z-order value before deleting sprite
				rsZOrder = hoPtr->roc->rcSprite->sprZOrder;
				
				[spriteGen delSpriteFast:hoPtr->roc->rcSprite];
				hoPtr->roc->rcSprite=nil;
				return;
			}
			else
			{
				[rhPtr remove_QuickDisplay:hoPtr];
				return;
			}
		}
		else
		{
			// Destroy the object if NEVERKILL isn't set
			if ((hoPtr->hoOEFlags&OEFLAG_NEVERKILL)==0)
			{
				[rhPtr destroy_Add:hoPtr->hoNumber];
			}
			return;
		}
	}
	else 
	{
		// Un objet qui dort, le faire reapparaitre ?
		// ------------------------------------------
		if (CRectIntersects(objRect, handleRect))
		{
			rsFlags&=~RSFLAG_SLEEPING;
			[self init2];
		}
	}
}

// Routine de modif
// ----------------
-(void)modifRoutine
{
	switch(rsSpriteType)
	{
		case 0:         // SPRTYPE_TRUESPRITE
			if (hoPtr->roc->rcSprite!=nil)
			{
				[spriteGen modifSpriteEx:hoPtr->roc->rcSprite withX:hoPtr->hoX andY:hoPtr->hoY andImage:hoPtr->roc->rcImage andScaleX:hoPtr->roc->rcScaleX andScaleY:hoPtr->roc->rcScaleY andScaleFlag:(hoPtr->ros->rsFlags&RSFLAG_SCALE_RESAMPLE)!=0 andAngle:hoPtr->roc->rcAngle andRotateFlag:(hoPtr->ros->rsFlags&RSFLAG_ROTATE_ANTIA)!=0];
			}
			break;
		case 1:         // SPRTYPE_OWNERDRAW
			[self objGetZoneInfos];
			if (hoPtr->roc->rcSprite!=nil)
			{
				[spriteGen modifOwnerDrawSprite:hoPtr->roc->rcSprite withX1:(int)hoPtr->hoRect.left andY1:(int)hoPtr->hoRect.top andX2:(int)hoPtr->hoRect.right andY2:(int)hoPtr->hoRect.bottom];
			}
			break;
		case 2:         // SPRTYPE_QUICKDISPLAY
			[self objGetZoneInfos];
			break;
	}
}

// CREATION D'UN VRAI SPRITE SIMPLE
// --------------------------------
-(BOOL)createSprite:(CSprite*)pSprBefore
{
	// Un vrai sprite
	// --------------
	if ((hoPtr->hoOEFlags&OEFLAG_ANIMATIONS)!=0)
	{
		CSprite* pSpr=[spriteGen addSprite:hoPtr->hoX withY:hoPtr->hoY andImage:hoPtr->roc->rcImage andLayer:rsLayer andZOrder:rsZOrder andBackColor:rsBackColor andFlags:rsCreaFlags andObject:hoPtr];
		
		if (pSpr!=nil)
		{
			hoPtr->roc->rcSprite=pSpr;						//; Stocke le Sprite
			hoPtr->hoFlags|=HOF_REALSPRITE;
			[spriteGen modifSpriteEffect:pSpr withInkEffect:rsEffect andInkEffectParam:rsEffectParam];
			
			if ( pSprBefore != nil )
				[spriteGen moveSpriteBefore:pSpr withSprite:pSprBefore];
			
			rsSpriteType=SPRTYPE_TRUESPRITE;
		}
		return YES;
	}
	// Un faux sprite, gere en owner-draw
	// ----------------------------------
	if ((hoPtr->hoOEFlags&OEFLAG_QUICKDISPLAY)==0)
	{
		rsCreaFlags|=SF_OWNERDRAW|SF_INACTIF;
		if ( (rsCreaFlags & SF_COLBOX) == 0 )
			rsCreaFlags |= SF_OWNERCOLMASK;
		rsFlags|=RSFLAG_INACTIVE;
		hoPtr->hoFlags|=HOF_OWNERDRAW;
		hoPtr->hoRect.left=hoPtr->hoX - hoPtr->hoImgXSpot;
		hoPtr->hoRect.top=hoPtr->hoY - hoPtr->hoImgYSpot;
		hoPtr->hoRect.right=hoPtr->hoRect.left + hoPtr->hoImgWidth;
		hoPtr->hoRect.bottom=hoPtr->hoRect.top + hoPtr->hoImgHeight;
		
		CSprite* spr=[spriteGen addOwnerDrawSprite:(int)hoPtr->hoRect.left withY1:(int)hoPtr->hoRect.top andX2:(int)hoPtr->hoRect.right andY2:(int)hoPtr->hoRect.bottom andLayer:rsLayer andZOrder:rsZOrder andBackColor:rsBackColor andFlags:rsCreaFlags andObject:hoPtr andDrawable:hoPtr];
		if (spr==nil) 
			return NO;
		hoPtr->roc->rcSprite=spr;
		if ( pSprBefore != nil )
			[spriteGen moveSpriteBefore:spr withSprite:pSprBefore];
		
		rsSpriteType=SPRTYPE_OWNERDRAW;
		return YES;
	}
	else
	{
		[hoPtr->hoAdRunHeader add_QuickDisplay:hoPtr];
		rsSpriteType=SPRTYPE_QUICKDISPLAY;

		return YES;
	}
}

// Creation d'un sprite fadein/out
// -------------------------------
-(BOOL)createFadeSprite:(BOOL)bFadeOut
{
	hoPtr->hoFlags&=~(HOF_FADEIN|HOF_FADEOUT);
	
	// Un fade?
	if (bFadeOut==NO)
	{
		if (hoPtr->hoCommon->ocFadeIn==nil)
		{
			return NO;
		}
		hoPtr->hoFlags|=HOF_FADEIN;
	}
	else
	{
		if (hoPtr->hoCommon->ocFadeOut==nil)
		{
			return NO;
		}
		hoPtr->hoFlags|=HOF_FADEOUT;
	}

	// Demarre le fade
	rsTrans = [[hoPtr->hoAdRunHeader->rhApp getTransitionManager] startObjectFade:hoPtr withFlag:bFadeOut];
	if (rsTrans == nil)
	{
		hoPtr->hoFlags &= ~(HOF_FADEIN | HOF_FADEOUT);
		return NO;
	}
	
	// Detruit un ancien sprite deja la!
	CSprite* pOldSprite = hoPtr->roc->rcSprite;
	if (pOldSprite != nil)
	{
		// Save Z-order value before deleting sprite
		rsZOrder = pOldSprite->sprZOrder;
	}
	
	// Cree un nouveau ownerdraw
	//	rsFadeCreaFlags=rsCreaFlags;				//; Correction bug collision absentes quand fadein + fade sprite
	rsCreaFlags &= ~(SF_RAMBO | SF_INACTIF);
	rsCreaFlags |= (SF_OWNERDRAW | SF_OWNERSAVE);
	hoPtr->hoRect.left = hoPtr->hoX - hoPtr->hoImgXSpot;
	hoPtr->hoRect.top = hoPtr->hoY - hoPtr->hoImgYSpot;
	hoPtr->hoRect.right = hoPtr->hoRect.left + hoPtr->hoImgWidth;
	hoPtr->hoRect.bottom = hoPtr->hoRect.top + hoPtr->hoImgHeight;
	
	fadeSprite = [[CFadeSprite alloc] initWithTrans:rsTrans];
	CSprite* pSpr = [spriteGen addOwnerDrawSprite:(int)hoPtr->hoRect.left withY1:(int)hoPtr->hoRect.top andX2:(int)hoPtr->hoRect.right andY2:(int)hoPtr->hoRect.bottom andLayer:rsLayer andZOrder:rsZOrder andBackColor:rsBackColor andFlags:rsCreaFlags andObject:hoPtr andDrawable:fadeSprite];
	if (pSpr != nil)
	{
		hoPtr->roc->rcSprite = pSpr;							//; Stocke le Sprite
		pSpr->sprFlags |= SF_FADE;							//; Marque comme sprite en fade...
		hoPtr->hoFlags |= HOF_REALSPRITE;
		[spriteGen modifSpriteEffect:pSpr withInkEffect:rsEffect andInkEffectParam:rsEffectParam];
		
		// Move sprite
		if (pOldSprite != nil)
		{
			[spriteGen moveSpriteBefore:pSpr withSprite:pOldSprite];
            [spriteGen delSpriteFast:pOldSprite];
//	FRA		if (hoPtr->hoType>=32)
//			{
//				CExtension* ext=(CExtension*)hoPtr;
//				[ext->ext pauseRunObject];
//			}
		}
		rsSpriteType = SPRTYPE_OWNERDRAW;
		rsFlags &= ~RSFLAG_SLEEPING;		//Fix for transition crash when sprite gets inactive
		return YES;
	}
	hoPtr->hoFlags &= ~(HOF_FADEIN | HOF_FADEOUT);
	return NO;	
}

// DESTRUCTION D'UN SPRITE
// -----------------------
-(BOOL)kill:(BOOL)fast
{
	BOOL bOwnerDrawRelease=NO;
	if (hoPtr->roc->rcSprite!=nil)							//; Est-il active?
	{
		// Save Z-order value before deleting sprite
		rsZOrder = hoPtr->roc->rcSprite->sprZOrder;
		
		// Un sprite normal
		if (fast==NO)								//; Mode fast?
		{
			bOwnerDrawRelease=(hoPtr->roc->rcSprite->sprFlags&SF_OWNERDRAW)!=0;
			[spriteGen delSprite:hoPtr->roc->rcSprite];
		}
		else
		{
			[spriteGen delSpriteFast:hoPtr->roc->rcSprite];
		}
		hoPtr->roc->rcSprite=nil;
	}				
	return bOwnerDrawRelease;
}

// RECREE UN SPRITE EN FIN DE PREMIERE BOUCLE FADE-IN   
// --------------------------------------------------
-(void)reInit_Spr:(BOOL)fast
{
	if (hoPtr->roc->rcSprite!=nil)
	{
		[self init2];
	}
	[self displayRoutine];
}

// Verification fin du fade in
// ---------------------------
-(BOOL)checkEndFadeIn
{
	// En Fade?
	// ~~~~~~~~
	if ((hoPtr->hoFlags & HOF_FADEIN) != 0)
	{
		// Sortie du fade in?
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~
		if ([rsTrans isCompleted])
		{
			CSprite* pOldSpr = hoPtr->roc->rcSprite;
			hoPtr->hoFlags &= ~HOF_FADEIN;
			
			if (pOldSpr != nil)
				rsZOrder = pOldSpr->sprZOrder;
			rsCreaFlags = rsFadeCreaFlags;
			[self createSprite:pOldSpr];
			if (pOldSpr != nil)
            {
                [fadeSprite release];
                fadeSprite = nil;
                [spriteGen delSpriteFast:pOldSpr];
            }

/*FRA		// Si objet d'extension, remet en CONTINUE
			if (hoPtr->hoType >= 32)
			{
				CExtension ext = (CExtension) hoPtr;
				ext.ext.continueRunObject();
			}
*/		}
		else
		{
			hoPtr->roc->rcChanged = YES;
		}
		return YES;
	}
	return NO;
}

-(BOOL)checkEndFadeOut
{
	if ((hoPtr->hoFlags & HOF_FADEOUT) != 0)						// Un fade?
	{
		if ([rsTrans isCompleted])
		{
			[hoPtr->hoAdRunHeader destroy_Add:hoPtr->hoNumber];
		}
		return YES;
	}
	return NO;
}

// Demande la taille du rectangle
// ------------------------------
-(void)objGetZoneInfos
{
	[hoPtr getZoneInfos];
	hoPtr->hoRect.left = hoPtr->hoX - hoPtr->hoImgXSpot;			// Calcul des coordonnees
	hoPtr->hoRect.right = hoPtr->hoRect.left + hoPtr->hoImgWidth;
	hoPtr->hoRect.top = hoPtr->hoY - hoPtr->hoImgYSpot;
	hoPtr->hoRect.bottom = hoPtr->hoRect.top + hoPtr->hoImgHeight;
}

// CACHE/MONTRE UN SPRITE
// ----------------------
-(void)obHide
{
	if ((rsFlags&RSFLAG_HIDDEN)==0)
	{
		rsFlags|=RSFLAG_HIDDEN;
		rsCreaFlags|=SF_HIDDEN;
		rsFadeCreaFlags|=SF_HIDDEN;
		hoPtr->roc->rcChanged=YES;
		if (hoPtr->roc->rcSprite!=nil)
		{
			[spriteGen showSprite:hoPtr->roc->rcSprite withFlag:NO];
		}
	}
}
-(void)obShow
{
	if ((rsFlags&RSFLAG_HIDDEN)!=0)
	{
		// Test if layer shown
		CLayer* pLayer = hoPtr->hoAdRunHeader->rhFrame->layers[hoPtr->hoLayer];
		if ( (pLayer->dwOptions & (FLOPT_TOHIDE|FLOPT_VISIBLE)) == FLOPT_VISIBLE )
		{
			rsCreaFlags&=~SF_HIDDEN;
			rsFadeCreaFlags&=~SF_HIDDEN;
			rsFlags&=~RSFLAG_HIDDEN;
			hoPtr->hoFlags&=~HOF_NOCOLLISION;				//; Des collisions de nouveau (objet texte)
			hoPtr->roc->rcChanged=YES;
			if (hoPtr->roc->rcSprite!=nil)
			{
				[spriteGen showSprite:hoPtr->roc->rcSprite withFlag:YES];
			}
		}
	}	
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"CRSpr: %@ - %@", hoPtr, fadeSprite];
}


@end
