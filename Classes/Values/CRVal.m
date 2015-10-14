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
// CRVAL : Alterable values et strings
//
//----------------------------------------------------------------------------------
#import "CRVal.h"
#import "CValue.h"
#import "CObjectCommon.h"
#import "CCreateObjectInfo.h"
#import "CDefValues.h"
#import "CDefStrings.h"

@implementation CRVal

-(void)dealloc
{
	int n;
	for (n=0; n< rvNumberOfValues ; n++)
	{
		if (rvValues[n]!=nil)
		{
			[rvValues[n] release];
		}
	}
	free(rvValues);
	for (n=0; n<STRINGS_NUMBEROF_ALTERABLE; n++)
	{
		if (rvStrings[n]!=nil)
		{
			[rvStrings[n] release];
		}
	}
	free(rvStrings);
	[super dealloc];
}
-(id)initWithHO:(CObject*)ho andOC:(CObjectCommon*)ocPtr andCOB:(CCreateObjectInfo*)cob
{
	self=[super init];
	
	// Creation des tableaux
	rvValueFlags=0;
	rvNumberOfValues=VALUES_NUMBEROF_ALTERABLE;
	rvValues=(CValue**)calloc(VALUES_NUMBEROF_ALTERABLE, sizeof(CValue*));
	rvStrings=(NSString**)calloc(STRINGS_NUMBEROF_ALTERABLE, sizeof(NSString*));

	for (int n=0; n<VALUES_NUMBEROF_ALTERABLE; n++)
		rvValues[n] = [[CValue alloc] initWithInt:0];

	for (int n=0; n<STRINGS_NUMBEROF_ALTERABLE; n++)
		rvStrings[n] = @"";

	// Initialisation des valeurs
	if (ocPtr->ocValues!=nil)
	{
	    for (int n=0; n<ocPtr->ocValues->nValues; n++)
			[rvValues[n] forceInt:ocPtr->ocValues->values[n]];
	}
	if (ocPtr->ocStrings!=nil)
	{
	    for (int n=0; n<ocPtr->ocStrings->nStrings; n++)
			rvStrings[n]=[[NSString alloc] initWithString:ocPtr->ocStrings->strings[n]];

	}
	
	return self;
}
			
-(void)kill:(BOOL)bFast
{
}

-(CValue*)getValue:(int)n
{
	return rvValues[n];
}

-(NSString*)getString:(int)n
{
	return rvStrings[n];
}
-(void)setString:(int)n withString:(NSString*)s
{
	[rvStrings[n] release];
	rvStrings[n]=[[NSString alloc] initWithString:s];
}

@end
