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
// COBJECT : Classe de base d'un objet'
//
//----------------------------------------------------------------------------------
#import "CObject.h"
#import "CRun.h"
#import "CRCom.h"
#import "CRAni.h"
#import "CRMvt.h"
#import "CRVal.h"
#import "CRSpr.h"
#import "CObjInfo.h"
#import "CArrayList.h"
#import "CObjectCommon.h"
#import "CRect.h"
#import "CImage.h"
#import "CMask.h"
#import "CSprite.h"
#import "CImageBank.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CServices.h"
#import "CRCom.h"
#import "CMove.h"
#import "CEventProgram.h"
#import "CRunApp.h"
#import "CQualToOiList.h"
#import "ObjectSelection.h"
#import "CRunFrame.h"
#import "CLayer.h"

@implementation CObject

-(void)dealloc
{
	if(replacedColors != nil)
	{
		[replacedColors freeRelease];
		[replacedColors release];
		replacedColors = nil;
	}
	if (hoPrevNoRepeat!=nil)
	{
		[hoPrevNoRepeat release];
	}
	if (hoBaseNoRepeat!=nil)
	{
		[hoBaseNoRepeat release];
	}
	if (roc!=nil)
	{
		[roc release];
		roc = nil;
	}
	if (rom!=nil)
	{
		[rom release];
		rom = nil;
	}
	if (rov!=nil)
	{
		[rov release];
		rov = nil;
	}
	if (ros!=nil)
	{
		[ros release];
		ros = nil;
	}
	if (roa!=nil)
	{
		[roa release];
		roa = nil;
	}
	[super dealloc];
}
-(void)setScale:(float)fScaleX withScaleY:(float)fScaleY andFlag:(BOOL)bResample
{
	BOOL bOldResample = NO;
	if ((ros->rsFlags & RSFLAG_SCALE_RESAMPLE) != 0)
	{
		bOldResample = YES;
	}
	
	if (roc->rcScaleX != fScaleX || roc->rcScaleY != fScaleY || bOldResample != bResample)
	{
		roc->rcScaleX = fScaleX;
		roc->rcScaleY = fScaleY;
		ros->rsFlags &= ~RSFLAG_SCALE_RESAMPLE;
		if (bResample)
		{
			ros->rsFlags |= RSFLAG_SCALE_RESAMPLE;
		}
		roc->rcChanged = YES;
		
		ImageInfo ifo = [hoAdRunHeader->rhApp->imageBank getImageInfoEx:roc->rcImage withAngle:roc->rcAngle andScaleX:roc->rcScaleX andScaleY:roc->rcScaleY];
		hoImgWidth=ifo.width;
		hoImgHeight=ifo.height;
		hoImgXSpot=ifo.xSpot;
		hoImgYSpot=ifo.ySpot;
	}
}

