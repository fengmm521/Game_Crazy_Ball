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
//  CRunkcinput.m
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 1/13/11.
//  Copyright 2011 Clickteam. All rights reserved.
//


//----------------------------------------------------------------------------------
//
// CRUNKCINPUT
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CRunkcinput.h"

#import "CActExtension.h"
#import "CCndExtension.h"

#import "CExtension.h"
#import "CPoint.h"
#import "CCreateObjectInfo.h"
#import "CFile.h"
#import "CFontInfo.h"

#import "CRect.h"
#import "CRunApp.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CServices.h"
#import "CTextSurface.h"
#import "CFont.h"
#import "CFontInfo.h"
#import "CIni.h"
#import "ModalInput.h"


//CONDITIONS
#define CND_OKCLICK 0
#define CND_CANCELCLICK 1


//ACTIONS
#define ACT_INPUTSTR 0
#define ACT_INPUTNUM 1
#define ACT_INPUTUSER 2
#define ACT_INPUTMULTI 3
#define ACT_INPUTMULTI2 4
#define ACT_SETINPUTSTR 5
#define ACT_SETINPUTNUM 6
#define ACT_SETINPUTPASS 7
#define ACT_SETINPUTLIMIT 8
#define ACT_SETINPUTPASSLIMIT 9

//EXPRESSIONS
#define EXP_GETINPUTSTR 0
#define EXP_GETINPUTNUM 1
#define EXP_GETINPUTPASS 2



@implementation CRunkcinput

-(int)getNumberOfConditions
{
	return 2;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	limit = 1024;
	limit2 = 1024;
	string = [[NSString alloc] initWithString:@""];
	string2 = [[NSString alloc] initWithString:@""];

	modalInput = nil;
	return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
	if(string != nil)
		[string release];
	if(string2 != nil)
		[string2 release];
}

-(int)handleRunObject
{
	return REFLAG_ONESHOT;
}



-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == 1)
	{
		[string release];
		string = [[NSString alloc] initWithString:modalInput.text];
		
		[string2 release];
		string2 = [[NSString alloc] initWithString:modalInput.password];
		state = 1;
	}
	else
		state = 2;

	[modalInput resignTextField];
	[rh resume];
}


// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_OKCLICK:
			return [self cnd_okClick];
		case CND_CANCELCLICK:
			return [self cnd_cancelClick];
	}
	return false;//won't happen
}

-(BOOL)cnd_okClick
{
	if(state == 1)
	{
		state = 0;
		return YES;
	}
	
	return NO;
}

-(BOOL)cnd_cancelClick
{
	if(state == 2)
	{
		state = 0;
		return YES;
	}
	
	return NO;
}

// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_INPUTSTR:
			[self act_inputString:[act getParamExpString:rh withNum:0] description:[act getParamExpString:rh withNum:1]];
			break;
		case ACT_INPUTNUM:
			[self act_inputNumber:[act getParamExpString:rh withNum:0] description:[act getParamExpString:rh withNum:1]];
			break;
		case ACT_INPUTUSER:
			[self act_inputUsernamePassword:[act getParamExpString:rh withNum:0] description:[act getParamExpString:rh withNum:1]];
			break;
		case ACT_INPUTMULTI:
		case ACT_INPUTMULTI2:
			[self act_inputMultiline:[act getParamExpString:rh withNum:0] description:[act getParamExpString:rh withNum:1]];
			break;
		case ACT_SETINPUTSTR:
			[self act_inputSetString:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_SETINPUTNUM:
			[self act_inputSetNumber:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETINPUTPASS:
			[self act_inputSetPassword:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_SETINPUTLIMIT:
			[self act_inputSetStringLimit:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETINPUTPASSLIMIT:
			[self act_inputSetPasswordLimit:[act getParamExpression:rh withNum:0]];
			break;
			
	}
}

-(void)act_inputString:(NSString*)title description:(NSString*)description
{
	[rh pause];
	if(modalInput != nil)
		[modalInput release];
	modalInput = [[ModalInput alloc] initStringWithTitle:title message:description delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"OK"];
	[modalInput.textField setText:string];
	[modalInput show];
}

-(void)act_inputNumber:(NSString*)title description:(NSString*)description
{
	[rh pause];
	if(modalInput != nil)
		[modalInput release];
	modalInput = [[ModalInput alloc] initNumberWithTitle:title message:description delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"OK"];
	[modalInput.textField setText:string];
	[modalInput show];
}

-(void)act_inputUsernamePassword:(NSString*)title description:(NSString*)description
{
	[rh pause];
	if(modalInput != nil)
		[modalInput release];
	modalInput = [[ModalInput alloc] initNamePasswordWithTitle:title message:description delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"OK"];
	[modalInput.textField setText:string];
	[modalInput show];
}

-(void)act_inputMultiline:(NSString*)title description:(NSString*)description
{
	[rh pause];
	if(modalInput != nil)
		[modalInput release];
	modalInput = [[ModalInput alloc] initStringWithTitle:title message:description delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"OK"];
	[modalInput.textField setText:string];
	[modalInput show];
}


-(void)act_inputSetString:(NSString*)newString
{
	[string release];
	string = [[NSString alloc] initWithString:newString];
}

-(void)act_inputSetNumber:(int)newNumber
{
	[string release];
	string = [[NSString stringWithFormat:@"%i", newNumber] retain];
}

-(void)act_inputSetPassword:(NSString*)newString
{
	[string2 release];
	string2 = [[NSString alloc] initWithString:newString];
}

-(void)act_inputSetStringLimit:(int)newLimit
{
	if(newLimit < 0)
		limit = 1024;
	limit = MIN(1024,newLimit);
}

-(void)act_inputSetPasswordLimit:(int)newLimit
{
	if(newLimit < 0)
		limit2 = 1024;
	limit2 = MIN(1024,newLimit);
}


// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_GETINPUTSTR:
			return [self exp_getInputStr];
		case EXP_GETINPUTNUM:
			return [self exp_getInputNum];
		case EXP_GETINPUTPASS:
			return [self exp_getInputPassword];
	}
	return [rh getTempValue:0];//won't happen
}


-(CValue*)exp_getInputStr
{
	return [rh getTempString:string];
}

-(CValue*)exp_getInputNum
{
	return [rh getTempValue:[string intValue]];
}


-(CValue*)exp_getInputPassword
{
	return [rh getTempString:string2];
}


@end
