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
// CRuniOS
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CFontInfo;
@class CBitmap;


@interface CRuniOS : CRunExtension 
{
    int reactivatedCount;
}

-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(int)handleRunObject;
-(void)destroyRunObject:(BOOL)bFast;
-(BOOL)reactivatedCnd;
-(BOOL)memoryWarningCnd;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension *)cnd;
-(void)actOpenURL:(CActExtension*)act;
-(void)actAuthoriseIAd:(CActExtension*)act;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;

@end