-(void)setBoundingBoxFromWidth:(int)cx andHeight:(int)cy andXSpot:(int)hsx andYSpot:(int)hsy
{
	float nAngle = roc->rcAngle;
	float fScaleX = roc->rcScaleX;
	float fScaleY = roc->rcScaleY;
	
	// No rotation
	if ( nAngle == 0 )
	{
		// Stretch en X
		if ( fScaleX != 1.0f )
		{
			hsx = (int)(hsx * fScaleX);
			cx = (int)(cx * fScaleX);
		}
		
		// Stretch en Y
		if ( fScaleY != 1.0f )
		{
			hsy = (int)(hsy * fScaleY);
			cy = (int)(cy * fScaleY);
		}
	}
	
	// Rotation
	else
	{
		// Calculate dimensions
		if ( fScaleX != 1.0f )
		{
			hsx = (int)(hsx * fScaleX);
			cx = (int)(cx * fScaleX);
		}
		
		if ( fScaleY != 1.0f )
		{
			hsy = (int)(hsy * fScaleY);
			cy = (int)(cy * fScaleY);
		}
		
		// Rotate
		float alpha = nAngle * _PI / 180.0f;
		float cosa = cosf(alpha);
		float sina = sinf(alpha);
		
		int nx2, ny2;
		int	nx4, ny4;
		
		if ( sina >= 0.0f )
		{
			nx2 = (int)(cy * sina + 0.5f);		// (1.0f-sina));		// 1-sina est ici pour l'arrondi ??
			ny4 = -(int)(cx * sina + 0.5f);		// (1.0f-sina));
		}
		else
		{
			nx2 = (int)(cy * sina - 0.5f);		// (1.0f-sina));
			ny4 = -(int)(cx * sina - 0.5f);		// (1.0f-sina));
		}
		
		if ( cosa == 0.0f )
		{
			ny2 = 0;
			nx4 = 0;
		}
		else if ( cosa > 0 )
		{
			ny2 = (int)(cy * cosa + 0.5f);		// (1.0f-cosa));
			nx4 = (int)(cx * cosa + 0.5f);		// (1.0f-cosa));
		}
		else
		{
			ny2 = (int)(cy * cosa - 0.5f);		// (1.0f-cosa));
			nx4 = (int)(cx * cosa - 0.5f);		// (1.0f-cosa));
		}
		
		int nx3 = nx2 + nx4;
		int ny3 = ny2 + ny4;
		int nhsx = (int)(hsx * cosa + hsy * sina);
		int nhsy = (int)(hsy * cosa - hsx * sina);
		
		// Faire translation par rapport au hotspot
		int nx1 = 0;	// -nhsx;
		int ny1 = 0;	// -nhsy;
		
		// Calculer la nouvelle bounding box (? optimiser ?ventuellement)
		int x1 = MIN(nx1, nx2);
		x1 = MIN(x1, nx3);
		x1 = MIN(x1, nx4);
		
		int x2 = MAX(nx1, nx2);
		x2 = MAX(x2, nx3);
		x2 = MAX(x2, nx4);
		
		int y1 = MIN(ny1, ny2);
		y1 = MIN(y1, ny3);
		y1 = MIN(y1, ny4);
		
		int y2 = MAX(ny1, ny2);
		y2 = MAX(y2, ny3);
		y2 = MAX(y2, ny4);
		
		cx = x2 - x1;
		cy = y2 - y1;
		
		hsx = -(x1 - nhsx);
		hsy = -(y1 - nhsy);
	}			

	hoImgWidth = cx;
	hoImgHeight = cy;
	hoImgXSpot = hsx;
	hoImgYSpot = hsy;
}

-(int)fixedValue
{
	return (hoCreationId << 16) + (((int)hoNumber) & 0xFFFF);
}

-(int)getX
{
	CLayer* layer = hoAdRunHeader->rhFrame->layers[hoLayer];
	int windowX = hoAdRunHeader->rhWindowX;
	return hoX - windowX*layer->xCoef - layer->x + windowX;
}

-(int)getY
{
	CLayer* layer = hoAdRunHeader->rhFrame->layers[hoLayer];
	int windowY = hoAdRunHeader->rhWindowY;
	return hoY - windowY*layer->yCoef - layer->y + windowY;
}

-(Vec2i)getPosition
{
	CLayer* layer = hoAdRunHeader->rhFrame->layers[hoLayer];
	int windowX = hoAdRunHeader->rhWindowX;
	int windowY = hoAdRunHeader->rhWindowY;
	return Vec2i((int)(hoX - windowX*layer->xCoef - layer->x + windowX), (int)(hoY - windowY*layer->yCoef - layer->y + windowY));
}

-(int)getWidth
{
	return hoImgWidth;
}

-(int)getHeight
{
	return hoImgHeight;
}

-(void)setX:(int)x
{
	//Alter x-coordinate based on layer coefficient
	CLayer* layer = hoAdRunHeader->rhFrame->layers[hoLayer];
	int windowX = hoAdRunHeader->rhWindowX;
	x = (x-windowX + layer->x) + windowX*layer->xCoef;

	if (rom != nil)
	{
		[rom->rmMovement setXPosition:x];
	}
	else
	{
		if (hoX != x)
		{
			hoX = x;
			if (roc != nil)
			{
				roc->rcChanged = YES;
				roc->rcCheckCollides = YES;
			}
		}
	}
}

-(void)setY:(int)y
{
	//Alter y-coordinate based on layer coefficient
	CLayer* layer = hoAdRunHeader->rhFrame->layers[hoLayer];
	int windowY = hoAdRunHeader->rhWindowY;
	y = (y-windowY + layer->y) + windowY*layer->yCoef;

	if (rom != nil)
	{
		[rom->rmMovement setYPosition:y];
	}
	else
	{
		if (hoY != y)
		{
			hoY = y;
			if (roc != nil)
			{
				roc->rcChanged = YES;
				roc->rcCheckCollides = YES;
			}
		}
	}
}

