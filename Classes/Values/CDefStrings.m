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
// CDEFSTRINGS : definition des alterable strings
//
//----------------------------------------------------------------------------------
#import "CDefStrings.h"
#import "CFile.h"

@implementation CDefStrings

-(id)init
{
	strings=nil;
	return self;
}
-(void)dealloc
{
	if (strings!=nil)
	{
		int n;
		for (n=0; n<nStrings; n++)
		{
			[strings[n] release];
		}
		free(strings);
	}
	[super dealloc];
}
-(void)load:(CFile*)file
{
	nStrings=[file readAShort];
	if (nStrings>0)
	{		
		strings=(NSString**)malloc(nStrings*sizeof(NSString*));
		int n;
		for (n=0; n<nStrings; n++)
		{
			strings[n]=[file readAString];
		}
	}
}
@end
