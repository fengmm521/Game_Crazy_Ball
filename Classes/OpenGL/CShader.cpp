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
//  CShader.m
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 6/10/10.
//  Copyright 2010 Clickteam. All rights reserved.
//

#import "CShader.h"
#import "CBitmap.h"
#import "CRenderer.h"

CShader::CShader(CRenderer* renderer)
{
	render = renderer;
	currentEffect = -1;
	currentR = currentG = currentB = currentA = -1;

	for (int i=0; i<NUM_UNIFORMS; ++i) {
		uniforms[i] = UNIFORM_TEXTURE;
	}
	forgetCachedState();
}
CShader::~CShader()
{
	glDeleteProgram(program);
	[sname release];
}

bool CShader::loadShader(NSString* shaderName, bool useTexCoord, bool useColors)
{
	NSString *vertShaderPathname, *fragShaderPathname;
	sname = [[NSString alloc] initWithString:shaderName];

	program = glCreateProgram();
	usesTexCoord = useTexCoord;
	usesColor = useColors;

    // Create and compile vertex shader
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"vsh" inDirectory:@""];
	if (vertShaderPathname == nil || !  compileShader(&vertexProgram, vertShaderPathname, GL_VERTEX_SHADER))
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }

    // Create and compile fragment shader
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"fsh" inDirectory:@""];
    if (fragShaderPathname == nil || !compileShader(&fragmentProgram, fragShaderPathname, GL_FRAGMENT_SHADER))
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }

	glAttachShader(program, vertexProgram);
    glAttachShader(program, fragmentProgram);

	glBindAttribLocation(program, ATTRIB_VERTEX, "position");

	if (!linkProgram(program))
    {
        NSLog(@"Failed to link program: %d", program);

        if (vertexProgram)
        {
            glDeleteShader(vertexProgram);
            vertexProgram = 0;
        }
        if (fragmentProgram)
        {
            glDeleteShader(fragmentProgram);
            fragmentProgram = 0;
        }
        if (program)
        {
            glDeleteProgram(program);
            program = 0;
        }
        return FALSE;
    }

	glUseProgram(program);
	uniforms[UNIFORM_PROJECTIONMATRIX] = glGetUniformLocation(program, "projectionMatrix");
	uniforms[UNIFORM_INKEFFECT] = glGetUniformLocation(program, "inkEffect");
	uniforms[UNIFORM_RGBA] = glGetUniformLocation(program, "blendColor");
	uniforms[UNIFORM_TRANSFORMMATRIX] = glGetUniformLocation(program, "transformMatrix");
	uniforms[UNIFORM_OBJECTMATRIX] = glGetUniformLocation(program, "objectMatrix");

	if(useTexCoord)
	{
		uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(program, "texture");
		uniforms[UNIFORM_TEXTUREMATRIX] = glGetUniformLocation(program, "textureMatrix");
		glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
		glActiveTexture(GL_TEXTURE0);
	}

	if(useColors)
	{
		uniforms[UNIFORM_GRADIENT] = glGetUniformLocation(program, "colorMatrix");
	}

	glEnableVertexAttribArray(ATTRIB_VERTEX);
	glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 0, 0);

	setTransformMatrix(Mat3f::identity());
	return TRUE;
}

GLuint CShader::compileShader(GLuint* shader, NSString* shaderName, GLint type)
{
	GLint status;
    const GLchar *source;

    source = (GLchar *)[[NSString stringWithContentsOfFile:shaderName encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        [NSException raise:@"Failed to load shader resource" format:@""];
    }

    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);

    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }

    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
		NSLog(@"Unable to compile shader");
        return FALSE;
    }

    return TRUE;

}

bool CShader::linkProgram(GLuint prog)
{
	GLint status;

    glLinkProgram(prog);

    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }

    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;

    return TRUE;
}

bool CShader::validateProgram(GLuint prog)
{
/*
	 GLint logLength, status;

    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }

    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
*/
    return TRUE;
}

void CShader::setRGBCoeff(float red, float green, float blue, float alpha)
{
	if(currentA != alpha || currentR != red || currentG != green || currentB != blue)
	{
		glUniform4f(uniforms[UNIFORM_RGBA], red, green, blue, alpha);
		currentR = red;
		currentG = green;
		currentB = blue;
		currentA = alpha;
	}
}

