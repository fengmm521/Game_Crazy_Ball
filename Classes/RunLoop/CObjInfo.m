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
// CObjInfo informations sur un objet
//
//----------------------------------------------------------------------------------
#import "CObjInfo.h"
#import "COI.h"
#import "CObjectCommon.h"

@implementation CObjInfo

-(id)init
{
	oilColList=nil;
	return self;
}

-(void)dealloc
{
	if (oilName!=nil)
	{
		[oilName release];
	}
    if (oilColList!=nil)
    {
        free(oilColList);
    }
	[super dealloc];
}
-(void)copyData:(COI*)oiPtr
{
	// Met dans l'OiList
	oilOi = oiPtr->oiHandle;
	oilType = oiPtr->oiType;
	
	oilOIFlags = oiPtr->oiFlags;
	CObjectCommon* ocPtr = (CObjectCommon*) oiPtr->oiOC;
	oilOCFlags2 = ocPtr->ocFlags2;
	oilInkEffect = oiPtr->oiInkEffect;
	oilEffectParam = oiPtr->oiInkEffectParam;
	oilOEFlags = ocPtr->ocOEFlags;
	oilBackColor = ocPtr->ocBackColor;
	oilEventCount = 0;
	oilObject = -1;
	oilLimitFlags = (short) OILIMITFLAGS_ALL;
    oilName=nil;
	if (oiPtr->oiName != nil)
	{
		oilName = [[NSString alloc] initWithString:oiPtr->oiName];
	}
	int q;
	for (q = 0; q < 8; q++)
	{
		oilQualifiers[q] = ocPtr->ocQualifiers[q];
	}
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"CObjInfo: Name: '%@' oi: %i  nObjects: %i", oilName, oilOi, oilNObjects];
}

@end
