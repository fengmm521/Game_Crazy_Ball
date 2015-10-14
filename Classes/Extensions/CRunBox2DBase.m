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
#import "CRunBox2DBase.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CCndExtension.h"
#import "CRMvt.h"
#import "CMove.h"
#import "CRCom.h"
#import "CRAni.h"
#import "CAnimDir.h"
#import "CAnim.h"
#import "CObjectCommon.h"
#import "CMoveDef.h"
#import "CMoveDefExtension.h"
#import "CMoveDefList.h"
#import "CMoveExtension.h"
#import "CMask.h"
#import "CRunApp.h"
#import "CImageBank.h"
#import "CImage.h"
#import "CServices.h"
#import "CRunFrame.h"
#import "CLayer.h"
#import "CLOList.h"
#import "CLO.h"
#import "COIList.h"
#import "COCBackground.h"
#import "CActExtension.h"
#import "CObjInfo.h"
#import "CEventProgram.h"

// BOX2D INTERFACE
// ---------------------------------------------------------------------
int GetAnimDir(CObject* pHo, int dir)
{
	CRAni* raPtr=pHo->roa;
	CAnim* anPtr=raPtr->raAnimOffset;
    
    CAnimDir* adPtr = anPtr->anDirs[dir];
    if (adPtr == nil)
    {
        // De quel cote est t'on le plus proche?
        if ((anPtr->anAntiTrigo[dir] & 0x40) != 0)
        {
            dir = anPtr->anAntiTrigo[dir] & 0x3F;
        }
        else if ((anPtr->anTrigo[dir] & 0x40) != 0)
        {
            dir = anPtr->anTrigo[dir] & 0x3F;
        }
        else
        {
            dir=anPtr->anTrigo[dir]&0x3F;
        }
    }
	return dir;
}

void GetObjects(LPRDATABASE rdPtr)
{
    rdPtr->fans->Clear();
    rdPtr->magnets->Clear();
    rdPtr->treadmills->Clear();
    
    int pOL = 0;
    int nObjects;
    
    for (nObjects = 0; nObjects<rdPtr->rh->rhNObjects; pOL++, nObjects++)
    {
        while(rdPtr->rh->rhObjectList[pOL]==nil) pOL++;
        CObject* pObject = rdPtr->rh->rhObjectList[pOL];
        if (pObject->hoType >= 32)
        {
            CExtension* pExtension = (CExtension*)pObject;
            if (pObject->hoCommon->ocIdentifier == FANIDENTIFIER)
            {
                rdPtr->fans->Add(((CRunBox2DParent*)pExtension->ext)->m_object);
            }
            if (pObject->hoCommon->ocIdentifier == MAGNETIDENTIFIER)
            {
                rdPtr->magnets->Add(((CRunBox2DParent*)pExtension->ext)->m_object);
            }
            if (pObject->hoCommon->ocIdentifier == TREADMILLIDENTIFIER)
            {
                rdPtr->treadmills->Add(((CRunBox2DParent*)pExtension->ext)->m_object);
            }
        }
    }
}

CRunMBase* GetMBase(LPRDATABASE rdPtr, CObject* pHo)
{
    if (pHo == nil || (pHo->hoFlags & HOF_DESTROYED) != 0)
        return nil;
    if (pHo->rom == nil)
        return nil;
    
    if (pHo->roc->rcMovementType == MVTYPE_EXT)
    {
        CMoveDefExtension* mvPtr = (CMoveDefExtension*)pHo->hoCommon->ocMovements->moveList[pHo->rom->rmMvtNum];
        if ([mvPtr->moduleName caseInsensitiveCompare:@"box2d8directions"] == 0
            || [mvPtr->moduleName caseInsensitiveCompare:@"box2dspring"] == 0
            || [mvPtr->moduleName caseInsensitiveCompare:@"box2dspaceship"] == 0
            || [mvPtr->moduleName caseInsensitiveCompare:@"box2dstatic"] == 0
            || [mvPtr->moduleName caseInsensitiveCompare:@"box2dracecar"] == 0
            || [mvPtr->moduleName caseInsensitiveCompare:@"box2daxial"] == 0
            || [mvPtr->moduleName caseInsensitiveCompare:@"box2dplatform"] == 0
            || [mvPtr->moduleName caseInsensitiveCompare:@"box2dbouncingball"] == 0
            || [mvPtr->moduleName caseInsensitiveCompare:@"box2dbackground"] == 0
            )
        {
            CRunMvtBox2D* pRunMvt=(CRunMvtBox2D*) ((CMoveExtension*)pHo->rom->rmMovement)->movement;
            CRunMvtPhysics* pBase = pRunMvt->m_movement;
            if (pBase->m_identifier==rdPtr->identifier)
            {
                return pBase->m_mBase;
            }
        }
    }
    return nil;
}

void* rGetMBase(void* rdPtr, CObject* pHo)
{
	return GetMBase((LPRDATABASE)rdPtr, pHo);
}
void rDestroyJoint(void* ptr, b2Joint* joint)
{
	LPRDATABASE rdPtr=(LPRDATABASE)ptr;
	rdPtr->world->DestroyJoint(joint);
}
void rWorldToFrame(void* ptr, b2Vec2* pVec)
{
	LPRDATABASE rdPtr=(LPRDATABASE)ptr;
    
	pVec->x=(pVec->x*rdPtr->factor)-rdPtr->xBase;
	pVec->y=rdPtr->yBase-(pVec->y*rdPtr->factor);
}
void rFrameToWorld(void* ptr, b2Vec2* pVec)
{
	LPRDATABASE rdPtr=(LPRDATABASE)ptr;
    
	pVec->x=(rdPtr->xBase+pVec->x)/rdPtr->factor;
	pVec->y=(rdPtr->yBase-pVec->y)/rdPtr->factor;
}

b2Body* rCreateBody(void* ptr, b2BodyType type, int x, int y, float angle, float gravity, void* userData, DWORD flags, float deceleration)
{
	LPRDATABASE rdPtr=(LPRDATABASE)ptr;
	CRunMBase* pMBase = (CRunMBase*)userData;
    
	if (pMBase != nil && type != b2_staticBody && pMBase->m_type!=MTYPE_PLATFORM && pMBase->m_type!=MTYPE_OBSTACLE)
	{
		int n;
		RUNDATAF* pFan;
		RUNDATAM* pMagnet;
		RUNDATAT* pTreadmill;
		for (n=0; n < rdPtr->fans->Size(); n++)
		{
			pFan = (RUNDATAF*)rdPtr->fans->Get(n);
			pFan->pAddObject(pFan, pMBase);
		}
		for (n=0; n < rdPtr->magnets->Size(); n++)
		{
			pMagnet = (RUNDATAM*)rdPtr->magnets->Get(n);
			pMagnet->pAddObject(pMagnet, pMBase);
		}
		for (n=0; n < rdPtr->treadmills->Size(); n++)
		{
			pTreadmill = (RUNDATAT*)rdPtr->treadmills->Get(n);
			pTreadmill->pAddObject(pTreadmill, pMBase);
		}
	}
	b2BodyDef bodyDef;
	bodyDef.type = type;
	bodyDef.position.Set((rdPtr->xBase+x)/rdPtr->factor, (rdPtr->yBase-y)/rdPtr->factor);
	bodyDef.angle=(float)((angle*b2_pi)/180.0);
	bodyDef.gravityScale=gravity;
	bodyDef.userData=userData;
	if (flags&CBFLAG_FIXEDROTATION)
		bodyDef.fixedRotation=YES;
	if (flags&CBFLAG_BULLET)
		bodyDef.bullet=YES;
	if (flags&CBFLAG_DAMPING)
		bodyDef.linearDamping=deceleration;
	b2Body* pBody=rdPtr->world->CreateBody(&bodyDef);
	return pBody;
}
void rBodyDestroyFixture(void* ptr, b2Body* pBody, b2Fixture* pFixture)
{
	pBody->DestroyFixture(pFixture);
}
b2Joint* rWorldCreateRevoluteJoint(void* ptr, b2RevoluteJointDef* jointDef, b2Body* body1, b2Body* body2, b2Vec2 position)
{
	jointDef->Initialize(body1, body2, position);
	LPRDATABASE rdPtr=(LPRDATABASE)ptr;
	return rdPtr->world->CreateJoint(jointDef);
}
void rDestroyBody(void* ptr, b2Body* pBody)
{
	LPRDATABASE rdPtr=(LPRDATABASE)ptr;

    CRunMBase* pMBase=(CRunMBase*)pBody->GetUserData();
	if (pMBase != nil && pMBase->m_type!=MTYPE_PLATFORM && pMBase->m_type!=MTYPE_OBSTACLE)
	{
		GetObjects(rdPtr);
		int n;
		RUNDATAF* pFan;
		RUNDATAM* pMagnet;
		RUNDATAT* pTreadmill;
		for (n=0; n < rdPtr->fans->Size(); n++)
		{
			pFan = (RUNDATAF*)rdPtr->fans->Get(n);
			pFan->pRemoveObject(pFan, pMBase);
		}
		for (n=0; n < rdPtr->magnets->Size(); n++)
		{
			pMagnet = (RUNDATAM*)rdPtr->magnets->Get(n);
			pMagnet->pRemoveObject(pMagnet, pMBase);
		}
		for (n=0; n < rdPtr->treadmills->Size(); n++)
		{
			pTreadmill = (RUNDATAT*)rdPtr->treadmills->Get(n);
			pTreadmill->pRemoveObject(pTreadmill, pMBase);
		}
	}

    if (rdPtr->contactListener->bWorking)
    {
        pBody->SetUserData(nil);
        rdPtr->bodiesToDestroy->Add(pBody);
        return;
    }
    
    destroyJointWithBody(rdPtr, pBody);
    rBodyStopForce(rdPtr, pBody);
    rBodyStopTorque(rdPtr, pBody);
	rdPtr->world->DestroyBody(pBody);
}

b2Fixture* rBodyCreateBoxFixture(void* ptr, b2Body* pBody, void* base, int x, int y, int sx, int sy, float density, float friction, float restitution)
{
	LPRDATABASE rdPtr=(LPRDATABASE)ptr;
	CRunMBase* pMBase = (CRunMBase*)base;
    
	if (pMBase != nil)
	{
		pMBase->rc.left = - sx / 2;
		pMBase->rc.right = sx / 2;
		pMBase->rc.top = - sy / 2;
		pMBase->rc.bottom = sy / 2;
	}
    
	b2PolygonShape box;
	sx-=1;
	sy-=1;
	b2Vec2 vect( (float)(rdPtr->xBase+x)/rdPtr->factor, (float)(rdPtr->yBase-y)/rdPtr->factor );
    //	box.SetAsBox( (float)(((float)sx)/2.0/rdPtr->factor), (float)(((float)sy)/2.0/rdPtr->factor), pBody->GetLocalPoint(vect), 0);
	box.SetAsBox( (float)(((float)sx)/2.0/rdPtr->factor), (float)(((float)sy)/2.0/rdPtr->factor));
    
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &box;
	fixtureDef.density = density;
	fixtureDef.friction = friction;
	fixtureDef.restitution=restitution;
	fixtureDef.userData=(void*)rdPtr;
	return pBody->CreateFixture(&fixtureDef);
}
b2Fixture* rBodyCreateCircleFixture(void* ptr, b2Body* pBody, void* base, int x, int y, int radius, float density, float friction, float restitution)
{
	LPRDATABASE rdPtr=(LPRDATABASE)ptr;
	CRunMBase* pMBase = (CRunMBase*)base;
    
	if (pMBase != nil)
	{
		pMBase->rc.left = - radius;
		pMBase->rc.right = radius;
		pMBase->rc.top = - radius;
		pMBase->rc.bottom = radius;
	}
    
	b2CircleShape circle;
	circle.m_radius = (float)(((float)radius)/rdPtr->factor);
	b2Vec2 vect( (float)(rdPtr->xBase+x)/rdPtr->factor, (float)(rdPtr->yBase-y)/rdPtr->factor );
	b2Vec2 local=pBody->GetLocalPoint(vect);
	circle.m_p.Set(local.x, local.y);
	
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &circle;
	fixtureDef.density = density;
	fixtureDef.friction = friction;
	fixtureDef.restitution=restitution;
	fixtureDef.userData=(void*)rdPtr;
	return pBody->CreateFixture(&fixtureDef);
}
void rCreateDistanceJoint(void* ptr, b2Body* pBody1, b2Body* pBody2, float dampingRatio, float frequency, int x, int y)
{
	LPRDATABASE rdPtr=(LPRDATABASE)ptr;
    
	b2Vec2 position1=pBody1->GetPosition();
	position1.x+=(((float)x)/rdPtr->factor);
	position1.y+=(((float)y)/rdPtr->factor);
	b2Vec2 position2=pBody2->GetPosition();
	b2DistanceJointDef jointDef;
	jointDef.collideConnected = YES;
	jointDef.frequencyHz=frequency;
	jointDef.dampingRatio=dampingRatio;
	jointDef.Initialize(pBody1, pBody2, position1, position2);
	rdPtr->world->CreateJoint(&jointDef);
}
void rBodyApplyForce(void* ptr, b2Body* pBody, float force, float angle)
{
	LPRDATABASE rdPtr=(LPRDATABASE)ptr;
    
	b2Vec2 position=pBody->GetPosition();
	b2Vec2 f(force*cos(angle*b2_pi/180.0f), force*sin(angle*b2_pi/180.0f));
    
	int n;
	CForce* cForce;
	for (n=0; n<rdPtr->forces->Size(); n++)
	{
		cForce = (CForce*)rdPtr->forces->Get(n);
		if (cForce->m_body == pBody)
		{
			cForce->m_force = f;
			cForce->m_position = position;
			return;
		}
	}
	cForce = new CForce(pBody, f, position);
	rdPtr->forces->Add(cForce);
}

void rBodyStopForce(void* ptr, b2Body* pBody)
{
	LPRDATABASE rdPtr = (LPRDATABASE)ptr;
    
	int n;
	CForce* cForce;
	for (n=0; n<rdPtr->forces->Size(); n++)
	{
		cForce = (CForce*)rdPtr->forces->Get(n);
		if (cForce->m_body == pBody)
		{
			delete cForce;
			rdPtr->forces->RemoveIndex(n);
			break;
		}
	}
}

void rBodyApplyAngularImpulse(void* ptr, b2Body* pBody, float torque)
{
	pBody->ApplyAngularImpulse(torque);
}
void rBodyApplyTorque(void* ptr, b2Body* pBody, float torque)
{
	LPRDATABASE rdPtr = (LPRDATABASE)ptr;
	int n;
	CTorque* cTorque;
	for (n=0; n<rdPtr->torques->Size(); n++)
	{
		cTorque = (CTorque*)rdPtr->torques->Get(n);
		if (cTorque->m_body == pBody)
		{
			cTorque->m_torque = torque;
			return;
		}
	}
	cTorque = new CTorque(pBody, torque);
	rdPtr->torques->Add(cTorque);
}
void rBodyStopTorque(void* ptr, b2Body* pBody)
{
	LPRDATABASE rdPtr = (LPRDATABASE)ptr;
    
	int n;
	CTorque* cTorque;
	for (n=0; n<rdPtr->torques->Size(); n++)
	{
		cTorque = (CTorque*)rdPtr->torques->Get(n);
		if (cTorque->m_body == pBody)
		{
			delete cTorque;
			rdPtr->torques->RemoveIndex(n);
			break;
		}
	}
}

