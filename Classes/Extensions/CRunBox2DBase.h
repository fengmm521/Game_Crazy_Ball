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
// CRunBox2DBase extension object
//
//----------------------------------------------------------------------------------
#import "CBox2D.h"
//#import "CObject.h"
//#import "CRun.h"
//#import "CRunApp.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CSprite;

// ------------------------------
// DEFINITION OF CONDITIONS CODES
// ------------------------------
#define	CND_LAST_BOX2DBASE					0

// ---------------------------
// DEFINITION OF ACTIONS CODES
// ---------------------------
enum
{
	ACTION_SETGRAVITYFORCE		,	// 0
	ACTION_SETGRAVITYANGLE		,
	ACTION_APPYLINEARIMPULSE	,
	ACTION_APPYANGULARIMPULSE	,
	ACTION_APPLYFORCE			,
	ACTION_APPLYTORQUE			,	// 5
	ACTION_SETLINEARVELOCITY	,
	ACTION_SETANGULARVELOCITY	,
	ACTION_DJOINTHOTSPOT		,
	ACTION_DJOINTACTIONPOINT	,
	ACTION_DJOINTPOSITION		,	// 10
	ACTION_RJOINTHOTSPOT		,
	ACTION_RJOINTACTIONPOINT	,
	ACTION_RJOINTPOSITION		,
	ACTION_PJOINTHOTSPOT		,
	ACTION_PJOINTACTIONPOINT	,	// 15
	ACTION_PJOINTPOSITION		,
	ACTION_GJOINTHOTSPOT		,
	ACTION_GJOINTACTIONPOINT	,
	ACTION_GJOINTPOSITION		,
	ACTION_WJOINTHOTSPOT		,	// 20
	ACTION_WJOINTACTIONPOINT	,
	ACTION_WJOINTPOSITION		,
	ACTION_ADDOBJECT			,
	ACTION_SUBOBJECT			,
	ACTION_SETDENSITY			,	// 25
	ACTION_SETFRICTION			,
	ACTION_SETELASTICITY		,
	ACTION_SETGRAVITY			,
	ACTION_DJOINTSETELASTICITY	,
	ACTION_RJOINTSETLIMITS		,	// 30
	ACTION_RJOINTSETMOTOR		,
	ACTION_PJOINTSETLIMITS		,
	ACTION_PJOINTSETMOTOR		,
	ACTION_PUJOINTHOTSPOT		,
	ACTION_PUJOINTACTIONPOINT	,
	ACTION_WJOINTSETMOTOR		,
	ACTION_WJOINTSETELASTICITY	,
	ACTION_DESTROYJOINT			,
	ACTION_SETITERATIONS		,
	ACT_LAST
};

// -------------------------------
// DEFINITION OF EXPRESSIONS CODES
// -------------------------------
enum
{
	EXPRESSION_GRAVITYSTRENGTH		,
	EXPRESSION_GRAVITYANGLE			,
	EXPRESSION_VELOCITYITERATIONS	,
	EXPRESSION_POSITIONITERATIONS	,
	EXPRESSION_ELASTICITYFREQUENCY	,
	EXPRESSION_ELASTICITYDAMPING	,
	EXPRESSION_LOWERANGLELIMIT		,
	EXPRESSION_UPPERANGLELIMIT		,
	EXPRESSION_MOTORSTRENGTH		,
	EXPRESSION_MOTORSPEED			,
	EXPRESSION_LOWERTRANSLATION		,
	EXPRESSION_UPPERTRANSLATION		,
	EXPRESSION_PMOTORSTRENGTH		,
	EXPRESSION_PMOTORSPEED			,
	EXP_LAST
};

// ------------------------------
// DEFINITION OF OTHER ID & VARS
// ------------------------------

#define	ID_MENUCONTROL				1000

#define BASEIDENTIFIER 0x42324547

#define APPLYIMPULSE_MULT 19.0f
#define APPLYANGULARIMPULSE_MULT 0.1f
#define APPLYFORCE_MULT 5.0f
#define APPLYTORQUE_MULT 1.0f
#define SETVELOCITY_MULT 20.5f
#define SETANGULARVELOCITY_MULT 15.0f


class CForce
{
public:
	CForce(b2Body* pBody, b2Vec2 force, b2Vec2 position);
	b2Body* m_body;
	b2Vec2 m_force;
	b2Vec2 m_position;
};

class CTorque
{
public:
	CTorque(b2Body* pBody, float torque);
	b2Body* m_body;
	float m_torque;
};


