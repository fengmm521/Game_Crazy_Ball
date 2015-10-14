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
// CRunKcArray: array object
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"
#import "CExtStorage.h"

#define ARRAY_GLOBAL 0x0008
#define CND_INDEXAEND 0
#define CND_INDEXBEND 1
#define CND_INDEXCEND 2
#define	ARRAY_TYPENUM 0x0001
#define	ARRAY_TYPETXT 0x0002
#define	INDEX_BASE1 0x0004

#define ACT_SETINDEXA 0
#define ACT_SETINDEXB 1
#define ACT_SETINDEXC 2
#define ACT_ADDINDEXA 3
#define ACT_ADDINDEXB 4
#define ACT_ADDINDEXC 5
#define ACT_WRITEVALUE 6
#define ACT_WRITESTRING 7
#define ACT_CLEARARRAY 8
#define ACT_LOAD 9
#define ACT_LOADSELECTOR 10
#define ACT_SAVE 11
#define ACT_SAVESELECTOR 12
#define ACT_WRITEVALUE_X 13
#define ACT_WRITEVALUE_XY 14
#define ACT_WRITEVALUE_XYZ 15
#define ACT_WRITESTRING_X 16
#define ACT_WRITESTRING_XY 17
#define ACT_WRITESTRING_XYZ 18

#define ARRAY_TYPENUM 0x0001
#define ARRAY_TYPETXT 0x0002
#define INDEX_BASE1 0x0004

#define EXP_INDEXA 0
#define EXP_INDEXB 1
#define EXP_INDEXC 2
#define EXP_READVALUE 3
#define EXP_READSTRING 4
#define EXP_READVALUE_X 5
#define EXP_READVALUE_XY 6
#define EXP_READVALUE_XYZ 7
#define EXP_READSTRING_X 8
#define EXP_READSTRING_XY 9
#define EXP_READSTRING_XYZ 10
#define EXP_DIMX 11
#define EXP_DIMY 12
#define EXP_DIMZ 13

@class KcArrayData;
@class CArrayList;

@interface CRunKcArray : CRunExtension
{
@public
    KcArrayData*         pArray;	
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(int)handleRunObject;
-(void)destroyRunObject:(BOOL)bFast;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(BOOL)EndIndexA;
-(BOOL)EndIndexB;
-(BOOL)EndIndexC;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(void)SetIndexA:(int)i;
-(void)SetIndexB:(int)i;
-(void)SetIndexC:(int)i;
-(void)IncIndexA;
-(void)IncIndexB;
-(void)IncIndexC;
-(void)WriteValue:(int)value;
-(void)WriteString:(NSString*)value;
-(void)ClearArray;
-(void)WriteValue_X:(int)value withX:(int)x;
-(void)WriteValue_XY:(int)value withX:(int)x andY:(int)y;
-(void)WriteValue_XYZ:(int)value withX:(int)x andY:(int)y andZ:(int)z;
-(void)WriteValueXYZ:(int)value withX:(int)x andY:(int)y andZ:(int)z;
-(void)WriteString_X:(NSString*)value withX:(int)x;
-(void)WriteString_XY:(NSString*)value withX:(int)x andY:(int)y;
-(void)WriteString_XYZ:(NSString*)value withX:(int)x andY:(int)y andZ:(int)z;
-(void)WriteStringXYZ:(NSString*)value withX:(int)x andY:(int)y andZ:(int)z;
-(CValue*)expression:(int)num;
-(CValue*)IndexA ;
-(CValue*)IndexB;
-(CValue*)IndexC;
-(CValue*)ReadValue;
-(CValue*)ReadString;
-(CValue*)ReadValue_X;
-(CValue*)ReadValue_XY;
-(CValue*)ReadValue_XYZ;
-(CValue*)ReadValueXYZ:(int)x withY:(int)y andZ:(int)z;
-(CValue*)ReadString_X;
-(CValue*)ReadString_XY;
-(CValue*)ReadString_XYZ;
-(CValue*)ReadStringXYZ:(int)x withY:(int)y andZ:(int)z;
-(CValue*)Exp_DimX;
-(CValue*)Exp_DimY;
-(CValue*)Exp_DimZ;


@end

#define ARRAY_TYPENUM 0x0001
#define ARRAY_TYPETXT 0x0002
#define INDEX_BASE1 0x0004
@interface KcArrayData : NSObject
{
@public 
    int			lDimensionX;
    int			lDimensionY;
    int			lDimensionZ;
    int			lFlags;
    int			lIndexA;
    int			lIndexB;
    int			lIndexC;
    int*		numberArray;
    NSString**  stringArray;	
}
-(void)dealloc;
-(id)initWithFlags:(int)flags withX:(int)dimX andY:(int)dimY andZ:(int)dimZ; 
-(int)oneBased;
-(void)Expand:(int)newX withY:(int)newY andZ:(int)newZ;
-(void)Clean;

@end

@interface KcArrayCGlobalDataList : CExtStorage
{
@public 
    CArrayList* dataList;
    CArrayList* names;    
}
-(void)dealloc;
-(id)init;
-(KcArrayData*)FindObject:(NSString*)objectName;
-(void)AddObject:(CRunKcArray*)o;
-(void)RemoveObject:(CRunKcArray*)o;

@end


