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
//  CRunBox2DGround.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 13/11/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//
#import "CRunBox2DGround.h"
#import "CExtension.h"

short gCreateRunObject(LPRDATAGROUND rdPtr, CFile* file);
int gHandleRunObject(LPRDATAGROUND rdPtr);

short gCreateRunObject(LPRDATAGROUND rdPtr, CFile* file)
{
    rdPtr->obstacle = [file readAShort];
    rdPtr->direction = [file readAShort];
    rdPtr->friction = (float)((float)[file readAInt] / 100.0f);
    rdPtr->restitution = (float)((float)[file readAInt] / 100.0f);
    rdPtr->identifier = [file readAInt];
	return NO;
}

int gHandleRunObject(LPRDATAGROUND rdPtr)
{
	return REFLAG_ONESHOT;
}


/////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CRunBox2DGround

-(int)getNumberOfConditions
{
	return 0;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    m_object = malloc(sizeof(RUNDATAGROUND));
    
    LPRDATAGROUND rdPtr = (LPRDATAGROUND)m_object;
    rdPtr->rh = ho->hoAdRunHeader;
    rdPtr->ho = ho;
    gCreateRunObject(rdPtr, file);
    
	return NO;
}

-(int)handleRunObject
{
	return REFLAG_ONESHOT;
}


@end