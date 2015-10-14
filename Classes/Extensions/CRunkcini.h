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
// CRUNKCINI : objet ini
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CActExtension;
@class CArrayList;
@class CIni;

@interface CRunkcini : CRunExtension 
{
    int saveCounter;
    CIni* ini;
    short iniFlags;
    NSString* iniName;
    NSString* iniCurrentGroup;
    NSString* iniCurrentItem;	
}
-(CValue*)GetStringGroupItem;
-(CValue*)GetStringItem;
-(CValue*)GetValueGroupItem;
-(CValue*)GetValueItem;
-(CValue*)GetString;
-(CValue*)GetValue;
-(CValue*)expression:(int)num;
-(void)DeleteGroup:(CActExtension*)act;
-(void)DeleteGroupItem:(CActExtension*)act;
-(void)DeleteItem:(CActExtension*)act;
-(void)SetStringGroupItem:(CActExtension*)act;
-(void)SetStringItem:(CActExtension*)act;
-(void)SetValueGroupItem:(CActExtension*)act;
-(void)SetValueItem:(CActExtension*)act;
-(void)SetCurrentFile:(CActExtension*)act;
-(void)SetString:(CActExtension*)act;
-(void)LoadPosition:(CActExtension*)act;
-(void)SavePosition:(CActExtension*)act;
-(void)SetValue:(CActExtension*)act;
-(void)SetCurrentItem:(CActExtension*)act;
-(void)SetCurrentGroup:(CActExtension*)act;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(int)handleRunObject;
-(void)destroyRunObject:(BOOL)bFast;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(int)getNumberOfConditions;
-(NSString*)cleanPCPath:(NSString*)srce;

@end


	