void rBodySetAngularVelocity(void* ptr, b2Body* pBody, float torque)
{
	pBody->SetAngularVelocity(torque);
}
void rBodySetAngularDamping(void* ptr, b2Body* pBody, float damping)
{
	pBody->SetAngularDamping(damping);
}
void rBodyAddVelocity(void* ptr, b2Body* pBody, float vx, float vy)
{
	b2Vec2 velocity=pBody->GetLinearVelocity();
	velocity.x+=vx;
	velocity.y+=vy;
	pBody->SetLinearVelocity(velocity);
}
void rBodySetGravityScale(void* ptr, b2Body* pBody, float gravity)
{
	pBody->SetGravityScale(gravity);
}
void rFixtureSetRestitution(void* ptr, b2Fixture* pFixture, float restitution)
{
	pFixture->SetRestitution(restitution);
}
b2Vec2 rBodyGetLinearVelocity(void* ptr, b2Body* pBody)
{
	return pBody->GetLinearVelocity();
}
b2Vec2 rBodyGetPosition(void* ptr, b2Body* pBody)
{
	return pBody->GetPosition();
}
float rBodyGetAngle(void* ptr, b2Body* pBody)
{
	return pBody->GetAngle();
}
float rBodyGetMass(void* ptr, b2Body* pBody)
{
	return pBody->GetMass();
}
void rBodySetLinearDamping(void* ptr, b2Body* pBody, float deceleration)
{
	pBody->SetLinearDamping(deceleration);
}
void rBodyApplyImpulse(void* ptr, b2Body* pBody, float force, float angle)
{
	b2Vec2 position=pBody->GetPosition();
	b2Vec2 f(force*cos(angle*b2_pi/180.0f), force*sin(angle*b2_pi/180.0f));
	pBody->ApplyLinearImpulse(f, position);
}
void rBodyApplyMMFImpulse(void* ptr, b2Body* pBody, float force, float angle)
{
	b2Vec2 velocity=pBody->GetLinearVelocity();
	b2Vec2 f(force*cos(angle*b2_pi/180.0f), force*sin(angle*b2_pi/180.0f));
	velocity.x += f.x / pBody->GetMass();
	velocity.y += f.y / pBody->GetMass();
	pBody->SetLinearVelocity(velocity);
}
void rBodySetTransform(void* ptr, b2Body* body, b2Vec2 position, float angle)
{
	body->SetTransform(position, angle);
}
void rBodySetPosition(void* ptr, b2Body* pBody, int x, int y)
{
	LPRDATABASE rdPtr=(LPRDATABASE)ptr;
    
	float angle=pBody->GetAngle();
	b2Vec2 position=pBody->GetPosition();
	if (x!=POSDEFAULT)
		position.x=(float)(rdPtr->xBase+x)/rdPtr->factor;
	if (y!=POSDEFAULT)
		position.y=(float)(rdPtr->yBase-y)/rdPtr->factor;
	pBody->SetTransform(position, angle);
}
void rBodySetAngle(void* ptr, b2Body* pBody, float angle)
{
	b2Vec2 position=pBody->GetPosition();
	pBody->SetTransform(position, angle*b2_pi/180.0f);
}
void rBodySetLinearVelocity(void* ptr, b2Body* pBody, float force, float angle)
{
	b2Vec2 f(force*cos(angle*b2_pi/180.0f), force*sin(angle*b2_pi/180.0f));
	pBody->SetLinearVelocity(f);
}
void rBodySetLinearVelocityVector(void* ptr, b2Body* pBody, b2Vec2 velocity)
{
	pBody->SetLinearVelocity(velocity);
}
void rBodySetFixedRotation(void* ptr, b2Body* pBody, BOOL flag)
{
	pBody->SetFixedRotation(flag?YES:NO);
}
void rBodyAddLinearVelocity(void* ptr, b2Body* pBody, float speed, float angle)
{
	b2Vec2 v(speed*cos(angle*b2_pi/180.0f), speed*sin(angle*b2_pi/180.0f));
	b2Vec2 velocity=pBody->GetLinearVelocity();
	velocity.x+=v.x;
	velocity.y+=v.y;
	pBody->SetLinearVelocity(velocity);
}
void rBodySetLinearVelocityAdd(void* ptr, b2Body* pBody, float force, float angle, float vx, float vy)
{
	b2Vec2 f(force*cos(angle*b2_pi/180.0f)+vx, force*sin(angle*b2_pi/180.0f)+vy);
	pBody->SetLinearVelocity(f);
}
BOOL isPoint(CMask* pMask, int x, int y)
{
	return [pMask testPoint:x withY:y];
}
void getYMinAndMaxRight(CCArrayList& pointList, int& y1, int& y2)
{
	int y;
	int xx;
	for (y=0, xx=-1; y<pointList.Size(); y+=2)
	{
		if (pointList.GetInt(y)>xx)
		{
			xx=pointList.GetInt(y);
			y1=y/2;
		}
	}
	for (y=pointList.Size()-2, xx=-1; y>=0; y-=2)
	{
		if (pointList.GetInt(y)>xx)
		{
			xx=pointList.GetInt(y);
			y2=y/2;
		}
	}
}
void getYMinAndMaxLeft(CCArrayList& pointList, int& y1, int& y2)
{
	int y;
	int xx;
	for (y=0, xx=10000; y<pointList.Size(); y+=2)
	{
		if (pointList.GetInt(y)<xx)
		{
			xx=pointList.GetInt(y);
			y1=y/2;
		}
	}
	for (y=pointList.Size()-2, xx=10000; y>=0; y-=2)
	{
		if (pointList.GetInt(y)<xx)
		{
			xx=pointList.GetInt(y);
			y2=y/2;
		}
	}
}
BOOL PointOK(int xNew, int yNew, int xOld, int yOld, int* angle)
{
	int deltaX=xNew-xOld;
	int deltaY=yNew-yOld;
	int a=*angle;
	*angle=(int)(atan2((double)deltaY, (double)deltaX)*57.2957795f);
	if (a==*angle)
		return NO;
	return YES;
}
b2Fixture* rBodyCreateShapeFixture(void* ptr, b2Body* pBody, void* base, int xp, int yp, DWORD img, float density, float friction, float restitution, float scaleX, float scaleY)
{
	LPRDATABASE rdPtr=(LPRDATABASE)ptr;
	CRunMBase* pMBase = (CRunMBase*)base;
    
	b2PolygonShape box;
    CImage* pImage = [rdPtr->rh->rhApp->imageBank getImageFromHandle:img];
    CMask* pMask = [pImage getMask:0 withAngle:0 andScaleX:1.0 andScaleY:1.0];
	int width=pImage->width;
	int height=pImage->height;
	int x, y, xPrevious, yPrevious;
	int xArray[16];
	int yArray[16];
	int xPos, yPos;
	int angle;
	int count=0;
	//float scaleError = ((float)height - 2.0f) / (float)height;
	float scaleError = 1.0f;
    
	if (pMBase != nil)
	{
		pMBase->rc.left = - (int)(width / 2 * scaleX);
		pMBase->rc.right = (int)(width / 2 * scaleX);
		pMBase->rc.top = - (int)(height/ 2 * scaleY);
		pMBase->rc.bottom = (int)(height / 2 * scaleY);
	}
    
    BOOL bBackground = NO;
    if (density < 0)
    {
        density = 0;
        bBackground = YES;
    }
    
	// Right - bottom
	for (y=height-1, xPos=-1; y>=0; y--)
	{
		for (x=width-1; x>=0; x--)
		{
			if (isPoint(pMask, x, y))
			{
				if (x>xPos)
				{
					xPos=x;
					yPos=y;
				}
				break;
			}
		}
	}
	if (xPos<0)
	{
		return rBodyCreateBoxFixture(ptr, pBody, base, xp, yp, width, height, density, friction, restitution);
	}
	xPrevious=xArray[count]=xPos;
	yPrevious=yArray[count]=yPos;
	count++;
    
	// Right - top
	for (y=0, xPos=-1; y<height; y++)
	{
		for (x=width-1; x>=0; x--)
		{
			if (isPoint(pMask, x, y))
			{
				if (x>xPos)
				{
					xPos=x;
					yPos=y;
				}
				break;
			}
		}
	}
	angle=1000;
	int c;
	if (PointOK(xPos, yPos, xPrevious, yPrevious, &angle))
	{
		for (c = 0; c < count; c++)
		{
			if (xArray[c] == xPos && yArray[c] == yPos)
				break;
		}
		if (c == count)
		{
			xPrevious=xArray[count]=xPos;
			yPrevious=yArray[count++]=yPos;
		}
	}
    
	// Top - right
	for (x=width-1, yPos=10000; x>=0; x--)
	{
		for (y=0; y<height; y++)
		{
			if (isPoint(pMask, x, y))
			{
				if (y<yPos)
				{
					xPos=x;
					yPos=y;
				}
				break;
			}
		}
	}
	for (c = 0; c < count; c++)
	{
		if (xArray[c] == xPos && yArray[c] == yPos)
			break;
	}
	if (c == count)
	{
		if (!PointOK(xPos, yPos, xPrevious, yPrevious, &angle))
			count--;
		xPrevious=xArray[count]=xPos;
		yPrevious=yArray[count++]=yPos;
	}
	// Top - left
	for (x=0, yPos=10000; x<width; x++)
	{
		for (y=0; y<height; y++)
		{
			if (isPoint(pMask, x, y))
			{
				if (y<yPos)
				{
					xPos=x;
					yPos=y;
				}
				break;
			}
		}
	}
	for (c = 0; c < count; c++)
	{
		if (xArray[c] == xPos && yArray[c] == yPos)
			break;
	}
	if (c == count)
	{
		if (!PointOK(xPos, yPos, xPrevious, yPrevious, &angle))
			count--;
		xPrevious=xArray[count]=xPos;
		yPrevious=yArray[count++]=yPos;
	}
	// Left - top
	for (y=0, xPos=10000; y<height; y++)
	{
		for (x=0; x<width; x++)
		{
			if (isPoint(pMask, x, y))
			{
				if (x<xPos)
				{
					xPos=x;
					yPos=y;
				}
				break;
			}
		}
	}
	for (c = 0; c < count; c++)
	{
		if (xArray[c] == xPos && yArray[c] == yPos)
			break;
	}
	if (c == count)
	{
		if (!PointOK(xPos, yPos, xPrevious, yPrevious, &angle))
			count--;
		xPrevious=xArray[count]=xPos;
		yPrevious=yArray[count++]=yPos;
	}
	// Left - bottom
	for (y=height-1, xPos=10000; y>=0; y--)
	{
		for (x=0; x<width; x++)
		{
			if (isPoint(pMask, x, y))
			{
				if (x<xPos)
				{
					xPos=x;
					yPos=y;
				}
				break;
			}
		}
	}
	for (c = 0; c < count; c++)
	{
		if (xArray[c] == xPos && yArray[c] == yPos)
			break;
	}
	if (c == count)
	{
		if (!PointOK(xPos, yPos, xPrevious, yPrevious, &angle))
			count--;
		xPrevious=xArray[count]=xPos;
		yPrevious=yArray[count++]=yPos;
	}
	// Bottom - left
	for (x=0, yPos=-1; x<width; x++)
	{
		for (y=height-1; y>=0; y--)
		{
			if (isPoint(pMask, x, y))
			{
				if (y>yPos)
				{
					xPos=x;
					yPos=y;
				}
				break;
			}
		}
	}
	for (c = 0; c < count; c++)
	{
		if (xArray[c] == xPos && yArray[c] == yPos)
			break;
	}
	if (c == count)
	{
		if (!PointOK(xPos, yPos, xPrevious, yPrevious, &angle))
			count--;
		xPrevious=xArray[count]=xPos;
		yPrevious=yArray[count++]=yPos;
	}
	// Bottom - right
	for (x=width-1, yPos=-1; x>=0; x--)
	{
		for (y=height-1; y>=0; y--)
		{
			if (isPoint(pMask, x, y))
			{
				if (y>yPos)
				{
					xPos=x;
					yPos=y;
				}
				break;
			}
		}
	}
	for (c = 0; c < count; c++)
	{
		if (xArray[c] == xPos && yArray[c] == yPos)
			break;
	}
	if (c == count)
	{
		if (!PointOK(xPos, yPos, xPrevious, yPrevious, &angle))
			count--;
		xArray[count]=xPos;
		yArray[count++]=yPos;
	}
    
    float xMiddle = 0;
    float yMiddle = 0;
    int n;
    if (!bBackground)
    {
        for (n = 0; n < count; n++)
        {
            xMiddle += xArray[n];
            yMiddle += yArray[n];
        }
        xMiddle /= count;
        yMiddle /= count;
    }
    else
    {
        xMiddle = (float)width / 2.0f;
        yMiddle = (float)height / 2.0f;
    }
    
	b2Vec2* vertices=(b2Vec2*)malloc(count*sizeof(b2Vec2));
	for (int n=0; n<count; n++)
	{
		float fx=(float)((float)(xArray[n]-xMiddle)/rdPtr->factor*scaleX*scaleError);
		float fy=(float)((float)(yMiddle-yArray[n])/rdPtr->factor*scaleY*scaleError);
		vertices[n].Set(fx, fy);
	}
    
	b2FixtureDef fixtureDef;
	b2PolygonShape polygon;
	b2EdgeShape edge;
	if (count > 2)
	{
		polygon.Set(vertices, count);
		fixtureDef.shape = &polygon;
	}
	else if (count == 2)
	{
		edge.Set(vertices[0], vertices[1]);
		fixtureDef.shape = &edge;
	}
	else
	{
		return rBodyCreateBoxFixture(ptr, pBody, base, xp, yp, width, height, density, friction, restitution);
	}
	fixtureDef.density = density;
	fixtureDef.friction = friction;
	fixtureDef.restitution=restitution;
	fixtureDef.userData=(void*)rdPtr;
	b2Fixture* ret=pBody->CreateFixture(&fixtureDef);
	free(vertices);
	return ret;
}
b2Body* rCreateBullet(void* ptr, float angle, float speed, void* pBase)
{
	LPRDATABASE rdPtr=(LPRDATABASE)ptr;
	if ((rdPtr->flags&B2FLAG_BULLETCREATE)==0)
		return nil;
    
	CRunMBase* pMBase = (CRunMBase*)pBase;
	CObject* hoPtr=pMBase->m_pHo;
    
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	bodyDef.position.Set((rdPtr->xBase+hoPtr->hoX)/rdPtr->factor, (rdPtr->yBase-hoPtr->hoY)/rdPtr->factor);
	bodyDef.angle=(float)((angle*b2_pi)/180.0);
	bodyDef.gravityScale=rdPtr->bulletGravity;
	bodyDef.userData=pMBase;
	bodyDef.bullet = YES;
	b2Body* pBody=rdPtr->world->CreateBody(&bodyDef);
    
	rBodyCreateShapeFixture(ptr, pBody, pMBase, hoPtr->hoX, hoPtr->hoY, hoPtr->roc->rcImage, rdPtr->bulletDensity, rdPtr->bulletFriction, rdPtr->bulletRestitution, hoPtr->roc->rcScaleX, hoPtr->roc->rcScaleY);
    
	b2Vec2 velocity(speed*cos(angle*b2_pi/180.0f), speed*sin(angle*b2_pi/180.0f));
	pBody->SetLinearVelocity(velocity);
    
	return pBody;
}
void rBodyResetMassData(void* ptr, b2Body* pBody)
{
	pBody->ResetMassData();
}
void rGetBodyPosition(void* ptr, b2Body* pBody, int* pX, int* pY, float* pAngle)
{
	b2Vec2 position=pBody->GetPosition();
	rWorldToFrame(ptr, &position);
	*pX=(int)position.x;
	*pY=(int)position.y;
	float angle=((pBody->GetAngle()*180)/b2_pi);
	int m=(int)(angle/360.0);
	*pAngle=angle-(m*360);
	if (*pAngle < 0)
		*pAngle += 360.0f;
}
void rGetImageDimensions(void* ptr, short img, int* x1, int* x2, int* y1, int* y2)
{
	LPRDATABASE rdPtr=(LPRDATABASE)ptr;
    
    CImage* pImage = [rdPtr->rh->rhApp->imageBank getImageFromHandle:img];
    CMask* pMask = [pImage getMask:0 withAngle:0 andScaleX:1.0 andScaleY:1.0];
    
	int xx, yy;
	*y1=0, *y2=pImage->height-1;
	BOOL quit;
	for (yy=0, quit=NO; yy<pImage->height; yy++)
	{
		for (xx=0; xx<pImage->width; xx++)
		{
			if (isPoint(pMask, xx, yy))
			{
				*y1=yy;
				quit=YES;
				break;
			}
		}
		if (quit) break;
	}
	for (yy=pImage->height-1, quit=NO; yy>=0; yy--)
	{
		for (xx=0; xx<pImage->width; xx++)
		{
			if (isPoint(pMask, xx, yy))
			{
				*y2=yy;
				quit=YES;
				break;
			}
		}
		if (quit) break;
	}
	*x1=0, *x2=pImage->width-1;
	for (xx=0, quit=NO; xx<pImage->width; xx++)
	{
		for (yy=0; yy<pImage->height; yy++)
		{
			if (isPoint(pMask, xx, yy))
			{
				*x1=xx;
				quit=YES;
				break;
			}
		}
		if (quit) break;
	}
	for (xx=pImage->width-1, quit=NO; xx>=0; xx--)
	{
		for (yy=pImage->height-1; yy>=0; yy--)
		{
			if (isPoint(pMask, xx, yy))
			{
				*x2=xx;
				quit=YES;
				break;
			}
		}
		if (quit) break;
	}
}
void rBodyCreatePlatformFixture(void* ptr, b2Body* pBody, void* base, short img, int vertical, int dummy, float density, float friction, float restitution, b2Fixture** pFixture, int* pOffsetX, int* pOffsetY, float scaleX, float scaleY, float maskWidth)
{
	LPRDATABASE rdPtr=(LPRDATABASE)ptr;
	CRunMBase* pMBase = (CRunMBase*)base;
	int xx1, yy1, xx2, yy2;
	float x1, y1, x2, y2;
	float xx, yy;
	rGetImageDimensions(ptr, img, &xx1, &xx2, &yy1, &yy2);
	x1 = (float)(xx1 * scaleX);
	y1 = (float)(yy1 * scaleY);
	x2 = (float)(xx2 * scaleX);
	y2 = (float)(yy2 * scaleY);
	b2Vec2 vertices[6];
	maskWidth = maxd(maskWidth, 0.1f);
	if (vertical == 0)
	{
		float sx=x2-x1;
		float middleX=(x1+x2)/2;
		float middleY=0;	//(y1+y2)/2; // 0
		float sy=(y1+y2)/2;
		
		xx=-sx/4*maskWidth;
		yy=middleY;
		vertices[0].Set( (float)((float)xx/rdPtr->factor), (float)((float)(yy)/rdPtr->factor));
		xx=sx/4*maskWidth;
		vertices[1].Set( (float)((float)xx/rdPtr->factor), (float)((float)(yy)/rdPtr->factor));
        
		xx=sx/2*maskWidth;
		yy=middleY+sy/8;
		vertices[2].Set( (float)((float)xx/rdPtr->factor), (float)((float)(yy)/rdPtr->factor));
        
		xx=sx/2*maskWidth;
		yy=middleY+sy*2;
		vertices[3].Set( (float)((float)xx/rdPtr->factor), (float)((float)(yy)/rdPtr->factor));
		xx=-sx/2*maskWidth;
		vertices[4].Set( (float)((float)xx/rdPtr->factor), (float)((float)(yy)/rdPtr->factor));
        
		xx=-sx/2*maskWidth;
		yy=middleY+sy/8;
		vertices[5].Set( (float)((float)xx/rdPtr->factor), (float)((float)(yy)/rdPtr->factor));
        
		*pOffsetX = (int)sx;
		*pOffsetY = (int)sy;
		pMBase->rc.left = - (int)(middleX * maskWidth);
		pMBase->rc.right = (int)(middleX * maskWidth);
		pMBase->rc.top = -(int)sy;
		pMBase->rc.bottom = (int)sy;
	}
	else
	{
		float sx=(float)y2-(float)y1;
		float sy=(float)x2-(float)x1;
		float middleX=sx/2;
		float middleY=sy/2;
		xx=middleX;
		yy=0;
		vertices[0].Set((float)(xx/rdPtr->factor), (float)(yy/rdPtr->factor));
		xx=sx;
		yy=middleY-sy/8;
		vertices[1].Set((float)(xx/rdPtr->factor), (float)(yy/rdPtr->factor));
		yy=middleY+sy/8;
		vertices[2].Set((float)(xx/rdPtr->factor), (float)(yy/rdPtr->factor));
		xx=middleX;
		yy=sy;
		vertices[3].Set((float)(xx/rdPtr->factor), (float)(yy/rdPtr->factor));
		xx=0;
		yy=middleY+sy/8;
		vertices[4].Set((float)(xx/rdPtr->factor), (float)(yy/rdPtr->factor));
		yy=middleY-sy/8;
		vertices[5].Set((float)(xx/rdPtr->factor), (float)(yy/rdPtr->factor));
		*pOffsetX = (int)sx;
		*pOffsetY = (int)sy;
		pMBase->rc.left = -(int)middleX;
		pMBase->rc.right = (int)middleX;
		pMBase->rc.top = -(int)middleY;
		pMBase->rc.bottom = (int)middleY;
	}
	b2PolygonShape polygon;
	polygon.Set(vertices, 6);
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &polygon;
	fixtureDef.density = density;
	fixtureDef.friction = friction;
	fixtureDef.restitution=restitution;
	fixtureDef.userData=(void*)rdPtr;
	*pFixture=pBody->CreateFixture(&fixtureDef);
}
void rAddNormalObject(void* ptr, CObject* pHo)
{
	LPRDATABASE rdPtr = (LPRDATABASE)ptr;
	if (rdPtr->flags & B2FLAG_ADDOBJECTS)
	{
		if (rdPtr->objects->IndexOf(pHo)<0)
		{
			if (pHo->hoType == 2 && GetMBase(rdPtr, pHo) == nil)
			{
				CRunMBase* pBase=new CRunMBase(rdPtr, pHo, MTYPE_FAKEOBJECT);
//				float angle=GetAnimDir(pHo, pHo->roc->rcDir)*11.25f;
				pBase->m_body=rCreateBody(rdPtr, b2_staticBody, pHo->hoX, pHo->hoY, 0, 0, (void*)pBase, 0, 0);
				rBodyCreateShapeFixture(rdPtr, pBase->m_body, pBase, pHo->hoX, pHo->hoY, pHo->roc->rcImage, rdPtr->npDensity, rdPtr->npFriction, 0, pHo->roc->rcScaleX, pHo->roc->rcScaleY);
				rdPtr->objects->Add(pBase);
				rdPtr->objectIDs->AddInt((pHo->hoCreationId<<16)|(pHo->hoNumber&0xFFFF));
			}
		}
	}
}

