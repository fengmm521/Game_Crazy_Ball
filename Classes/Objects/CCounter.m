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
// CCounter : Objet compteur
//
//----------------------------------------------------------------------------------
#import "CCounter.h"
#import "CRun.h"
#import "CRSpr.h"
#import "CObjectCommon.h"
#import "CMask.h"
#import "CSprite.h"
#import "CImageBank.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CRunApp.h"
#import "CFontBank.h"
#import "CDefCounters.h"
#import "CDefCounter.h"
#import "CRect.h"
#import "CRCom.h"
#import "CSpriteGen.h"
#import "CImage.h"
#import "CFont.h"
#import "CServices.h"
#import "CBitmap.h"
#import "CRenderer.h"
#import "CTextSurface.h"

@implementation CCounter

-(void)dealloc
{
	[rsValue release];
	if(prevValue != nil)
		[prevValue release];
	if(textSurface != nil)
		[textSurface release];
	[cachedString release];
	[tmp release];
	[super dealloc];
}

-(void)initObject:(CObjectCommon*)ocPtr withCOB:(CCreateObjectInfo*)cob
{
	// Hidden counter?
	rsFlags = 0;			// adlo->loFlags; V2 pourquoi y avait ca en V1???
	rsFont = -1;
	rsColor1 = 0;
	rsColor2 = 0;
	hoImgWidth = hoImgHeight = 1;		// 0

	rsValue=[[CValue alloc] init];
	prevValue = nil;
	tmp = [[CValue alloc] init];
	
	cachedLength = 0;
	cachedString = @"";
	textSurface = nil;
	
	if (hoCommon->ocCounters == nil)
	{
		hoImgWidth = rsBoxCx = 1;
		hoImgHeight = rsBoxCy = 1;
	}
	else
	{
		CDefCounters* ctPtr = (CDefCounters*) hoCommon->ocCounters;
		hoImgWidth = rsBoxCx = ctPtr->odCx;
		hoImgHeight = rsBoxCy = ctPtr->odCy;
		displayFlags = ctPtr->odDisplayFlags;
		switch (ctPtr->odDisplayType)
		{
			case 5:	    // CTA_TEXT:
				rsColor1 = ctPtr->ocColor1;
				textSurface = [[CTextSurface alloc] initWidthWidth:hoImgWidth andHeight:hoImgHeight];
				break;
			case 2:	    // CTA_VBAR:
			case 3:	    // CTA_HBAR:
				rsColor1 = ctPtr->ocColor1;
				rsColor2 = ctPtr->ocColor2;
				break;
		}
	}
	
	CDefCounter* cPtr = (CDefCounter*) hoCommon->ocObject;
	rsMini = cPtr->ctMini;
	rsMaxi = cPtr->ctMaxi;
	rsMiniDouble = (double) rsMini;
	rsMaxiDouble = (double) rsMaxi;
	[rsValue forceInt:cPtr->ctInit];
	rsOldFrame = -1;
	[self modif];
}

-(void)handle
{
	[ros handle];
	if (roc->rcChanged)
	{
		roc->rcChanged = NO;
		[ros modifRoutine];
	}
}

-(void)modif
{
	[ros modifRoutine];
}

-(void)display
{
	[ros displayRoutine];
}

-(void)updateCachedData
{
	if ([rsValue getType] == TYPE_INT)
	{
		vInt = [rsValue getInt];
	}
	else
	{
		vDouble = [rsValue getDouble];
		vInt = (int) vDouble;
	}
	
	CDefCounters* adCta = (CDefCounters*) hoCommon->ocCounters;
	switch (adCta->odDisplayType)
	{
		case 1:
		case 5:
		{
			if(prevValue != nil && [rsValue equal:prevValue])
				break;
			if(prevValue == nil)
				prevValue = [[CValue alloc] initWithValue:rsValue];
			
			[cachedString release];
			if ([rsValue getType]==TYPE_INT)
				cachedString = [CServices intToString:vInt withFlags:displayFlags];
			else
				cachedString = [CServices doubleToString:vDouble withFlags:displayFlags];
			cachedLength = [cachedString length];
			break;
		}
		default:
			break;
	}
	[prevValue forceValue:rsValue];
}

