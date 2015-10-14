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
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CCreateObjectInfo;
@class CRun;
@class CBitmap;
@class CFile;

#define EXP_INT_INT 0
#define EXP_INT_STRING 1
#define EXP_INT_FLOAT 2
#define EXP_STRING_INT 3
#define EXP_STRING_STRING 4
#define EXP_STRING_FLOAT 5
#define EXP_FLOAT_INT 6
#define EXP_FLOAT_STRING 7
#define EXP_FLOAT_FLOAT 8
#define EXP_INT_BOOL 9
#define EXP_STRING_BOOL 10
#define EXP_FLOAT_BOOL 11
#define EXP_BOOL_INT 12
#define EXP_BOOL_STRING 13
#define EXP_BOOL_FLOAT 14
#define EXP_LAST_COMP 15

@interface CRunIIF : CRunExtension 
{
	BOOL Last;
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(int)handleRunObject;
-(void)displayRunObject:(CRenderer*)renderer;
-(CValue*)expression:(int)num;
-(CValue*)IntInt;
-(CValue*)IntString;
-(CValue*)IntFloat;
-(CValue*)StringInt;
-(CValue*)StringString;
-(CValue*)StringFloat;
-(CValue*)FloatInt;
-(CValue*)FloatString;
-(CValue*)FloatFloat;
-(CValue*)IntBool;
-(CValue*)StringBool;
-(CValue*)FloatBool;
-(CValue*)BoolInt;
-(CValue*)BoolString;
-(CValue*)BoolFloat;
-(CValue*)LastComp;
-(BOOL)CompareInts:(int)p1 withParam1:(NSString*)comp andParam2:(int)p2;
-(BOOL)CompareStrings:(NSString*)p1 withParam1:(NSString*)comp andParam2:(NSString*)p2;
-(BOOL)CompareFloats:(double)p1 withParam1:(NSString*)comp andParam2:(double)p2;

@end