void CreateBorders(LPRDATABASE rdPtr)
{
	CRunMBase* pMBase = new CRunMBase(rdPtr, nil, MTYPE_BORDERBOTTOM);
    pMBase->m_body = rCreateBody(rdPtr, b2_staticBody, rdPtr->rh->rhLevelSx/2, rdPtr->rh->rhLevelSy + 8, 0, 0, pMBase, 0, 0);
    rBodyCreateBoxFixture(rdPtr, pMBase->m_body, pMBase, rdPtr->rh->rhLevelSx/2, rdPtr->rh->rhLevelSy + 8, rdPtr->rh->rhLevelSx, 16, 0, 1, 0);
    
	pMBase = new CRunMBase(rdPtr, nil, MTYPE_BORDERLEFT);
    pMBase->m_body = rCreateBody(rdPtr, b2_staticBody, -8, rdPtr->rh->rhLevelSy / 2, 0, 0, pMBase, 0, 0);
    rBodyCreateBoxFixture(rdPtr, pMBase->m_body, pMBase, -8, rdPtr->rh->rhLevelSy / 2, 16, rdPtr->rh->rhLevelSy, 0, 1, 0);
    
	pMBase = new CRunMBase(rdPtr, nil, MTYPE_BORDERRIGHT);
    pMBase->m_body = rCreateBody(rdPtr, b2_staticBody, rdPtr->rh->rhLevelSx + 8, rdPtr->rh->rhLevelSy / 2, 0, 0, pMBase, 0, 0);
    rBodyCreateBoxFixture(rdPtr, pMBase->m_body, pMBase, rdPtr->rh->rhLevelSx + 8, rdPtr->rh->rhLevelSy / 2, 16, rdPtr->rh->rhLevelSy, 0, 1, 0);
    
	pMBase = new CRunMBase(rdPtr, nil, MTYPE_BORDERTOP);
	pMBase->m_body = rCreateBody(rdPtr, b2_staticBody, rdPtr->rh->rhLevelSx / 2, -8, 0, 0, pMBase, 0, 0);
    rBodyCreateBoxFixture(rdPtr, pMBase->m_body, pMBase, rdPtr->rh->rhLevelSx / 2, -8, rdPtr->rh->rhLevelSx, 16, 0, 1, 0);
}


void computeGroundObjects(LPRDATABASE rdPtr)
{
    CRun* rhPtr = rdPtr->rh;
	int pOL=0;
	CObjectCommon* ocGround = nil;
    CCArrayList ocGrounds;
	for (int nObjects=0; nObjects<rhPtr->rhNObjects; nObjects++)
	{
		while(rhPtr->rhObjectList[pOL] == nil) pOL++;
		CObject* pHo=rhPtr->rhObjectList[pOL];
        pOL++;
        if (pHo->hoType>=32)
		{
			if (pHo->hoCommon->ocIdentifier==GROUNDIDENTIFIER)
			{
				RUNDATAGROUND* pGround = (RUNDATAGROUND*)((CRunBox2DParent*)((CExtension*)pHo)->ext)->m_object;
				if (pGround->identifier == rdPtr->identifier)
				{
                    int n;
                    for (n = 0; n < ocGrounds.Size(); n++)
                    {
                        if (pHo->hoCommon == (CObjectCommon*)ocGrounds.Get(n))
                            break;
                    }
                    if (n == ocGrounds.Size())
                    {
                        ocGrounds.Add(pHo->hoCommon);
                        ocGround = pGround->ho->hoCommon;
                        short obstacle = pGround->obstacle;
                        short direction = pGround->direction;
                        int pOL2 = pOL;
                        CCArrayList* list = new CCArrayList();
                        list->Add(pGround);
                        for (int nObjects2 = nObjects + 1; nObjects2 < rhPtr->rhNObjects; nObjects2++)
                        {
                            while(rhPtr->rhObjectList[pOL2] == nil) pOL2++;
                            CObject* pHo=rhPtr->rhObjectList[pOL2];
                            pOL2++;
                            
                            if (pHo->hoType>=32)
                            {
                                if (pHo->hoCommon->ocIdentifier == GROUNDIDENTIFIER && pHo->hoCommon == ocGround)
                                {
                                    RUNDATAGROUND* pGround2 = (RUNDATAGROUND*)((CRunBox2DParent*)((CExtension*)pHo)->ext)->m_object;
                                    if (pGround2->identifier == rdPtr->identifier && pGround2->obstacle == obstacle && pGround2->direction == direction)
                                    {
                                        list->Add(pGround2);
                                    }
                                }
                            }
                        }
                        if (list->Size() >= 2)
                        {
                            int pos;
                            BOOL flag;
                            do
                            {
                                flag = NO;
                                pos = 0;
                                do
                                {
                                    RUNDATAGROUND* pSort1 = (RUNDATAGROUND*)list->Get(pos);
                                    RUNDATAGROUND* pSort2 = (RUNDATAGROUND*)list->Get(pos + 1);
                                    RUNDATAGROUND* temp;
                                    int x1 = pSort1->ho->hoX + 8;
                                    int x2 = pSort2->ho->hoX + 8;
                                    int y1 = pSort1->ho->hoY + 8;
                                    int y2 = pSort2->ho->hoY + 8;
                                    switch(direction)
                                    {
                                        case DIRECTION_LEFTTORIGHT:
                                            if (x2 < x1)
                                            {
                                                temp = pSort1;
                                                list->Set(pos, pSort2);
                                                list->Set(pos + 1, temp);
                                                flag = YES;
                                            }
                                            break;
                                        case DIRECTION_RIGHTTOLEFT:
                                            if (x2 > x1)
                                            {
                                                temp = pSort1;
                                                list->Set(pos, pSort2);
                                                list->Set(pos + 1, temp);
                                                flag = YES;
                                            }
                                            break;
                                        case DIRECTION_TOPTOBOTTOM:
                                            if (y2 < y1)
                                            {
                                                temp = pSort1;
                                                list->Set(pos, pSort2);
                                                list->Set(pos + 1, temp);
                                                flag = YES;
                                            }
                                            break;
                                        case DIRECTION_BOTTOMTOTOP:
                                            if (y2 > y1)
                                            {
                                                temp = pSort1;
                                                list->Set(pos, pSort2);
                                                list->Set(pos + 1, temp);
                                                flag = YES;
                                            }
                                            break;
                                    }
                                    pos++;
                                } while(pos < list->Size() - 1);
                            } while(flag);
                            
                            RUNDATAGROUND* pSort = (RUNDATAGROUND*)list->Get(0);
                            int x1 = pSort->ho->hoX + 8;
                            pSort = (RUNDATAGROUND*)list->Get(list->Size()-1);
                            int x2 = pSort->ho->hoX + 8;
                            int y1 = 10000;
                            int y2 = -10000;
                            for (pos = 0; pos < list->Size(); pos++)
                            {
                                pSort = (RUNDATAGROUND*)list->Get(pos);
                                y1 = MIN(pSort->ho->hoY + 8, y1);
                                y2 = MAX(pSort->ho->hoY + 8, y2);
                            }
                            int middleX = (x1 + x2) / 2;
                            int middleY = (y1 + y2) / 2;
                            CRunMBase* pMBase = new CRunMBase(rdPtr, nil, (obstacle==BOBSTACLE_OBSTACLE)?MTYPE_OBSTACLE:MTYPE_PLATFORM);
                            pMBase->m_identifier = rdPtr->identifier;
                            pMBase->m_subType = MSUBTYPE_BOTTOM;
                            pMBase->m_body = rCreateBody(rdPtr, b2_staticBody, middleX, middleY, 0, 0, pMBase, 0, 0);
                            pMBase->rc.left = -middleX;
                            pMBase->rc.right = middleX;
                            pMBase->rc.top = y2 - y1;
                            pMBase->rc.bottom = y2 - y1;
                            
                            b2Vec2* chain = (b2Vec2*)malloc(list->Size() * sizeof(b2Vec2));
                            for (pos = 0; pos < list->Size(); pos++)
                            {
                                pSort = (RUNDATAGROUND*)list->Get(pos);
                                int x1 = pSort->ho->hoX + 8;
                                int y1 = pSort->ho->hoY + 8;
                                chain[pos].x = (float)((x1 - middleX))/rdPtr->factor;
                                chain[pos].y = -(float)((y1 - middleY))/rdPtr->factor;
                            }
                            b2ChainShape shape;
                            shape.CreateChain(chain, list->Size());
                            b2FixtureDef fixtureDef;
                            fixtureDef.shape = &shape;
                            fixtureDef.density = 1.0f;
                            fixtureDef.friction = pGround->friction;
                            fixtureDef.restitution = pGround->restitution;
                            fixtureDef.userData=(void*)rdPtr;
                            pMBase->m_body->CreateFixture(&fixtureDef);
                        }
                    }
                }
			}
		}
	}
}

void computeBackdropObjects(LPRDATABASE rdPtr)
{
	CRunFrame* pCurFrame=rdPtr->rh->rhFrame;
	CRunApp* pCurApp=rdPtr->rh->rhApp;
    
	int nLayer, i;
	CLO* plo;
	COI* poi;
	COC* poc;
    
	for (nLayer=0; nLayer < pCurFrame->nLayers; nLayer++)
	{
		CLayer* pLayer = pCurFrame->layers[nLayer];
        
		// Invisible layer? continue
		if ( (pLayer->dwOptions & FLOPT_VISIBLE) == 0 )
		{
			continue;
		}
        
        int cpt;
		for (i=0, cpt=0; i<pLayer->nBkdLOs; i++, cpt++)
		{
            plo = [rdPtr->rh->rhFrame->LOList getLOFromIndex:pLayer->nFirstLOIndex+i];
            
			int x, y;
			int typeObj = plo->loType;
			int width, height, obstacle;
            
			if ( typeObj >= OBJ_SPR )
                continue;
            
            x=plo->loX;
			y=plo->loY;
			poi = [pCurApp->OIList getOIFromHandle:plo->loOiHandle];
			if ( poi==nil || poi->oiOC==nil )
				continue;
			poc = poi->oiOC;
                
			width=poc->ocCx;
			height=poc->ocCy;
			obstacle = poc->ocObstacleType;

			if (obstacle==1 || obstacle==2)
			{
				CRunMBase* pMBase = new CRunMBase(rdPtr, nil, (obstacle==1)?MTYPE_OBSTACLE:MTYPE_PLATFORM);
				pMBase->m_body = rCreateBody(rdPtr, b2_staticBody, x+width/2, y+height/2, 0, 0, pMBase, 0, 0);
				if (typeObj==OBJ_BOX)
					rBodyCreateBoxFixture(rdPtr, pMBase->m_body, pMBase, x+width/2, y+height/2, width, height, 0.0f, rdPtr->friction, rdPtr->restitution);
				else
				{
					short img = ((COCBackground*)poc)->ocImage;
					rBodyCreateShapeFixture(rdPtr, pMBase->m_body, pMBase, x+width/2, y+height/2, img, -1, rdPtr->friction, rdPtr->restitution, 1.0f, 1.0f);
				}
			}
		}
	}
}

