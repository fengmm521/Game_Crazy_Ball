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
// -----------------------------------------------------------------------------
//
// CBACKDRAWPASTE
//
// -----------------------------------------------------------------------------
#import "CBackDrawPaste.h"
#import "CImageBank.h"
#import "CMask.h"
#import "CRun.h"
#import "CColMask.h"
#import "CImage.h"
#import "CRunApp.h"
#import "CColMask.h"
#import "CRunFrame.h"
#import "CSpriteGen.h"
#import "CBitmap.h"

@implementation CBackDrawPaste

-(void)execute:(CRun*)rhPtr withBitmap:(CBitmap*)bitmap
{
	// Demande la largeur et la hauteur de l'image
	CImage* ifo=[rhPtr->rhApp->imageBank getImageFromHandle:img];
	
	int xImage = x;
	int x1Image = xImage - ifo->xSpot;
	int x2Image = x1Image + ifo->width;
	int yImage = y;
	int y1Image = yImage - ifo->ySpot;
	int y2Image = y1Image + ifo->height;
	
	// En fonction de type de paste
	CMask* mask;
	switch (typeObst)
	{
	    case 0:
			// Un rien
			// -------
			if (rhPtr->rhFrame->colMask!=nil)
			{
				mask=[ifo getMask:GCMF_OBSTACLE withAngle:0 andScaleX:1.0 andScaleY:1.0];
				[rhPtr->rhFrame->colMask orMask:mask withX:x1Image andY:y1Image andPlane:CM_OBSTACLE | CM_PLATFORM andValue:0];
			}
			[rhPtr y_Ladder_Sub:0 withX1:x1Image andY1:y1Image andX2:x2Image andY2:y2Image];
			break;
	    case 1:
			// Un obstacle
			// -----------
			if (rhPtr->rhFrame->colMask!=nil)
			{
				mask=[ifo getMask:GCMF_OBSTACLE withAngle:0 andScaleX:1.0 andScaleY:1.0];
				[rhPtr->rhFrame->colMask orMask:mask withX:x1Image andY:y1Image andPlane:CM_OBSTACLE|CM_PLATFORM andValue:CM_OBSTACLE|CM_PLATFORM];
			}
			break;
	    case 2:
			// Une plateforme
			// --------------
			if (rhPtr->rhFrame->colMask!=nil)
			{
				mask=[ifo getMask:GCMF_OBSTACLE withAngle:0 andScaleX:1.0 andScaleY:1.0];
				[rhPtr->rhFrame->colMask orMask:mask withX:x1Image andY:y1Image andPlane:CM_OBSTACLE|CM_PLATFORM andValue:0];
				[rhPtr->rhFrame->colMask orPlatformMask:mask withX:x1Image andY:y1Image];
			}
			break;
	    case 3:
			// Une echelle
			[rhPtr y_Ladder_Add:0 withX1:x1Image andY1:y1Image andX2:x2Image andY2:y2Image];
			if (rhPtr->rhFrame->colMask!=nil)
			{
				[rhPtr->rhFrame->colMask fillRectangle:x1Image withY1:y1Image andX2:x2Image andY2:y2Image andValue:0];
			}
			break;
	    default:
			break;
	}
	
	// Paste dans l'image!
	// -------------------
	
	//ANDOS TODO
	//[rhPtr->spriteGen pasteSpriteEffect:bitmap withImage:img andX:x1Image andY:y1Image andFlags:0 andInkEffect:inkEffect andInkEffectParam:inkEffectParam];	
}

@end