-(void)getZoneInfos
{
	// Hidden counter?
	hoImgWidth = hoImgHeight = 1;		// 0
	if (hoCommon->ocCounters == nil)
		return;

	BOOL sameValue = [prevValue equal:rsValue];

	CDefCounters* adCta = (CDefCounters*) hoCommon->ocCounters;
	int nbl;
	short img;
	
	[self updateCachedData];
	
	switch (adCta->odDisplayType)
	{
		case 4:	    // CTA_ANIM:
		{
			nbl = adCta->nFrames;
			nbl -= 1;
			if (rsMaxi <= rsMini)
			{
				rsOldFrame = 0;
			}
			else
			{
				rsOldFrame = (short) ((int) ((int) (vInt - rsMini) * (int) nbl) / (int) (rsMaxi - rsMini));
                if (rsOldFrame>=adCta->nFrames)
                    rsOldFrame=(short)adCta->nFrames-1;
			}
			img = adCta->frames[rsOldFrame];
			CImage* ifo = [hoAdRunHeader->rhApp->imageBank getImageFromHandle:img];
            if (ifo!=nil)
            {
                rsBoxCx = hoImgWidth = ifo->width;
                rsBoxCy = hoImgHeight = ifo->height;
                hoImgXSpot = ifo->xSpot;
                hoImgYSpot = ifo->ySpot;
            }
			break;
		}	
		case 2:	    // CTA_VBAR:
		case 3:	    // CTA_HBAR:
		{
			nbl = rsBoxCx;
			if (adCta->odDisplayType == CTA_VBAR)
			{
				nbl = rsBoxCy;
			}
			if (rsMaxi <= rsMini)
			{
				rsOldFrame = 0;
			}
			else
			{
				rsOldFrame = (short) (((vInt - rsMini) * nbl) / (rsMaxi - rsMini));
			}
			if (adCta->odDisplayType == CTA_HBAR)
			{
				hoImgYSpot = 0;
				hoImgHeight = rsBoxCy;
				hoImgWidth = rsOldFrame;
				if ((adCta->odDisplayFlags & BARFLAG_INVERSE) != 0)
				{
					hoImgXSpot = rsOldFrame - rsBoxCx;
				}
				else
				{
					hoImgXSpot = 0;
				}
			}
			else
			{
				hoImgXSpot = 0;
				hoImgWidth = rsBoxCx;
				hoImgHeight = rsOldFrame;
				if ((adCta->odDisplayFlags & BARFLAG_INVERSE) != 0)
				{
					hoImgYSpot = rsOldFrame - rsBoxCy;
				}
				else
				{
					hoImgYSpot = 0;
				}
			}
			break;
		}	
		case 1:	    // CTA_DIGITS:
		{
			int i;
			int dx = 0;
			int dy = 0;
			CImage* ifo;
			for (i = 0; i < cachedLength; i++)
			{
				unichar c = [cachedString characterAtIndex:i];
				img = 0;
				switch (c)
				{
					case '-':
						img = adCta->frames[10];	// COUNTER_IMAGE_SIGN_NEG
						break;
					case '.':
						img = adCta->frames[12];	// COUNTER_IMAGE_POINT
						break;
					case '+':
						img = adCta->frames[11];	// COUNTER_IMAGE_SIGN_PLUS
						break;
					case 'e':
					case 'E':
						img = adCta->frames[13];	// COUNTER_IMAGE_EXP
						break;
					default:
						if (c >= '0' && c <= '9')
							img = adCta->frames[c - '0'];
						break;
				}
				ifo = [hoAdRunHeader->rhApp->imageBank getImageFromHandle:img];
				dx += ifo->width;
				dy = MAX(dy, ifo->height);
			}
			hoImgWidth = dx;
			hoImgHeight = dy;
			hoImgXSpot = dx;
			hoImgYSpot = dy;
			break;
		}	
		case 5:	    // CTA_TEXT:
		{
			// Rectangle
			CRect rc = CRectCreate(hoX, hoY, hoX + rsBoxCx, hoY + rsBoxCy);
			hoImgWidth = (short) rc.width();
			hoImgHeight = (short) rc.height();
			hoImgXSpot = hoImgYSpot = 0;

			if(!sameValue)
			{
				// Get font
				short nFont = rsFont;
				if (nFont == -1)
				{
					nFont = adCta->odFont;
				}
				CFont* font = [hoAdRunHeader->rhApp->fontBank getFontFromHandle:nFont];

				// Get exact size
				ht = 0;
				short dtflags = (short) (DT_RIGHT | DT_VCENTER | DT_SINGLELINE);
				int x2 = (int)rc.right;
				ht = [CServices drawText:nil withString:cachedString andFlags:(short)(dtflags|DT_CALCRECT) andRect:rc andColor:0 andFont:font andEffect:0 andEffectParam:0];
				rc.right = x2;	// keep zone width
			}
			if (ht != 0)
			{
				hoImgXSpot = hoImgWidth = (short)rc.width();
				if (hoImgHeight < rc.height())
					hoImgHeight = (short)rc.height();
				hoImgYSpot = hoImgHeight;
			}
			break;
		}
	}
}