b2Body* rAddABackdrop(void* ptr, int x, int y, short img, int obstacle)
{
	LPRDATABASE rdPtr = (LPRDATABASE)ptr;
    if (rdPtr->flags & B2FLAG_ADDBACKDROPS)
    {
        CImage* image = [rdPtr->rh->rhApp->imageBank getImageFromHandle:img];
        CRunMBase* pMBase = new CRunMBase(rdPtr, nil, (obstacle==1)?MTYPE_OBSTACLE:MTYPE_PLATFORM);
        pMBase->m_body = rCreateBody(rdPtr, b2_staticBody, x + image->width / 2, y + image->height / 2, 0, 0, pMBase, 0, 0);
        rBodyCreateShapeFixture(rdPtr, pMBase->m_body, pMBase, x + image->width / 2, y + image->height / 2, img, -1.0, rdPtr->friction, rdPtr->restitution, 1.0f, 1.0f);
        rdPtr->backgroundBases->Add(pMBase);
        return pMBase->m_body;
    }
    return nil;
}
void rSubABackdrop(void* ptr, b2Body* body)
{
	LPRDATABASE rdPtr = (LPRDATABASE)ptr;
    int n;
    for (n = 0; n < rdPtr->backgroundBases->Size(); n++)
    {
        CRunMBase* pBase = (CRunMBase*)rdPtr->backgroundBases->Get(n);
        if (pBase->m_body == body)
        {
            rdPtr->world->DestroyBody(body);
            delete pBase;
            rdPtr->backgroundBases->RemoveIndex(n);
            return;
        }
    }
}

void rRJointSetLimits(void* rdPtr, b2RevoluteJoint* pJoint, int angle1, int angle2)
{
	float lAngle=(float)((float)angle1*b2_pi/180.0f);
	float uAngle=(float)((float)angle2*b2_pi/180.0f);
	if (lAngle>uAngle)
	{
		pJoint->EnableLimit(FALSE);
	}
	else
	{
		pJoint->EnableLimit(TRUE);
		pJoint->SetLimits(lAngle, uAngle);
	}
}

void rRJointSetMotor(void* rdPtr, b2RevoluteJoint* pJoint, int t, int s)
{
	float torque=(float)((float)t/100.0f)*RMOTORTORQUEMULT;
	float speed=(float)((float)s/100.0f)*RMOTORSPEEDMULT;
	BOOL flag=YES;
	if (torque==0 && speed==0)
		flag=NO;
	pJoint->EnableMotor(flag);
	pJoint->SetMaxMotorTorque(torque);
	pJoint->SetMotorSpeed(speed);
}

b2Joint* rJointCreate(void* ptr, void* pBase1, short jointType, short jointAnchor, NSString* jointName, NSString* jointObject, float param1, float param2)
{
	if (jointType == JTYPE_NONE)
		return nil;
    
	LPRDATABASE rdPtr = (LPRDATABASE)ptr;
	CRunMBase* pMBase1 = (CRunMBase*)pBase1;
    int pOL = 0;
    int nObjects;
	CRunMBase* pMBase2 = nil;
	double distance = 100000000;
	for (nObjects=0; nObjects<rdPtr->rh->rhNObjects; pOL++, nObjects++)
	{
		while(rdPtr->rh->rhObjectList[pOL]==nil) pOL++;
		CObject* pObject=rdPtr->rh->rhObjectList[pOL];
		if ([pObject->hoOiList->oilName caseInsensitiveCompare:jointObject] == 0)
		{
			CRunMBase* pMBaseObject = GetMBase(rdPtr, pObject);
			if (pMBaseObject != nil)
			{
				int deltaX = pMBaseObject->m_pHo->hoX - pMBase1->m_pHo->hoX;
				int deltaY = pMBaseObject->m_pHo->hoY - pMBase1->m_pHo->hoY;
				double d = sqrt(deltaX * deltaX + deltaY * deltaY);
				if (d <= distance)
				{
					distance = d;
					pMBase2 = pMBaseObject;
				}
			}
		}
	}
	if (pMBase2 != nil)
	{
		CJoint* pJoint = CreateJoint(rdPtr, jointName);
		if (pJoint != nil)
		{
			switch (jointType)
			{
                case JTYPE_REVOLUTE:
				{
					b2RevoluteJointDef jointDef;
					jointDef.collideConnected=YES;
					if (param1 > param2)
						jointDef.enableLimit = NO;
					else
					{
						jointDef.enableLimit = YES;
						jointDef.lowerAngle = param1;
						jointDef.upperAngle = param2;
					}
					b2Vec2 position;
					switch (jointAnchor)
					{
                        case JANCHOR_HOTSPOT:
                            position=pMBase1->m_body->GetPosition();
                            break;
                        case JANCHOR_ACTIONPOINT:
                            position=GetActionPointPosition(rdPtr, pMBase1);
                            break;
					}
					jointDef.Initialize(pMBase1->m_body, pMBase2->m_body, position);
					pJoint->SetJoint(TYPE_REVOLUTE, rdPtr->world->CreateJoint(&jointDef));
					return pJoint->m_joint;
				}
                case JTYPE_DISTANCE:
				{
					b2DistanceJointDef jointDef;
					jointDef.collideConnected=YES;
					jointDef.frequencyHz = param1;
					jointDef.dampingRatio = param2;
					b2Vec2 position1, position2;
					switch (jointAnchor)
					{
                        case JANCHOR_HOTSPOT:
                            position1=pMBase1->m_body->GetPosition();
                            position2=pMBase2->m_body->GetPosition();
                            break;
                        case JANCHOR_ACTIONPOINT:
                            position1=GetActionPointPosition(rdPtr, pMBase1);
                            position2=GetActionPointPosition(rdPtr, pMBase2);
                            break;
					}
					jointDef.Initialize(pMBase1->m_body, pMBase2->m_body, position1, position2);
					pJoint->SetJoint(TYPE_DISTANCE, rdPtr->world->CreateJoint(&jointDef));
					return pJoint->m_joint;
				}
                case JTYPE_PRISMATIC:
				{
					b2PrismaticJointDef jointDef;
					jointDef.collideConnected=YES;
					if (param1 > param2)
						jointDef.enableLimit = NO;
					else
					{
						jointDef.enableLimit = YES;
						jointDef.lowerTranslation = param1 / rdPtr->factor;
						jointDef.upperTranslation = param2 / rdPtr->factor;
					}
					b2Vec2 position1, position2;
					switch (jointAnchor)
					{
                        case JANCHOR_HOTSPOT:
                            position1=pMBase1->m_body->GetPosition();
                            position2=pMBase2->m_body->GetPosition();
                            break;
                        case JANCHOR_ACTIONPOINT:
                            position1=GetActionPointPosition(rdPtr, pMBase1);
                            position2=GetActionPointPosition(rdPtr, pMBase2);
                            break;
					}
					b2Vec2 axis(position2.x-position1.x, position2.y-position1.y);
					jointDef.Initialize(pMBase1->m_body, pMBase2->m_body, position1, axis);
					pJoint->SetJoint(TYPE_PRISMATIC, rdPtr->world->CreateJoint(&jointDef));
					return pJoint->m_joint;
				}
			}
		}
	}
	return nil;
}

// Build 283.2
// Adds a fan to an engine and returns YES if it was really added
BOOL b2brAddFan(void* ptr, void* pObject)
{
	LPRDATABASE rdPtrBase=(LPRDATABASE)ptr;
	RUNDATAF* pFan = (RUNDATAF*)(((CRunBox2DParent*)((CExtension*)pObject)->ext)->m_object);
	if ( pFan->identifier == rdPtrBase->identifier)
	{
		// Add fan to engine
		rdPtrBase->fans->Add(pFan);

		// Add active objets to fan
		int pOL=0;
		int nObjects;
	    CRun* rhPtr = rdPtrBase->rh;
		for (nObjects=0; nObjects<rhPtr->rhNObjects; pOL++, nObjects++)
		{
			while(rhPtr->rhObjectList[pOL]==nil) pOL++;
			CObject* pObjectActive=rhPtr->rhObjectList[pOL];
			if ( pObjectActive->hoType == OBJ_SPR )
			{
				CRunMBase* pMBase = GetMBase(rdPtrBase, pObjectActive);	// [rhPtr GetMBase:pObjectActive];
				if ( pMBase )
					pFan->pAddObject(pFan, pMBase);
			}
		}
		return YES;
	}
	return NO;
}

// Build 283.2
// Adds a magnet to an engine and returns YES if it was really added
BOOL b2brAddMagnet(void* ptr, void* pObject)
{
	LPRDATABASE rdPtrBase=(LPRDATABASE)ptr;
	RUNDATAM* pMagnet = (RUNDATAM*)(((CRunBox2DParent*)((CExtension*)pObject)->ext)->m_object);
	if ( pMagnet->identifier == rdPtrBase->identifier)
	{
		// Add magnet to engine
		rdPtrBase->magnets->Add(pMagnet);

		// Add active objets to magnet
		int pOL=0;
		int nObjects;
	    CRun* rhPtr = rdPtrBase->rh;
		for (nObjects=0; nObjects<rhPtr->rhNObjects; pOL++, nObjects++)
		{
			while(rhPtr->rhObjectList[pOL]==nil) pOL++;
			CObject* pObjectActive=rhPtr->rhObjectList[pOL];
			if ( pObjectActive->hoType == OBJ_SPR )
			{
				CRunMBase* pMBase = GetMBase(rdPtrBase, pObjectActive);	// [rhPtr GetMBase:pObjectActive];
				if ( pMBase )
					pMagnet->pAddObject(pMagnet, pMBase);
			}
		}
		return YES;
	}
	return NO;
}

// Build 283.2
// Adds a treadmill to an engine and returns YES if it was really added
BOOL b2brAddTreadmill(void* ptr, void* pObject)
{
	LPRDATABASE rdPtrBase=(LPRDATABASE)ptr;
	RUNDATAT* pTreadmill = (RUNDATAT*)(((CRunBox2DParent*)((CExtension*)pObject)->ext)->m_object);
	if ( pTreadmill->identifier == rdPtrBase->identifier)
	{
		// Add treadmill to engine
		rdPtrBase->treadmills->Add(pTreadmill);

		// Add active objets to treadmill
		int pOL=0;
		int nObjects;
	    CRun* rhPtr = rdPtrBase->rh;
		for (nObjects=0; nObjects<rhPtr->rhNObjects; pOL++, nObjects++)
		{
			while(rhPtr->rhObjectList[pOL]==nil) pOL++;
			CObject* pObjectActive=rhPtr->rhObjectList[pOL];
			if ( pObjectActive->hoType == OBJ_SPR )
			{
				CRunMBase* pMBase = GetMBase(rdPtrBase, pObjectActive);	// [rhPtr GetMBase:pObjectActive];
				if ( pMBase )
					pTreadmill->pAddObject(pTreadmill, pMBase);
			}
		}
		return YES;
	}
	return NO;
}


BOOL b2brStartObject(void* ptr)
{
	LPRDATABASE rdPtr=(LPRDATABASE)ptr;
	if (rdPtr->started==NO)
	{
		GetObjects(rdPtr);
		rdPtr->started=YES;
		
		if (rdPtr->flags&B2FLAG_ADDBACKDROPS)
			computeBackdropObjects(rdPtr);
		computeGroundObjects(rdPtr);
	}
	return NO;
}
BOOL CheckOtherEngines(LPRDATABASE rdPtr)
{
    int pOL = 0;
    int nObjects;
	for (nObjects=0; nObjects<rdPtr->rh->rhNObjects; pOL++, nObjects++)
	{
		while(rdPtr->rh->rhObjectList[pOL] == nil) pOL++;
		CObject* pBase=rdPtr->rh->rhObjectList[pOL];
		if (pBase->hoType>=32)
		{
			if (pBase->hoCommon->ocIdentifier==BASEIDENTIFIER)
            {
                CExtension* pExtension = (CExtension*)pBase;
                CRunBox2DParent* pParent = (CRunBox2DParent*)pExtension->ext;
                if (rdPtr != pParent->m_object)
                {
                    LPRDATABASE pEngine=(LPRDATABASE)pParent->m_object;
                    if (pEngine->identifier==rdPtr->identifier)
                    {
                        return YES;
                    }
                }
			}
		}
	}
	return NO;
}

short b2bCreateRunObject(LPRDATABASE rdPtr, LPEDATABASE edPtr)
{
    
	rdPtr->xBase=0;
	rdPtr->yBase=rdPtr->rh->rhApp->gaCyWin;
    
	rdPtr->flags=edPtr->flags;
	rdPtr->gravity=edPtr->gravity;
	rdPtr->angle=(float)(((float)edPtr->angle*b2_pi)/16.0);
	rdPtr->angleBase=edPtr->angle;
	rdPtr->factor=(float)edPtr->factor;
	rdPtr->friction=(float)(((float)edPtr->friction)/100.0);
	rdPtr->restitution=(float)(((float)edPtr->restitution)/100.0);
	rdPtr->velocityIterations=edPtr->velocityIterations;
	rdPtr->positionIterations=edPtr->positionIterations;
	rdPtr->bulletDensity=(float)(((float)edPtr->bulletDensity)/100.0);
	rdPtr->bulletGravity=(float)(((float)edPtr->bulletGravity)/100.0);
	rdPtr->bulletFriction=(float)(((float)edPtr->bulletFriction)/100.0);
	rdPtr->bulletRestitution=(float)(((float)edPtr->bulletRestitution)/100.0);
	rdPtr->shapeStep=8;
	rdPtr->identifier=edPtr->identifier;
	rdPtr->npDensity = (float)(((float)edPtr->npDensity)/100.0);
	rdPtr->npFriction = (float)(((float)edPtr->npFriction)/100.0);
    
	b2Vec2 gravity((float)rdPtr->gravity*cos(rdPtr->angle), (float)rdPtr->gravity*sin(rdPtr->angle));
	rdPtr->world=new b2World(gravity);
	rdPtr->world->SetAllowSleeping(NO);
	rdPtr->contactListener=new ContactListener();
	rdPtr->world->SetContactListener(rdPtr->contactListener);
	rdPtr->pWorldToFrame=rWorldToFrame;
	rdPtr->pFrameToWorld=rFrameToWorld;
	rdPtr->pCreateBody=rCreateBody;
	rdPtr->pBodyCreateBoxFixture=rBodyCreateBoxFixture;
	rdPtr->pBodyCreateCircleFixture=rBodyCreateCircleFixture;
	rdPtr->pBodyCreateShapeFixture=rBodyCreateShapeFixture;
	rdPtr->pGetBodyPosition=rGetBodyPosition;
	rdPtr->pBodyApplyForce=rBodyApplyForce;
	rdPtr->pBodyApplyImpulse=rBodyApplyImpulse;
	rdPtr->pBodyApplyMMFImpulse=rBodyApplyMMFImpulse;
	rdPtr->pBodyAddVelocity=rBodyAddVelocity;
	rdPtr->pBodySetLinearVelocity=rBodySetLinearVelocity;
	rdPtr->pBodySetLinearVelocityAdd=rBodySetLinearVelocityAdd;
	rdPtr->pGetImageDimensions=rGetImageDimensions;
	rdPtr->pDestroyBody=rDestroyBody;
	rdPtr->pCreateDistanceJoint=rCreateDistanceJoint;
	rdPtr->pBodyCreatePlatformFixture=rBodyCreatePlatformFixture;
	rdPtr->pBodySetTransform=rBodySetTransform;
	rdPtr->pBodyAddLinearVelocity=rBodyAddLinearVelocity;
	rdPtr->pBodySetPosition=rBodySetPosition;
	rdPtr->pBodySetAngle=rBodySetAngle;
	rdPtr->pStartObject=b2brStartObject;
	rdPtr->pBodyResetMassData=rBodyResetMassData;
	rdPtr->pBodyApplyAngularImpulse=rBodyApplyAngularImpulse;
	rdPtr->pBodyApplyTorque=rBodyApplyTorque;
	rdPtr->pBodySetAngularVelocity=rBodySetAngularVelocity;
	rdPtr->pBodyStopForce=rBodyStopForce;
	rdPtr->pBodyStopTorque=rBodyStopTorque;
	rdPtr->pAddNormalObject=rAddNormalObject;
	rdPtr->pBodyDestroyFixture=rBodyDestroyFixture;
	rdPtr->pWorldCreateRevoluteJoint=rWorldCreateRevoluteJoint;
	rdPtr->pBodySetLinearVelocityVector=rBodySetLinearVelocityVector;
	rdPtr->pBodyGetLinearVelocity=rBodyGetLinearVelocity;
	rdPtr->pBodySetLinearDamping=rBodySetLinearDamping;
	rdPtr->pBodyGetPosition=rBodyGetPosition;
	rdPtr->pBodyGetAngle=rBodyGetAngle;
	rdPtr->pBodySetGravityScale=rBodySetGravityScale;
	rdPtr->pFixtureSetRestitution=rFixtureSetRestitution;
	rdPtr->pBodySetAngularDamping=rBodySetAngularDamping;
	rdPtr->pBodyGetMass=rBodyGetMass;
	rdPtr->pGetMBase=rGetMBase;
	rdPtr->pDestroyJoint=rDestroyJoint;
	rdPtr->pBodySetFixedRotation=rBodySetFixedRotation;
	rdPtr->pJointCreate = rJointCreate;
    rdPtr->pAddABackdrop = rAddABackdrop;
    rdPtr->pSubABackdrop = rSubABackdrop;
    rdPtr->pRJointSetLimits = rRJointSetLimits;
    rdPtr->pRJointSetMotor = rRJointSetMotor;
	rdPtr->pAddFan=b2brAddFan;
	rdPtr->pAddMagnet=b2brAddMagnet;
	rdPtr->pAddTreadmill=b2brAddTreadmill;
    
	rdPtr->pCreateBullet=rCreateBullet;
	rdPtr->started=NO;
    
	// If another engine exists with the same identifier -> set identifier to random value
	if (CheckOtherEngines(rdPtr))
		rdPtr->identifier = 1000 + rdPtr->ho->hoNumber;
    
    rdPtr->objects = new CCArrayList();
	rdPtr->objectIDs = new CCArrayList();
	rdPtr->joints = new CCArrayList();
	rdPtr->forces = new CCArrayList();
	rdPtr->torques = new CCArrayList();
	rdPtr->treadmills = new CCArrayList();
	rdPtr->fans = new CCArrayList();
	rdPtr->magnets = new CCArrayList();
    rdPtr->backgroundBases = new CCArrayList();
    rdPtr->bodiesToDestroy = new CCArrayList();
    
	CreateBorders(rdPtr);
    
	// No errors
	return 0;
}