-(void)setWidth:(int)width
{
	hoImgWidth = width;
	hoRect.right = hoRect.left + width;
}

-(void)setHeight:(int)height
{
	hoImgHeight = height;
	hoRect.bottom = hoRect.top + height;
}

-(void)generateEvent:(int)code withParam:(int)param
{
	if (hoAdRunHeader->rh2PauseCompteur == 0 && hoAdRunHeader->rhFrame->pTrans == nil)
	{
		int p0 = hoAdRunHeader->rhEvtProg->rhCurParam[0];
		hoAdRunHeader->rhEvtProg->rhCurParam[0] = param;
		
		code = (-(code + EVENTS_EXTBASE + 1) << 16);
		code |= (((int) hoType) & 0xFFFF);
		[hoAdRunHeader->rhEvtProg handle_Event:self withCode:code];
		
		hoAdRunHeader->rhEvtProg->rhCurParam[0] = p0;
	}
}

-(void)pushEvent:(int)code withParam:(int)param
{
	if (hoAdRunHeader->rh2PauseCompteur == 0)
	{
		code = (-(code + EVENTS_EXTBASE + 1) << 16);
		code |= (((int) hoType) & 0xFFFF);
		[hoAdRunHeader->rhEvtProg push_Event:1 withCode:code andParam:param andObject:self andOI:hoOi];
	}
}

-(void)pause
{
	[hoAdRunHeader pause];
}

-(void)resume
{
	[hoAdRunHeader resume];
}

-(void)redisplay
{
	[hoAdRunHeader ohRedrawLevel:YES];
}

-(void)redraw
{
	[self modif];
	if ((hoOEFlags & (OEFLAG_ANIMATIONS | OEFLAG_MOVEMENTS | OEFLAG_SPRITES)) != 0)
	{
		roc->rcChanged = YES;
	}
}

-(void)destroy
{
	[hoAdRunHeader destroy_Add:hoNumber];
}

-(void)setPosition:(int)x withY:(int)y
{
	//Alter coordinate based on layer coefficient
	CLayer* layer = hoAdRunHeader->rhFrame->layers[hoLayer];
	int windowX = hoAdRunHeader->rhWindowX;
	int windowY = hoAdRunHeader->rhWindowY;
	x = (x-windowX + layer->x) + windowX*layer->xCoef;
	y = (y-windowY + layer->y) + windowY*layer->yCoef;

	if (rom != nil)
	{
		[rom->rmMovement setXPosition:x];
		[rom->rmMovement setYPosition:y];
	}
	else
	{
		hoX = x;
		hoY = y;
		if (roc != nil)
		{
			roc->rcChanged = YES;
			roc->rcCheckCollides = YES;
		}
	}
}

-(void)initObject:(CObjectCommon*)ocPtr withCOB:(CCreateObjectInfo*)cob
{
}

-(void)runtimeIsReady
{
}

-(void)handle
{
}

-(void)modif
{
}

-(void)display
{
}

-(BOOL)kill:(BOOL)bFast
{
	return NO;
}

-(void)getZoneInfos
{
}

-(void)saveBack:(CBitmap*)bitmap
{
}

-(void)restoreBack:(CBitmap*)bitmap
{
}

-(void)killBack
{
}

-(void)draw:(CRenderer*)bitmap
{
}

-(CMask*)getCollisionMask:(int)flags
{
	return nil;
}

// IDrawable
-(void)spriteDraw:(CRenderer*)renderer withSprite:(CSprite*)spr andImageBank:(CImageBank*)bank andX:(int)x andY:(int)y
{
}
-(void)spriteKill:(CSprite*)spr
{
}

-(CMask*)spriteGetMask
{
	return nil;
}
-(NSString*)description
{
	return [NSString stringWithFormat:@"%@ [%i,%i]", hoOiList->oilName, hoX, hoY];
}

-(CObject*)getObjectFromFixed:(int)fixed
{
	int index = 0x0000FFFF & fixed;
	if (index >= hoAdRunHeader->rhMaxObjects)
		return nil;
	return hoAdRunHeader->rhObjectList[index];
}

-(BOOL)isOfType:(short)OiList
{
	return [hoAdRunHeader->objectSelection objectIsOfType:self type:OiList];
}

@end
