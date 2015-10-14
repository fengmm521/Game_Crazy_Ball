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
//
//  CRunkcinput.h
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 1/13/11.
//  Copyright 2011 Clickteam. All rights reserved.
//

//----------------------------------------------------------------------------------
//
// CRUNKINPUT: Input object
//
//----------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CCreateObjectInfo;
@class CActExtension;
@class CCndExtension;
@class CFile;
@class CValue;
@class CArrayList;
@class CFontInfo;
@class CListItem;
@class ModalInput;

@interface CRunkcinput : CRunExtension <UIAlertViewDelegate>
{
	int state;
	NSString* string;
	NSString* string2;
	int limit;
	int limit2;
	int retNumber;
	
	ModalInput* modalInput;
}

-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(int)handleRunObject;
-(void)destroyRunObject:(BOOL)bFast;

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;


//CONDITIONS
-(BOOL)cnd_okClick;
-(BOOL)cnd_cancelClick;


//ACTIONS
-(void)act_inputString:(NSString*)title description:(NSString*)description;
-(void)act_inputNumber:(NSString*)title description:(NSString*)description;
-(void)act_inputUsernamePassword:(NSString*)title description:(NSString*)description;
-(void)act_inputMultiline:(NSString*)title description:(NSString*)description;

-(void)act_inputSetString:(NSString*)newString;
-(void)act_inputSetNumber:(int)newNumber;
-(void)act_inputSetPassword:(NSString*)newString;
-(void)act_inputSetStringLimit:(int)newLimit;
-(void)act_inputSetPasswordLimit:(int)newLimit;


//EXPRESSIONS
-(CValue*)exp_getInputStr;
-(CValue*)exp_getInputNum;
-(CValue*)exp_getInputPassword;


@end