short b2bDestroyRunObject(LPRDATABASE rdPtr, int fast)
{
	delete rdPtr->world;
    delete rdPtr->objects;
	delete rdPtr->objectIDs;
	delete rdPtr->joints;
	delete rdPtr->forces;
	delete rdPtr->torques;
	delete rdPtr->treadmills;
	delete rdPtr->fans;
	delete rdPtr->magnets;

    int n;
    for (n = 0; n < rdPtr->backgroundBases->Size(); n++)
    {
        CRunMBase* pBase = (CRunMBase*)rdPtr->backgroundBases->Get(n);
        delete pBase;
    }
    delete rdPtr->backgroundBases;
	return 0;
}

CObject* GetHO(LPRDATABASE rdPtr, int fixedValue)
{
	CObject* hoPtr=rdPtr->rh->rhObjectList[fixedValue&0xFFFF];
	if (hoPtr!=nil && hoPtr->hoCreationId==fixedValue>>16)
	{
		return hoPtr;
	}
	return nil;
}

short b2bHandleRunObject(LPRDATABASE rdPtr)
{
	b2brStartObject(rdPtr);
    
	int i;
	for (i=0; i<rdPtr->forces->Size(); i++)
	{
		CForce* force = (CForce*)rdPtr->forces->Get(i);
		force->m_body->ApplyForce(force->m_force, force->m_position);
	}
	for (i=0; i<rdPtr->torques->Size(); i++)
	{
		CTorque* torque = (CTorque*)rdPtr->torques->Get(i);
		torque->m_body->ApplyTorque(torque->m_torque);
	}
    
	for (i=0; i<rdPtr->objectIDs->Size(); i++)
	{
		int value=rdPtr->objectIDs->GetInt(i);
		CObject* pHo=GetHO(rdPtr, value);
		CRunMBase* pBase=(CRunMBase*)rdPtr->objects->Get(i);
		if (pHo!=nil && pBase->m_pHo!=pHo)
		{
			pHo=nil;
		}
		if (pHo==nil)
		{
			rDestroyBody(rdPtr, pBase->m_body);
			rdPtr->objectIDs->RemoveIndex(i);
			rdPtr->objects->RemoveIndex(i);
			i--;
		}
		else
		{
			b2Vec2 position((rdPtr->xBase+pHo->hoX)/rdPtr->factor, (rdPtr->yBase-pHo->hoY)/rdPtr->factor);
			float angle=((float)GetAnimDir(pHo, pHo->roc->rcDir))*b2_pi/16.0f;
			pBase->m_body->SetTransform(position, angle);
		}
	}
	if (rdPtr->world!=nil)
	{
		float32 timeStep = 1.0f /rdPtr->rh->rhApp->gaFrameRate;
		rdPtr->world->Step(timeStep, rdPtr->velocityIterations, rdPtr->positionIterations);
	}
    
    if (rdPtr->bodiesToDestroy->Size() > 0)
    {
        for (i = 0; i < rdPtr->bodiesToDestroy->Size(); i++)
        {
            rDestroyBody(rdPtr, (b2Body*)rdPtr->bodiesToDestroy->Get(i));
        }
        rdPtr->bodiesToDestroy->Clear();
    }
        
	return 0;
}

short RACTION_SETGRAVITY(LPRDATABASE rdPtr, CActExtension* act)
{
	CObject* pHo=[act getParamObject:rdPtr->rh withNum:0];
	CRunMBase* pmBase = GetMBase(rdPtr, pHo);
	if (pmBase!=nil)
	{
		int value = [act getParamExpression:rdPtr->rh withNum:1];
		pmBase->m_movement->ActionEntry(pHo, ACT_EXTSETGRAVITYSCALE, value, 0);
	}
	return 0;
}

short RACTION_SETFRICTION(LPRDATABASE rdPtr, CActExtension* act)
{
	CObject* pHo=[act getParamObject:rdPtr->rh withNum:0];
	CRunMBase* pmBase = GetMBase(rdPtr, pHo);
	if (pmBase!=nil)
	{
		int value = [act getParamExpression:rdPtr->rh withNum:1];
		pmBase->m_movement->ActionEntry(pHo, ACT_EXTSETFRICTION, value, 0);
	}
	return 0;
}

short RACTION_SETELASTICITY(LPRDATABASE rdPtr, CActExtension* act)
{
	CObject* pHo=[act getParamObject:rdPtr->rh withNum:0];
	CRunMBase* pmBase = GetMBase(rdPtr, pHo);
	if (pmBase!=nil)
	{
		int value = [act getParamExpression:rdPtr->rh withNum:1];
		pmBase->m_movement->ActionEntry(pHo, ACT_EXTSETELASTICITY, value, 0);
	}
	return 0;
}

short RACTION_SETDENSITY(LPRDATABASE rdPtr, CActExtension* act)
{
	CObject* pHo=[act getParamObject:rdPtr->rh withNum:0];
	CRunMBase* pmBase = GetMBase(rdPtr, pHo);
	if (pmBase!=nil)
	{
		int value = [act getParamExpression:rdPtr->rh withNum:1];
		pmBase->m_movement->ActionEntry(pHo, ACT_EXTSETDENSITY, value, 0);
	}
	return 0;
}