typedef struct tagEDATABASE
{
	DWORD			flags;
	DWORD			velocityIterations;
	DWORD			positionIterations;
	float			gravity;
	DWORD			angle;
	DWORD			factor;
	DWORD			friction;
	DWORD			restitution;
	DWORD			bulletFriction;
	DWORD			bulletRestitution;
	DWORD			bulletGravity;
	DWORD			bulletDensity;
	long			gravity64;
	DWORD			identifier;
	DWORD			npDensity;
	DWORD			npFriction;
	DWORD			security[5];
} EDITDATABASE;
typedef EDITDATABASE* LPEDATABASE;
#define B2FLAG_ADDBACKDROPS	0x0001
#define B2FLAG_BULLETCREATE 0x0002
#define B2FLAG_ADDOBJECTS 0x0004
#define RMOTORTORQUEMULT 20.0f
#define RMOTORSPEEDMULT 10.0f

// Object versions
#define	KCX_CURRENT_VERSION			0


// FAN OBJECT DATA STRUCTURE
typedef struct tagRDATAF
{
	AddObject		pAddObject;
	RemoveObject	pRemoveObject;
	StartObject		pStartObject;
	DWORD			identifier;
    
	LPRDATABASE		base;
	CCArrayList*		objects;
	DWORD			flags;
	float			strength;
	int			strengthBase;
	float			angle;
	BOOL			check;
    CRun*           rh;
    CExtension*     ho;
    
} RUNDATAF;
typedef	RUNDATAF*	LPRDATAF;

// TREADMILL OBJECT DATA STRUCTURE
typedef struct tagRDATAT
{
	AddObject		pAddObject;
	RemoveObject	pRemoveObject;
	StartObject		pStartObject;
	DWORD			identifier;
    
	LPRDATABASE		base;
	CCArrayList*	objects;
	DWORD			flags;
	float			strength;
	int				strengthBase;
	float			angle;
	BOOL			check;
    CRun*           rh;
    CObject*        ho;
} RUNDATAT;
typedef	RUNDATAT*	LPRDATAT;

// MAGNET OBJECT DATA STRUCTURE
typedef struct tagRDATAM
{
	AddObject		pAddObject;
	RemoveObject	pRemoveObject;
	StartObject		pStartObject;
	DWORD			identifier;
    
	LPRDATABASE		base;
	CCArrayList*	objects;
	DWORD			flags;
	float			strength;
	int				strengthBase;
	DWORD			angle;
	int				radius;
    CRun*           rh;
    CObject*        ho;
} RUNDATAM;
typedef	RUNDATAM*	LPRDATAM;

// ROPEANDCHAIN OBJECT DATA STRUCTURE
#define MAX_IMAGESRC 8
typedef struct tagRDATARC
{
	AddObject		pAddObject;
	RemoveObject	pRemoveObject;
	StartObject		pStartObject;
	DWORD identifier;
    
	LPRDATABASE	base;
    DWORD flags;
    int number;
    float angle;
    float friction;
    float restitution;
    float density;
    float gravity;
    int nImages;
    short imageStart[1];
    short images[MAX_IMAGESRC];
    short imageEnd[1];
    CCArrayList* elements;
    b2Body* bodyStart;
    b2Body* bodyEnd;
    BOOL stopped;
    BOOL stopLoop;
	int loopIndex;
    void* currentElement;
    LPHO currentObject;
    CCArrayList* joints;
	CCArrayList* ropeJoints;
    NSString* loopName;
	int oldX;
	int oldY;
	int lastElement;
	LPHO collidingHO;
	int effect;
	int effectParam;
	BOOL visible;
	float damping;
    CRun* rh;
    CExtension* ho;
} RUNDATARC;
typedef	RUNDATARC*			LPRDATARC;
class CElement
{
public:
	CRunMBase* m_mBase;
    int number;
    LPRDATARC parent;
    int x;
    int y;
    float angle;
    short image;
	CSprite* sprite;
    
	CElement(LPRDATARC p, WORD i, int n, int xx, int yy, BOOL visible);
	~CElement();
    void kill(LPRDATABASE pBase);
	void setPosition();
	void setEffect(int effect, int effectParam);
	void show(BOOL visible);
};

