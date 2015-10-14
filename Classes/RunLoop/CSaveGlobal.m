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
// ---------------------------------------------------------------------------------
//
// CSaveGlobal : Sauvegarde des objets globaux
//
// ---------------------------------------------------------------------------------
#import "CSaveGlobal.h"
#import "CArrayList.h"
#import "CRVal.h"

@implementation CSaveGlobal

-(id)init
{
	name=nil;
	objects=nil;
	return self;
}
-(void)dealloc
{
	[name release];
	if (objects!=nil)
	{
		[objects clearRelease];
		[objects release];
	}
	[super dealloc];
}
@end

@implementation CSaveGlobalCounter
-(id)init
{
	pValue=nil;
	return self;
}
-(void)dealloc
{
	if (pValue!=nil)
	{
		[pValue release];
	}
	[super dealloc];
}
@end

@implementation CSaveGlobalText
-(id)init
{
	pString=nil;
	return self;
}
-(void)dealloc
{
	if (pString!=nil)
	{
		[pString release];
	}
	[super dealloc];
}
@end

@implementation CSaveGlobalValues
-(id)init
{
	pStrings=nil;
	pValues=nil;
	return self;
}
-(void)dealloc
{
	int n;
	if (pStrings!=nil)
	{
		for (n=0; n<STRINGS_NUMBEROF_ALTERABLE; n++)
		{
			if (pStrings[n]!=nil)
			{
				[pStrings[n] release];
			}
		}
		free(pStrings);
	}
	if (pValues!=nil)
	{
		for (n=0; n<rvNumberOfValues; n++)
		{
			if (pValues[n]!=nil)
			{
				[pValues[n] release];
			}
		}
		free(pValues);
	}
	[super dealloc];
}
@end


