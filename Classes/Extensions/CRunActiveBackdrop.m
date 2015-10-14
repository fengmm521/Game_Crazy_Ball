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
// CRUNACRTIVEBACKDROP
//
//----------------------------------------------------------------------------------
#import "CRunActiveBackdrop.h"
#import "CExtension.h"
#import "CRun.h"
#import "CBitmap.h"
#import "CServices.h"
#import "CCreateObjectInfo.h"
#import "CFile.h"
#import "CImage.h"
#import "CActExtension.h"
#import "CRenderer.h"

@implementation CRunActiveBackdrop

-(int)getNumberOfConditions
{
	return 1;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	ho->hoImgWidth = [file readAInt];
	ho->hoImgHeight = [file readAInt];
	nImages=[file readAShort];
	flags=[file readAInt];
	imageList=(short*)calloc(nImages, sizeof(short));
	int n;
	for (n=0; n<nImages; n++)
	{
		imageList[n]=[file readAShort];
	}
	if (nImages>0)
	{
		[ho loadImageList:imageList withLength:nImages];
		currentImage=0;
        [self getZoneInfos];
	}
	else
	{
		currentImage=-1;
	}
	return NO;
}

-(void)destroyRunObject:(BOOL)bFast
{
	free(imageList);
}

-(void)displayRunObject:(CRenderer*)renderer
{
	if (currentImage>=0)
	{
		if ((flags&ABFLAG_VISIBLE)!=0)
		{
			CImage* image = [ho getImage:imageList[currentImage]];
			renderer->renderImage(image,
								  ho->hoX,
								  ho->hoY,
								  image->width,
								  image->height,
								  0, 0);
		}
	}
}

-(void)getZoneInfos
{
	if (currentImage>=0)
	{
		CImage* image=[ho getImage:imageList[currentImage]];
		ho->hoImgWidth=image->width;
		ho->hoImgHeight=image->height;
	}
	else
	{
		ho->hoImgWidth=1;
		ho->hoImgHeight=1;
	}
}

// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case 0:
			return [self cndVisible];
	}
	return false;
}

-(BOOL)cndVisible
{
	return (flags&ABFLAG_VISIBLE)!=0;
}

// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case 0:
			[self actSetImage:act];
			break;
		case 1: 
			[self actSetX:act];
			break;
		case 2:
			[self actSetY:act];
			break;
		case 3:
			[self actShow];
			break;
		case 4:
			[self actHide];
			break;
	}
}

-(void)actHide
{
	flags&=~ABFLAG_VISIBLE;
	[ho redisplay];
}

-(void)actShow
{
	flags|=ABFLAG_VISIBLE;
	[ho redisplay];
}

-(void)actSetImage:(CActExtension*)act
{
	int image=[act getParamExpression:rh withNum:0];
	if (image>=0 && image<nImages)
	{
		currentImage=image;
        [self getZoneInfos];
		[ho redisplay];
	}
}
-(void)actSetX:(CActExtension*)act
{
	ho->hoX=[act getParamExpression:rh withNum:0];
	[ho redisplay];
}

-(void)actSetY:(CActExtension*)act
{
	ho->hoY=[act getParamExpression:rh withNum:0];
	[ho redisplay];
}

// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case 0:
			return [self expGetImage];
		case 1:
			return [self expGetX];
		case 2:
			return [self expGetY];
	}
	return nil;
}

-(CValue*)expGetImage
{
	return [rh getTempValue:currentImage];
}

-(CValue*)expGetX
{
	return [rh getTempValue:ho->hoX];
}

-(CValue*)expGetY
{
	return [rh getTempValue:ho->hoY];
}

@end
