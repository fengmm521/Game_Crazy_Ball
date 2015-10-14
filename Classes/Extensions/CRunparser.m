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
// CRunparser: String Parser object
// fin 14/04/09
//
//----------------------------------------------------------------------------------
#import "CRunparser.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CCndExtension.h"
#import "CArrayList.h"
#import "CServices.h"
#import "NSExtensions.h"

#define CASE_INSENSITIVE  0
#define SEARCH_LITERAL  0
#define CND_ISURLSAFE  0
#define ACT_SETSTRING  0
#define ACT_SAVETOFILE  1
#define ACT_LOADFROMFILE  2
#define ACT_APPENDTOFILE  3
#define ACT_APPENDFROMFILE  4
#define ACT_RESETDELIMS  5
#define ACT_ADDDELIM  6
#define ACT_SETDELIM  7
#define ACT_DELETEDELIMINDEX  8
#define ACT_DELETEDELIM  9
#define ACT_SETDEFDELIMINDEX  10
#define ACT_SETDEFDELIM  11
#define ACT_SAVEASCSV  12
#define ACT_LOADFROMCSV  13
#define ACT_SAVEASMMFARRAY  14
#define ACT_LOADFROMMMFARRAY  15
#define ACT_SAVEASDYNAMICARRAY  16
#define ACT_LOADFROMDYNAMICARRAY  17
#define ACT_CASEINSENSITIVE  18
#define ACT_CASESENSITIVE  19
#define ACT_SEARCHLITERAL  20
#define ACT_SEARCHWILDCARDS  21
#define ACT_SAVEASINI  22
#define ACT_LOADFROMINI  23
#define EXP_GETSTRING  0
#define EXP_GETLENGTH  1
#define EXP_EXTLEFT  2
#define EXP_EXTRIGHT  3
#define EXP_EXTMIDDLE  4
#define EXP_NUMBEROFSUBS  5
#define EXP_INDEXOFSUB  6
#define EXP_INDEXOFFIRSTSUB  7
#define EXP_INDEXOFLASTSUB  8
#define EXP_REMOVE  9
#define EXP_REPLACE  10
#define EXP_INSERT  11
#define EXP_REVERSE  12
#define EXP_UPPERCASE  13
#define EXP_LOWERCASE  14
#define EXP_URLENCODE  15
#define EXP_CHR  16
#define EXP_ASC  17
#define EXP_ASCLIST  18
#define EXP_NUMBEROFDELIMS  19
#define EXP_GETDELIM  20
#define EXP_GETDELIMINDEX  21
#define EXP_GETDEFDELIM  22
#define EXP_GETDEFDELIMINDEX  23
#define EXP_LISTCOUNT  24
#define EXP_LISTSETAT  25
#define EXP_LISTINSERTAT  26
#define EXP_LISTAPPEND  27
#define EXP_LISTPREPEND  28
#define EXP_LISTGETAT  29
#define EXP_LISTFIRST  30
#define EXP_LISTLAST  31
#define EXP_LISTFIND  32
#define EXP_LISTCONTAINS  33
#define EXP_LISTDELETEAT  34
#define EXP_LISTSWAP  35
#define EXP_LISTSORTASC  36
#define EXP_LISTSORTDESC  37
#define EXP_LISTCHANGEDELIMS  38
#define EXP_SETSTRING  39
#define EXP_SETVALUE  40
#define EXP_GETMD5  41



@implementation CRunparser

-(int)getNumberOfConditions
{
	return 1;
}

-(NSString*)fixString:(NSString*)input
{
	for (int i = 0; i < [input length]; i++)
	{
		if ([input characterAtIndex:i] < 10)
		{
			NSString* ret=[input substringToIndex:i];
			[input release];
			return ret;
		}
	}
	return input;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	[file skipBytes:4];
	int textLength = (file->bUnicode ? 511 : 1025);

	source = [self fixString:[file readAStringWithSize:textLength]];
	short nComparison = [file readAShort];
	if (nComparison == CASE_INSENSITIVE)
	{
		caseSensitive = NO;
	}
	else
	{
		caseSensitive = YES;
	}
	short nSearchMode = [file readAShort];
	if (nSearchMode == SEARCH_LITERAL)
	{
		wildcards = NO;
	}
	else
	{
		wildcards = YES;
	}
	delims=[[CArrayList alloc] init];
	tokensE=[[CArrayList alloc] init];
	defaultDelim=[[NSString alloc] initWithString:@""];
	return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
	if (delims!=nil)
	{
		[delims clearRelease];
		[delims release];
	}
	if (tokensE!=nil)
	{
		[tokensE clearRelease];
		[tokensE release];
	}
	[source release];
 
}

-(void)redoTokens
{
	[tokensE clearRelease];
	NSString* sourceToTest = source;
	parserElement* element;
	int i = 0, j = 0, index = 0, lastTokenLocation = 0;
	if ([sourceToTest compare:@""]!=0)
	{
		lastTokenLocation = 0;
		BOOL work = YES;
		CArrayList* aTokenE = [[CArrayList alloc] init]; //parserElement
		CArrayList* aDelim = [[CArrayList alloc] init]; //String
		while (work)
		{
			for (j = 0; j < [delims size]; j++)
			{
				NSString* delim = (NSString*) [delims get:j];
				index = [self getSubstringIndex:sourceToTest withParam1:delim andParam2:0];
				if (index != -1)
				{
					element=[[parserElement alloc] init];
					[element setValues:[sourceToTest substringToIndex:index] withParam1:lastTokenLocation];
					[aTokenE add:element];
					[aDelim add:[[NSString alloc] initWithString:delim]];
				}
			}
			//pick smallest token
			NSInteger smallestC = NSIntegerMax;
			NSInteger smallest = -1;
			for (j = 0; j < [aTokenE size]; j++)
			{
				if ( [((parserElement*)[aTokenE get:j])->text length] < smallestC)
				{
					smallestC = [((parserElement*)[aTokenE get:j])->text length];
					smallest = j;
				}
			}
			if (smallest != -1)
			{
				[tokensE add:[[parserElement alloc] initWithElement:((parserElement*)[aTokenE get:smallest])]];
				sourceToTest = [sourceToTest substringFromIndex:[((parserElement*)[aTokenE get:smallest])->text length] + [((NSString*)[aDelim get:smallest]) length]];
				lastTokenLocation += [((parserElement*)[aTokenE get:smallest])->text length]+[((NSString*)[aDelim get:smallest]) length];
			}
			else
			{
				//if at end of search, add remainder
				element=[[parserElement alloc] init];
				[element setValues:sourceToTest withParam1:lastTokenLocation];
				[tokensE add:element];
				work = NO;
			}
			[aTokenE clearRelease];
			[aDelim clearRelease];
		}
		[aTokenE release];
		[aDelim release];

		for (i = 0; i < [tokensE size]; i++)
		{
			//remove ""
			parserElement* e = (parserElement*)[tokensE get:i];
			if ([e->text compare:@""]==0)
			{
				[e release];
				[tokensE removeIndex:i];
				i--;
			}
		}
	}
}
	