// PARTICULES OBJECT DATA STRUCTURE
class CParticule
{
public:
	CRunMBase* m_mBase;
    void* parent;
    int nLayer;
    int initialX;
    int initialY;
    int x;
    int y;
    float angle;
    int nImages;
    short* images;
    short image;
    int animationSpeed;
    int animationSpeedCounter;
    BOOL destroyed;
    float m_addVFlag;
    float m_addVX;
    float m_addVY;
    float oldWidth;
    float oldHeight;
    b2Fixture* fixture;
    float scaleSpeed;
    float scale;
	CSprite* sprite;
	DWORD flags;
	float m_force;
	float m_torque;
	float m_direction;
	BOOL stopped;
    
	CParticule(void* rdPtr, int xx, int yy);
	~CParticule();
	void setForce(float force, float torque, float direction);
	void setAnimation(short* images, int nImages, int animationSpeed, DWORD flags, BOOL visible);
	void setScale(float scaleSpeed);
	void setEffect(int effect, int effectParam);
	void animate();
	void show(BOOL visible);
};
#define MAX_IMAGESPA 32
typedef struct tagRDATAPARTICULES
{
	AddObject		pAddObject;
	RemoveObject	pRemoveObject;
	StartObject		pStartObject;
    DWORD identifier;
    
	LPRDATABASE base;
    WORD type;
    DWORD flags;
    int number;
    int animationSpeed;
    DWORD angleDWORD;
    int speed;
    int speedInterval;
    float friction;
    float restitution;
    float density;
    int angleInterval;
    float gravity;
    float rotation;
    int nImages;
    short images[MAX_IMAGESPA];
    CCArrayList* particules;
    CCArrayList* toDestroy;
    int creationSpeed;
    int creationSpeedCounter;
    float angle;
    CParticule* currentParticule1;
    CParticule* currentParticule2;
    BOOL stopped;
    BOOL stopLoop;
    int loopIndex;
    float applyForce;
    float applyTorque;
    float scaleSpeed;
    int destroyDistance;
    NSString* loopName;
	LPHO collidingHO;
	int effect;
	int effectParam;
	BOOL visible;
    CRun* rh;
    CExtension* ho;
} RUNDATAPARTICULES;
typedef	RUNDATAPARTICULES *			LPRDATAPARTICULES;

typedef struct
{
    CExtension*     ho;
    CRun*           rh;
    short			obstacle;
	short			direction;
	float			friction;
	float			restitution;
	unsigned int	identifier;
}RUNDATAGROUND;
typedef	RUNDATAGROUND*	LPRDATAGROUND;

#define DIRECTION_LEFTTORIGHT 0
#define DIRECTION_RIGHTTOLEFT 1
#define DIRECTION_TOPTOBOTTOM 2
#define DIRECTION_BOTTOMTOTOP 3
#define BOBSTACLE_OBSTACLE 0
#define BOBSTACLE_PLATFORM 1

#define CBFLAG_FIXEDROTATION 0x0001
#define CBFLAG_BULLET 0x0002
#define CBFLAG_DAMPING 0x0004

#define JTYPE_NONE 0
#define JTYPE_REVOLUTE 1
#define JTYPE_DISTANCE 2
#define JTYPE_PRISMATIC 3
#define JTYPE_FIXED 4
#define JANCHOR_HOTSPOT 0
#define JANCHOR_ACTIONPOINT 1
#define MAX_JOINTNAME		24
#define MAX_JOINTOBJECT		24

#define POSDEFAULT 0x56586532


// Joint class
//////////////////////////////////////////////////////////////////////
#define TYPE_ALL 0
#define TYPE_DISTANCE 1
#define TYPE_REVOLUTE 2
#define TYPE_PRISMATIC 3
#define TYPE_PULLEY 4
#define TYPE_GEAR 5
#define TYPE_MOUSE 6
#define TYPE_WHEEL 7
class CJoint
{
public:
	LPRDATABASE m_rdPtr;
	NSString* m_name;
	b2Joint* m_joint;
	int m_type;
	CJoint(LPRDATABASE rdPtr, NSString* name);
	~CJoint();
	void DestroyJoint();
	void SetJoint(int type, b2Joint* joint);
};