short RACTION_SETITERATIONS(LPRDATABASE rdPtr, CActExtension* act)
{
	rdPtr->velocityIterations=[act getParamExpression:rdPtr->rh withNum:0];
	rdPtr->positionIterations=[act getParamExpression:rdPtr->rh withNum:0];
	return 0;
}
short RACTION_SETGRAVITYFORCE(LPRDATABASE rdPtr, CActExtension* act)
{
	rdPtr->gravity=[act getParamExpDouble:rdPtr->rh withNum:0];
	b2Vec2 gravity((float)rdPtr->gravity*cos(rdPtr->angle), (float)rdPtr->gravity*sin(rdPtr->angle));
	rdPtr->world->SetGravity(gravity);
	return YES;
}
short RACTION_SETGRAVITYANGLE(LPRDATABASE rdPtr, CActExtension* act)
{
	rdPtr->angleBase=[act getParamExpression:rdPtr->rh withNum:0];
	rdPtr->angle=rdPtr->angleBase*b2_pi/180.0f;
	b2Vec2 gravity((float)rdPtr->gravity*cos(rdPtr->angle), (float)rdPtr->gravity*sin(rdPtr->angle));
	rdPtr->world->SetGravity(gravity);
	return YES;
}
CJoint* CreateJoint(LPRDATABASE rdPtr, NSString* name)
{
	CJoint* pJoint;
	pJoint=new CJoint(rdPtr, name);
	rdPtr->joints->Add(pJoint);
	return pJoint;
}
CJoint* GetJoint(LPRDATABASE rdPtr, CJoint* sJoint, NSString* name, int type)
{
	int n;
    int index = 0;
	CJoint* pJoint;
    
    if (sJoint != nil)
    {
        index = rdPtr->joints->IndexOf(sJoint);
        if (index < 0)
            return nil;
        index++;
    }
	for (n=index; n<rdPtr->joints->Size(); n++)
	{
		pJoint=(CJoint*)rdPtr->joints->Get(n);
		if ([pJoint->m_name caseInsensitiveCompare:name]==0)
		{
			break;
		}
	}
	if (n<rdPtr->joints->Size())
	{
		if (type==TYPE_ALL || type==pJoint->m_type)
		{
			return pJoint;
		}
	}
	return nil;
}
b2Vec2 GetActionPointPosition(LPRDATABASE rdPtr, CRunMBase* pBase)
{
	CObject* pHo=pBase->m_pHo;
	float x=(float)pHo->hoX;
	float y=(float)pHo->hoY;
    
	if (pBase->m_image != -1)
	{
        CImage* pImage = [rdPtr->rh->rhApp->imageBank getImageFromHandle:pBase->m_image];
		float angle;
		angle = (float)(pHo->roc->rcAngle * b2_pi / 180.0f);
		float deltaX = (float)(pImage->xAP - pImage->xSpot);
		float deltaY = (float)(pImage->yAP - pImage->ySpot);
        float plusX = (float)(deltaX * cos(angle) - deltaY * sin(angle));
        float plusY = (float)(deltaX * sin(angle) + deltaY * cos(angle));
        x += plusX;
        y += plusY;
	}
	b2Vec2 position((rdPtr->xBase+x)/rdPtr->factor, (rdPtr->yBase-y)/rdPtr->factor);
	return position;
}
short RACTION_DJOINTHOTSPOT(LPRDATABASE rdPtr, CActExtension* act)
{
	NSString* pName = [act getParamExpString:rdPtr->rh withNum:0];
	CRunMBase* pBase1=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:1]);
	CRunMBase* pBase2=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:2]);
	if (pBase1!=nil && pBase2!=nil)
	{
		CJoint* pJoint=CreateJoint(rdPtr, pName);
		b2DistanceJointDef jointDef;
		jointDef.collideConnected=YES;
		b2Vec2 position1=pBase1->m_body->GetPosition();
		b2Vec2 position2=pBase2->m_body->GetPosition();
		jointDef.Initialize(pBase1->m_body, pBase2->m_body, position1, position2);
		pJoint->SetJoint(TYPE_DISTANCE, rdPtr->world->CreateJoint(&jointDef));
	}
	return YES;
}
short RACTION_DJOINTACTIONPOINT(LPRDATABASE rdPtr, CActExtension* act)
{
	NSString* pName = [act getParamExpString:rdPtr->rh withNum:0];
	CRunMBase* pBase1=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:1]);
	CRunMBase* pBase2=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:2]);
	if (pBase1!=nil && pBase2!=nil)
	{
		CJoint* pJoint=CreateJoint(rdPtr, pName);
		b2DistanceJointDef jointDef;
		jointDef.collideConnected=YES;
		jointDef.frequencyHz = 0;
		jointDef.dampingRatio = 0;
		b2Vec2 position1=GetActionPointPosition(rdPtr, pBase1);
		b2Vec2 position2=GetActionPointPosition(rdPtr, pBase2);
		jointDef.Initialize(pBase1->m_body, pBase2->m_body, position1, position2);
		pJoint->SetJoint(TYPE_DISTANCE, rdPtr->world->CreateJoint(&jointDef));
	}
	return YES;
}
short RACTION_DJOINTSETELASTICITY(LPRDATABASE rdPtr, CActExtension* act)
{
    NSString* pName = [act getParamExpString:rdPtr->rh withNum:0];
    float frequency=(float)[act getParamExpression:rdPtr->rh withNum:1];
    float damping=(float)((float)[act getParamExpression:rdPtr->rh withNum:1]/100.0f);
	CJoint* pJoint=GetJoint(rdPtr, nil, pName, TYPE_DISTANCE);
	while (pJoint!=nil)
	{
		b2DistanceJoint* pDJoint=(b2DistanceJoint*)pJoint->m_joint;
		pDJoint->SetFrequency(frequency);
		pDJoint->SetDampingRatio(damping);
        pJoint=GetJoint(rdPtr, pJoint, pName, TYPE_DISTANCE);
	}
	return 0;
}
b2Vec2 GetImagePosition(LPRDATABASE rdPtr, CRunMBase* pBase, int x1, int y1)
{
	b2Vec2 position=pBase->m_body->GetPosition();
	position.x+=x1/rdPtr->factor;
	position.y-=y1/rdPtr->factor;
	return position;
}
short RACTION_DJOINTPOSITION(LPRDATABASE rdPtr, CActExtension* act)
{
	NSString* pName = [act getParamExpString:rdPtr->rh withNum:0];
	CRunMBase* pBase1=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:1]);
	int x1=[act getParamExpression:rdPtr->rh withNum:2];
	int y1=[act getParamExpression:rdPtr->rh withNum:3];
	CRunMBase* pBase2=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:4]);
	int x2=[act getParamExpression:rdPtr->rh withNum:5];
	int y2=[act getParamExpression:rdPtr->rh withNum:6];
	if (pBase1!=nil && pBase2!=nil)
	{
		CJoint* pJoint=CreateJoint(rdPtr, pName);
		b2Vec2 position1=GetImagePosition(rdPtr, pBase1, x1, y1);
		b2Vec2 position2=GetImagePosition(rdPtr, pBase2, x2, y2);
		b2DistanceJointDef jointDef;
		jointDef.collideConnected=YES;
		jointDef.Initialize(pBase1->m_body, pBase2->m_body, position1, position2);
		pJoint->SetJoint(TYPE_DISTANCE, rdPtr->world->CreateJoint(&jointDef));
	}
	return YES;
}
short RACTION_RJOINTHOTSPOT(LPRDATABASE rdPtr, CActExtension* act)
{
	NSString* pName = [act getParamExpString:rdPtr->rh withNum:0];
	CRunMBase* pBase1=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:1]);
	CRunMBase* pBase2=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:2]);
	if (pBase1!=nil && pBase2!=nil)
	{
		CJoint* pJoint=CreateJoint(rdPtr, pName);
		b2RevoluteJointDef jointDef;
		jointDef.collideConnected=YES;
		b2Vec2 position=pBase1->m_body->GetPosition();
		jointDef.Initialize(pBase1->m_body, pBase2->m_body, position);
		pJoint->SetJoint(TYPE_REVOLUTE, rdPtr->world->CreateJoint(&jointDef));
	}
	return YES;
}
short RACTION_RJOINTACTIONPOINT(LPRDATABASE rdPtr, CActExtension* act)
{
	NSString* pName = [act getParamExpString:rdPtr->rh withNum:0];
	CRunMBase* pBase1=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:1]);
	CRunMBase* pBase2=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:2]);
	if (pBase1!=nil && pBase2!=nil)
	{
		CJoint* pJoint=CreateJoint(rdPtr, pName);
		b2RevoluteJointDef jointDef;
		jointDef.collideConnected=YES;
		b2Vec2 position=GetActionPointPosition(rdPtr, pBase1);
		jointDef.Initialize(pBase1->m_body, pBase2->m_body, position);
		pJoint->SetJoint(TYPE_REVOLUTE, rdPtr->world->CreateJoint(&jointDef));
	}
	return YES;
}
short RACTION_RJOINTPOSITION(LPRDATABASE rdPtr, CActExtension* act)
{
	NSString* pName = [act getParamExpString:rdPtr->rh withNum:0];
	CRunMBase* pBase1=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:1]);
	int x1=[act getParamExpression:rdPtr->rh withNum:2];
	int y1=[act getParamExpression:rdPtr->rh withNum:3];
	CRunMBase* pBase2=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:1]);
	if (pBase1!=nil && pBase2!=nil)
	{
		CJoint* pJoint=CreateJoint(rdPtr, pName);
		b2RevoluteJointDef jointDef;
		jointDef.collideConnected=YES;
		b2Vec2 position=GetImagePosition(rdPtr, pBase1, x1, y1);
		jointDef.Initialize(pBase1->m_body, pBase2->m_body, position);
		pJoint->SetJoint(TYPE_REVOLUTE, rdPtr->world->CreateJoint(&jointDef));
	}
	return YES;
}
short RACTION_RJOINTSETLIMITS(LPRDATABASE rdPtr, CActExtension* act)
{
    NSString* pName =[act getParamExpString:rdPtr->rh withNum:0];
    float lAngle=(float)((float)[act getParamExpression:rdPtr->rh withNum:1]*b2_pi/180.0f);
    float uAngle=(float)((float)[act getParamExpression:rdPtr->rh withNum:2]*b2_pi/180.0f);
	CJoint* pJoint=GetJoint(rdPtr, nil, pName, TYPE_REVOLUTE);
	while (pJoint!=nil)
	{
		b2RevoluteJoint* pRJoint=(b2RevoluteJoint*)pJoint->m_joint;
		if (lAngle>uAngle)
		{
			pRJoint->EnableLimit(NO);
		}
		else
		{
			pRJoint->EnableLimit(YES);
			pRJoint->SetLimits(lAngle, uAngle);
		}
        pJoint=GetJoint(rdPtr, pJoint, pName, TYPE_REVOLUTE);
	}
	return 0;
}
#define RMOTORTORQUEMULT 20.0f
#define RMOTORSPEEDMULT 10.0f
short RACTION_RJOINTSETMOTOR(LPRDATABASE rdPtr, CActExtension* act)
{
    NSString* pName = [act getParamExpString:rdPtr->rh withNum:0];
    float torque=(float)((float)[act getParamExpression:rdPtr->rh withNum:1]/100.0f)*RMOTORTORQUEMULT;
    float speed=(float)((float)[act getParamExpression:rdPtr->rh withNum:2]/100.0f)*RMOTORSPEEDMULT;
	CJoint* pJoint=GetJoint(rdPtr, nil, pName, TYPE_REVOLUTE);
	while (pJoint!=nil)
	{
		b2RevoluteJoint* pRJoint=(b2RevoluteJoint*)pJoint->m_joint;
		bool flag=YES;
		if (torque==0 && speed==0)
			flag=NO;
		pRJoint->EnableMotor(flag);
		pRJoint->SetMaxMotorTorque(torque);
		pRJoint->SetMotorSpeed(-speed);
        pJoint=GetJoint(rdPtr, pJoint, pName, TYPE_REVOLUTE);
	}
	return 0;
}
short RACTION_PJOINTHOTSPOT(LPRDATABASE rdPtr, CActExtension* act)
{
	NSString* pName = [act getParamExpString:rdPtr->rh withNum:0];
	CRunMBase* pBase1=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:1]);
	CRunMBase* pBase2=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:2]);
	if (pBase1!=nil && pBase2!=nil)
	{
		CJoint* pJoint=CreateJoint(rdPtr, pName);
		b2PrismaticJointDef jointDef;
		jointDef.collideConnected=YES;
		b2Vec2 position1=pBase1->m_body->GetPosition();
		b2Vec2 position2=pBase2->m_body->GetPosition();
		b2Vec2 axis(position2.x-position1.x, position2.y-position1.y);
		jointDef.Initialize(pBase1->m_body, pBase2->m_body, position1, axis);
		pJoint->SetJoint(TYPE_PRISMATIC, rdPtr->world->CreateJoint(&jointDef));
	}
	return YES;
}
short RACTION_PJOINTACTIONPOINT(LPRDATABASE rdPtr, CActExtension* act)
{
	NSString* pName = [act getParamExpString:rdPtr->rh withNum:0];
	CRunMBase* pBase1=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:1]);
	CRunMBase* pBase2=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:2]);
	if (pBase1!=nil && pBase2!=nil)
	{
		CJoint* pJoint=CreateJoint(rdPtr, pName);
		b2PrismaticJointDef jointDef;
		jointDef.collideConnected=YES;
		b2Vec2 position1=GetActionPointPosition(rdPtr, pBase1);
		b2Vec2 position2=GetActionPointPosition(rdPtr, pBase2);
		b2Vec2 axis(position2.x-position1.x, position2.y-position1.y);
		jointDef.Initialize(pBase1->m_body, pBase2->m_body, position1, axis);
		pJoint->SetJoint(TYPE_PRISMATIC, rdPtr->world->CreateJoint(&jointDef));
	}
	return YES;
}
short RACTION_PJOINTPOSITION(LPRDATABASE rdPtr, CActExtension* act)
{
	NSString* pName = [act getParamExpString:rdPtr->rh withNum:0];
	CRunMBase* pBase1=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:1]);
	int x1=[act getParamExpression:rdPtr->rh withNum:2];
	int y1=[act getParamExpression:rdPtr->rh withNum:3];
	CRunMBase* pBase2=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:4]);
	int x2=[act getParamExpression:rdPtr->rh withNum:5];
	int y2=[act getParamExpression:rdPtr->rh withNum:6];
	if (pBase1!=nil && pBase2!=nil)
	{
		CJoint* pJoint=CreateJoint(rdPtr, pName);
		b2PrismaticJointDef jointDef;
		jointDef.collideConnected=YES;
		b2Vec2 position1=GetImagePosition(rdPtr, pBase1, x1, y1);
		b2Vec2 position2=GetImagePosition(rdPtr, pBase1, x2, y2);
		b2Vec2 axis(position2.x-position1.x, position2.y-position1.y);
		jointDef.Initialize(pBase1->m_body, pBase2->m_body, position1, axis);
		pJoint->SetJoint(TYPE_PRISMATIC, rdPtr->world->CreateJoint(&jointDef));
	}
	return YES;
}
short RACTION_PJOINTSETLIMITS(LPRDATABASE rdPtr, CActExtension* act)
{
    NSString* pName = [act getParamExpString:rdPtr->rh withNum:0];
    float lLimit=(float)((float)[act getParamExpression:rdPtr->rh withNum:1]/rdPtr->factor);
    float uLimit=(float)((float)[act getParamExpression:rdPtr->rh withNum:2]/rdPtr->factor);
	CJoint* pJoint=GetJoint(rdPtr, nil, pName, TYPE_PRISMATIC);
	while (pJoint!=nil)
	{
		b2PrismaticJoint* pRJoint=(b2PrismaticJoint*)pJoint->m_joint;
		bool flag=YES;
		if (lLimit>uLimit)
			flag=NO;
		pRJoint->EnableLimit(flag);
		pRJoint->SetLimits(lLimit, uLimit);
        pJoint=GetJoint(rdPtr, pJoint, pName, TYPE_PRISMATIC);
	}
	return 0;
}
#define PJOINTMOTORFORCEMULT 20.0f
#define PJOINTMOTORSPEEDMULT 10.0f
short RACTION_PJOINTSETMOTOR(LPRDATABASE rdPtr, CActExtension* act)
{
    NSString* pName = [act getParamExpString:rdPtr->rh withNum:0];
    float force=(float)((float)[act getParamExpression:rdPtr->rh withNum:1]/100.0f)*PJOINTMOTORFORCEMULT;
    float speed=(float)((float)[act getParamExpression:rdPtr->rh withNum:2]/100.0f)*PJOINTMOTORSPEEDMULT;
	CJoint* pJoint=GetJoint(rdPtr, nil, pName, TYPE_PRISMATIC);
	while (pJoint!=nil)
	{
		b2PrismaticJoint* pRJoint=(b2PrismaticJoint*)pJoint->m_joint;
		bool flag=YES;
		if (force==0 && speed==0)
			flag=NO;
		pRJoint->EnableMotor(flag);
		pRJoint->SetMaxMotorForce(force);
		pRJoint->SetMotorSpeed(speed);
        pJoint=GetJoint(rdPtr, pJoint, pName, TYPE_PRISMATIC);
	}
	return 0;
}
short RACTION_PUJOINTHOTSPOT(LPRDATABASE rdPtr, CActExtension* act)
{
	NSString* pName = [act getParamExpString:rdPtr->rh withNum:0];
	CRunMBase* pBase1=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:1]);
	CRunMBase* pBase2=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:2]);
	if (pBase1!=nil && pBase2!=nil)
	{
		CJoint* pJoint=CreateJoint(rdPtr, pName);
		b2PulleyJointDef jointDef;
		jointDef.collideConnected=YES;
		b2Vec2 position1=pBase1->m_body->GetPosition();
		b2Vec2 position2=pBase2->m_body->GetPosition();
		float length1=(float)((float)[act getParamExpression:rdPtr->rh withNum:3]/rdPtr->factor);
		float angle1=(float)((float)[act getParamExpression:rdPtr->rh withNum:4]*b2_pi/180.0f);
		float length2=(float)((float)[act getParamExpression:rdPtr->rh withNum:5]/rdPtr->factor);
		float angle2=(float)((float)[act getParamExpression:rdPtr->rh withNum:6]*b2_pi/180.0f);
		float ratio=(float)((float)[act getParamExpression:rdPtr->rh withNum:7]/100.0f);
		b2Vec2 rope1(position1.x+length1*cos(angle1), position1.y+length1*sin(angle1));
		b2Vec2 rope2(position2.x+length2*cos(angle2), position2.y+length2*sin(angle2));
		jointDef.Initialize(pBase1->m_body, pBase2->m_body, rope1, rope2, position1, position2, ratio);
		pJoint->SetJoint(TYPE_PULLEY, rdPtr->world->CreateJoint(&jointDef));
	}
	return YES;
}
short RACTION_PUJOINTACTIONPOINT(LPRDATABASE rdPtr, CActExtension* act)
{
	NSString* pName = [act getParamExpString:rdPtr->rh withNum:0];
	CRunMBase* pBase1=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:1]);
	CRunMBase* pBase2=GetMBase(rdPtr, [act getParamObject:rdPtr->rh withNum:2]);
	if (pBase1!=nil && pBase2!=nil)
	{
		CJoint* pJoint=CreateJoint(rdPtr, pName);
		b2PulleyJointDef jointDef;
		jointDef.collideConnected=YES;
		b2Vec2 position1=GetActionPointPosition(rdPtr, pBase1);
		b2Vec2 position2=GetActionPointPosition(rdPtr, pBase2);
		float length1=(float)((float)[act getParamExpression:rdPtr->rh withNum:3]/rdPtr->factor);
		float angle1=(float)((float)[act getParamExpression:rdPtr->rh withNum:4]*b2_pi/180.0f);
		float length2=(float)((float)[act getParamExpression:rdPtr->rh withNum:5]/rdPtr->factor);
		float angle2=(float)((float)[act getParamExpression:rdPtr->rh withNum:6]*b2_pi/180.0f);
		float ratio=(float)((float)[act getParamExpression:rdPtr->rh withNum:7]/100.0f);
		b2Vec2 rope1(position1.x+length1*cos(angle1), position1.y+length1*sin(angle1));
		b2Vec2 rope2(position2.x+length2*cos(angle2), position2.y+length2*sin(angle2));
		jointDef.Initialize(pBase1->m_body, pBase2->m_body, rope1, rope2, position1, position2, ratio);
		pJoint->SetJoint(TYPE_PULLEY, rdPtr->world->CreateJoint(&jointDef));
	}
	return YES;
}

short RACTION_DESTROYJOINT(LPRDATABASE rdPtr, CActExtension* act)
{
    int n;
    NSString* name = [act getParamExpString:rdPtr->rh withNum:0];
    for (n=0; n<rdPtr->joints->Size(); n++)
	{
		CJoint* pJoint=(CJoint*)rdPtr->joints->Get(n);
		if ([pJoint->m_name caseInsensitiveCompare:name]==0)
		{
            rdPtr->world->DestroyJoint(pJoint->m_joint);
            rdPtr->joints->RemoveObject(pJoint);
            n--;
		}
	}
	return 0;
}
void destroyJointWithBody(LPRDATABASE rdPtr, b2Body* body)
{
    int n;
    for (n=0; n<rdPtr->joints->Size(); n++)
	{
		CJoint* pJoint=(CJoint*)rdPtr->joints->Get(n);
		if (pJoint->m_joint->GetBodyA() == body || pJoint->m_joint->GetBodyB() == body)
		{
            rdPtr->joints->RemoveObject(pJoint);
            n--;
		}
	}
}

short RACTION_ADDOBJECT(LPRDATABASE rdPtr, CActExtension* act)
{
	CObject* pHo=[act getParamObject:rdPtr->rh withNum:0];
	if (rdPtr->objects->IndexOf(pHo)<0)
	{
		if (GetMBase(rdPtr, pHo) == nil)
		{
			CRunMBase* pBase=new CRunMBase(rdPtr, pHo, MTYPE_FAKEOBJECT);
			float angle=GetAnimDir(pHo, pHo->roc->rcDir)*11.25f;
			float density = (float)((float)[act getParamExpression:rdPtr->rh withNum:1]/100.0);
			float friction = (float)((float)[act getParamExpression:rdPtr->rh withNum:2]/100.0);
			int shape = [act getParamExpression:rdPtr->rh withNum:3];
			pBase->m_body=rCreateBody(rdPtr, b2_staticBody, pHo->hoX, pHo->hoY, angle, 0, (void*)pBase, 0, 0);
			switch(shape)
			{
                case 0:
                    rBodyCreateBoxFixture(rdPtr, pBase->m_body, pBase, pHo->hoX, pHo->hoY, pHo->hoImgWidth, pHo->hoImgHeight, density, friction, 0);
                    break;
                case 1:
                    rBodyCreateCircleFixture(rdPtr, pBase->m_body, pBase, pHo->hoX, pHo->hoY, pHo->hoImgWidth/2, density, friction, 0);
                    break;
                default:
                    rBodyCreateShapeFixture(rdPtr, pBase->m_body, pBase, pHo->hoX, pHo->hoY, pHo->roc->rcImage, density, friction, 0, pHo->roc->rcScaleX, pHo->roc->rcScaleY);
                    break;
			}
			rdPtr->objects->Add(pBase);
			rdPtr->objectIDs->AddInt((pHo->hoCreationId<<16)|(pHo->hoNumber&0xFFFF));
		}
	}
	return YES;
}
short RACTION_SUBOBJECT(LPRDATABASE rdPtr, CActExtension* act)
{
	CObject* pHo=[act getParamObject:rdPtr->rh withNum:0];
    int n;
    CRunMBase* pBase;
    for (n = 0; n < rdPtr->objects->Size(); n++)
    {
        CRunMBase* pBase = (CRunMBase*)rdPtr->objects->Get(n);
        if (pBase->m_pHo == pHo)
            break;
    }
	if (n < rdPtr->objects->Size())
	{
		rDestroyBody(rdPtr, pBase->m_body);
		rdPtr->objects->RemoveIndex(n);
		rdPtr->objectIDs->RemoveIndex(n);
	}
	return YES;
}

