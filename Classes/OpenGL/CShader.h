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
//  CShader.h
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 6/10/10.
//  Copyright 2010 Clickteam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import "CoreMath.h"

@class CTexture;

class CRenderer;

enum {
    UNIFORM_TEXTURE,
	UNIFORM_PROJECTIONMATRIX,
	UNIFORM_TRANSFORMMATRIX,
	UNIFORM_OBJECTMATRIX,
	UNIFORM_TEXTUREMATRIX,
	UNIFORM_INKEFFECT,
	UNIFORM_RGBA,
	UNIFORM_GRADIENT,
    NUM_UNIFORMS
};

#define ATTRIB_VERTEX 0

class CShader
{
public:
	GLuint program;
	GLuint fragmentProgram;
	GLuint vertexProgram;
	int uniforms[NUM_UNIFORMS];
	BOOL usesTexCoord;
	BOOL usesColor;
	CRenderer* render;

	Mat3f prevTransform;
	Mat3f prevProjection;
	Mat3f prevTexCoord;

	int currentEffect;
	float currentR, currentG, currentB, currentA;
	NSString* sname;

	CShader(CRenderer* renderer);
	~CShader();

	bool loadShader(NSString* shaderName, bool useTexCoord, bool useColors);

	GLuint compileShader(GLuint* shader, NSString* shaderName, GLint type);
	bool linkProgram(GLuint prog);
	bool validateProgram(GLuint prog);

	void setTexture(CTexture* texture);
	void setTexture(CTexture* texture, Mat3f &textureMatrix);
	void setTexCoord(Mat3f &texCoord);
	void setRGBCoeff(float red, float green, float blue, float alpha);
	void setInkEffect(int effect);
	void forgetCachedState();

	void bindShader();
	void setProjectionMatrix(const Mat3f &matrix);
	void setTransformMatrix(const Mat3f &matrix);
	void setObjectMatrix(const Mat3f &matrix);

	void setGradientColors(int color);
	void setGradientColors(int a, int b, BOOL horizontal);
	void setGradientColors(int a, int b, int c, int d);
	void setGradientColors(GradientColor gradient);

};