int GetAnimDir(CObject* pHo, int dir);
void GetObjects(LPRDATABASE rdPtr);
CRunMBase* GetMBase(LPRDATABASE rdPtr, CObject* pHo);
void* rGetMBase(void* rdPtr, CObject* pHo);
void rDestroyJoint(void* ptr, b2Joint* joint);
void rWorldToFrame(void* ptr, b2Vec2* pVec);
void rFrameToWorld(void* ptr, b2Vec2* pVec);
b2Body* rCreateBody(void* ptr, b2BodyType type, int x, int y, float angle, float gravity, void* userData, DWORD flags, float deceleration);
void rBodyDestroyFixture(void* ptr, b2Body* pBody, b2Fixture* pFixture);
b2Joint* rWorldCreateRevoluteJoint(void* ptr, b2RevoluteJointDef* jointDef, b2Body* body1, b2Body* body2, b2Vec2 position);
void rDestroyBody(void* ptr, b2Body* pBody);
b2Fixture* rBodyCreateBoxFixture(void* ptr, b2Body* pBody, void* base, int x, int y, int sx, int sy, float density, float friction, float restitution);
b2Fixture* rBodyCreateCircleFixture(void* ptr, b2Body* pBody, void* base, int x, int y, int radius, float density, float friction, float restitution);
void rCreateDistanceJoint(void* ptr, b2Body* pBody1, b2Body* pBody2, float dampingRatio, float frequency, int x, int y);
void rBodyApplyForce(void* ptr, b2Body* pBody, float force, float angle);
void rBodyStopForce(void* ptr, b2Body* pBody);
void rBodyApplyAngularImpulse(void* ptr, b2Body* pBody, float torque);
void rBodyApplyTorque(void* ptr, b2Body* pBody, float torque);
void rBodyStopTorque(void* ptr, b2Body* pBody);
void rBodySetAngularVelocity(void* ptr, b2Body* pBody, float torque);
void rBodySetAngularDamping(void* ptr, b2Body* pBody, float damping);
void rBodyAddVelocity(void* ptr, b2Body* pBody, float vx, float vy);
void rBodySetGravityScale(void* ptr, b2Body* pBody, float gravity);
void rFixtureSetRestitution(void* ptr, b2Fixture* pFixture, float restitution);
b2Vec2 rBodyGetLinearVelocity(void* ptr, b2Body* pBody);
b2Vec2 rBodyGetPosition(void* ptr, b2Body* pBody);
float rBodyGetAngle(void* ptr, b2Body* pBody);
float rBodyGetMass(void* ptr, b2Body* pBody);
void rBodySetLinearDamping(void* ptr, b2Body* pBody, float deceleration);
void rBodyApplyImpulse(void* ptr, b2Body* pBody, float force, float angle);
void rBodyApplyMMFImpulse(void* ptr, b2Body* pBody, float force, float angle);
void rBodySetTransform(void* ptr, b2Body* body, b2Vec2 position, float angle);
void rBodySetPosition(void* ptr, b2Body* pBody, int x, int y);
void rBodySetAngle(void* ptr, b2Body* pBody, float angle);
void rBodySetLinearVelocity(void* ptr, b2Body* pBody, float force, float angle);
void rBodySetLinearVelocityVector(void* ptr, b2Body* pBody, b2Vec2 velocity);
void rBodySetFixedRotation(void* ptr, b2Body* pBody, BOOL flag);
void rBodyAddLinearVelocity(void* ptr, b2Body* pBody, float speed, float angle);
void rBodySetLinearVelocityAdd(void* ptr, b2Body* pBody, float force, float angle, float vx, float vy);
BOOL isPoint(CMask* pMask, int x, int y);
void getYMinAndMaxRight(CCArrayList& pointList, int& y1, int& y2);
void getYMinAndMaxLeft(CCArrayList& pointList, int& y1, int& y2);
BOOL PointOK(int xNew, int yNew, int xOld, int yOld, int* angle);
b2Fixture* rBodyCreateShapeFixture(void* ptr, b2Body* pBody, void* base, int xp, int yp, DWORD img, float density, float friction, float restitution, float scaleX, float scaleY);
b2Body* rCreateBullet(void* ptr, float angle, float speed, void* pBase);
void rBodyResetMassData(void* ptr, b2Body* pBody);
void rGetBodyPosition(void* ptr, b2Body* pBody, int* pX, int* pY, float* pAngle);
void rGetImageDimensions(void* ptr, WORD img, int* x1, int* x2, int* y1, int* y2);
void rBodyCreatePlatformFixture(void* ptr, b2Body* pBody, void* base, short img, int vertical, int dummy, float density, float friction, float restitution, b2Fixture** pFixture, int* pOffsetX, int* pOffsetY, float scaleX, float scaleY, float maskWidth);
void rAddNormalObject(void* ptr, CObject* pHo);
void CreateBorders(LPRDATABASE rdPtr);
void computeGroundObjects(LPRDATABASE rdPtr);
void computeBackdropObjects(LPRDATABASE rdPtr);
BOOL b2brStartObject(void* ptr);
BOOL CheckOtherEngines(LPRDATABASE rdPtr);
short RACTION_SUBOBJECT(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_ADDOBJECT(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_DESTROYJOINT(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_PUJOINTACTIONPOINT(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_PUJOINTHOTSPOT(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_PJOINTSETMOTOR(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_PJOINTSETLIMITS(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_PJOINTPOSITION(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_PJOINTACTIONPOINT(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_PJOINTHOTSPOT(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_RJOINTSETMOTOR(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_RJOINTSETLIMITS(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_RJOINTPOSITION(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_RJOINTACTIONPOINT(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_RJOINTHOTSPOT(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_DJOINTPOSITION(LPRDATABASE rdPtr, CActExtension* act);
b2Vec2 GetImagePosition(LPRDATABASE rdPtr, CRunMBase* pBase, int x1, int y1);
short RACTION_DJOINTSETELASTICITY(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_DJOINTACTIONPOINT(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_DJOINTHOTSPOT(LPRDATABASE rdPtr, CActExtension* act);
b2Vec2 GetActionPointPosition(LPRDATABASE rdPtr, CRunMBase* pBase);
CJoint* GetJoint(LPRDATABASE rdPtr, CJoint* joint, NSString* name, int type);
CJoint* CreateJoint(LPRDATABASE rdPtr, NSString* name);
short RACTION_SETGRAVITYANGLE(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_SETGRAVITYFORCE(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_SETITERATIONS(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_SETDENSITY(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_SETELASTICITY(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_SETFRICTION(LPRDATABASE rdPtr, CActExtension* act);
short RACTION_SETGRAVITY(LPRDATABASE rdPtr, CActExtension* act);
short b2bHandleRunObject(LPRDATABASE rdPtr);
CObject* GetHO(LPRDATABASE rdPtr, int fixedValue);
short b2bDestroyRunObject(LPRDATABASE rdPtr, int fast);
short b2bCreateRunObject(LPRDATABASE rdPtr, LPEDATABASE edPtr);
void rGetImageDimensions(void* ptr, short img, int* x1, int* x2, int* y1, int* y2);
b2Joint* rJointCreate(void* ptr, void* pBase1, short jointType, short jointAnchor, NSString* jointName, NSString* jointObject, float param1, float param2);
CValue* REXPRESSION_GRAVITYSTRENGTH(LPRDATABASE rdPtr);
CValue* REXPRESSION_GRAVITYANGLE(LPRDATABASE rdPtr);
CValue* REXPRESSION_VELOCITYITERATIONS(LPRDATABASE rdPtr);
CValue* REXPRESSION_POSITIONITERATIONS(LPRDATABASE rdPtr);
CValue* REXPRESSION_ELASTICITYFREQUENCY(LPRDATABASE rdPtr);
CValue* REXPRESSION_ELASTICITYDAMPING(LPRDATABASE rdPtr);
CValue* REXPRESSION_LOWERANGLELIMIT(LPRDATABASE rdPtr);
CValue* REXPRESSION_UPPERANGLELIMIT(LPRDATABASE rdPtr);
CValue* REXPRESSION_MOTORSTRENGTH(LPRDATABASE rdPtr);
CValue* REXPRESSION_MOTORSPEED(LPRDATABASE rdPtr);
CValue* REXPRESSION_LOWERTRANSLATION(LPRDATABASE rdPtr);
CValue* REXPRESSION_UPPERTRANSLATION(LPRDATABASE rdPtr);
CValue* REXPRESSION_PMOTORSTRENGTH(LPRDATABASE rdPtr);
CValue* REXPRESSION_PMOTORSPEED(LPRDATABASE rdPtr);
b2Body* rAddABackdrop(void* ptr, int x, int y, short img, int obstacle);
void rSubABackdrop(void* ptr, b2Body* body);
void rRJointSetMotor(void* rdPtr, b2RevoluteJoint* pJoint, int t, int s);
void rRJointSetLimits(void* rdPtr, b2RevoluteJoint* pJoint, int angle1, int angle2);
void destroyJointWithBody(LPRDATABASE rdPtr, b2Body* body);
BOOL b2brAddFan(void* ptr, void* pObject);
BOOL b2brAddMagnet(void* ptr, void* pObject);
BOOL b2brAddTreadmill(void* ptr, void* pObject);



///////////////////////////////////////////////////////////////////////////////////////////

@interface CRunBox2DBase : CRunBox2DParent
{
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(int)handleRunObject;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;

@end


