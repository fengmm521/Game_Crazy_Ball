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
// CSPRITE : Un sprite
//
//----------------------------------------------------------------------------------
#import "CSprite.h"
#import "CObject.h"
#import "CMask.h"
#import "CArrayList.h"
#import "CImageBank.h"
#import "CRect.h"
#import "CImage.h"
#import "CServices.h"
#import "CBitmap.h"
#import "CRenderer.h"
#import "CRCom.h"

@implementation CSprite

-(id)initWithBank:(CImageBank*)b 
{
	bank=b;

	objPrev = objNext = nil;
	sprColMask = sprTempColMask = nil;
	sprSf = sprTempSf = nil;
	sprRout = nil;
	sprExtraInfo = nil;
    
    sprFlags = sprZOrder = 0;
    sprLayer = sprAngle = 0;
    sprX = sprY = sprX1 = sprY1 = sprX2 = sprY2 = 0;
	sprXnew = sprYnew = sprX1new = sprY1new = sprX2new = sprY2new = sprX1z = sprY1z = sprX2z = sprY2z = 0;
	sprScaleX = sprScaleY = 1;
	
	sprTempImg = sprTempAngle = 0;
    sprTempScaleX = sprTempScaleY = 0;
	
    sprImg = sprImgNew = 0;
	sprEffect = sprBackColor = 0;
	sprEffectParam = 1;
	
	return self;
}

-(void)dealloc
{
	if (sprColMask!=nil)
	{
		[sprColMask release];
	}
	if (sprTempColMask!=nil)
	{
		[sprTempColMask release];
	}
	if (sprSf!=nil)
	{
		[sprSf release];
	}
	if (sprTempSf!=nil)
	{
		[sprTempSf release];
	}		
	[super dealloc];
}

-(int)getSpriteLayer 
{
	return sprLayer/2;
}

-(int)getSpriteFlags
{
	return sprFlags;
}

-(int)setSpriteFlags:(int)dwNewFlags
{
	int dwOldFlags;
	dwOldFlags = sprFlags;
	sprFlags = dwNewFlags;
	return dwOldFlags;
}

-(int)setSpriteColFlag:(int)colMode
{
	int om;
	om = (sprFlags & SF_RAMBO);
	sprFlags = (sprFlags & ~SF_RAMBO) | colMode;
	return om;
}

-(void)killSpriteZone
{
}

-(float)getSpriteScaleX
{
	return sprScaleX;
}

-(float)getSpriteScaleY
{
	return sprScaleY;
}

-(BOOL)getSpriteScaleResample
{
	return (sprFlags & SF_SCALE_RESAMPLE) != 0;
}

-(float)getSpriteAngle
{
	return sprAngle;
}

-(BOOL)getSpriteAngleAntiA
{
	return ((sprFlags & SF_ROTATE_ANTIA) != 0);
}

-(CRect)getSpriteRect 
{
	rect.left = sprX1new;
	rect.right = sprX2new;
	rect.top = sprY1new;
	rect.bottom = sprY2new;
	return rect;
}

-(void)draw:(CRenderer*)renderer
{
	int hsx=0;
	int hsy=0;
	BOOL resample = (sprFlags & (SF_SCALE_RESAMPLE|SF_ROTATE_ANTIA)) != 0;
		
	CImage* toDraw = sprSf;
	if (sprSf == nil)
	    toDraw=[bank getImageFromHandle:sprImg];
	
	if(toDraw != nil)
	{
		BOOL hasHotspot = (sprFlags&SF_NOHOTSPOT)==0;
		if (hasHotspot)
		{
			hsx=toDraw->xSpot;
			hsy=toDraw->ySpot;
		}
		[toDraw setResampling:resample];
		renderer->renderScaledRotatedImage(toDraw, sprAngle, sprScaleX, sprScaleY, hsx, hsy, sprX, sprY, toDraw->originalWidth, toDraw->originalHeight, sprEffect, sprEffectParam);
	}
}

