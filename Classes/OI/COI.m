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
// COI
//
//----------------------------------------------------------------------------------
#import "COI.h"
#import "COC.h"
#import "CFile.h"
#import "IEnum.h"
#import "CObjectCommon.h"
#import "COCBackground.h"
#import "COCQBackdrop.h"

@implementation COI

-(id)init
{
    oiHandle=0;
    oiType=0;
    oiFlags=0;			
    oiInkEffect=0;			
    oiInkEffectParam=0;	    
    oiOC=nil;			
    oiFileOffset=0;
    oiLoadFlags=0;
    oiLoadCount=0;
    oiCount=0;
	oiName=nil;
		
	return self;
}
-(void)dealloc
{
	if (oiName!=nil)
	{
		[oiName release];
	}
	if (oiOC!=nil)
	{
		[oiOC release];
	}
	[super dealloc];
}
-(void)loadHeader:(CFile*)file
{
	oiHandle=[file readAShort];
	oiType=[file readAShort];
	oiFlags=[file readAShort];
	[file skipBytes:2];
	oiInkEffect=[file readAInt];
	oiInkEffectParam=[file readAInt];
}
-(void)load:(CFile*)file 
{
	// Positionne au debut
	[file seek:oiFileOffset];
	
	// En fonction du type
	switch (oiType)
	{
	    case 0:		// Quick background
			oiOC=[[COCQBackdrop alloc] init];
			break;
	    case 1:
			oiOC=[[COCBackground alloc] init];
			break;
	    default:
			oiOC=[[CObjectCommon alloc] init];
			break;
	}
	[oiOC load:file withType:oiType andCOI:self];
	oiLoadFlags=0;
}
-(void)unLoad
{
	if (oiOC!=nil)
	{
		[oiOC release];
		oiOC=nil;
	}
}
-(void)enumElements:(id)enumImages withFont:(id)enumFonts
{
	[oiOC enumElements:enumImages withFont:enumFonts];
}

@end