-(void)draw:(CRenderer*)renderer
{
	// Dispatcher suivant l'objet et son ctaType
	// -----------------------------------------
	if (hoCommon->ocCounters == nil)
	{
		return;
	}
	CDefCounters* adCta = (CDefCounters*) hoCommon->ocCounters;
	int effect = ros->rsEffect;
	int effectParam = ros->rsEffectParam;
	
	[self updateCachedData];
	
	int cx;
	int cy;
	int x;
	int y;
	int color1, color2;
	color1 = rsColor1;
	color2 = 0;
	switch (adCta->odDisplayType)
	{
		case CTA_ANIM:
			[hoAdRunHeader->spriteGen pasteSpriteEffect:renderer withImage:adCta->frames[rsOldFrame] andX:(int)hoRect.left andY:(int)hoRect.top andFlags:0 andInkEffect:effect andInkEffectParam:effectParam];
			break;
			
		case CTA_VBAR:
		case CTA_HBAR:
		{
			int nbl = rsBoxCx;
			if (adCta->odDisplayType == CTA_VBAR)
				nbl = rsBoxCy;

			cx = (int)hoRect.width();
			cy = (int)hoRect.height();
			x = (int)hoRect.left;
			y = (int)hoRect.top;
			
			color2 = rsColor2;
			
			if (adCta->ocFillType == CTA_FILLTYPE_SOLID)
				color2 = color1;

			int dl;
			if ((adCta->odDisplayFlags & BARFLAG_INVERSE) != 0)
			{
				dl = color1;
				color1 = color2;
				color2 = dl;
			}

			dl = getR(color2) - getR(color1);
			int r = ((dl * (int) rsOldFrame) / nbl + getR(color1)) & 0xFF;
			dl = getG(color2) - getG(color1);
			int g = ((dl * (int) rsOldFrame) / nbl + getG(color1)) & 0xFF;
			dl = getB(color2) - getB(color1);
			int b = ((dl * (int) rsOldFrame) / nbl + getB(color1)) & 0xFF;
			color2 = getRGB(r, g, b);

			// Si gradient, calcul de la couleur destination
			if (adCta->ocFillType == CTA_FILLTYPE_GRADIENT)
			{
				//TODO: Make a generic horizontal flag based on displayType and ocGradientFlags

				//	VERTICAL
				if (adCta->odDisplayType == CTA_VBAR)	
				{
					GradientColor gradient = GradientColor(color1, color2, (hoCommon->ocCounters->ocGradientFlags == CTA_GRAD_HORIZONTAL));
					renderer->renderGradient(gradient, x, y, cx, cy, effect, effectParam);
				}
				else	// CTA_HBAR 
				{
					GradientColor gradient = GradientColor(color1, color2, (hoCommon->ocCounters->ocGradientFlags == CTA_GRAD_HORIZONTAL));
					renderer->renderGradient(gradient, x, y, cx, cy, effect, effectParam);
				}			
			}
			else if (adCta->ocFillType == CTA_FILLTYPE_SOLID)
			{
				renderer->renderGradient(GradientColor(color1), x, y, cx, cy, effect, effectParam);
			}
			break;
		}	
		case CTA_DIGITS:
		{
			x = (int)hoRect.left;
			y = (int)hoRect.top;
			
			int i;
			short img;
			for (i = 0; i < cachedLength; i++)
			{
				char c = [cachedString characterAtIndex:i];
				img = 0;	
				switch (c)
				{
					case '-':
						img = adCta->frames[10];	// COUNTER_IMAGE_SIGN_NEG
						break;
					case '.':
						img = adCta->frames[12];	// COUNTER_IMAGE_POINT
						break;
					case '+':
						img = adCta->frames[11];	// COUNTER_IMAGE_SIGN_PLUS
						break;
					case 'e':
					case 'E':
						img = adCta->frames[13];	// COUNTER_IMAGE_EXP
						break;
					default:
						if (c >= '0' && c <= '9')
							img = adCta->frames[c - '0'];
						break;
				}
				[hoAdRunHeader->spriteGen pasteSpriteEffect:renderer withImage:img andX:x andY:y andFlags:0 andInkEffect:effect andInkEffectParam:effectParam];
				CImage* ifo = [hoAdRunHeader->rhApp->imageBank getImageFromHandle:img];
				x += ifo->width;
			}
			break;
		}	
		case CTA_TEXT:
		{
			// Get font
			short nFont = rsFont;
			if (nFont == -1)
			{
				nFont = adCta->odFont;
			}
			CFont* font = [hoAdRunHeader->rhApp->fontBank getFontFromHandle:nFont];
			
			short dtflags = (short) (DT_RIGHT | DT_VCENTER | DT_SINGLELINE);
			if (hoRect.bottom - hoRect.top != 0)
			{
				[textSurface setText:cachedString withFlags:dtflags andColor:BGRtoARGB(rsColor1) andFont:font];
				[textSurface draw:renderer withX:hoRect.left andY:hoRect.top andEffect:effect andEffectParam:effectParam];
			}
			break;
		}
	}
}
				
