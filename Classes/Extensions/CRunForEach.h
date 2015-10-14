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
//  CRunForEach.h
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 2/3/12.
//  Copyright (c) 2012 Clickteam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CRunExtension.h"


@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CArrayList;
@class CObject;
@class ForEachLoop;
@class ObjectSelection;

@interface CRunForEach : CRunExtension
{
	NSMutableDictionary* forEachLoops;		// Name => ForEachLoop lookup
	NSMutableDictionary* pausedLoops;		// Name => Paused ForEachLoop lookup
	NSMutableDictionary* groups;			// Groupname => CArrayList of objects
	ForEachLoop* currentForEach;
	CObject* currentLooped;
	
	//Variables for the ObjectSelection framework to access
	ForEachLoop* populateLoop;	//To fill with all currently selected objects
	ForEachLoop* partOfLoop;	//To access the loop in question
	CArrayList* partOfGroup;	//To access the group in question
	short oiToCheck;
	NSString* currentGroup;
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension *)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;
-(void)executeForEachLoop:(ForEachLoop*)loop;

@end

@interface ForEachLoop : NSObject
{
@public
	NSString* name;
	CArrayList* fvs;
	int loopIndex;
	int loopMax;
	bool paused;
}
-(id)init;
-(void)dealloc;
-(void)addObject:(CObject*)object;
-(void)addFixed:(int)fixed;
@end


BOOL getSelected(CObject* rdPtr, CObject* object);
BOOL getSelectedForGroup(CObject* rdPtr, CObject* object);
BOOL filterPartOfLoop(CObject* rdPtr, CObject* object);
BOOL filterPartOfGroup(CObject* rdPtr, CObject* object);