-(int)getSubstringIndex:(NSString*)s withParam1:(NSString*)find andParam2:(int)occurance
{ //occurance is 0-based
	NSString* theSource = s;
	if ([s length]==0)
	{
		return -1;
	}
	if (!caseSensitive)
	{
		theSource = [theSource lowercaseString];
		find = [find lowercaseString];
	}
	NSInteger i, j, r;
	NSRange range;
	if (wildcards)
	{
		StringTokenizer* st = [[StringTokenizer alloc] initWithParams:find withParam1:@"*"];
		int ct = [st countTokens];
		NSString** asteriskless = (NSString**)calloc(ct, sizeof(NSString*));
		for (i = 0; i < ct; i++)
		{
			asteriskless[i] = [st nextToken];
		}
		int lastOccurance = -1;
		NSInteger* asterisklessLocation = NULL;
		if(ct > 0)
			asterisklessLocation = (NSInteger*)calloc(ct, sizeof(NSInteger));
		int ll=ct;
		for (int occ = 0; occ <= occurance; occ++)
		{
			for (int asterisk = 0; asterisk < ct; asterisk++)
			{
				for (i = 0; i < [theSource length]; i++)
				{
					NSString* findThis = asteriskless[asterisk];
					//replace "?" occurances with chars from source
					for (j = 0; j < [findThis length]; j++)
					{
						if ([findThis characterAtIndex:j]=='?')
						{
							if (i + j < [theSource length])
							{
								NSString* temp=[findThis substringToIndex:j];
								range.location=i+j;
								range.length=1;
								temp=[temp stringByAppendingString:[theSource substringWithRange:range]]; 
								findThis = [temp stringByAppendingString:[findThis substringFromIndex:j+1]];
							}
						}
					}
					if ((asterisk == 0) || (asterisklessLocation[asterisk - 1] == -1))
					{
						range.location=lastOccurance+1;
						range.length=[theSource length]-range.location;
						r=[theSource rangeOfString:findThis options:0 range:range].location;
						asterisklessLocation[asterisk]=(r!=NSNotFound?r:-1);
					}
					else
					{
						range.location=asterisklessLocation[asterisk - 1];
						range.length=[theSource length]-range.location;
						r=[theSource rangeOfString:findThis options:0 range:range].location;
						asterisklessLocation[asterisk]=(r!=NSNotFound?r:-1);
					}
					if (asterisklessLocation[asterisk] != -1)
					{
						i = [theSource length]; //stop
					}
				}
			}
			//now each int in asterisklessLocation should be in an acsending order (lowest first)
			//if they are not, then the string wasn't found in the source
			int last = -1;
			for (int i = 0; i < ct; i++)
			{
				if (asterisklessLocation[i] > last)
				{
					last = (int)asterisklessLocation[i];
				}
				else
				{
					lastOccurance = -1;
					i = ct; //stop
				}
			}
			if ((occ == 0) || (lastOccurance != -1))
			{
				if (ll > 0)
				{
					lastOccurance = (int)asterisklessLocation[0];
				}
				else
				{
					lastOccurance = -1;
				}
			}
		}
		[st release];
		free(asteriskless);
		free(asterisklessLocation);		
		return lastOccurance;
	}
	else
	{ //no wildcards
		NSInteger lastIndex = -1;
		for (int i = 0; i <= occurance; i++)
		{
			range.location=lastIndex+1;
			range.length=[theSource length]-range.location;
			r=[theSource rangeOfString:find options:0 range:range].location;
			lastIndex=(r!=NSNotFound?r:-1);
		}
		return (int)lastIndex;
	}
}

