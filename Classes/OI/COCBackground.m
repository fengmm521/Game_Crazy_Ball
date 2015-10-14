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
// COCBACKGROUND : un objet dÈcor normal
//
//----------------------------------------------------------------------------------
#import "COCBackground.h"
#import "CFile.h"
#import "IEnum.h"
#import "COI.h"

@implementation COCBackground

-(id)init
{
	self=[super init];
	return self;
}
-(void)dealloc
{
	[super dealloc];
}
-(void)load:(CFile*)file withType:(short)type andCOI:(COI*)pOI
{
	pCOI=pOI;
	[file skipBytes:4];		// ocDWSize
	ocObstacleType=[file readAShort];
	ocColMode=[file readAShort];
	ocCx=[file readAInt];
	ocCy=[file readAInt];
	ocImage=[file readAShort];
}

-(void)enumElements:(id)enumImages withFont:(id)enumFonts
{
	if (enumImages!=nil)
	{
		id<IEnum> pImages=enumImages;
	    short num=[pImages enumerate:ocImage];
	    if (num!=-1)
	    {
			ocImage=num;
	    }
	}
}

-(void)spriteDraw:(CBitmap*)g withSprite:(CSprite*)spr andImageBank:(CImageBank*)bank andX:(int)x andY:(int)y
{
}

-(void)spriteKill:(CSprite*)spr
{
}
-(CMask*)spriteGetMask
{
	return nil;
}

@end
