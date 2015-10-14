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
//  CRunBox2DJoint.h
//  RuntimeIPhone
//
//  Created by Francois Lionet on 26/11/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//

#import "CRunExtension.h"
#import "CRunBox2DBase.h"

typedef struct tagRDATA
{
	LPRDATABASE		base;
	DWORD			flags;
	int				number;
	int             angle1;
	int             angle2;
	int				speed;
	int				torque;
	DWORD			identifier;
	b2Body*			bodyStatic;
	CCArrayList*		joints;
    CRun* rh;
    CExtension* ho;
} RUNDATA;
typedef	RUNDATA*	LPRDATA;

class CJointO
{
public:
	int m_fv1;
	int m_fv2;
	b2RevoluteJoint* m_joint;
	CJointO(CRunMBase* pBase1, CRunMBase* pBase2, b2RevoluteJoint* joint);
};

///////////////////////////////////////////////////////////////////////////////////////////

@interface CRunBox2DJoint : CRunBox2DParent
{
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(int)handleRunObject;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;

@end
