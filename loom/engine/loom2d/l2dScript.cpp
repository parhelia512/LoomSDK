/*
 * ===========================================================================
 * Loom SDK
 * Copyright 2011, 2012, 2013
 * The Game Engine Company, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ===========================================================================
 */

#include "loom/script/loomscript.h"

#include "loom/engine/loom2d/l2dPoint.h"
#include "loom/engine/loom2d/l2dRectangle.h"
#include "loom/engine/loom2d/l2dMatrix.h"
#include "loom/engine/loom2d/l2dEventDispatcher.h"
#include "loom/engine/loom2d/l2dDisplayObject.h"
#include "loom/engine/loom2d/l2dDisplayObjectContainer.h"
#include "loom/engine/loom2d/l2dStage.h"
#include "loom/engine/loom2d/l2dSprite.h"
#include "loom/engine/loom2d/l2dShape.h"
#include "loom/engine/loom2d/l2dQuad.h"
#include "loom/engine/loom2d/l2dImage.h"
#include "loom/engine/loom2d/l2dQuadBatch.h"

namespace Loom2D
{
class Loom2DNative
{
    static bool sInitialized;

public:

    static void initialize(lua_State *L)
    {
        // on shutdown, we should deinitialize
        //lmAssert(!sInitialized, "Loom2DNative already initialized");

        Point::initialize(L);
        Rectangle::initialize(L);
        Matrix::initialize(L);

        DisplayObject::initialize(L);
        DisplayObjectContainer::initialize(L);
        Sprite::initialize(L);
        Quad::initialize(L);
        Image::initialize(L);
        QuadBatch::initialize(L);

        sInitialized = true;
    }
};

bool Loom2DNative::sInitialized = false;

static Matrix *StaticMatrixConstructor(lua_State *L)
{
    return new Matrix((float)lua_tonumber(L, 2), (float)lua_tonumber(L, 3),
                      (float)lua_tonumber(L, 4), (float)lua_tonumber(L, 5),
                      (float)lua_tonumber(L, 6), (float)lua_tonumber(L, 7));
}


static Rectangle *StaticRectangleConstructor(lua_State *L)
{
    return new Rectangle((float)lua_tonumber(L, 2), (float)lua_tonumber(L, 3),
                         (float)lua_tonumber(L, 4), (float)lua_tonumber(L, 5));
}


static int registerLoom2D(lua_State *L)
{
    beginPackage(L, "loom2d.native")

       .beginClass<Loom2DNative> ("Loom2DNative")
       .addStaticMethod("initialize", &Loom2DNative::initialize)
       .endClass()

       .endPackage();

    beginPackage(L, "loom2d.math")

       .beginClass<Matrix>("Matrix")

       .addStaticConstructor(StaticMatrixConstructor)

       .addProperty("a", &Matrix::get_a, &Matrix::set_a)
       .addProperty("b", &Matrix::get_b, &Matrix::set_b)
       .addProperty("c", &Matrix::get_c, &Matrix::set_c)
       .addProperty("d", &Matrix::get_d, &Matrix::set_d)
       .addProperty("tx", &Matrix::get_tx, &Matrix::set_tx)
       .addProperty("ty", &Matrix::get_ty, &Matrix::set_ty)

       .addMethod("toString", &Matrix::toString)

       .addMethod("identity", &Matrix::identity)
       .addMethod("determinant", &Matrix::determinant)
       .addMethod("concat", &Matrix::concat)
       .addMethod("invert", &Matrix::invert)

       .addMethod("skew", &Matrix::skew)
       .addMethod("translate", &Matrix::translate)
       .addMethod("scale", &Matrix::scale)
       .addMethod("rotate", &Matrix::rotate)

       .addLuaFunction("transformCoord", &Matrix::transformCoord)
       .addLuaFunction("deltaTransformCoord", &Matrix::deltaTransformCoord)
       .addLuaFunction("setTo", &Matrix::setTo)
       .addLuaFunction("copyFrom", &Matrix::copyFrom)

       .endClass()

       .beginClass<Rectangle>("Rectangle")

       .addStaticConstructor(StaticRectangleConstructor)

       .addProperty("x", &Rectangle::getX, &Rectangle::setX)
       .addProperty("y", &Rectangle::getY, &Rectangle::setY)
       .addProperty("width", &Rectangle::getWidth, &Rectangle::setWidth)
       .addProperty("height", &Rectangle::getHeight, &Rectangle::setHeight)

    // TODO: these could use the fast path
       .addMethod("__pget_minX", &Rectangle::getMinX)
       .addMethod("__pget_maxX", &Rectangle::getMaxX)

       .addMethod("__pget_minY", &Rectangle::getMinY)
       .addMethod("__pget_maxY", &Rectangle::getMaxY)

       .addProperty("top", &Rectangle::getTop, &Rectangle::setTop)
       .addProperty("bottom", &Rectangle::getBottom, &Rectangle::setBottom)
       .addProperty("left", &Rectangle::getLeft, &Rectangle::setLeft)
       .addProperty("right", &Rectangle::getRight, &Rectangle::setRight)

       .addLuaFunction("expandByPoint", &Rectangle::expandByPoint)
       .addLuaFunction("containsPoint", &Rectangle::containsPoint)
       .addMethod("containsRect", &Rectangle::containsRect)
       .addLuaFunction("contains", &Rectangle::contains)

       .addMethod("setTo", &Rectangle::setTo)
       .addMethod("clip", &Rectangle::clip)

       .addMethod("clone", &Rectangle::clone)

       .addMethod("toString", &Rectangle::toString)

       .endClass()


       .endPackage();

    beginPackage(L, "loom2d.events")

       .beginClass<EventDispatcher>("EventDispatcher")
       .addConstructor<void (*)(void)>()
       .endClass()

       .endPackage();

    beginPackage(L, "loom2d.display")

    // DisplayObject
       .deriveClass<DisplayObject, EventDispatcher>("DisplayObject")

       .addConstructor<void (*)(void)>()

    // fast path properties
       .addProperty("x", &DisplayObject::getX, &DisplayObject::setX)
       .addProperty("y", &DisplayObject::getY, &DisplayObject::setY)
       .addProperty("scaleX", &DisplayObject::getScaleX, &DisplayObject::setScaleX)
       .addProperty("scaleY", &DisplayObject::getScaleY, &DisplayObject::setScaleY)
       .addProperty("pivotX", &DisplayObject::getPivotX, &DisplayObject::setPivotX)
       .addProperty("pivotY", &DisplayObject::getPivotY, &DisplayObject::setPivotY)
       .addProperty("skewX", &DisplayObject::getSkewX, &DisplayObject::setSkewX)
       .addProperty("skewY", &DisplayObject::getSkewY, &DisplayObject::setSkewY)
       .addProperty("rotation", &DisplayObject::getRotation, &DisplayObject::setRotation)
       .addProperty("alpha", &DisplayObject::getAlpha, &DisplayObject::setAlpha)
       .addProperty("blendMode", &DisplayObject::getBlendMode, &DisplayObject::setBlendMode)

       .addProperty("name", &DisplayObject::getName, &DisplayObject::setName)

       .addProperty("visible", &DisplayObject::getVisible, &DisplayObject::setVisible)
       .addProperty("touchable", &DisplayObject::getTouchable, &DisplayObject::setTouchable)

       .addProperty("depth", &DisplayObject::getDepth, &DisplayObject::setDepth)

       .addProperty("valid", &DisplayObject::getValid, &DisplayObject::setValid)

       .addMethod("__pset__parent", &DisplayObject::setParent)

       .addLuaFunction("__pget_transformationMatrix", &DisplayObject::getTransformationMatrix)
       .addLuaFunction("__pset_transformationMatrix", &DisplayObject::setTransformationMatrix)

       .addMethod("__pset_scale", &DisplayObject::setScale)
       .addMethod("__pget_scale", &DisplayObject::getScale)

       .addMethod("getTargetTransformationMatrix", &DisplayObject::getTargetTransformationMatrix)

       .addVarAccessor("customRender", &DisplayObject::getCustomRenderDelegate)
       .addVarAccessor("onRender", &DisplayObject::getOnRenderDelegate)

       .endClass()

    // DisplayObjectContainer
       .deriveClass<DisplayObjectContainer, DisplayObject>("DisplayObjectContainer")
       .addConstructor<void (*)(void)>()
       .addProperty("depthSort", &DisplayObjectContainer::getDepthSort, &DisplayObjectContainer::setDepthSort)
       //.addProperty("view", &DisplayObjectContainer::getView, &DisplayObjectContainer::setView)
       .addMethod("setClipRect", &DisplayObjectContainer::setClipRect)
       .endClass()

    // Stage
       .deriveClass<Stage, DisplayObjectContainer>("Stage")
       .addConstructor<void (*)(void)>()

       .addMethod("render", &Stage::render)
       .addMethod("firePendingResizeEvent", &Stage::firePendingResizeEvent)

       .addMethod("__pget_nativeStageWidth", &Stage::getWidth)
       .addMethod("__pget_nativeStageHeight", &Stage::getHeight)

       .addProperty("orientation", &Stage::getOrientation, &Stage::setOrientation)

       .addProperty("vectorQuality", &Stage::getVectorQuality, &Stage::setVectorQuality)

       .addVarAccessor("onTouchBegan", &Stage::getTouchBeganDelegate)
       .addVarAccessor("onTouchMoved", &Stage::getTouchMovedDelegate)
       .addVarAccessor("onTouchEnded", &Stage::getTouchEndedDelegate)
       .addVarAccessor("onTouchCancelled", &Stage::getTouchCancelledDelegate)
       .addVarAccessor("onKeyUp", &Stage::getKeyUpDelegate)
       .addVarAccessor("onKeyDown", &Stage::getKeyDownDelegate)
       .addVarAccessor("onMenuKey", &Stage::getMenuKeyDelegate)
       .addVarAccessor("onBackKey", &Stage::getBackKeyDelegate)
       .addVarAccessor("onScrollWheelYMoved", &Stage::getScrollWheelYMovedDelegate)
       .addVarAccessor("onAccelerate", &Stage::getAccelerateDelegate)

       .addVarAccessor("onOrientationChange", &Stage::getOrientationChangeDelegate)
       .addVarAccessor("onSizeChange", &Stage::getSizeChangeDelegate)

       .addStaticProperty("onRenderStage", &Stage::getRenderStageDelegate)

       .endClass()

    // Sprite
       .deriveClass<Sprite, DisplayObjectContainer>("Sprite")
       .addConstructor<void (*)(void)>()
       .endClass()

    // TextFormat
       .beginClass<GFX::VectorTextFormat>("TextFormat")
       .addConstructor<void(*)(void)>()
       .addStaticMethod("load", &GFX::VectorTextFormat::load)
       .addProperty("font", &GFX::VectorTextFormat::getFont, &GFX::VectorTextFormat::setFont)
       .addProperty("color", &GFX::VectorTextFormat::getColor, &GFX::VectorTextFormat::setColor)
       .addProperty("size", &GFX::VectorTextFormat::getSize, &GFX::VectorTextFormat::setSize)
       .addProperty("align", &GFX::VectorTextFormat::getAlign, &GFX::VectorTextFormat::setAlign)
       .addProperty("letterSpacing", &GFX::VectorTextFormat::getLetterSpacing, &GFX::VectorTextFormat::setLetterSpacing)
       .addProperty("lineHeight", &GFX::VectorTextFormat::getLineHeight, &GFX::VectorTextFormat::setLineHeight)
       .endClass()

    // SVG
       .beginClass<GFX::VectorSVG>("SVG")
	   .addConstructor<void(*)(void)>()
	   .addProperty("width", &GFX::VectorSVG::getWidth)
	   .addProperty("height", &GFX::VectorSVG::getHeight)
       .addMethod("loadFile", &GFX::VectorSVG::loadFile)
       .addMethod("loadString", &GFX::VectorSVG::loadString)
       .endClass()

    // Shape
       .deriveClass<Shape, DisplayObject>("Shape")
       .addConstructor<void(*)(void)>()
       .addMethod("setClipRect", &Shape::setClipRect)
       .addMethod("__pget_graphics", &Shape::getGraphics)
       .endClass()

    // Graphics
       .beginClass<GFX::VectorGraphics>("Graphics")
       .addConstructor<void(*)(void)>()
       .addMethod("clear", &GFX::VectorGraphics::clear)
       .addMethod("lineStyle", &GFX::VectorGraphics::lineStyle)
       .addMethod("textFormat", &GFX::VectorGraphics::textFormat)
       .addMethod("textLineBounds", &GFX::VectorGraphics::textLineBounds)
       .addMethod("textLineAdvance", &GFX::VectorGraphics::textLineAdvance)
       .addMethod("textBoxBounds", &GFX::VectorGraphics::textBoxBounds)
       .addMethod("beginFill", &GFX::VectorGraphics::beginFill)
       .addMethod("endFill", &GFX::VectorGraphics::endFill)
       .addMethod("moveTo", &GFX::VectorGraphics::moveTo)
       .addMethod("lineTo", &GFX::VectorGraphics::lineTo)
       .addMethod("curveTo", &GFX::VectorGraphics::curveTo)
       .addMethod("cubicCurveTo", &GFX::VectorGraphics::cubicCurveTo)
       .addMethod("arcTo", &GFX::VectorGraphics::arcTo)
       .addMethod("drawCircle", &GFX::VectorGraphics::drawCircle)
       .addMethod("drawEllipse", &GFX::VectorGraphics::drawEllipse)
       .addMethod("drawRect", &GFX::VectorGraphics::drawRect)
       .addMethod("drawRoundRect", &GFX::VectorGraphics::drawRoundRect)
       .addMethod("drawRoundRectComplex", &GFX::VectorGraphics::drawRoundRectComplex)
       .addMethod("drawArc", &GFX::VectorGraphics::drawArc)
       .addMethod("drawTextLine", &GFX::VectorGraphics::drawTextLine)
       .addMethod("drawTextBox", &GFX::VectorGraphics::drawTextBox)
       .addMethod("drawSVG", &GFX::VectorGraphics::drawSVG)
       .addMethod("getBounds", &GFX::VectorGraphics::getBounds)
       .endClass()

    // Quad
       .deriveClass<Quad, DisplayObject>("Quad")
       .addConstructor<void (*)(void)>()
       .addProperty("nativeTextureID", &Quad::getNativeTextureID, &Quad::setNativeTextureID)
       .addProperty("nativeVertexDataInvalid", &Quad::getNativeVertexDataInvalid, &Quad::setNativeVertexDataInvalid)
       .endClass()

    // Image
       .deriveClass<Image, Quad>("Image")
       .addConstructor<void (*)(void)>()
       .endClass()

    // QuadBatch
       .deriveClass<QuadBatch, DisplayObject>("QuadBatch")
       .addConstructor<void (*)(void)>()
       .addProperty("nativeTextureID", &QuadBatch::getNativeTextureID, &QuadBatch::setNativeTextureID)
       .addProperty("numQuads", &QuadBatch::getNumQuads)
       .addLuaFunction("_addQuad", &QuadBatch::_addQuad)
       .addLuaFunction("_updateQuad", &QuadBatch::_updateQuad)
       .addLuaFunction("_getBounds", &QuadBatch::_getBounds)
       .addLuaFunction("reset", &QuadBatch::reset)
       .endClass()


       .endPackage();


    return 0;
}
}

