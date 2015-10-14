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
// CRunStringTokenizer
//
//----------------------------------------------------------------------------------
#import "CRunStringTokenizer.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CObject.h"
#import "CRun.h"
#import "CArrayList.h"
#import "CCreateObjectInfo.h"
#import "CExtension.h"
#import "CValue.h"

#define ACT0_SPLITSTRING0WITHDELIMITERS11D 0
#define ACT1_SPLITSTRING0WITHDELIMITERS1AND22D 1
#define EXP0_ELEMENTCOUNT 0
#define EXP1_ELEMENT 1
#define EXP2_ELEMENT2D 2
#define EXP3_ELEMENTCOUNTX 3
#define EXP4_ELEMENTCOUNTY 4


@implementation CRunStringTokenizer

-(int) getNumberOfConditions
{
	return 0;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	Tokens=[[CArrayList alloc] init];
	Tokens2D=[[CArrayList alloc] init];
	return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
	[Tokens clearRelease];
	[Tokens release];
	[self clearTokens2D];
	[Tokens2D release];
}

-(void)clearTokens2D
{
	int i;
	for (i=0; i<[Tokens2D size]; i++)
	{
		CArrayList* array=(CArrayList*)[Tokens2D get:i];
		[array clearRelease];
		[array release];
	}
	[Tokens2D clear];
}

-(void)act0_Splitstring0withdelimiters11D:(CActExtension*)act
{
	NSString* param0 = [act getParamExpString:rh withNum:0];
	NSString* param1 = [act getParamExpString:rh withNum:1];

	//Remove windows carriage returns
	param0 = [param0 stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	param1 = [param1 stringByReplacingOccurrencesOfString:@"\r" withString:@""];

	[Tokens clearRelease];
	CStringTokeniser* Tokeniser = [[CStringTokeniser alloc] init:param0 withParam:param1];
	int TokenCount = [Tokeniser countTokens];
	int i;
	for(i = 0; i < TokenCount; i++)
	{
		[Tokens add:[[NSString alloc] initWithString:[Tokeniser nextToken]]];
	}
	[Tokeniser release];
}

-(void)act1_Splitstring0withdelimiters1and22D:(CActExtension*)act
{
	NSString* param0 = [act getParamExpString:rh withNum:0];
	NSString* param1 = [act getParamExpString:rh withNum:1];
	NSString* param2 = [act getParamExpString:rh withNum:2];

	//Remove windows carriage returns
	param0 = [param0 stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	param1 = [param1 stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	param2 = [param2 stringByReplacingOccurrencesOfString:@"\r" withString:@""];

	for(int i=0; i<[Tokens2D size]; ++i)
	{
		CArrayList* line = (CArrayList*)[Tokens2D get:i];
		[line clearRelease];
	}
	[Tokens2D clearRelease];
	
	CStringTokeniser* YTokeniser = [[CStringTokeniser alloc] init:param0 withParam:param1];
	int YTokenCount = [YTokeniser countTokens];
	for(int y = 0; y < YTokenCount; y++)
	{
		CArrayList* New = [[CArrayList alloc] init];
		CStringTokeniser* XTokeniser=[[CStringTokeniser alloc] init:[YTokeniser nextToken] withParam:param2];
		int XTokenCount = [XTokeniser countTokens];
		for(int x = 0; x < XTokenCount; x++)
		{
			[New add:[[NSString alloc] initWithString:[XTokeniser nextToken]]];
		}	
		[Tokens2D add:New];
		[XTokeniser release];
	}
	[YTokeniser release];
}

-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT0_SPLITSTRING0WITHDELIMITERS11D: // '\0'
			[self act0_Splitstring0withdelimiters11D:act];
			break;
			
		case ACT1_SPLITSTRING0WITHDELIMITERS1AND22D: // '\001'
			[self act1_Splitstring0withdelimiters1and22D:act];
			break;
	}
}


-(CValue*)exp0_ElementCount
{
	return [rh getTempValue:[Tokens size]];
}

-(CValue*)exp1_Element
{
	int param0 = [[ho getExpParam] getInt];
	CValue* ret=[rh getTempValue:0];
	NSString* s=(NSString*)[Tokens get:param0];
	if (s==nil)
	{
		s=@"";
	}	        
	[ret forceString:s];
	return ret;
}

-(CValue*)exp2_Element2D
{
	int param0 = [[ho getExpParam] getInt];
	int param1 = [[ho getExpParam] getInt];
	CValue* ret=[rh getTempValue:0];
	NSString* s=(NSString*)[ (CArrayList*)[Tokens2D get:param0] get:param1];
	if (s==nil)
	{
		s=@"";
	}	        
	[ret forceString:s];
	return ret;
}

-(CValue*)exp3_ElementCountX
{
	return [rh getTempValue:[Tokens2D size]];
}

-(CValue*)exp4_ElementCountY
{
	int sz = 0;
	int param0 = [[ho getExpParam] getInt];
    if ( param0 >= 0 && param0 < [Tokens2D size] )
		sz = [(CArrayList*)[Tokens2D get:param0] size];
	return [rh getTempValue:sz];
}	    


-(CValue*)expression:(int)num
{
	switch (num)
	{
        case EXP0_ELEMENTCOUNT: // '\0'
            return [self exp0_ElementCount];
				
        case EXP1_ELEMENT: // '\001'
            return [self exp1_Element];
			
        case EXP2_ELEMENT2D: // '\002'
            return [self exp2_Element2D];
				
        case EXP3_ELEMENTCOUNTX: // '\003'
            return [self exp3_ElementCountX];
				
        case EXP4_ELEMENTCOUNTY: // '\004'
            return [self exp4_ElementCountY];
	}
	return nil;
}

@end

@implementation CStringTokeniser


-(id)init:(NSString*)text withParam:(NSString*)delimiter
{
	tokens=[[CArrayList alloc] init];
	
	NSUInteger oldPos=0;
	NSRange range = [text rangeOfString:delimiter];
	NSUInteger pos=range.location;
	while(pos!=NSNotFound)
	{
		if (pos>oldPos)
		{
			range.location=oldPos;
			range.length=pos-oldPos;
			[tokens add:[[NSString alloc] initWithString:[text substringWithRange:range]]];
		}
		oldPos=pos+[delimiter length];
		if (oldPos>=[text length])
		{
			break;
		}
		range.location=oldPos;
		range.length=[text length]-oldPos;
		range=[text rangeOfString:delimiter options:0 range:range];
		pos=range.location;
	}
	if ([text length]>oldPos)
	{
		range.location=oldPos;
		range.length=[text length]-oldPos;
		[tokens add:[[NSString alloc] initWithString:[text substringWithRange:range]]];
	}
	numToken=0;
	
	return self;
}
-(void)dealloc
{
	[tokens clearRelease];
	[tokens release];
	[super dealloc];
}

-(int)countTokens
{
	return [tokens size];
}
-(NSString*)nextToken
{
	if (numToken<[tokens size])
	{
		NSString* s=(NSString*)[tokens get:numToken++];
		if (s==nil)
		{
			return @"";
		}
		return s;
	}
	return @"";
}

@end