-(void)updateBoundingBox
{
	// Get image size & hot spot
	CImage* ptei=[bank getImageFromHandle:sprImgNew];
	if ( ptei==nil )
	{
	    sprX1new = sprXnew;
	    sprX2new = sprXnew+1;
	    sprY1new = sprYnew;
	    sprY2new = sprYnew+1;
	    return;
	}
	
	int cx = ptei->width;
	int cy = ptei->height;
	int hsx = 0;
	int hsy = 0;
	if ( (sprFlags & SF_NOHOTSPOT) == 0 )
	{
	    hsy = ptei->ySpot;
	    hsx = ptei->xSpot;
	}
	
	// No rotation
	if ( sprAngle == 0 )
	{
	    // Pas de stretch en X
	    if ( sprScaleX == 1.0f )
	    {
			sprX1new = sprXnew - hsx;
			sprX2new = sprX1new + cx;
	    }
		
	    // Stretch en X
	    else
	    {
			sprX1new = sprXnew - (int)(hsx * sprScaleX+0.5f);
			sprX2new = sprX1new + (int)(cx * sprScaleX+0.5f);
	    }
		
	    // Pas de stretch en Y
	    if ( sprScaleY == 1.0f )
	    {
			sprY1new = sprYnew - hsy;
			sprY2new = sprY1new + cy;
	    }
		
	    // Stretch en Y
	    else
	    {
			sprY1new = sprYnew - (int)(hsy * sprScaleY+0.5f);
			sprY2new = sprY1new + (int)(cy * sprScaleY+0.5f);
	    }
	}
	
	// Rotation
	else
	{
	    // Calculate dimensions
	    //int x1, y1, x2, y2;
		
	    if ( sprScaleX != 1.0f )
	    {
			hsx = (int)(hsx * sprScaleX);
			cx = (int)(cx * sprScaleX);
	    }
	    //x1 = ptSpr.sprXnew - hsx;
	    //x2 = ptSpr.sprX1new + cx;
		
	    if ( sprScaleY != 1.0f )
	    {
			hsy = (int)(hsy * sprScaleY+0.5f);
			cy = (int)(cy * sprScaleY+0.5f);
	    }
	    //y1 = ptSpr.sprYnew - hsy;
	    //y2 = ptSpr.sprY1new + cy;
		
	    // Rotate
	    int nhsx;
	    int nhsy;
		
	    int nx1;
	    int ny1;
		
	    int nx2;
	    int ny2;
		
	    int	nx4;
	    int	ny4;
		
	    cx--;	// new
	    cy--;	// new
		
	    if ( sprAngle == 90 )
	    {
			nx2 = cy;
			ny4 = -cx;
			
			ny2 = 0;
			nx4 = 0;
			
			nhsx = hsy;
			nhsy = -hsx;
	    }
	    else if ( sprAngle == 180 )
	    {
			nx2 = 0;
			ny4 = 0;
			
			ny2 = -cy;
			nx4 = -cx;
			
			nhsx = -hsx;
			nhsy = -hsy;
	    }
	    else if ( sprAngle == 270 )
	    {
			nx2 = -cy;
			ny4 = cx;
			
			ny2 = 0;
			nx4 = 0;
			
			nhsx = -hsy;
			nhsy = hsx;
	    }
	    else
	    {
			float alpha = sprAngle * 3.141592653589793f/180.0f;
			float cosa = cosf(alpha);
			float sina = sinf(alpha);
			
			nhsx = (int)(hsx * cosa + hsy * sina);
			nhsy = (int)(hsy * cosa - hsx * sina);
			/*
			 if ( sina >= 0.0f )
			 {
			 nx2 = (int)(cy * sina + 0.5f);		// (1.0f-sina));		// 1-sina est ici pour l'arrondi
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
			 else if ( cosa > 0.0f )
			 {
			 ny2 = (int)(cy * cosa + 0.5f);		// (1.0f-cosa));
			 nx4 = (int)(cx * cosa + 0.5f);		// (1.0f-cosa));
			 }
			 else
			 {
			 ny2 = (int)(cy * cosa - 0.5f);		// (1.0f-cosa));
			 nx4 = (int)(cx * cosa - 0.5f);		// (1.0f-cosa));
			 } */
			
			nx2 = (int)(cy * sina+0.5f);	// new
			ny4 = -(int)(cx * sina+0.5f);	// new
			ny2 = (int)(cy * cosa+0.5f);	// new
			nx4 = (int)(cx * cosa+0.5f);	// new
	    }
		
	    int nx3 = nx2 + nx4;
	    int ny3 = ny2 + ny4;
		
	    // Faire translation par rapport au hotspot
	    nx1 = sprXnew - nhsx;
	    ny1 = sprYnew - nhsy;
	    nx2 += sprXnew - nhsx;
	    ny2 += sprYnew - nhsy;
	    nx3 += sprXnew - nhsx;
	    ny3 += sprYnew - nhsy;
	    nx4 += sprXnew - nhsx;
	    ny4 += sprYnew - nhsy;
		
	    // Calculer la nouvelle bounding box (� optimiser �ventuellement)
	    sprX1new = MIN(nx1,nx2);
	    sprX1new = MIN(sprX1new,nx3);
	    sprX1new = MIN(sprX1new,nx4);
		
	    sprX2new = MAX(nx1,nx2);
	    sprX2new = MAX(sprX2new,nx3);
	    sprX2new = MAX(sprX2new,nx4);
		
	    sprX2new++;	// new
		
	    sprY1new = MIN(ny1,ny2);
	    sprY1new = MIN(sprY1new,ny3);
	    sprY1new = MIN(sprY1new,ny4);
		
	    sprY2new = MAX(ny1,ny2);
	    sprY2new = MAX(sprY2new,ny3);
	    sprY2new = MAX(sprY2new,ny4);
		
	    sprY2new++; // new
	}
}

