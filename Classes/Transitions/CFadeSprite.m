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
// CFADESPRITE sprite pour transisions
//
//----------------------------------------------------------------------------------
#import "CFadeSprite.h"
#import "CTrans.h"
#import "CRSpr.h"
#import "CSprite.h"
#import "CImageBank.h"
#import "CObject.h"
#import "CImage.h"
#import "CBitmap.h"
#import "CRenderer.h"
#import "CRenderToTexture.h"

@implementation CFadeSprite

-(id)initWithTrans:(CTrans*)t
{
	trans=t;
	return self;
}
-(void)dealloc
{
	if (trans!=nil)
	{
		[trans release];
	}
	[super dealloc];
}
-(void)spriteDraw:(CRenderer*)renderer withSprite:(CSprite*)spr andImageBank:(CImageBank*)bank andX:(int)x andY:(int)y
{
	int trFlags = 0;
	if ((spr->sprExtraInfo->hoFlags&HOF_FADEOUT)!=0)
		trFlags |= TRFLAG_FADEOUT;
	else
		trFlags |= TRFLAG_FADEIN;

	renderer->setOrigin(x, y);
	[trans stepDraw:trFlags];
	renderer->setOrigin(0, 0);
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
	return [NSString stringWithFormat:@"FadeSprite: %@", trans];
}

@end
