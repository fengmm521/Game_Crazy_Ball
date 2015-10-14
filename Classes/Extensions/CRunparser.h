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
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CArrayList;

@interface CRunparser : CRunExtension
{
    NSString* source;
    BOOL caseSensitive;
    BOOL wildcards;
    CArrayList* delims; //Strings
    NSString* defaultDelim;
    CArrayList* tokensE; //parserElement	
}
-(int)getSubstringIndex:(NSString*)source withParam1:(NSString*)find andParam2:(int)occurance;
-(void)redoTokens;
-(BOOL)substringMatches:(NSString*)source withParam1:(NSString*)find;

-(void)SP_saveToFile:(NSString*)filename;
-(void)SP_loadFromFile:(NSString*)filename;
-(void)SP_appendToFile:(NSString*)filename;
-(void)SP_appendFromFile:(NSString*)filename;

-(void)SP_saveAsCSV:(NSString*)filename;
-(void)SP_loadFromCSV:(NSString*)filename;
-(void)SP_saveAsMMFArray:(NSString*)filename;
-(void)SP_loadFromMMFArray:(NSString*)filename;
-(void)SP_saveAsDynamicArray:(NSString*)filename;
-(void)SP_loadFromDynamicArray:(NSString*)filename;


@end

@interface StringTokenizer : NSObject
{
	NSArray* array;
	int count;
}	
-(id)initWithParams:(NSString*)s withParam1:(NSString*)d;
-(void)dealloc;
-(int)countTokens;
-(NSString*)nextToken;
@end

@interface parserElement : NSObject
{
@public
	NSString* text;
	int index;
	int endIndex;
}	
-(id)initWithElement:(parserElement*)element;
-(void)setValues:(NSString*)t withParam1:(int)i;
-(void)dealloc;
@end