-(void)calcBoundingBox:(short)newImg withX:(int)newX andY:(int)newY andAngle:(float)newAngle andScaleX:(float)newScaleX andScaleY:(float)newScaleY andRect:(CRect)prc
{
	CImage* ptei;
	
	// Empty rect
	prc.left = prc.top = prc.right = prc.bottom = 0;
	
	// Get image size & hot spot
	ptei = [bank getImageFromHandle:newImg];
	if (ptei==nil)
	    return;
	
	int cx = ptei->width;
	int cy = ptei->height;
	int hsx = 0;
	int hsy = 0;
	if ( (sprFlags & SF_NOHOTSPOT) == 0 )
	{
	    hsy = ptei->ySpot;
	    hsx = ptei->xSpot;
	}
	
	// No rotation
	if ( newAngle == 0 )
	{
	    // Pas de stretch en X
	    if ( newScaleX == 1.0f )
	    {
			prc.left = newX - hsx;
			prc.right = prc.left + cx;
	    }
		
	    // Stretch en X
	    else
	    {
			prc.left = newX - (int)(hsx * newScaleX);
			prc.right = prc.left + (int)(cx * newScaleX);
	    }
		
	    // Pas de stretch en Y
	    if ( newScaleY == 1.0f )
	    {
			prc.top = newY - hsy;
			prc.bottom = prc.top + cy;
	    }
		
	    // Stretch en Y
	    else
	    {
			prc.top = newY - (int)(hsy * newScaleY);
			prc.bottom = prc.top + (int)(cy * newScaleY);
	    }
	}
	
	// Rotation
	else
	{
	    // Calculate dimensions
	    if ( newScaleX != 1.0f )
	    {
			hsx = (int)(hsx * newScaleX);
			cx = (int)(cx * newScaleX);
	    }
		
	    if ( newScaleY != 1.0f )
	    {
			hsy = (int)(hsy * newScaleY);
			cy = (int)(cy * newScaleY);
	    }
		
	    // Rotate
	    int nhsx;
	    int nhsy;
		
	    int nx1;
	    int ny1;
		
	    int nx2;
	    int ny2;
		
	    int	nx4;
	    int	ny4;
		
	    cx--;	// new
	    cy--;	// new
		
	    if ( newAngle == 90 )
	    {
			nx2 = cy;
			ny4 = -cx;
			
			ny2 = 0;
			nx4 = 0;
			
			nhsx = hsy;
			nhsy = -hsx;
	    }
	    else if ( newAngle == 180 )
	    {
			nx2 = 0;
			ny4 = 0;
			
			ny2 = -cy;
			nx4 = -cx;
			
			nhsx = -hsx;
			nhsy = -hsy;
	    }
	    else if ( newAngle == 270 )
	    {
			nx2 = -cy;
			ny4 = cx;
			
			ny2 = 0;
			nx4 = 0;
			
			nhsx = -hsy;
			nhsy = hsx;
	    }
	    else
	    {
			float alpha = newAngle * M_PI / 180.0f;
			float cosa = cosf(alpha);
			float sina = sinf(alpha);
			
			nhsx = (int)(hsx * cosa + hsy * sina);
			nhsy = (int)(hsy * cosa - hsx * sina);
			
			nx2 = (int)(cy * sina);	// new
			ny4 = -(int)(cx * sina);	// new
			ny2 = (int)(cy * cosa);	// new
			nx4 = (int)(cx * cosa);	// new
	    }
		
	    int nx3 = nx2 + nx4;
	    int ny3 = ny2 + ny4;
		
	    // Faire translation par rapport au hotspot
	    nx1 = newX - nhsx;
	    ny1 = newY - nhsy;
	    nx2 += newX - nhsx;
	    ny2 += newY - nhsy;
	    nx3 += newX - nhsx;
	    ny3 += newY - nhsy;
	    nx4 += newX - nhsx;
	    ny4 += newY - nhsy;
		
	    // Calculer la nouvelle bounding box (‡ optimiser Èventuellement)
	    prc.left = MIN(nx1,nx2);
	    prc.left = MIN(prc.left,nx3);
	    prc.left = MIN(prc.left,nx4);
		
	    prc.right = MAX(nx1,nx2);
	    prc.right = MAX(prc.right,nx3);
	    prc.right = MAX(prc.right,nx4);
		
	    prc.right++;	// new
		
	    prc.top = MIN(ny1,ny2);
	    prc.top = MIN(prc.top,ny3);
	    prc.top = MIN(prc.top,ny4);
		
	    prc.bottom = MAX(ny1,ny2);
	    prc.bottom = MAX(prc.bottom,ny3);
	    prc.bottom = MAX(prc.bottom,ny4);
		
	    prc.bottom++;	// new
	}
}

-(NSString*)description
{
	if(sprExtraInfo != nil)
		return [NSString stringWithFormat:@"Sprite[%i, %i]: %@ %@ %@", sprX, sprY, [sprExtraInfo description], sprRout, [super description]];
	return [NSString stringWithFormat:@"Sprite[%i, %i] %@ %@", sprX, sprY, sprRout, [super description]];
}


@end