-(CMask*)getCollisionMask:(int)flags
{
	return nil;
}


-(void)cpt_ToFloat:(CValue*)pValue
{
	if ([rsValue getType]==TYPE_INT)
	{
		if ([pValue getType]==TYPE_INT)
		{
			return;
		}
		[rsValue forceDouble:(double)[rsValue getInt]];
//		display();
		roc->rcChanged = YES;
	}
	else
	{
		[pValue convertToDouble];
	}
}

-(void)cpt_Change:(CValue*)pValue
{
	if ([rsValue getType] == TYPE_INT)
	{
		// Compteur entier
		int value = [pValue getInt];
		if (value < rsMini)
		{
			value = rsMini;
		}
		if (value > rsMaxi)
		{
			value = rsMaxi;
		}
		if (value != [rsValue getInt])
		{
			[rsValue forceInt:value];
			roc->rcChanged=YES;
			[self modif];
		}
	}
	else
	{
		// Compteur float
		double d = [pValue getDouble];
		if (d < rsMiniDouble)
		{
			d = rsMiniDouble;
		}
		if (d > rsMaxiDouble)
		{
			d = rsMaxiDouble;
		}
		if (d != [rsValue getDouble])
		{
			[rsValue forceDouble:d];
			roc->rcChanged=YES;
			[self modif];
		}
	}
}

-(void)cpt_Add:(CValue*)pValue
{
	[self cpt_ToFloat:pValue];
	[tmp forceValue:rsValue];
	[tmp add:pValue];
	[self cpt_Change:tmp];
}

-(void)cpt_Sub:(CValue*)pValue
{
	[self cpt_ToFloat:pValue];
	[tmp forceValue:rsValue];
	[tmp sub:pValue];
	[self cpt_Change:tmp];
}

-(void)cpt_SetMin:(CValue*)value
{
	rsMini = [value getInt];
	rsMiniDouble = [value getDouble];
	[tmp forceValue:rsValue];
	[self cpt_Change:tmp];
}

-(void)cpt_SetMax:(CValue*)value
{
	rsMaxi = [value getInt];
	rsMaxiDouble = [value getDouble];
	[tmp forceValue:rsValue];
	[self cpt_Change:tmp];
}

-(void)cpt_SetColor1:(int)rgb
{
	rsColor1 = rgb;
	[self display];
	roc->rcChanged = YES;
}

-(void)cpt_SetColor2:(int)rgb
{
	rsColor2 = rgb;
	[self display];
	roc->rcChanged = YES;
}

-(CValue*)cpt_GetValue
{
	return rsValue;
}

-(void)cpt_GetMin:(CValue*)value
{
	if (rsValue->type == TYPE_INT)
	{
		[value forceInt:rsMini];
	}
	else
	{
		[value forceDouble:rsMiniDouble];
	}
}

-(void)cpt_GetMax:(CValue*)value
{
	if (rsValue->type == TYPE_INT)
	{
		[value forceInt:rsMaxi];
	}
	else
	{
		[value forceDouble:rsMaxiDouble];
	}
}

-(int)cpt_GetColor1
{
	return rsColor1;
}

-(int)cpt_GetColor2
{
	return rsColor2;
}



-(CFontInfo*)getFont
{
	CDefCounters* adCta = (CDefCounters*) hoCommon->ocCounters;
	if (adCta->odDisplayType == 5)	// CTA_TEXT
	{
		short nFont = rsFont;
		if (nFont == -1)
		{
			nFont = adCta->odFont;
		}
		return [hoAdRunHeader->rhApp->fontBank getFontInfoFromHandle:nFont];
	}
	return nil;
}

-(void)setFont:(CFontInfo*)info withRect:(CRect)pRc
{
	CDefCounters* adCta = (CDefCounters*) hoCommon->ocCounters;
	if (adCta->odDisplayType == 5)	// CTA_TEXT
	{
		rsFont = [hoAdRunHeader->rhApp->fontBank addFont:info];
		if(!pRc.isNil())
		{
			hoImgWidth = rsBoxCx = (int)pRc.width();
			hoImgHeight = rsBoxCy = (int)pRc.height();
		}
		[self modif];
		roc->rcChanged = YES;
	}
}

-(int)getFontColor
{
	return rsColor1;
}

-(void)setFontColor:(int)rgb
{
	rsColor1 = rgb;
	[self modif];
	roc->rcChanged = YES;
}

// IDrawable
-(void)spriteDraw:(CRenderer*)renderer withSprite:(CSprite*)spr andImageBank:(CImageBank*)bank andX:(int)x andY:(int)y
{
	[self draw:renderer];
}

-(void)spriteKill:(CSprite*)spr
{
	[spr->sprExtraInfo release];
	spr->sprExtraInfo = nil;
}
-(CMask*)spriteGetMask
{
	return nil;
}

@end
