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
// CRunObjectMover: extension object
//
//----------------------------------------------------------------------------------
#import "CRunObjectMover.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CCndExtension.h"
#import "CRMvt.h"
#import "CMove.h"
#import "CRCom.h"


@implementation CRunObjectMover

-(int)getNumberOfConditions
{
	return 1;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	ho->hoImgWidth = [file readAInt];
	ho->hoImgHeight = [file readAInt];
	enabled = [file readAShort];
	previousX = ho->hoX;
	previousY = ho->hoY;
	
	return NO;
}

-(int)handleRunObject
{
	if (ho->hoX != previousX || ho->hoY != previousY)
	{
		int deltaX = ho->hoX - previousX;
		int deltaY = ho->hoY - previousY;
		if (enabled != 0)
		{
			int n;
			int x1 = previousX;
			int y1 = previousY;
			int x2 = previousX + ho->hoImgWidth;
			int y2 = previousY + ho->hoImgHeight;
			CRun* rhPtr = ho->hoAdRunHeader;
			int count = 0;
			for (n = 0; n < rhPtr->rhNObjects; n++)
			{
				while (rhPtr->rhObjectList[count] == nil)
				{
					count++;
				}
				CObject* pHo = rhPtr->rhObjectList[count];
				count++;
				if (pHo != ho)
				{
					if (pHo->hoX >= x1 && pHo->hoX + pHo->hoImgWidth < x2)
					{
						if (pHo->hoY >= y1 && pHo->hoY + pHo->hoImgHeight < y2)
						{
							[self setPosition:pHo  withParam1:pHo->hoX + deltaX  andParam2:pHo->hoY + deltaY];
						}
					}
				}
			}
		}
		previousX = ho->hoX;
		previousY = ho->hoY;
	}
	return 0;
}

-(void)setPosition:(CObject*)pHo withParam1:(int)x andParam2:(int)y
{
	if (pHo->rom != nil)
	{
		[pHo->rom->rmMovement setXPosition:x];
		[pHo->rom->rmMovement setYPosition:y];
	}
	else
	{
		pHo->hoX = x;
		pHo->hoY = y;
		if (pHo->roc != nil)
		{
			pHo->roc->rcChanged = YES;
			pHo->roc->rcCheckCollides = YES;
		}
	}
}

// Conditions
// --------------------------------------------------
-(BOOL)cndEnabled:(CCndExtension*)cnd
{
	return enabled != 0;
}

-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case 0:
			return [self cndEnabled:cnd];
	}
	return NO;
}

// Actions
// -------------------------------------------------
-(void)actEnable:(CActExtension*)act
{
	enabled = 1;
}

-(void)actDisable:(CActExtension*)act
{
	enabled = 0;
}

-(void)actSetWidth:(CActExtension*)act
{
	int width = [act getParamExpression:rh withNum:0];
	if (width > 0)
	{
		ho->hoImgWidth = width;
	}
}

-(void)actSetHeight:(CActExtension*)act
{
	int height = [act getParamExpression:rh withNum:0];
	if (height > 0)
	{
		ho->hoImgHeight = height;
	}
}

-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case 0:
			[self actSetWidth:act];
			break;
		case 1:
			[self actSetHeight:act];
			break;
		case 2:
			[self actEnable:act];
			break;
		case 3:
			[self actDisable:act];
			break;
	}
}

// Expressions
// --------------------------------------------
-(CValue*)expGetWidth
{
	return [rh getTempValue:ho->hoImgWidth];
}

-(CValue*)expGetHeight
{
	return [rh getTempValue:ho->hoImgHeight];
}

-(CValue*)expression:(int)num
{
	switch (num)
	{
		case 0:
			return [self expGetWidth];
		case 1:
			return [self expGetHeight];
	}
	return nil;
}

@end