void CShader::setInkEffect(int effect)
{
	//Set transparency based on the inkEffect
	switch (effect)
	{
		default:
		case BOP_COPY:
		case BOP_BLEND:
		case BOP_BLEND_REPLEACETRANSP:
		case BOP_BLEND_DONTREPLACECOLOR:
		case BOP_OR:
		case BOP_XOR:
		case BOP_MONO:
		case BOP_INVERT:
			render->setBlendEquation(GL_FUNC_ADD);
			render->setBlendFunction(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			break;
		case BOP_ADD:
			render->setBlendEquation(GL_FUNC_ADD);
			render->setBlendFunction(GL_SRC_ALPHA, GL_ONE);
			break;
		case BOP_SUB:
			render->setBlendEquationSeperate(GL_FUNC_REVERSE_SUBTRACT, GL_FUNC_ADD);
			render->setBlendFunction(GL_SRC_ALPHA, GL_ONE);
			break;
	}

	if(currentEffect != effect)
	{
		glUniform1i(uniforms[UNIFORM_INKEFFECT], effect);
		currentEffect = effect;
	}
}

void CShader::bindShader()
{
	glUseProgram(program);
}

void CShader::forgetCachedState()
{
	prevTransform = Mat3f::zero();
	prevProjection = Mat3f::zero();
	prevTexCoord = Mat3f::zero();
}

void CShader::setProjectionMatrix(const Mat3f &matrix)
{
	if(prevProjection != matrix)
	{
		glUniformMatrix3fv(uniforms[UNIFORM_PROJECTIONMATRIX], 1, GL_FALSE, (float*)&matrix);
		prevProjection = matrix;
	}
}

void CShader::setTransformMatrix(const Mat3f &matrix)
{
	if(prevTransform != matrix)
	{
		glUniformMatrix3fv(uniforms[UNIFORM_TRANSFORMMATRIX], 1, GL_FALSE, (float*)&matrix);
		prevTransform = matrix;
	}
}

void CShader::setTexCoord(Mat3f &texCoord)
{
	if(prevTexCoord != texCoord)
	{
		glUniformMatrix3fv(uniforms[UNIFORM_TEXTUREMATRIX], 1, GL_FALSE, (float*)&texCoord);
		prevTexCoord = texCoord;
	}
}

void CShader::setTexture(CTexture* texture)
{
	int texId = texture->textureId;
	if(render->currentTextureID != texId)
	{
		glBindTexture(GL_TEXTURE_2D, texId);
		render->currentTextureID = texId;
	}
	if(prevTexCoord != texture->textureMatrix)
	{
		glUniformMatrix3fv(uniforms[UNIFORM_TEXTUREMATRIX], 1, GL_FALSE, (float*)&texture->textureMatrix);
		prevTexCoord = texture->textureMatrix;
	}
}

void CShader::setTexture(CTexture* texture, Mat3f &textureMatrix)
{
	int texId = texture->textureId;
	if(render->currentTextureID != texId)
	{
		glBindTexture(GL_TEXTURE_2D, texId);
		render->currentTextureID = texId;
	}
	if(prevTexCoord != textureMatrix)
	{
		glUniformMatrix3fv(uniforms[UNIFORM_TEXTUREMATRIX], 1, GL_FALSE, (float*)&textureMatrix);
		prevTexCoord = textureMatrix;
	}
}

void CShader::setObjectMatrix(const Mat3f &matrix)
{
	glUniformMatrix3fv(uniforms[UNIFORM_OBJECTMATRIX], 1, GL_FALSE, (float*)&matrix);
}

void CShader::setGradientColors(GradientColor gradient)
{
	glUniformMatrix4fv(uniforms[UNIFORM_GRADIENT], 1, GL_FALSE, (float*)&gradient);
}

void CShader::setGradientColors(int color)
{
	GradientColor gradient = GradientColor(color);
	glUniformMatrix4fv(uniforms[UNIFORM_GRADIENT], 1, GL_FALSE, (float*)&gradient);
}

void CShader::setGradientColors(int a, int b, BOOL horizontal)
{
	GradientColor gradient = GradientColor(a, b, horizontal);
	glUniformMatrix4fv(uniforms[UNIFORM_GRADIENT], 1, GL_FALSE, (float*)&gradient);
}

void CShader::setGradientColors(int a, int b, int c, int d)
{
	GradientColor gradient = GradientColor(a, b, c, d);
	glUniformMatrix4fv(uniforms[UNIFORM_GRADIENT], 1, GL_FALSE, (float*)&gradient);
}
