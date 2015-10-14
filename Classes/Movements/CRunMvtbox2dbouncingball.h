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
//  CRunMvtbox2dbouncingball.h
//  RuntimeIPhone
//
//  Created by Francois Lionet on 08/11/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//

#import "CRunMvtExtension.h"
#import "CRunBox2DBase.h"


#define BBFLAG_ROTATE		0x0001
#define BBFLAG_MOVEATSTART	0x0002
#define BBFLAG_SMOOTH		0x0004
#define BBFLAG_BULLET		0x0008
#define BBFLAG_FIXED		0x0010
#define BBFLAG_FINECOLLISIONS 0x0020

class CRunBox2DBouncingBall : public CRunMvtPhysics
{
    
public:
	// Construction / Destruction
	virtual void		Initialize(LPHO hoPtr, CFile* file);
    virtual void		Delete(void);
    
	virtual BOOL		Move(LPHO pHo);
	virtual void		SetPosition(LPHO pHo, int x, int y);
	virtual void		SetXPosition(LPHO pHo, int x);
	virtual void		SetYPosition(LPHO pHo, int y);
    
	virtual void		Stop(LPHO pHo, BOOL bCurrent);
	virtual void		Bounce(LPHO pHo, BOOL bCurrent);
	virtual void		Reverse(LPHO pHo);
	virtual void		Start(LPHO pHo);
	virtual void		SetSpeed(LPHO pHo, int speed);
	virtual void		SetMaxSpeed(LPHO pHo, int speed);
	virtual void		SetDir(LPHO pHo, int dir);
	virtual void		SetAcc(LPHO pHo, int acc);
	virtual void		SetDec(LPHO pHo, int dec);
	virtual void		SetRotSpeed(LPHO pHo, int speed);
	virtual void		Set8Dirs(LPHO pHo, int dirs);
	virtual void		SetGravity(LPHO pHo, int gravity);
	virtual double		ActionEntry(LPHO pHo, int action, double param1, double param2);
	virtual int			GetSpeed(LPHO hoPtr);
	virtual int			GetAcceleration(LPHO hoPtr);
	virtual int			GetDeceleration(LPHO hoPtr);
	virtual int			GetGravity(LPHO hoPtr);
	LPRDATABASE			GetBase();
	virtual BOOL		CreateBody(LPHO pHo);
	virtual void		SetFriction(int friction);
	virtual void		SetGravity(int gravity);
	virtual void		SetDensity(int density);
	virtual void		SetRestitution(int restitution);
	virtual	int			GetDir(LPHO pHo);
	virtual void		SetAngle(float angle);
	virtual float		GetAngle();
	void				CreateFixture(LPHO pho);
    
    // End of public interface
    //////////////////////////
    
    // Private interface
public:
	// Constructor
	void GetAngle(double vX, double vY, double& angle, double& vector);
	int DirAtStart(LPHO pHo, DWORD dirAtStart);
	DWORD GetRestitution();
	DWORD GetDensity();
	DWORD GetFriction();
	void CreateJoint(LPHO pHo);
    void SetTheAngle(float angle);
    
    // Private data
public:
	LPHO m_pHo;
	LPRDATABASE	m_base;
	float m_angle;
	float m_friction;
	float m_gravity;
	float m_density;
	float m_restitution;
	WORD m_shape;
	DWORD m_flags;
	float m_previousX;
	float m_previousY;
	float m_speed;
	DWORD m_speedDWORD;
	float m_deceleration;
	DWORD m_decelerationDW;
	float m_previousAngle;
	BOOL m_hwa;
	b2Fixture* m_fixture;
	int m_applyImpulse;
	float m_scaleX;
	float m_scaleY;
	int m_imgWidth;
	int m_imgHeight;
	WORD m_jointType;
	WORD m_jointAnchor;
	NSString* m_jointName;
	NSString* m_jointObject;
	float m_rJointLLimit;
	float m_rJointULimit;
	float m_dJointFrequency;
	float m_dJointDamping;
	float m_pJointLLimit;
	float m_pJointULimit;
    BOOL m_started;
    float m_angleMoving;
};
#define MOVING 123456789

//////////////////////////////////////////////////////////////////////////////////////////////////////


@interface CRunMvtbox2dbouncingball : CRunMvtBox2D
{
@public
	CRunBox2DBouncingBall* m_object;
}
-(void)initialize:(CFile*)file;
-(void)kill;
-(BOOL)move;
-(void)setPosition:(int)x withY:(int)y;
-(void)setXPosition:(int)x;
-(void)setYPosition:(int)y;
-(void)stop:(BOOL)bCurrent;
-(void)bounce:(BOOL)bCurrent;
-(void)start;
-(void)setSpeed:(int)speed;
-(void)setMaxSpeed:(int)speed;
-(void)setDir:(int)dir;
-(void)setAcc:(int)acc;
-(void)setDec:(int)dec;
-(void)setRotSpeed:(int)speed;
-(void)setGravity:(int)gravity;
-(double)actionEntry:(int)action;
-(int)getSpeed;
-(int)getAcceleration;
-(int)getDeceleration;
-(int)getGravity;
-(int)getDir;

@end