-(BOOL)substringMatches:(NSString*)s withParam1:(NSString*)find
{
	NSString* theSource = s;
	if (!caseSensitive)
	{
		theSource = [theSource lowercaseString];
		find = [find lowercaseString];
	}
	NSInteger i, j, r, ll;
	NSRange range;
	if (wildcards)
	{
		StringTokenizer* st =[[StringTokenizer alloc] initWithParams:find withParam1:@"*"];
		int ct = [st countTokens];
		NSString** asteriskless = (NSString**)calloc(ct, sizeof(NSString*));
		for (i = 0; i < ct; i++)
		{
			asteriskless[i] = [st nextToken];
		}
		NSInteger* asterisklessLocation = NULL;
		if(ct > 0)
			asterisklessLocation = (NSInteger*)calloc(ct, sizeof(NSInteger));
		ll=ct;
		for (int asterisk = 0; asterisk < ct; asterisk++)
		{
			for (i = 0; i < [theSource length]; i++)
			{
				NSString* findThis = asteriskless[asterisk];
				//replace "?" occurances with chars from source
				for (j = 0; j < [findThis length]; j++)
				{
					if ([findThis characterAtIndex:j]=='?')
					{
						if (i + j < [theSource length])
						{
							NSString* temp=[findThis substringToIndex:j];
							range.location=i+j;
							range.length=1;
							temp=[temp stringByAppendingString:[theSource substringWithRange:range]]; 
							findThis = [temp stringByAppendingString:[findThis substringFromIndex:j+1]];
						}
					}
				}
				if ((asterisk == 0) || (asterisklessLocation[asterisk - 1] == -1))
				{
					r=[theSource rangeOfString:findThis].location;
					asterisklessLocation[asterisk]=(r!=NSNotFound?r:-1);
				}
				else
				{
					range.location=asterisklessLocation[asterisk - 1];
					range.length=[theSource length]-range.location;
					r=[theSource rangeOfString:findThis options:0 range:range].location;
					asterisklessLocation[asterisk]=(r!=NSNotFound?r:-1);
				}
				if (asterisklessLocation[asterisk] != -1)
				{
					i = [theSource length]; //stop
				}
			}
		}
		//now each int in asterisklessLocation should be in an acsending order (lowest first)
		//if they are not, then the string wasn't found in the source
		NSInteger last = -1;
		BOOL ok = YES;
		for (int i = 0; i < ct; i++)
		{
			if (asterisklessLocation[i] > last)
			{
				last = asterisklessLocation[i];
			}
			else
			{
				i = ct; //stop
				ok = NO;
			}
		}
		[st release];
		if ((ok) && ([find length] > 0) && (ll > 0))
		{
			if ([self getSubstringIndex:theSource withParam1:find andParam2:1] == -1)
			{ //no other occurances
				if ([find characterAtIndex:0]=='*')
				{
					if ([find characterAtIndex:[find length]-1]=='*')
					{
						//if it starts with a * and ends with a *
						free(asteriskless);
						free(asterisklessLocation);		
						return YES;
					}
					else
					{
						//if last element is at the end of the source
						if (asterisklessLocation[ct - 1] + [asteriskless[ct - 1] length] == [theSource length])
						{
							free(asteriskless);
							free(asterisklessLocation);		
							return YES;
						}
					}
				}
				else
				{
					if (asterisklessLocation[0] == 0)
					{
						if ([find characterAtIndex:[find length]-1]=='*')
						{
							//if it starts with a * and ends with a *
							free(asteriskless);
							free(asterisklessLocation);		
							return YES;
						}
						else
						{
							//if last element is at the end of the source
							if (asterisklessLocation[ct - 1] + [asteriskless[ct - 1] length] == [theSource length])
							{
								free(asteriskless);
								free(asterisklessLocation);		
								return YES;
							}
						}
					}
				}
			}
		}
	}
	else
	{ //no wildcards
		if (([theSource length] == [find length]) && ([theSource rangeOfString:find].location==0))
		{
			return YES;
		}
	}
	return NO;
}

-(BOOL)isLetterOrDigit:(char)c
{
	if (c>='0' && c<='9')
		return YES;
	if (c>='a' && c<='z')
		return YES;
	if (c>='A' && c<='Z')
		return YES;
	return NO;
}

// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	if (num == CND_ISURLSAFE)
	{
		for (int index = 0; index < [source length]; index++)
		{
			while (![self isLetterOrDigit:[source characterAtIndex:index]])
			{
				if ([source characterAtIndex:index] == '+')
				{
					break;
				}
				else
				{
					if ([source characterAtIndex:index] == '%')
					{
						if ([source length] > index + 2)
						{
							if ([self isLetterOrDigit:[source characterAtIndex:index + 1]] && [self isLetterOrDigit:[source characterAtIndex:index + 2]])
							{
								index = index + 2;
							}
							else
							{
								return NO;
							}
							break;
						}
						else
						{
							return NO;
						}
					}
					else
					{
						return NO;
					}
				}
			}
		}
		return YES;
	}
	return NO;
}

// Actions
// -------------------------------------------------
-(void)SP_addDelim:(NSString*)delim
{
	if ([delim length]!=0)
	{
		BOOL exists = NO;
		for (int i = 0; i < [delims size]; i++)
		{
			NSString* thisDelim = (NSString*)[delims get:i];
			if ([self getSubstringIndex:thisDelim  withParam1:delim  andParam2:0] >= 0)
			{
				exists = YES;
			}
		}
		if (exists == NO)
		{
			[delims add:[[NSString alloc] initWithString:delim]];
			[self redoTokens];
			defaultDelim = delim;
		}
	}
}

-(void)SP_setDelim:(NSString*)delim withParam1:(int)index
{
	if ((index >= 0) && (index <= [delims size]))
	{
		if (index==[delims size])
		{
			[delims add:[[NSString alloc] initWithString:delim]];
		}
		else
		{
			[delims set:index object:[[NSString alloc] initWithString:delim]];
		}
		defaultDelim = delim;
		[self redoTokens];
	}
}


-(void)SP_deleteDelimIndex:(int)index
{
	if ((index >= 0) && (index < [delims size]))
	{
		[(NSString*)[delims get:index] release];
		[delims removeIndex:index];
		if (index < [delims size])
		{
			defaultDelim = (NSString*)[delims get:index];
		}
		else
		{
			defaultDelim = nil;
		}
		[self redoTokens];
	}
}

-(void)SP_deleteDelim:(NSString*)delim
{
	for (int i = 0; i < [delims size]; i++)
	{
		if ( [ ((NSString*)[delims get:i]) compare:delim]==0 )
		{
			[(NSString*)[delims get:i] release];
			[delims removeIndex:i];
			if (i < [delims size])
			{
				defaultDelim = (NSString*)[delims get:i];
			}
			else
			{
				defaultDelim = nil;
			}
			[self redoTokens];
			return;
		}
	}
}

-(void)SP_setDefDelimIndex:(int)index
{
	if ((index >= 0) && (index < [delims size]))
	{
		defaultDelim = (NSString*)[delims get:index];
	}
}

-(void)SP_setDefDelim:(NSString*)delim
{
	for (int i = 0; i < [delims size]; i++)
	{
		if ( [ ((NSString*)[delims get:i]) compare:delim]==0 )
		{
			defaultDelim = (NSString*)[delims get:i];
			return;
		}
	}
}