CValue* REXPRESSION_GRAVITYSTRENGTH(LPRDATABASE rdPtr)
{
    CValue* ret=[rdPtr->rh getTempValue:0];
	[ret forceDouble:rdPtr->gravity];
	return ret;
}
CValue* REXPRESSION_GRAVITYANGLE(LPRDATABASE rdPtr)
{
    CValue* ret=[rdPtr->rh getTempValue:0];
	[ret forceInt:rdPtr->angleBase];
	return ret;
}
CValue* REXPRESSION_VELOCITYITERATIONS(LPRDATABASE rdPtr)
{
    CValue* ret=[rdPtr->rh getTempValue:0];
	[ret forceInt:rdPtr->velocityIterations];
	return ret;
}
CValue* REXPRESSION_POSITIONITERATIONS(LPRDATABASE rdPtr)
{
    CValue* ret=[rdPtr->rh getTempValue:0];
	[ret forceInt:rdPtr->positionIterations];
	return ret;
}
CValue* REXPRESSION_ELASTICITYFREQUENCY(LPRDATABASE rdPtr)
{
	NSString* pName = [[rdPtr->ho getExpParam] getString];
	CJoint* pJoint=GetJoint(rdPtr, nil, pName, TYPE_DISTANCE);
    CValue* ret=[rdPtr->rh getTempValue:0];
	if (pJoint!=nil)
	{
        [ret forceDouble:((b2DistanceJoint*)pJoint->m_joint)->GetFrequency()];
        return ret;
	}
	return ret;
}
CValue* REXPRESSION_ELASTICITYDAMPING(LPRDATABASE rdPtr)
{
	NSString* pName = [[rdPtr->ho getExpParam] getString];
	CJoint* pJoint=GetJoint(rdPtr, nil, pName, TYPE_DISTANCE);
    CValue* ret=[rdPtr->rh getTempValue:0];
	if (pJoint!=nil)
	{
        [ret forceInt:(int)(((b2DistanceJoint*)pJoint->m_joint)->GetDampingRatio()*100)];
        return ret;
	}
	return ret;
}
CValue* REXPRESSION_LOWERANGLELIMIT(LPRDATABASE rdPtr)
{
	NSString* pName = [[rdPtr->ho getExpParam] getString];
	CJoint* pJoint=GetJoint(rdPtr, nil, pName, TYPE_REVOLUTE);
    CValue* ret=[rdPtr->rh getTempValue:0];
	if (pJoint!=nil)
	{
        [ret forceInt:(int)(((b2RevoluteJoint*)pJoint->m_joint)->GetLowerLimit()*180.0f/b2_pi)];
        return ret;
	}
	return ret;
}
CValue* REXPRESSION_UPPERANGLELIMIT(LPRDATABASE rdPtr)
{
	NSString* pName = [[rdPtr->ho getExpParam] getString];
	CJoint* pJoint=GetJoint(rdPtr, nil, pName, TYPE_REVOLUTE);
    CValue* ret=[rdPtr->rh getTempValue:0];
	if (pJoint!=nil)
	{
        [ret forceInt:(int)(((b2RevoluteJoint*)pJoint->m_joint)->GetUpperLimit()*180.0f/b2_pi)];
        return ret;
	}
	return ret;
}
CValue* REXPRESSION_MOTORSTRENGTH(LPRDATABASE rdPtr)
{
	NSString* pName = [[rdPtr->ho getExpParam] getString];
	CJoint* pJoint=GetJoint(rdPtr, nil, pName, TYPE_REVOLUTE);
    CValue* ret=[rdPtr->rh getTempValue:0];
	if (pJoint!=nil)
	{
        [ret forceInt:(int)(((b2RevoluteJoint*)pJoint->m_joint)->GetMaxMotorTorque()*100/RMOTORTORQUEMULT)];
        return ret;
	}
	return 0;
}
CValue* REXPRESSION_MOTORSPEED(LPRDATABASE rdPtr)
{
	NSString* pName = [[rdPtr->ho getExpParam] getString];
	CJoint* pJoint=GetJoint(rdPtr, nil, pName, TYPE_REVOLUTE);
    CValue* ret=[rdPtr->rh getTempValue:0];
	if (pJoint!=nil)
	{
        [ret forceInt:(int)(((b2RevoluteJoint*)pJoint->m_joint)->GetMotorSpeed()*100/RMOTORSPEEDMULT)];
        return ret;
	}
	return ret;
}
CValue* REXPRESSION_LOWERTRANSLATION(LPRDATABASE rdPtr)
{
	NSString* pName = [[rdPtr->ho getExpParam] getString];
	CJoint* pJoint=GetJoint(rdPtr, nil, pName, TYPE_PRISMATIC);
    CValue* ret=[rdPtr->rh getTempValue:0];
	if (pJoint!=nil)
	{
        [ret forceInt:(int)(((b2PrismaticJoint*)pJoint->m_joint)->GetLowerLimit()*rdPtr->factor)];
        return ret;
	}
	return ret;
}
CValue* REXPRESSION_UPPERTRANSLATION(LPRDATABASE rdPtr)
{
	NSString* pName = [[rdPtr->ho getExpParam] getString];
	CJoint* pJoint=GetJoint(rdPtr, nil, pName, TYPE_PRISMATIC);
    CValue* ret=[rdPtr->rh getTempValue:0];
	if (pJoint!=nil)
	{
        [ret forceInt:(int)(((b2PrismaticJoint*)pJoint->m_joint)->GetUpperLimit()*rdPtr->factor)];
        return ret;
	}
	return ret;
}
CValue* REXPRESSION_PMOTORSTRENGTH(LPRDATABASE rdPtr)
{
	NSString* pName = [[rdPtr->ho getExpParam] getString];
	CJoint* pJoint=GetJoint(rdPtr, nil, pName, TYPE_PRISMATIC);
    CValue* ret=[rdPtr->rh getTempValue:0];
	if (pJoint!=nil)
	{
        [ret forceInt:(int)(((b2PrismaticJoint*)pJoint->m_joint)->GetMaxMotorForce()*100/PJOINTMOTORFORCEMULT)];
        return ret;
	}
	return ret;
}
CValue* REXPRESSION_PMOTORSPEED(LPRDATABASE rdPtr)
{
	NSString* pName = [[rdPtr->ho getExpParam] getString];
	CJoint* pJoint=GetJoint(rdPtr, nil, pName, TYPE_PRISMATIC);
    CValue* ret=[rdPtr->rh getTempValue:0];
	if (pJoint!=nil)
	{
        [ret forceInt:(int)(((b2PrismaticJoint*)pJoint->m_joint)->GetMotorSpeed()*100/PJOINTMOTORSPEEDMULT)];
        return ret;
	}
	return ret;
}

// CONTACT LISTENER
////////////////////////////////////////////////////////////////////
#define	NUMCND_EXTCOLBACK 13
#define NUMCND_EXTCOLLISION 14
#define NUMCND_EXTOUTPLAYFIELD 12
enum
{
	CND_ONEACH,
	CND_PARTICULECOLLISION,
	CND_PARTICULEOUTLEFT,
	CND_PARTICULEOUTRIGHT,
	CND_PARTICULEOUTTOP,
	CND_PARTICULEOUTBOTTOM,
	CND_PARTICULESCOLLISION,
	CND_PARTICULECOLLISIONBACKDROP,
	CND_LAST_PARTICULES
};
enum
{
	CND_ONEACHRC,
	CND_ELEMENTCOLLISIONRC,
	CND_ELEMENTOUTLEFTRC,
	CND_ELEMENTOUTRIGHTRC,
	CND_ELEMENTOUTTOPRC,
	CND_ELEMENTOUTBOTTOMRC,
	CND_NONE,
	CND_ELEMENTCOLLISIONBACKDROPRC,
	CND_LAST_RC
};

void ContactListener::PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
{
    bWorking = YES;
    
	b2WorldManifold worldManifold;
	contact->GetWorldManifold(&worldManifold);
	const b2Body* bodyA = contact->GetFixtureA()->GetBody();
	const b2Body* bodyB = contact->GetFixtureB()->GetBody();
	LPRDATABASE rdPtr=(LPRDATABASE)contact->GetFixtureA()->GetUserData();
	CRun* rhPtr=rdPtr->rh;
    
	CRunMBase* movement1=(CRunMBase*)bodyA->GetUserData();
	CRunMBase* movement2=(CRunMBase*)bodyB->GetUserData();
	CRunMBase* movement;
	CRunMBase* movementB;
    
	DWORD params[2];
	params[0] = 0;
	params[1] = 0;
	CParticule* particule;
	LPRDATAPARTICULES parent;
	LPRDATARC rope;
	CElement* element;
	CObject* pHo;
    
	if (movement1==nil || movement2==nil)
	{
		contact->SetEnabled(NO);
	}
    else if (movement1->m_type == MTYPE_BORDERLEFT || movement2->m_type == MTYPE_BORDERLEFT)
    {
        if (movement1->m_type == MTYPE_BORDERLEFT)
		{
            movement = movement2;
			movementB = movement1;
		}
        else
		{
            movement = movement1;
			movementB = movement2;
		}
        
		switch (movement->m_type)
		{
            case MTYPE_OBJECT:
                movement->PrepareCondition();
                ((CRunMvtPhysics*)movement->m_movement)->SetCollidingObject(movementB);
                pHo = movement->m_pHo;
                rhPtr->rhEvtProg->rhCurParam[0] = BORDER_LEFT;
                [rhPtr->rhEvtProg handle_Event:pHo withCode:CNDL_EXTOUTPLAYFIELD];
                if (!movement->IsStop())
                    contact->SetEnabled(NO);
                break;
            case MTYPE_FAKEOBJECT:
                contact->SetEnabled(NO);
                break;
            case MTYPE_PARTICULE:
                particule = (CParticule*)movement->m_particule;
                parent = (LPRDATAPARTICULES)particule->parent;
                parent->currentParticule1 = particule;
                parent->currentParticule2 = nil;
                parent->stopped = NO;
                [parent->ho generateEvent:CND_PARTICULEOUTLEFT withParam:0];
                if (!parent->stopped)
                    contact->SetEnabled(NO);
                break;
            case MTYPE_ELEMENT:
                element = (CElement*)movement->m_element;
                rope = element->parent;
                rope->currentElement = element;
                rope->stopped = NO;
                [rope->ho generateEvent:CND_ELEMENTOUTLEFTRC withParam:0];
                if (!rope->stopped)
                    contact->SetEnabled(NO);
                break;
		}
    }
    else if (movement1->m_type == MTYPE_BORDERRIGHT || movement2->m_type == MTYPE_BORDERRIGHT)
    {
        if (movement1->m_type == MTYPE_BORDERRIGHT)
		{
            movement = movement2;
			movementB = movement1;
		}
        else
		{
            movement = movement1;
			movementB = movement2;
		}
        
		switch (movement->m_type)
		{
            case MTYPE_OBJECT:
                movement->PrepareCondition();
                ((CRunMvtPhysics*)movement->m_movement)->SetCollidingObject(movementB);
                pHo = movement->m_pHo;
                rhPtr->rhEvtProg->rhCurParam[0] = BORDER_RIGHT;
                [rhPtr->rhEvtProg handle_Event:pHo withCode:CNDL_EXTOUTPLAYFIELD];
                if (!movement->IsStop())
                    contact->SetEnabled(NO);
                break;
            case MTYPE_FAKEOBJECT:
                contact->SetEnabled(NO);
                break;
            case MTYPE_PARTICULE:
                particule = (CParticule*)movement->m_particule;
                parent = (LPRDATAPARTICULES)particule->parent;
                parent->currentParticule1 = particule;
                parent->currentParticule2 = nil;
                parent->stopped = NO;
                [parent->ho generateEvent:CND_PARTICULEOUTRIGHT withParam:0];
                if (!parent->stopped)
                    contact->SetEnabled(NO);
                break;
            case MTYPE_ELEMENT:
                element = (CElement*)movement->m_element;
                rope = element->parent;
                rope->currentElement = element;
                rope->stopped = NO;
                [rope->ho generateEvent:CND_ELEMENTOUTRIGHTRC withParam:0];
                if (!rope->stopped)
                    contact->SetEnabled(NO);
                break;
		}
    }
    else if (movement1->m_type == MTYPE_BORDERTOP || movement2->m_type == MTYPE_BORDERTOP)
    {
        if (movement1->m_type == MTYPE_BORDERTOP)
		{
            movement = movement2;
			movementB = movement1;
		}
        else
		{
            movement = movement1;
			movementB = movement2;
		}
        
		switch (movement->m_type)
		{
            case MTYPE_OBJECT:
                movement->PrepareCondition();
                ((CRunMvtPhysics*)movement->m_movement)->SetCollidingObject(movementB);
                pHo = movement->m_pHo;
                rhPtr->rhEvtProg->rhCurParam[0] = BORDER_TOP;
                [rhPtr->rhEvtProg handle_Event:pHo withCode:CNDL_EXTOUTPLAYFIELD];
                if (!movement->IsStop())
                    contact->SetEnabled(NO);
                break;
            case MTYPE_FAKEOBJECT:
                contact->SetEnabled(NO);
                break;
            case MTYPE_PARTICULE:
                particule = (CParticule*)movement->m_particule;
                parent = (LPRDATAPARTICULES)particule->parent;
                parent->currentParticule1 = particule;
                parent->currentParticule2 = nil;
                parent->stopped = NO;
                [parent->ho generateEvent:CND_PARTICULEOUTTOP withParam:0];
                if (!parent->stopped)
                    contact->SetEnabled(NO);
                break;
            case MTYPE_ELEMENT:
                element = (CElement*)movement->m_element;
                rope = element->parent;
                rope->currentElement = element;
                rope->stopped = NO;
                [rope->ho generateEvent:CND_ELEMENTOUTTOPRC withParam:0];
                if (!rope->stopped)
                    contact->SetEnabled(NO);
                break;
		}
    }
    else if (movement1->m_type == MTYPE_BORDERBOTTOM || movement2->m_type == MTYPE_BORDERBOTTOM)
    {
        if (movement1->m_type == MTYPE_BORDERBOTTOM)
		{
            movement = movement2;
			movementB = movement1;
		}
        else
		{
            movement = movement1;
			movementB = movement2;
		}
        
		switch (movement->m_type)
		{
            case MTYPE_OBJECT:
                movement->PrepareCondition();
                ((CRunMvtPhysics*)movement->m_movement)->SetCollidingObject(movementB);
                pHo = movement->m_pHo;
                rhPtr->rhEvtProg->rhCurParam[0] = BORDER_BOTTOM;
                [rhPtr->rhEvtProg handle_Event:pHo withCode:CNDL_EXTOUTPLAYFIELD];
                if (!movement->IsStop())
                    contact->SetEnabled(NO);
                break;
            case MTYPE_FAKEOBJECT:
                contact->SetEnabled(NO);
                break;
            case MTYPE_PARTICULE:
                particule = (CParticule*)movement->m_particule;
                parent = (LPRDATAPARTICULES)particule->parent;
                parent->currentParticule1 = particule;
                parent->currentParticule2 = nil;
                parent->stopped = NO;
                [parent->ho generateEvent:CND_PARTICULEOUTBOTTOM withParam:0];
                if (!parent->stopped)
                    contact->SetEnabled(NO);
                break;
            case MTYPE_ELEMENT:
                element = (CElement*)movement->m_element;
                rope = element->parent;
                rope->currentElement = element;
                rope->stopped = NO;
                [rope->ho generateEvent:CND_ELEMENTOUTBOTTOMRC withParam:0];
                if (!rope->stopped)
                    contact->SetEnabled(NO);
                break;
		}
    }
    else if (movement1->m_type == MTYPE_OBSTACLE || movement2->m_type == MTYPE_OBSTACLE)
    {
        if (movement1->m_type == MTYPE_OBSTACLE)
		{
            movement = movement2;
			movementB = movement1;
		}
        else
		{
            movement = movement1;
			movementB = movement2;
		}
        
		switch (movement->m_type)
		{
            case MTYPE_OBJECT:
                movement->PrepareCondition();
                ((CRunMvtPhysics*)movement->m_movement)->SetCollidingObject(movementB);
                pHo=movement->m_pHo;
                [rhPtr->rhEvtProg handle_Event:pHo withCode:CNDL_EXTCOLBACK];
                if (!movement->IsStop())
                    contact->SetEnabled(NO);
                break;
            case MTYPE_FAKEOBJECT:
                contact->SetEnabled(NO);
                break;
            case MTYPE_PARTICULE:
                particule = (CParticule*)movement->m_particule;
                parent = (LPRDATAPARTICULES)particule->parent;
                parent->currentParticule1 = particule;
                parent->currentParticule2 = nil;
                parent->stopped = NO;
                [parent->ho generateEvent:CND_PARTICULECOLLISIONBACKDROP withParam:0];
                if (!parent->stopped)
                    contact->SetEnabled(NO);
                break;
            case MTYPE_ELEMENT:
                element = (CElement*)movement->m_element;
                rope = element->parent;
                rope->currentElement = element;
                rope->stopped = NO;
                [rope->ho generateEvent:CND_ELEMENTCOLLISIONBACKDROPRC withParam:0];
                if (!rope->stopped)
                    contact->SetEnabled(NO);
                break;
		}
	}
    else if (movement1->m_type == MTYPE_PLATFORM || movement2->m_type == MTYPE_PLATFORM)
    {
		b2Vec2 velocity;
        if (movement1->m_type == MTYPE_PLATFORM)
		{
            movement = movement2;
			movementB = movement1;
			velocity=bodyB->GetLinearVelocity();
		}
        else
		{
            movement = movement1;
			movementB = movement2;
			velocity=bodyA->GetLinearVelocity();
		}
		switch (movement->m_type)
		{
            case MTYPE_OBJECT:
                movement->PrepareCondition();
                ((CRunMvtPhysics*)movement->m_movement)->SetCollidingObject(movementB);
                pHo=movement->m_pHo;
                [rhPtr->rhEvtProg handle_Event:pHo withCode:CNDL_EXTCOLBACK];
                if (!movement->IsStop())
                    contact->SetEnabled(NO);
                else
                {
                    if (velocity.y>=0.0f)
                    {
                        contact->SetEnabled(NO);
                    }
                }
                break;
            case MTYPE_FAKEOBJECT:
                contact->SetEnabled(NO);
                break;
            case MTYPE_PARTICULE:
                particule = (CParticule*)movement->m_particule;
                parent = (LPRDATAPARTICULES)particule->parent;
                parent->currentParticule1 = particule;
                parent->currentParticule2 = nil;
                parent->stopped = NO;
                [parent->ho generateEvent:CND_PARTICULECOLLISIONBACKDROP withParam:0];
                if (!parent->stopped)
                    contact->SetEnabled(NO);
                else
                {
                    if (velocity.y >= 0.0)
                        contact->SetEnabled(NO);
                }
                break;
            case MTYPE_ELEMENT:
                element = (CElement*)movement->m_element;
                rope = element->parent;
                rope->currentElement = element;
                rope->stopped = NO;
                [rope->ho generateEvent:CND_ELEMENTCOLLISIONBACKDROPRC withParam:0];
                if (!rope->stopped)
                    contact->SetEnabled(NO);
                else
                {
                    if (velocity.y >= 0.0)
                        contact->SetEnabled(NO);
                }
                break;
		}
	}
	else
	{
        movement = movement1;
		switch (movement->m_type)
		{
            case MTYPE_OBJECT:
                switch (movement2->m_type)
			{
                case MTYPE_OBJECT:
				{
                    if (movement->m_background)
                    {
                        CRunMBase* temp = movement;
                        movement = movement2;
                        movement2 = temp;
                    }
					movement->PrepareCondition();
					movement2->PrepareCondition();
					((CRunMvtPhysics*)movement->m_movement)->SetCollidingObject(movement2);
					((CRunMvtPhysics*)movement2->m_movement)->SetCollidingObject(movement);
					pHo=movement->m_pHo;
					CObject* pHo2=movement2->m_pHo;
					rhPtr->rhEvtProg->rh1stObjectNumber = pHo2->hoNumber;
					params[0] = pHo2->hoOi;
					[rhPtr->rhEvtProg handle_Event:pHo withCode:CNDL_EXTCOLLISION];
					if (!movement->IsStop() && !movement2->IsStop())
						contact->SetEnabled(NO);
                    break;
				}
                case MTYPE_FAKEOBJECT:
				{
					movement->PrepareCondition();
					movement2->PrepareCondition();
					((CRunMvtPhysics*)movement->m_movement)->SetCollidingObject(movement2);
					pHo=movement->m_pHo;
					CObject* pHo2=movement2->m_pHo;
					rhPtr->rhEvtProg->rh1stObjectNumber = pHo2->hoNumber;
					rhPtr->rhEvtProg->rhCurParam[0] = pHo2->hoOi;
					[rhPtr->rhEvtProg handle_Event:pHo withCode:CNDL_EXTCOLLISION];
					if (!movement->IsStop())
						contact->SetEnabled(NO);
                    break;
				}
                case MTYPE_PARTICULE:
                    particule = (CParticule*)movement2->m_particule;
                    parent = (LPRDATAPARTICULES)particule->parent;
                    parent->currentParticule1 = particule;
                    parent->currentParticule2 = nil;
                    parent->stopped = NO;
                    parent->collidingHO = movement->m_pHo;
                    movement->PrepareCondition();
                    ((CRunMvtPhysics*)movement->m_movement)->SetCollidingObject(movement2);
                    [movement2->m_pHo generateEvent:CND_PARTICULECOLLISION withParam:movement->m_pHo->hoOi];
                    if (!movement->IsStop() && !parent->stopped)
                        contact->SetEnabled(NO);
                    break;
                case MTYPE_ELEMENT:
                    element = (CElement*)movement2->m_element;
                    rope = (LPRDATARC)element->parent;
                    rope->currentElement = element;
                    rope->stopped = NO;
                    movement->PrepareCondition();
                    ((CRunMvtPhysics*)movement->m_movement)->SetCollidingObject(movement2);
                    rope->stopped = NO;
                    rope->collidingHO = movement->m_pHo;
                    [movement2->m_pHo generateEvent:CND_ELEMENTCOLLISIONRC withParam:movement->m_pHo->hoOi];
                    if (!movement->IsStop() && !rope->stopped)
                        contact->SetEnabled(NO);
                    break;
			}
                break;
            case MTYPE_FAKEOBJECT:
                switch (movement2->m_type)
			{
                case MTYPE_OBJECT:
				{
					movement2->PrepareCondition();
					((CRunMvtPhysics*)movement2->m_movement)->SetCollidingObject(movement);
					pHo=movement->m_pHo;
					CObject* pHo2=movement2->m_pHo;
					rhPtr->rhEvtProg->rh1stObjectNumber = pHo->hoNumber;
					rhPtr->rhEvtProg->rhCurParam[0] = pHo->hoOi;
					[rhPtr->rhEvtProg handle_Event:pHo2 withCode:CNDL_EXTCOLLISION];
					if (!movement2->IsStop())
						contact->SetEnabled(NO);
                    break;
				}
                case MTYPE_FAKEOBJECT:
					contact->SetEnabled(NO);
                    break;
                case MTYPE_PARTICULE:
                    particule = (CParticule*)movement2->m_particule;
                    parent = (LPRDATAPARTICULES)particule->parent;
                    parent->currentParticule1 = particule;
                    parent->currentParticule2 = nil;
                    parent->stopped = NO;
                    parent->collidingHO = movement->m_pHo;
                    movement->PrepareCondition();
                    [movement2->m_pHo generateEvent:CND_PARTICULECOLLISION withParam:movement->m_pHo->hoOi];
                    if (!movement->IsStop() && !parent->stopped)
                        contact->SetEnabled(NO);
                    break;
                case MTYPE_ELEMENT:
                    element = (CElement*)movement2->m_element;
                    rope = (LPRDATARC)element->parent;
                    rope->currentElement = element;
                    rope->stopped = NO;
                    movement->PrepareCondition();
                    rope->stopped = NO;
                    rope->collidingHO = movement->m_pHo;
                    [movement2->m_pHo generateEvent:CND_ELEMENTCOLLISIONRC withParam:movement->m_pHo->hoOi];
                    if (!movement->IsStop() && !rope->stopped)
                        contact->SetEnabled(NO);
                    break;
			}
                break;
            case MTYPE_PARTICULE:
                switch (movement2->m_type)
			{
                case MTYPE_OBJECT:
                    particule = (CParticule*)movement->m_particule;
                    parent = (LPRDATAPARTICULES)particule->parent;
                    parent->currentParticule1 = particule;
                    parent->currentParticule2 = nil;
                    parent->stopped = NO;
                    parent->collidingHO = movement2->m_pHo;
                    movement2->PrepareCondition();
                    ((CRunMvtPhysics*)movement2->m_movement)->SetCollidingObject(movement);
                    parent->stopped = NO;
                    [movement->m_pHo generateEvent:CND_PARTICULECOLLISION withParam:movement2->m_pHo->hoOi];
                    if (!movement2->IsStop() && !parent->stopped)
                        contact->SetEnabled(NO);
                    break;
                case MTYPE_FAKEOBJECT:
                    particule = (CParticule*)movement->m_particule;
                    parent = (LPRDATAPARTICULES)particule->parent;
                    parent->currentParticule1 = particule;
                    parent->currentParticule2 = nil;
                    parent->stopped = NO;
                    movement2->PrepareCondition();
                    parent->stopped = NO;
                    [movement->m_pHo generateEvent:CND_PARTICULECOLLISION withParam:0];
                    if (!movement2->IsStop() && !parent->stopped)
                        contact->SetEnabled(NO);
                    break;
                case MTYPE_PARTICULE:
				{
					CParticule* particule1 = (CParticule*)movement->m_particule;
					CParticule* particule2 = (CParticule*)movement2->m_particule;
					parent = (LPRDATAPARTICULES)particule1->parent;
					parent->currentParticule1 = particule1;
					parent->currentParticule2 = particule2;
					parent->stopped = NO;
					[movement->m_pHo generateEvent:CND_PARTICULESCOLLISION withParam:0];
					if (!parent->stopped)
						contact->SetEnabled(NO);
                    break;
				}
                case MTYPE_ELEMENT:
                    contact->SetEnabled(NO);
                    break;
			}
                break;

            case MTYPE_ELEMENT:
                switch (movement2->m_type)
			{
                case MTYPE_OBJECT:
                    element = (CElement*)movement->m_element;
                    rope = (LPRDATARC)element->parent;
                    rope->currentElement = element;
                    rope->stopped = NO;
                    rope->collidingHO = movement2->m_pHo;
                    movement2->PrepareCondition();
                    ((CRunMvtPhysics*)movement2->m_movement)->SetCollidingObject(movement);
                    [movement->m_pHo generateEvent:CND_ELEMENTCOLLISIONRC withParam:movement2->m_pHo->hoOi];
                    if (!movement2->IsStop() && !rope->stopped)
                        contact->SetEnabled(NO);
                    break;
                case MTYPE_FAKEOBJECT:
                    element = (CElement*)movement->m_element;
                    rope = (LPRDATARC)element->parent;
                    rope->currentElement = element;
                    rope->stopped = NO;
                    movement2->PrepareCondition();
                    [movement->m_pHo generateEvent:CND_ELEMENTCOLLISIONRC withParam:movement2->m_pHo->hoOi];
                    if (!movement2->IsStop() && !rope->stopped)
                        contact->SetEnabled(NO);
                    break;
                case MTYPE_PARTICULE:
                    contact->SetEnabled(NO);
                    break;
                case MTYPE_ELEMENT:
                    contact->SetEnabled(NO);
                    break;
			}
                break;
		}
	}
    bWorking = NO;
}

