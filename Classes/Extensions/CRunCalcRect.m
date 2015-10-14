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
// CRUNCALCRECT
//
//----------------------------------------------------------------------------------
#import "CRunCalcRect.h"
#import "CFile.h"
#import "CServices.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CCndExtension.h"
#import "CActExtension.h"
#import "CRect.h"
#import "CFontInfo.h"
#import "CFont.h"
#import "CRun.h"

@implementation CRunCalcRect

-(void)dealloc
{
	[text release];
	[fontName release];
	[super dealloc];
}

-(int)getNumberOfConditions
{
	return 0;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	text=[[NSString alloc] initWithString:@""];
	fontName=[[NSString alloc] initWithString:@""];
	fontHeight=10;
	maxWidth=1000000;
	return YES;
}

// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_SetFont:
			[self SetFont:[act getParamExpString:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1] andParam2:[act getParamExpression:rh withNum:2]];
			break;
				
		case ACT_SetText:
			[self SetText:[act getParamExpString:rh withNum:0]];
			break;
			
		case ACT_SetMaxWidth:
			[self SetMaxWidth:[act getParamExpression:rh withNum:0]];
			break;
					
		case ACT_CalcRect:
			[self CalcRect];
			break;
	}
}
			
// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_GetWidth:
			return [self GetWidth];
			
		case EXP_GetHeight:
			return [self GetHeight];
	}
	return nil;
}

-(void)CalcRect
{
	//Font
	CFontInfo* fontInfo = [[CFontInfo alloc] init];
	fontInfo->lfFaceName = [[NSString alloc] initWithString:fontName];
	fontInfo->lfHeight = fontHeight;
	fontInfo->lfItalic = (unsigned char)(fontItalic ? 1 : 0);
	fontInfo->lfUnderline = (unsigned char) (fontUnderline ? 1 : 0);
	CFont* font=[CFont createFromFontInfo:fontInfo];
	UIFont* theFont = [font createFont];

#ifdef __IPHONE_8_0
	CGSize size = [text boundingRectWithSize:CGSizeMake(maxWidth, 100000) options:NSStringDrawingUsesDeviceMetrics attributes:@{NSFontAttributeName:theFont} context:nil].size;
#else
	CGSize size = [text sizeWithFont:theFont constrainedToSize:CGSizeMake(maxWidth, 100000) lineBreakMode:0];
#endif

	//Size
	calcWidth = (int)size.width;
	calcHeight = (int)size.height;
	
	[fontInfo release];
	[font release];
}

-(CValue*)GetHeight
{
	return [rh getTempValue:calcHeight];
}

-(CValue*)GetWidth
{
	return [rh getTempValue:calcWidth];
}

-(void)SetFont:(NSString*)name withParam1:(int)height andParam2:(int)style
{
	[fontName release];
	fontName = [[NSString alloc] initWithString:name];
	fontHeight = height;
	fontBold = (style & 1) == 1;
	fontItalic = (style & 2) == 2;
	fontUnderline = (style & 4) == 4;
}

-(void)SetMaxWidth:(int)width
{
	if (width <= 0)
	{
		maxWidth = 1000000;
	}
	else
	{
		maxWidth = width;
	}
}

-(void)SetText:(NSString*)t
{
	[text release];
	text = [[NSString alloc] initWithString:t];
}

@end
