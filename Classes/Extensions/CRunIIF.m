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
// CRUNIIF
//
//----------------------------------------------------------------------------------
#import "CRunIIF.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CRun.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CExtension.h"
#import "CValue.h"

@implementation CRunIIF

-(int)getNumberOfConditions
{
	return 0;
}
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	Last=NO;
	return NO;
}
-(void)destroyRunObject:(BOOL)bFast
{
}

-(int)handleRunObject
{
	return REFLAG_ONESHOT;
}

-(void)displayRunObject:(CRenderer*)renderer
{
}

// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_INT_INT:
			return [self IntInt];
		case EXP_INT_STRING:
			return [self IntString];
		case EXP_INT_FLOAT:
			return [self IntFloat];
		case EXP_STRING_INT:
			return [self StringInt];
		case EXP_STRING_STRING:
			return [self StringString];
		case EXP_STRING_FLOAT:
			return [self StringFloat];
		case EXP_FLOAT_INT:
			return [self FloatInt];
		case EXP_FLOAT_STRING:
			return [self FloatString];
		case EXP_FLOAT_FLOAT:
			return [self FloatFloat];
		case EXP_INT_BOOL:
			return [self IntBool];
		case EXP_STRING_BOOL:
			return [self StringBool];
		case EXP_FLOAT_BOOL:
			return [self FloatBool];
		case EXP_BOOL_INT:
			return [self BoolInt];
		case EXP_BOOL_STRING:
			return [self BoolString];
		case EXP_BOOL_FLOAT:
			return [self BoolFloat];
		case EXP_LAST_COMP:
			return [self LastComp];
	}
	return nil;
}
-(CValue*)IntInt
{
	//get parameters
	int p1=[[ho getExpParam] getInt];
	NSString* comp = [[ho getExpParam] getString];
	int p2 = [[ho getExpParam] getInt];
	int r1 = [[ho getExpParam] getInt];
	int r2 = [[ho getExpParam] getInt];
	
	Last = [self CompareInts:p1 withParam1:comp andParam2:p2];
	if(Last)
		return [rh getTempValue:r1];
	else
		return [rh getTempValue:r2];
}

-(CValue*)IntString
{
	//get parameters
	NSString* p1 = [[ho getExpParam] getString];
	NSString* comp = [[ho getExpParam] getString];
	NSString* p2 = [[ho getExpParam] getString];
	int r1 = [[ho getExpParam] getInt];
	int r2 = [[ho getExpParam] getInt];
	
	Last = [self CompareStrings:p1 withParam1:comp andParam2:p2];
	if(Last)
		return [rh getTempValue:r1];
	else
		return [rh getTempValue:r2];
}

-(CValue*)IntFloat
{
	//get parameters
	double p1 = [[ho getExpParam] getDouble];
	NSString* comp = [[ho getExpParam] getString];
	double p2 = [[ho getExpParam] getDouble];
	int r1 = [[ho getExpParam] getInt];
	int r2 = [[ho getExpParam] getInt];
	
	Last = [self CompareFloats:p1 withParam1:comp andParam2:p2];
	if(Last)
		return [rh getTempValue:r1];
	else
		return [rh getTempValue:r2];
}

-(CValue*)StringInt
{
	//get parameters
	int p1 = [[ho getExpParam] getInt];
	NSString* comp = [[ho getExpParam] getString];
	int p2 = [[ho getExpParam] getInt];
	NSString* r1 = [[ho getExpParam] getString];
	NSString* r2 = [[ho getExpParam] getString];
	
	Last = [self CompareInts:p1 withParam1:comp andParam2:p2];
	CValue* ret=[rh getTempValue:0];
	if (Last)
	{
		[ret forceString:r1];
	}		
	else
	{
		[ret forceString:r2];
	}
	return ret;
}

-(CValue*)StringString
{
	//get parameters
	NSString* p1 = [[ho getExpParam] getString];
	NSString* comp = [[ho getExpParam] getString];
	NSString* p2 = [[ho getExpParam] getString];
	NSString* r1 = [[ho getExpParam] getString];
	NSString* r2 = [[ho getExpParam] getString];
	
	Last = [self CompareStrings:p1 withParam1:comp andParam2:p2];
	CValue* ret=[rh getTempValue:0];
	if (Last)
	{
		[ret forceString:r1];
	}		
	else
	{
		[ret forceString:r2];
	}
	return ret;
}