// Joint class
//////////////////////////////////////////////////////////////////////
CJoint::CJoint(LPRDATABASE rdPtr, NSString* name)
{
	m_rdPtr=rdPtr;
	m_name=[[NSString alloc] initWithString:name];
	m_type=0;
	m_joint=nil;
}
CJoint::~CJoint()
{
    [m_name release];
	DestroyJoint();
}
void CJoint::DestroyJoint()
{
	if (m_joint != nil)
		m_rdPtr->world->DestroyJoint(m_joint);
}
void CJoint::SetJoint(int type, b2Joint* joint)
{
	m_type=type;
	m_joint=joint;
}

// CFORCE CLASS
//////////////////////////////////////////////////////////////////////
CForce::CForce(b2Body* pBody, b2Vec2 force, b2Vec2 position)
{
	m_body = pBody;
	m_force = force;
	m_position = position;
}

// CTORQUE CLASS
//////////////////////////////////////////////////////////////////////
CTorque::CTorque(b2Body* pBody, float torque)
{
	m_body = pBody;
	m_torque = torque;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CRunBox2DBase

-(int)getNumberOfConditions
{
	return 0;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    m_object = malloc(sizeof(RUNDATABASE));
    
    LPEDATABASE object = (LPEDATABASE)malloc(sizeof(EDITDATABASE));
    object->flags = [file readAInt];
    object->velocityIterations = [file readAInt];
    object->positionIterations = [file readAInt];
	[file skipBytes:4];         // Gravity
    object->angle = [file readAInt];
    object->factor = [file readAInt];
    object->friction = [file readAInt];
    object->restitution = [file readAInt];
    object->bulletFriction = [file readAInt];
    object->bulletRestitution = [file readAInt];
    object->bulletGravity = [file readAInt];
    object->bulletDensity = [file readAInt];
    object->gravity = [file readAFloat];
    object->identifier = [file readAInt];
    object->npDensity = [file readAInt];
    object->npFriction = [file readAInt];
    
    LPRDATABASE rdPtr = (LPRDATABASE)m_object;
    rdPtr->rh = ho->hoAdRunHeader;
    rdPtr->ho = ho;
    
    b2bCreateRunObject(rdPtr, object);
    free(object);
	return NO;
}

-(void)destroyRunObject:(BOOL)bFast
{
    b2bDestroyRunObject((LPRDATABASE)m_object, bFast);
    free(m_object);
}


-(int)handleRunObject
{
	return b2bHandleRunObject((LPRDATABASE)m_object);
}


// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	return NO;
}

// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
    LPRDATABASE rdPtr = (LPRDATABASE)m_object;
    switch (num)
    {
        case ACTION_SETGRAVITYFORCE:
            RACTION_SETGRAVITYFORCE(rdPtr, act);
            break;
        case ACTION_SETGRAVITYANGLE:
            RACTION_SETGRAVITYANGLE(rdPtr, act);
            break;
        case ACTION_DJOINTHOTSPOT:
            RACTION_DJOINTHOTSPOT(rdPtr, act);
            break;
        case ACTION_DJOINTACTIONPOINT:
            RACTION_DJOINTACTIONPOINT(rdPtr, act);
            break;
        case ACTION_DJOINTPOSITION:
            RACTION_DJOINTPOSITION(rdPtr, act);
            break;
        case ACTION_RJOINTHOTSPOT:
            RACTION_RJOINTHOTSPOT(rdPtr, act);
            break;
        case ACTION_RJOINTACTIONPOINT:
            RACTION_RJOINTACTIONPOINT(rdPtr, act);
            break;
        case ACTION_RJOINTPOSITION:
            RACTION_RJOINTPOSITION(rdPtr, act);
            break;
        case ACTION_PJOINTHOTSPOT:
            RACTION_PJOINTHOTSPOT(rdPtr, act);
            break;
        case ACTION_PJOINTACTIONPOINT:
            RACTION_PJOINTACTIONPOINT(rdPtr, act);
            break;
        case ACTION_PJOINTPOSITION:
            RACTION_PJOINTPOSITION(rdPtr, act);
            break;
        case ACTION_ADDOBJECT:
            RACTION_ADDOBJECT(rdPtr, act);
            break;
        case ACTION_SUBOBJECT:
            RACTION_SUBOBJECT(rdPtr, act);
            break;
        case ACTION_SETDENSITY:
            RACTION_SETDENSITY(rdPtr, act);
            break;
        case ACTION_SETFRICTION:
            RACTION_SETFRICTION(rdPtr, act);
            break;
        case ACTION_SETELASTICITY:
            RACTION_SETELASTICITY(rdPtr, act);
            break;
        case ACTION_SETGRAVITY:
            RACTION_SETGRAVITY(rdPtr, act);
            break;
        case ACTION_DJOINTSETELASTICITY:
            RACTION_DJOINTSETELASTICITY(rdPtr, act);
            break;
        case ACTION_RJOINTSETLIMITS:
            RACTION_RJOINTSETLIMITS(rdPtr, act);
            break;
        case ACTION_RJOINTSETMOTOR:
            RACTION_RJOINTSETMOTOR(rdPtr, act);
            break;
        case ACTION_PJOINTSETLIMITS:
            RACTION_PJOINTSETLIMITS(rdPtr, act);
            break;
        case ACTION_PJOINTSETMOTOR:
            RACTION_PJOINTSETMOTOR(rdPtr, act);
            break;
        case ACTION_PUJOINTHOTSPOT:
            RACTION_PUJOINTHOTSPOT(rdPtr, act);
            break;
        case ACTION_PUJOINTACTIONPOINT:
            RACTION_PUJOINTACTIONPOINT(rdPtr, act);
            break;
        case ACTION_DESTROYJOINT:
            RACTION_DESTROYJOINT(rdPtr, act);
            break;
        case ACTION_SETITERATIONS:
            RACTION_SETITERATIONS(rdPtr, act);
            break;
    }
}

// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
    LPRDATABASE rdPtr = (LPRDATABASE)m_object;
    switch (num)
    {
        case EXPRESSION_GRAVITYSTRENGTH:
            return REXPRESSION_GRAVITYSTRENGTH(rdPtr);
        case EXPRESSION_GRAVITYANGLE:
            return REXPRESSION_GRAVITYANGLE(rdPtr);
        case EXPRESSION_VELOCITYITERATIONS:
            return REXPRESSION_VELOCITYITERATIONS(rdPtr);
        case EXPRESSION_POSITIONITERATIONS:
            return REXPRESSION_POSITIONITERATIONS(rdPtr);
        case EXPRESSION_ELASTICITYFREQUENCY:
            return REXPRESSION_ELASTICITYFREQUENCY(rdPtr);
        case EXPRESSION_ELASTICITYDAMPING:
            return REXPRESSION_ELASTICITYDAMPING(rdPtr);
        case EXPRESSION_LOWERANGLELIMIT:
            return REXPRESSION_LOWERANGLELIMIT(rdPtr);
        case EXPRESSION_UPPERANGLELIMIT:
            return REXPRESSION_UPPERANGLELIMIT(rdPtr);
        case EXPRESSION_MOTORSTRENGTH:
            return REXPRESSION_MOTORSTRENGTH(rdPtr);
        case EXPRESSION_MOTORSPEED:
            return REXPRESSION_MOTORSPEED(rdPtr);
        case EXPRESSION_LOWERTRANSLATION:
            return REXPRESSION_LOWERTRANSLATION(rdPtr);
        case EXPRESSION_UPPERTRANSLATION:
            return REXPRESSION_UPPERTRANSLATION(rdPtr);
        case EXPRESSION_PMOTORSTRENGTH:
            return REXPRESSION_PMOTORSTRENGTH(rdPtr);
        case EXPRESSION_PMOTORSPEED:
            return REXPRESSION_PMOTORSPEED(rdPtr);
            
    }
	return nil;
}

@end
