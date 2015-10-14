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
// MOVEMENT CONTROLLER: extension object
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

#define ACT_SETOBJECT 0
#define ACT_SETOBJECTFIXED 1
#define ACT_POSITIONIN 2
#define ACT_POSITIONOUT 3
#define ACT_MOVEIN 4
#define ACT_MOVEOUT 5
#define ACTION_POSITIONIN 0
#define ACTION_POSITIONOUT 1
#define ACTION_MOVEIN 2
#define ACTION_MOVEOUT 3

@class CObject;
@class CRun;
@class CActExtension;
@class CCndExtension;
@class CBitmap;
@class CCreateObjectInfo;

@interface CRunInAndOutController : CRunExtension
{
    CObject* currentObject;
	
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;
-(CObject*)getCurrentObject:(NSString*)dllName;
-(void)Action_SetObject_Object:(CActExtension*)act;
-(void)Action_SetObject_FixedValue:(CActExtension*)act;
-(void)RACT_POSITIONIN:(CActExtension*)act;
-(void)RACT_POSITIONOUT:(CActExtension*)act;
-(void)RACT_MOVEIN:(CActExtension*)act;
-(void)RACT_MOVEOUT:(CActExtension*)act;

@end