-(void)SP_saveToFile:(NSString*)filename
{
	NSString* path = [rh->rhApp getPathForWriting:filename];
	[source writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
}

-(void)SP_loadFromFile:(NSString*)filename
{
	if(source != nil)
		[source release];
	NSData* stringData = [rh->rhApp loadResourceData:filename];
	if(stringData != nil)
	{
		NSString* guessed = [rh->rhApp stringGuessingEncoding:stringData];
		if(guessed != nil)
			source = [guessed retain];
	}
}

-(void)SP_appendToFile:(NSString*)filename
{
	NSString* path = [rh->rhApp getPathForWriting:filename];
	NSOutputStream* os = [NSOutputStream outputStreamToFileAtPath:path append:YES];
	if(os == nil)
	{
		[self SP_saveToFile:filename];
		return;
	}

	NSData* data = [source dataUsingEncoding:NSUTF8StringEncoding];
	[os open];
	[os write:(const u_int8_t*)[data bytes] maxLength:[data length]];
	[os close];
}

-(void)SP_appendFromFile:(NSString*)filename
{
	NSData* stringData = [rh->rhApp loadResourceData:filename];
	if(stringData == nil)
		return;

	NSString* guessed = [rh->rhApp stringGuessingEncoding:stringData];
	if(guessed != nil)
	{
		NSString* newSource = [[NSString alloc] initWithFormat:@"%@%@", source, guessed];
		if(source != nil)
			[source release];
		source = newSource;
	}
}


-(void)SP_saveAsCSV:(NSString*)filename
{
	NSLog(@"String Parser: Save as CSV - Not yet implemented.");
}

-(void)SP_loadFromCSV:(NSString*)filename
{
	NSLog(@"String Parser: Load from CSV - Not yet implemented.");
}

-(void)SP_saveAsMMFArray:(NSString*)filename
{
	NSLog(@"String Parser: Save as MMF array - Not yet implemented.");
}

-(void)SP_loadFromMMFArray:(NSString*)filename
{
	NSLog(@"String Parser: Load from MMF array - Not yet implemented.");
}

-(void)SP_saveAsDynamicArray:(NSString*)filename
{
	NSLog(@"String Parser: Save as 3EE dynamic array - Not yet implemented.");
}

-(void)SP_loadFromDynamicArray:(NSString*)filename
{
	NSLog(@"String Parser: Load from 3EE dynamic array - Not yet implemented.");
}



-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_SETSTRING:
			source = [[NSString alloc] initWithString:[act getParamExpString:rh withNum:0]];
			[self redoTokens];
			break;
		case ACT_SAVETOFILE:
			[self SP_saveToFile:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_LOADFROMFILE:
			[self SP_loadFromFile:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_APPENDTOFILE:
			[self SP_appendToFile:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_APPENDFROMFILE:
			[self SP_appendFromFile:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_RESETDELIMS:
			[delims clearRelease];
			break;
		case ACT_ADDDELIM:
			[self SP_addDelim:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_SETDELIM:
			[self SP_setDelim:[act getParamExpString:rh withNum:0]  withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case ACT_DELETEDELIMINDEX:
			[self SP_deleteDelimIndex:[act getParamExpression:rh withNum:0]];
		case ACT_DELETEDELIM:
			[self SP_deleteDelim:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_SETDEFDELIMINDEX:
			[self SP_setDefDelimIndex:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETDEFDELIM:
			[self SP_setDefDelim:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_SAVEASCSV:
			[self SP_saveAsCSV:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_LOADFROMCSV:
			[self SP_loadFromCSV:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_SAVEASMMFARRAY:
			[self SP_saveAsMMFArray:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_LOADFROMMMFARRAY:
			[self SP_loadFromMMFArray:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_SAVEASDYNAMICARRAY:
			[self SP_saveAsDynamicArray:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_LOADFROMDYNAMICARRAY:
			[self SP_loadFromDynamicArray:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_CASEINSENSITIVE:
			caseSensitive = NO;
			[self redoTokens];
			break;
		case ACT_CASESENSITIVE:
			caseSensitive = YES;
			[self redoTokens];
			break;
		case ACT_SEARCHLITERAL:
			wildcards = NO;
			[self redoTokens];
			break;
		case ACT_SEARCHWILDCARDS:
			wildcards = YES;
			[self redoTokens];
			break;
		case ACT_SAVEASINI:
//			[self SP_saveAsINI:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_LOADFROMINI:
//			[self SP_loadFromINI:[act getParamExpString:rh withNum:0]];
			break;
	}
}

// Expressions
// --------------------------------------------
-(CValue*)essai
{
	return nil;
}
-(CValue*)SP_left:(int)i
{
	CValue* ret;
	if ((i >= 0) && i <= [source length])
	{
		ret=[rh getTempValue:0];
		[ret forceString:[source substringToIndex:i]];
		return ret;
	}
	ret=[rh getTempValue:0];
	[ret forceString:@""];
	return ret;
}

-(CValue*)SP_right:(int)i
{
	CValue* ret;
	if ((i >= 0) && (i <= [source length]))
	{
		ret=[rh getTempValue:0];
		[ret forceString:[source substringFromIndex:[source length]-i]];
		return ret;
	}
	ret=[rh getTempValue:0];
	[ret forceString:@""];
	return ret;
}

-(CValue*)SP_middle
{
	CValue* ret;
	int i=[[ho getExpParam] getInt];
	int length=[[ho getExpParam] getInt];
	length = MAX(0, length);
	if ((i >= 0) && (i + length <= [source length]))
	{
		NSRange range;
		range.location=i;
		range.length=length;
		ret=[rh getTempValue:0];
		[ret forceString:[source substringWithRange:range]];
		return ret;
	}
	ret=[rh getTempValue:0];
	[ret forceString:@""];
	return ret;
}

-(CValue*)SP_numberOfSubs:(NSString*)sub
{
	int count = 0;
	while ([self getSubstringIndex:source  withParam1:sub  andParam2:count] != -1)
	{
		count++;
	}
	return [rh getTempValue:count];
}

-(CValue*)SP_indexOfSub
{ //1-based
	NSString* sub=[[ho getExpParam] getString];
	int occurance=[[ho getExpParam] getInt];
	occurance = MAX(1,occurance);
	return [rh getTempValue:[self getSubstringIndex:source  withParam1:sub  andParam2:occurance - 1]];
}

-(CValue*)SP_indexOfFirstSub:(NSString*)sub
{
	return [rh getTempValue:[self getSubstringIndex:source  withParam1:sub  andParam2:0]];
}

-(CValue*)SP_indexOfLastSub:(NSString*)sub
{
	int n = MAX(1, [[self SP_numberOfSubs:sub] getInt]);
	return [rh getTempValue:[self getSubstringIndex:source  withParam1:sub  andParam2:n - 1]];
}

-(CValue*)SP_remove:(NSString*)sub
{
	CValue* ret;
	int count = 0;
	CArrayList* parts = [[CArrayList alloc] init]; //Integer
	int index = [self getSubstringIndex:source  withParam1:sub  andParam2:count];
	while (index != -1)
	{
		[parts addInt:index];
		count++;
		index = [self getSubstringIndex:source  withParam1:sub  andParam2:count];
	}
	if ([parts size] == 0)
	{
		[parts release];
		ret=[rh getTempValue:0];
		[ret forceString:source];
		return ret;
	}
	NSInteger last = 0;
	NSString* r = @"";
	NSRange range;
	for (int i = 0; i < [parts size]; i++)
	{
		range.location=last;
		range.length=[parts getInt:i]-last;
		r = [r stringByAppendingString:[source substringWithRange:range]];
		last = [parts getInt:i]+[sub length];
		if (i == [parts size] - 1)
		{
			r = [r stringByAppendingString:[source substringFromIndex:last]];
		}
	}
	[parts release];
	ret=[rh getTempValue:0];
	[ret forceString:r];
	return ret;
}
			  
-(CValue*)SP_replace
{
	CValue* ret;

	NSString* old=[[ho getExpParam] getString];
	NSString* newString=[[ho getExpParam] getString];
	int count = 0;
	CArrayList* parts = [[CArrayList alloc] init]; //Integer
	int index = [self getSubstringIndex:source  withParam1:old  andParam2:count];
	while (index != -1)
	{
		[parts addInt:index];
		count++;
		index = [self getSubstringIndex:source  withParam1:old  andParam2:count];
	}
	if ([parts size] == 0)
	{
		[parts release];
		ret=[rh getTempValue:0];
		[ret forceString:source];
		return ret;
	}
	NSInteger last = 0;
	NSString* r = @"";
	NSRange range;
	for (int i = 0; i < [parts size]; i++)
	{
		range.location=last;
		range.length=[parts getInt:i]-last;
		r = [r stringByAppendingString:[source substringWithRange:range]];
		r=[r stringByAppendingString:newString];
		last = [parts getInt:i]+[old length];
		if (i == [parts size] - 1)
		{
			r = [r stringByAppendingString:[source substringFromIndex:last]];
		}
	}
	[parts release];
	ret=[rh getTempValue:0];
	[ret forceString:r];
	return ret;
}

-(CValue*)SP_insert
{
	CValue* ret;
	NSString* insert=[[ho getExpParam] getString];
	int index=[[ho getExpParam] getInt];
	
	if ((index >= 1) && (index <= [source length]))
	{
		NSString* r=[source substringToIndex:index - 1];
		r=[r stringByAppendingString:insert];
		r=[r stringByAppendingString:[source substringFromIndex:index - 1]];
		ret=[rh getTempValue:0];
		[ret forceString:r];
		return ret;
	}
	ret=[rh getTempValue:0];
	[ret forceString:@""];
	return ret;
}

-(CValue*)SP_reverse
{
	CValue* ret;
	NSString* r = @"";
	NSRange range;
	for (NSInteger i = [source length] - 1; i >= 0; i--)
	{
		range.location=i;
		range.length=1;
		r = [r stringByAppendingString:[source substringWithRange:range]];
	}
	ret=[rh getTempValue:0];
	[ret forceString:r];
	return ret;
}

-(CValue*)SP_urlEncode
{
	CValue* ret;
	NSString* r = @"";
	NSRange range;
	for (int i = 0; i < [source length]; i++)
	{
		if ([self isLetterOrDigit:[source characterAtIndex:i]])
		{
			range.location=i;
			range.length=1;
			r = [r stringByAppendingString:[source substringWithRange:range]];
		}
		else
		{
			if ([source characterAtIndex:i]==' ')
			{
				r = [r stringByAppendingString:@"+"];
			}
			else
			{
				if ([source characterAtIndex:i]==13)
				{
					r = [r stringByAppendingString:@"+"];
					i++;
				}
				else
				{
					r = [r stringByAppendingString:@"%"];
					r=[r stringByAppendingString:[NSString stringWithFormat:@"%lX", (unsigned long)(i>>4)]];
					r=[r stringByAppendingString:[NSString stringWithFormat:@"%lX", (unsigned long)(i%16)]];
				}
			}
		}
	}
	ret=[rh getTempValue:0];
	[ret forceString:r];
	return ret;
}

-(CValue*)SP_chr:(int)value
{
	CValue* ret;
	unichar buffer[1];
	buffer[0]=value;
	ret=[rh getTempValue:0];
	[ret forceString:[NSString stringWithCharacters:buffer length:1]];
	return ret;
}
-(CValue*)SP_asc:(NSString*)value
{
	if ([value length] > 0)
	{
		return [rh getTempValue:[value characterAtIndex:0]];
	}			
	return [rh getTempValue:0];
}

-(CValue*)SP_ascList:(NSString*)delim
{
	CValue* ret;
	NSString* r = @"";
	for (int i = 0; i < [source length]; i++)
	{
		r=[r stringByAppendingString:[NSString stringWithFormat:@"%i", [source characterAtIndex:i]]];
		if (i < [source length] - 1)
		{
			r=[r stringByAppendingString:delim];
		}
	}
	ret=[rh getTempValue:0];
	[ret forceString:r];
	return ret;
}

-(CValue*)SP_getDelim:(int)i
{ //0-based, silly 3ee
	CValue* ret;
	if ((i >= 0) && (i < [delims size]))
	{
		ret=[rh getTempValue:0];
		[ret forceString:(NSString*)[delims get:i]];
		return ret;
	}
	ret=[rh getTempValue:0];
	[ret forceString:@""];
	return ret;
}

-(CValue*)SP_getDelimIndex:(NSString*)delim
{
	for (int i = 0; i < [delims size]; i++)
	{
		NSString* thisDelim = (NSString*)[delims get:i];
		if ([self getSubstringIndex:thisDelim  withParam1:delim  andParam2:0] >= 0)
		{
			return [rh getTempValue:i];
		}
	}
	return [rh getTempValue:-1];
}

-(CValue*)SP_getDefDelim
{
	CValue* ret;
	if (defaultDelim != nil)
	{
		ret=[rh getTempValue:0];
		[ret forceString:defaultDelim];
		return ret;
	}
	ret=[rh getTempValue:0];
	[ret forceString:@""];
	return ret;
}

-(CValue*)SP_getDefDelimIndex
{
	if (defaultDelim != nil)
	{
		for (int i = 0; i < [delims size]; i++)
		{
			NSString* thisDelim = (NSString*)[delims get:i];
			if ([self getSubstringIndex:thisDelim  withParam1:defaultDelim  andParam2:0] >= 0)
			{
				return [rh getTempValue:i];
			}
		}
	}
	return [rh getTempValue:-1];
}

-(CValue*)SP_listSetAt
{ //1-based
	NSString* replace=[[ho getExpParam] getString];
	int index=[[ho getExpParam] getInt];
	CValue* ret;
	if ((index >= 1) && (index <= [tokensE size]))
	{
		parserElement* e = (parserElement*)[tokensE get:index - 1];
		NSString* r = [source substringToIndex:e->index];
		r=[r stringByAppendingString:replace];
		r=[r stringByAppendingString:[source substringFromIndex:e->endIndex]];
		ret=[rh getTempValue:0];
		[ret forceString:r];
		return ret;
	}
	ret=[rh getTempValue:0];
	[ret forceString:@""];
	return ret;
}

-(CValue*)SP_listInsertAt
{ //1-based
	NSString* insert=[[ho getExpParam] getString];
	int index=[[ho getExpParam] getInt];

	CValue* ret;
	if ((index >= 1) && (index <= [tokensE size]))
	{
		parserElement* e = (parserElement*)[tokensE get:index - 1];
		NSString* r = [source substringToIndex:e->index];
		r=[r stringByAppendingString:insert];
		r=[r stringByAppendingString:[source substringFromIndex:e->index]];
		ret=[rh getTempValue:0];
		[ret forceString:r];
		return ret;
	}
	ret=[rh getTempValue:0];
	[ret forceString:@""];
	return ret;
}

-(CValue*)SP_listGetAt:(int)index
{ //1-based
	CValue* ret;

	if ((index >= 1) && (index <= [tokensE size]))
	{
		parserElement* e = (parserElement*)[tokensE get:index - 1];
		ret=[rh getTempValue:0];
		[ret forceString:e->text];
		return ret;
	}
	ret=[rh getTempValue:0];
	[ret forceString:@""];
	return ret;
}

-(CValue*)SP_listFirst
{
	CValue* ret;

	if ([tokensE size] > 0)
	{
		parserElement* e = (parserElement*)[tokensE get:0];
		ret=[rh getTempValue:0];
		[ret forceString:e->text];
		return ret;
	}
	ret=[rh getTempValue:0];
	[ret forceString:@""];
	return ret;
}

-(CValue*)SP_listLast
{
	CValue* ret;

	if ([tokensE size] > 0)
	{
		parserElement* e = (parserElement*)[tokensE get:[tokensE size]-1];
		ret=[rh getTempValue:0];
		[ret forceString:e->text];
		return ret;
	}
	ret=[rh getTempValue:0];
	[ret forceString:@""];
	return ret;
}

-(CValue*)SP_listFind
{ //matching //1-based
	NSString* find=[[ho getExpParam] getString];
	int occurance=[[ho getExpParam] getInt];

	if ((occurance > 0) && [find length] > 0)
	{
		int occuranceCount = 0;
		for (int i = 0; i < [tokensE size]; i++)
		{
			parserElement* e = (parserElement*)[tokensE get:i];
			if ([self substringMatches:e->text  withParam1:find])
			{
				occuranceCount++;
			}
			if (occuranceCount == occurance)
			{
				return [rh getTempValue:i + 1];
			}
		}
	}
	return [rh getTempValue:0];
}

-(CValue*)SP_listContains
{ //matching //1-based
	NSString* find=[[ho getExpParam] getString];
	int occurance=[[ho getExpParam] getInt];

	if ((occurance > 0) && [find length] > 0)
	{
		int occuranceCount = 0;
		for (int i = 0; i < [tokensE size]; i++)
		{
			parserElement* e = (parserElement*)[tokensE get:i];
			if ([self getSubstringIndex:e->text  withParam1:find  andParam2:0] != -1)
			{
				occuranceCount++;
			}
			if (occuranceCount == occurance)
			{
				return [rh getTempValue:i + 1];
			}
		}
	}
	return [rh getTempValue:0];
}

-(CValue*)SP_listDeleteAt:(int)index
{ //1-based
	CValue* ret;

	if ((index >= 1) && (index <= [tokensE size]))
	{
		parserElement* e = (parserElement*)[tokensE get:index-1];
		NSString* r = [source substringToIndex:e->index];
		r=[r stringByAppendingString:[source substringFromIndex:e->endIndex]];
		ret=[rh getTempValue:0];
		[ret forceString:r];
		return ret;
	}
	ret=[rh getTempValue:0];
	[ret forceString:@""];
	return ret;
}

-(CValue*)SP_listSwap
{ //1-based
	int i1=[[ho getExpParam] getInt];
	int i2=[[ho getExpParam] getInt];
	NSRange range;
	CValue* ret;

	if ((i1 >= 1) && (i2 >= 1) && (i1 <= [tokensE size]) && (i2 <= [tokensE size]))
	{
		if (i1 == i2)
		{
			ret=[rh getTempValue:0];
			[ret forceString:source];
			return ret;
		}
		parserElement* e1 = (parserElement*)[tokensE get:i1-1];
		parserElement* e2= (parserElement*)[tokensE get:i2-1];
		NSString* r = @"";
		if (i1 > i2)
		{
			//e2 comes sooner
			r = [r stringByAppendingString:[source substringToIndex:e2->index]];
			range.location=e1->index;
			range.length=e1->endIndex-range.location;
			r = [r stringByAppendingString:[source substringWithRange:range]];
			range.location=e2->endIndex;
			range.length=e1->index-range.location;
			r = [r stringByAppendingString:[source substringWithRange:range]];
			range.location=e2->index;
			range.length=e2->endIndex-range.location;
			r = [r stringByAppendingString:[source substringWithRange:range]];
			r = [r stringByAppendingString:[source substringFromIndex:e1->endIndex]];
		}
		else
		{ //i1 < i2
			//e1 comes sooner
			r = [r stringByAppendingString:[source substringToIndex:e1->index]];
			range.location=e2->index;
			range.length=e2->endIndex-range.location;
			r = [r stringByAppendingString:[source substringWithRange:range]];
			range.location=e1->endIndex;
			range.length=e2->index-range.location;
			r = [r stringByAppendingString:[source substringWithRange:range]];
			range.location=e1->index;
			range.length=e1->endIndex-range.location;
			r = [r stringByAppendingString:[source substringWithRange:range]];
			r = [r stringByAppendingString:[source substringFromIndex:e2->endIndex]];
		}
		ret=[rh getTempValue:0];
		[ret forceString:r];
		return ret;
	}
	ret=[rh getTempValue:0];
	[ret forceString:@""];
	return ret;
}

-(CValue*)SP_listSortAsc
{
	CArrayList* sorted = [[CArrayList alloc] init]; //parserElement
	for (int i = 0; i < [tokensE size]; i++)
	{
		parserElement* e = (parserElement*)[tokensE get:i];
		if ([sorted size] == 0)
		{
			[sorted add:e];
		}
		else
		{
			int index = 0;
			for (int j = 0; j < [sorted size]; j++)
			{
				parserElement* element = (parserElement*)[tokensE get:j];
				if (caseSensitive)
				{
					if ([e->text compare:element->text] >= 0)
					{
						index = j;
					}
				}
				else
				{
					if ([e->text caseInsensitiveCompare:element->text] >= 0)
					{
						index = j;
					}
				}
			}
			[sorted addIndex:index object:e];
		}
	}
	NSString* r = @"";
	NSRange range;
	CValue* ret;
	for (int i = 0; i < [sorted size]; i++)
	{
		parserElement* e = (parserElement*)[sorted get:i];
		parserElement* oe = (parserElement*)[tokensE get:i];
		if (i == 0)
		{
			r = [r stringByAppendingString:[source substringToIndex:oe->index]];
		}
		else
		{
			parserElement* lastOrigE = (parserElement*)[tokensE get:i-1];
			range.location=lastOrigE->endIndex;
			range.length=oe->index-range.location;
			r = [r stringByAppendingString:[source substringWithRange:range]];
		}
		range.location=e->index;
		range.length=e->endIndex-range.location;
		r = [r stringByAppendingString:[source substringWithRange:range]];
		if (i == [sorted size] - 1)
		{
			r = [r stringByAppendingString:[source substringFromIndex:oe->endIndex]];
		}
	}
	[sorted release];
	ret=[rh getTempValue:0];
	[ret forceString:r];
	return ret;
}

-(CValue*)SP_listSortDesc
{
	CArrayList* sorted = [[CArrayList alloc] init]; //parserElement
	for (int i = 0; i < [tokensE size]; i++)
	{
		parserElement* e = (parserElement*)[tokensE get:i];
		if ([sorted size] == 0)
		{
			[sorted add:e];
		}
		else
		{
			int index = [sorted size];
			for (int j = [sorted size] - 1; j >= 0; j--)
			{
				parserElement* element = (parserElement*)[tokensE get:j];
				if (caseSensitive)
				{
					if ([e->text compare:element->text] >= 0)
					{
						index = j;
					}
				}
				else
				{
					if ([e->text caseInsensitiveCompare:element->text] >= 0)
					{
						index = j;
					}
				}
			}
			[sorted addIndex:index object:e];
		}
	}
	NSString* r = @"";
	CValue* ret;
	NSRange range;
	for (int i = 0; i < [sorted size]; i++)
	{
		parserElement* e = (parserElement*)[sorted get:i];
		parserElement* oe = (parserElement*)[tokensE get:i];
		if (i == 0)
		{
			r = [r stringByAppendingString:[source substringToIndex:oe->index]];
		}
		else
		{
			parserElement* lastOrigE = (parserElement*)[tokensE get:i-1];
			range.location=lastOrigE->endIndex;
			range.length=oe->index-range.location;
			r = [r stringByAppendingString:[source substringWithRange:range]];
		}
		range.location=e->index;
		range.length=e->endIndex-range.location;
		r = [r stringByAppendingString:[source substringWithRange:range]];
		if (i == [sorted size] - 1)
		{
			r = [r stringByAppendingString:[source substringFromIndex:oe->endIndex]];
		}
	}
	[sorted release];
	ret=[rh getTempValue:0];
	[ret forceString:r];
	return ret;
}

-(CValue*)SP_listChangeDelims:(NSString*)changeDelim
{
	CValue* ret;

	if (defaultDelim != nil)
	{
		NSString* r = @"";
		NSRange range;
		for (int i = 0; i < [tokensE size]; i++)
		{
			parserElement* e = (parserElement*)[tokensE get:i];
			NSInteger here = e->index - [defaultDelim length];
			range.location=here;
			range.length=e->index-range.location;
			NSString* temp=[source substringWithRange:range];
			if ((here >= 0) && ([temp compare:defaultDelim]==0))
			{
				r = [r stringByAppendingString:changeDelim];
			}
			else
			{
				if (i == 0)
				{
					r = [r stringByAppendingString:[source substringToIndex:e->index]];
				}
				else
				{
					parserElement* lastOrigE = (parserElement*)[tokensE get:i-1];
					range.location=lastOrigE->endIndex;
					range.length=e->index-range.location;
					r = [r stringByAppendingString:[source substringWithRange:range]];
				}
			}
			range.location=e->index;
			range.length=e->endIndex-range.location;
			r = [r stringByAppendingString:[source substringWithRange:range]];
			if (i == [tokensE size] - 1)
			{
				if ([[source substringFromIndex:e->endIndex] compare:defaultDelim] ==0)
				{
					r = [r stringByAppendingString:changeDelim];
				}
				else
				{
					r = [r stringByAppendingString:[source substringFromIndex:e->endIndex]];
				}
			}
		}
		ret=[rh getTempValue:0];
		[ret forceString:r];
		return ret;
	}
	ret=[rh getTempValue:0];
	[ret forceString:@""];
	return ret;
}

-(CValue*)SP_setStringEXP:(NSString*)newSource
{
	CValue* ret;

	[source release];
	source = newSource;
	[self redoTokens];
	ret=[rh getTempValue:0];
	[ret forceString:@""];
	return ret;
}

-(CValue*)SP_setValueEXP:(NSString*)newSource
{
	[source release];
	source = newSource;
	[self redoTokens];
	return [rh getTempValue:0];
}

-(CValue*)SP_getMD5
{
	return [rh getTempString:[source md5]];
}

-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_GETSTRING:
			return [rh getTempString:source];
		case EXP_GETLENGTH:
			return [rh getTempValue:(int)[source length]];
		case EXP_EXTLEFT:
			return [self SP_left:[[ho getExpParam] getInt]];
		case EXP_EXTRIGHT:
			return [self SP_right:[[ho getExpParam] getInt]];
		case EXP_EXTMIDDLE:
			return [self SP_middle];
		case EXP_NUMBEROFSUBS:
			return [self SP_numberOfSubs:[[ho getExpParam] getString]];
		case EXP_INDEXOFSUB:
			return [self SP_indexOfSub];
		case EXP_INDEXOFFIRSTSUB:
			return [self SP_indexOfFirstSub:[[ho getExpParam] getString]];
		case EXP_INDEXOFLASTSUB:
			return [self SP_indexOfLastSub:[[ho getExpParam] getString]];
		case EXP_REMOVE:
			return [self SP_remove:[[ho getExpParam] getString]];
		case EXP_REPLACE:
			return [self SP_replace];
		case EXP_INSERT:
			return [self SP_insert];
		case EXP_REVERSE:
			return [self SP_reverse];
		case EXP_UPPERCASE:
			return [rh getTempString:[source uppercaseString]];
		case EXP_LOWERCASE:
			return [rh getTempString:[source lowercaseString]];
		case EXP_URLENCODE:
			return [self SP_urlEncode];
		case EXP_CHR:
			return [self SP_chr:[[ho getExpParam] getInt]];
		case EXP_ASC:
			return [self SP_asc:[[ho getExpParam] getString]];
		case EXP_ASCLIST:
			return [self SP_ascList:[[ho getExpParam] getString]];
		case EXP_NUMBEROFDELIMS:
			return [rh getTempValue:[delims size]];
		case EXP_GETDELIM:
			return [self SP_getDelim:[[ho getExpParam] getInt]];
		case EXP_GETDELIMINDEX:
			return [self SP_getDelimIndex:[[ho getExpParam] getString]];
		case EXP_GETDEFDELIM:
			return [self SP_getDefDelim];
		case EXP_GETDEFDELIMINDEX:
			return [self SP_getDefDelimIndex];
		case EXP_LISTCOUNT:
			return [rh getTempValue:[tokensE size]];
		case EXP_LISTSETAT:
			return [self SP_listSetAt];
		case EXP_LISTINSERTAT:
			return [self SP_listInsertAt];
		case EXP_LISTAPPEND:
			return [rh getTempString:[source stringByAppendingString:[[ho getExpParam] getString]]];
		case EXP_LISTPREPEND:
			return [rh getTempString:[[[ho getExpParam] getString] stringByAppendingString:source]];
		case EXP_LISTGETAT:
			return [self SP_listGetAt:[[ho getExpParam] getInt]];
		case EXP_LISTFIRST:
			return [self SP_listFirst];
		case EXP_LISTLAST:
			return [self SP_listLast];
		case EXP_LISTFIND: //matching
			return [self SP_listFind];
		case EXP_LISTCONTAINS:
			return [self SP_listContains];
		case EXP_LISTDELETEAT:
			return [self SP_listDeleteAt:[[ho getExpParam] getInt]];
		case EXP_LISTSWAP:
			return [self SP_listSwap];
		case EXP_LISTSORTASC:
			return [self SP_listSortAsc];
		case EXP_LISTSORTDESC:
			return [self SP_listSortDesc];
		case EXP_LISTCHANGEDELIMS:
			return [self SP_listChangeDelims:[[ho getExpParam] getString]];
		case EXP_SETSTRING:
			return [self SP_setStringEXP:[[ho getExpParam] getString]];
		case EXP_SETVALUE:
			return [self SP_setValueEXP:[[ho getExpParam] getString]];
		case EXP_GETMD5:
			return [self SP_getMD5];
	}
	return [rh getTempValue:0];//won't be used
}


@end



@implementation StringTokenizer

-(id)initWithParams:(NSString*)source withParam1:(NSString*)delim
{
	array=[source componentsSeparatedByString:delim];
	[array retain];
	count=0;
	return self;
}
-(void)dealloc
{
	[array release];
	[super dealloc];
}
-(int)countTokens
{
	return (int)[array count];
}
-(NSString*)nextToken
{
	return (NSString*)[array  objectAtIndex:count++];
}
@end

@implementation parserElement

-(void)setValues:(NSString*)t withParam1:(int)i
{
	text=[[NSString alloc] initWithString:t];
	index = i;
	endIndex = (int)(index + [text length]);
}
-(id)initWithElement:(parserElement*)element
{
	if(self = [super init])
	{
		text=[[NSString alloc] initWithString:element->text];
		index = element->index;
		endIndex = element->endIndex;
	}
	return self;
}
-(void)dealloc
{
	[text release];
	[super dealloc];
}

@end