-(CValue*)StringFloat
{
	//get parameters
	double p1 = [[ho getExpParam] getDouble];
	NSString* comp = [[ho getExpParam] getString];
	double p2 = [[ho getExpParam] getDouble];
	NSString* r1 = [[ho getExpParam] getString];
	NSString* r2 = [[ho getExpParam] getString];
	
	Last = [self CompareFloats:p1 withParam1:comp andParam2:p2];
	CValue* ret=[rh getTempValue:0];
	if (Last)
	{
		[ret forceString:r1];
	}		
	else
	{
		[ret forceString:r2];
	}
	return ret;
}

-(CValue*)FloatInt
{
	//get parameters
	int p1 = [[ho getExpParam] getInt];
	NSString* comp = [[ho getExpParam] getString];
	int p2 = [[ho getExpParam] getInt];
	double r1 = [[ho getExpParam] getDouble];
	double r2 = [[ho getExpParam] getDouble];
	
	Last = [self CompareInts:p1 withParam1:comp andParam2:p2];
	CValue* ret=[rh getTempValue:0];
	if (Last)
	{
		[ret forceDouble:r1];
	}		
	else
	{
		[ret forceDouble:r2];
	}
	return ret;
}

-(CValue*)FloatString
{
	//get parameters
	NSString* p1 =[[ho getExpParam] getString];
	NSString* comp =[[ho getExpParam] getString];
	NSString* p2 =[[ho getExpParam] getString];
	double r1 = [[ho getExpParam] getDouble];
	double r2 = [[ho getExpParam] getDouble];
	
	Last = [self CompareStrings:p1 withParam1:comp andParam2:p2];
	CValue* ret=[rh getTempValue:0];
	if (Last)
	{
		[ret forceDouble:r1];
	}		
	else
	{
		[ret forceDouble:r2];
	}
	return ret;
}

-(CValue*)FloatFloat
{
	//get parameters
	double p1=[[ho getExpParam] getDouble];
	NSString* comp = [[ho getExpParam] getString];
	double p2 = [[ho getExpParam] getDouble];
	double r1=[[ho getExpParam] getDouble];
	double r2 = [[ho getExpParam] getDouble];
	
	Last = [self CompareFloats:p1 withParam1:comp andParam2:p2];
	CValue* ret=[rh getTempValue:0];
	if (Last)
	{
		[ret forceDouble:r1];
	}		
	else
	{
		[ret forceDouble:r2];
	}
	return ret;
}

-(CValue*)IntBool
{
	//get parameters
	BOOL p1 = [[ho getExpParam] getInt]!=0;
	int r1 = [[ho getExpParam] getInt];
	int r2 = [[ho getExpParam] getInt];
	
	if(p1)
		return [rh getTempValue:r1];
	else
		return [rh getTempValue:r2];
}

-(CValue*)StringBool
{
	//get parameters
	BOOL p1 = [[ho getExpParam] getInt]!=0;
	NSString* r1 = [[ho getExpParam] getString];
	NSString* r2 = [[ho getExpParam] getString];
	
	CValue* ret=[rh getTempValue:0];
	if (p1)
	{
		[ret forceString:r1];
	}		
	else
	{
		[ret forceString:r2];
	}
	return ret;
}

-(CValue*)FloatBool
{
	//get parameters
	BOOL p1 = [[ho getExpParam] getInt]!=0;
	double r1=[[ho getExpParam] getDouble];
	double r2 =[[ho getExpParam] getDouble];
	
	if(p1)
		return [rh getTempValue:r1];
	else
		return [rh getTempValue:r2];
}

-(CValue*)BoolInt
{
	//get parameters
	int p1 = [[ho getExpParam] getInt];
	NSString* comp = [[ho getExpParam] getString];
	int p2 = [[ho getExpParam] getInt];
	
	Last = [self CompareInts:p1 withParam1:comp andParam2:p2];
	if (Last)
		return [rh getTempValue:1];
	else
		return [rh getTempValue:0];
}