void installLoom2D()
{
    LOOM_DECLARE_NATIVETYPE(Loom2D::Loom2DNative, Loom2D::registerLoom2D);

    LOOM_DECLARE_NATIVETYPE(Loom2D::Rectangle, Loom2D::registerLoom2D);
    LOOM_DECLARE_NATIVETYPE(Loom2D::Matrix, Loom2D::registerLoom2D);

    LOOM_DECLARE_MANAGEDNATIVETYPE(GFX::VectorTextFormat, Loom2D::registerLoom2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(GFX::VectorSVG, Loom2D::registerLoom2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(GFX::VectorGraphics, Loom2D::registerLoom2D);

    LOOM_DECLARE_MANAGEDNATIVETYPE(Loom2D::EventDispatcher, Loom2D::registerLoom2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(Loom2D::DisplayObject, Loom2D::registerLoom2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(Loom2D::DisplayObjectContainer, Loom2D::registerLoom2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(Loom2D::Stage, Loom2D::registerLoom2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(Loom2D::Sprite, Loom2D::registerLoom2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(Loom2D::Shape, Loom2D::registerLoom2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(Loom2D::Image, Loom2D::registerLoom2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(Loom2D::Quad, Loom2D::registerLoom2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(Loom2D::QuadBatch, Loom2D::registerLoom2D);
}