-(CValue*)BoolString
{
	//get parameters
	NSString* p1 = [[ho getExpParam] getString];
	NSString* comp = [[ho getExpParam] getString];
	NSString* p2 = [[ho getExpParam] getString];
	
	Last = [self CompareStrings:p1 withParam1:comp andParam2:p2];
	if (Last)
		return [rh getTempValue:1];
	else
		return [rh getTempValue:0];
}

-(CValue*)BoolFloat
{
	//get parameters
	double p1 = [[ho getExpParam] getDouble];
	NSString* comp = [[ho getExpParam] getString];
	double p2 = [[ho getExpParam] getDouble];
	
	Last = [self CompareFloats:p1 withParam1:comp andParam2:p2];
	if (Last)
		return [rh getTempValue:1];
	else
		return [rh getTempValue:0];
}

-(CValue*)LastComp
{
	if (Last)
		return [rh getTempValue:1];
	else
		return [rh getTempValue:0];
}

// ============================================================================
//
// MATT'S FUNCTIONS
//
// ============================================================================
-(BOOL)CompareInts:(int)p1 withParam1:(NSString*)comp andParam2:(int)p2
{
	//catch NULL
	if(comp == nil)
		return p1 == p2;
	
	if( ([comp characterAtIndex:0]=='=') || [comp characterAtIndex:0] == 0 )
		return p1 == p2;
	if([comp characterAtIndex:0] == '!')
		return p1 != p2;
	
	if([comp characterAtIndex:0] == '>')
	{
		if([comp length]>1 && [comp characterAtIndex:1] == '=')
			return p1>=0;
		return p1>0;
	}
	
	if([comp characterAtIndex:0] == '<')
	{
		if([comp length]>1 && [comp characterAtIndex:1] == '=')
			return p1 <= p2;
		if([comp length]>1 && [comp characterAtIndex:1] == '>')
			return p1 != p2;
		return p1 < p2;
	}
	
	//default
	return p1 == p2;
}

-(BOOL)CompareStrings:(NSString*)p1 withParam1:(NSString*)comp andParam2:(NSString*)p2
{
	//catch NULLs
	NSString* NullStr = @"";
	if(p1 == nil)
		p1 = NullStr;
	if(p2 == nil)
		p2 = NullStr;
	
	if(comp == nil)
		return [p1 compare:p2] == 0;
	
	if(([comp characterAtIndex:0] == '=') || [comp characterAtIndex:0] == '\0' ) 
		return [p1 compare:p2] == 0;
	if([comp characterAtIndex:0] == '!')
		return [p1 compare:p2] != 0;
	
	if([comp characterAtIndex:0] == '>')
	{
		if([comp length]>1 && [comp characterAtIndex:1] == '=')
			return [p1 compare:p2] >= 0;
		return [p1 compare:p2] > 0;
	}
	
	if([comp characterAtIndex:0] == '<')
	{
		if([comp length]>1 && [comp characterAtIndex:1] == '=')
			return [p1 compare:p2] <= 0;
		if([comp length]>1 && [comp characterAtIndex:1] == '>')
			return [p1 compare:p2] != 0;
		return [p1 compare:p2] < 0;
	}
	
	return [p1 compare:p2] == 0;
}

-(BOOL)CompareFloats:(double)p1 withParam1:(NSString*)comp andParam2:(double)p2
{
	//catch NULL
	if(comp == nil)
		return p1 == p2;
	
	if(([comp characterAtIndex:0] == '=') || [comp characterAtIndex:0] == '\0')
		return p1 == p2;
	if([comp characterAtIndex:0] == '!')
		return p1 != p2;
	
	if([comp characterAtIndex:0] == '>')
	{
		if([comp length]>1 && [comp characterAtIndex:1] == '=')
			return p1 >= p2;
		return p1 > p2;
	}
	
	if([comp characterAtIndex:0] == '<')
	{
		if([comp length]>1 && [comp characterAtIndex:1] == '=')
			return p1 <= p2;
		if([comp length]>1 && [comp characterAtIndex:1] == '>')
			return p1 != p2;
		return p1 < p2;
	}
	
	//default
	return p1 == p2;
}


@end
