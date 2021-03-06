/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls
{
    import feathers.core.FeathersControl;
    import feathers.core.IFocusDisplayObject;
    import feathers.core.ITextEditor;
    import feathers.core.ITextRenderer;
    import feathers.events.FeathersEventType;

    import loom2d.math.Point;
    //import flash.ui.Mouse;
    //import flash.ui.MouseCursor;

    import loom2d.Loom2D;
    import loom2d.display.DisplayObject;
    import loom2d.events.Event;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    
    import loom.platform.LoomKeyboardType;

    /**
     * Dispatched when the text input's `text` property changes.
     *
     * @eventType loom2d.events.Event.CHANGE
     */
    [Event(name="change",type="loom2d.events.Event")]

    /**
     * Dispatched when the user presses the Enter key while the text input
     * has focus. This event may not be dispatched at all times. Certain text
     * editors will not dispatch an event for the enter key on some platforms,
     * depending on the values of certain properties. This may include the
     * default values for some platforms! If you've encountered this issue,
     * please see the specific text editor's API documentation for complete
     * details of this event's limitations and requirements.
     *
     * @eventType feathers.events.FeathersEventType.ENTER
     */
    [Event(name="enter",type="loom2d.events.Event")]

    /**
     * Dispatched when the text input receives focus.
     *
     * @eventType feathers.events.FeathersEventType.FOCUS_IN
     */
    [Event(name="focusIn",type="loom2d.events.Event")]

    /**
     * Dispatched when the text input loses focus.
     *
     * @eventType feathers.events.FeathersEventType.FOCUS_OUT
     */
    [Event(name="focusOut",type="loom2d.events.Event")]

    /**
     * A text entry control that allows users to enter and edit a single line of
     * uniformly-formatted text.
     *
     * To set things like font properties, the ability to display as
     * password, and character restrictions, use the `textEditorProperties` to pass
     * values to the `ITextEditor` instance.
     *
     * @see http://wiki.starling-framework.org/feathers/text-input
     * @see http://wiki.starling-framework.org/feathers/text-editors
     * @see feathers.core.ITextEditor
     */
    public class TextInput extends FeathersControl implements IFocusDisplayObject
    {
        /**
         * @private
         */
        private static const HELPER_POINT:Point = new Point();

        /**
         * @private
         */
        private static const HELPER_TOUCHES_VECTOR:Vector.<Touch> = new <Touch>[];

        /**
         * @private
         */
        protected static const INVALIDATION_FLAG_PROMPT_FACTORY:String = "promptFactory";

        /**
         * Constructor.
         */
        public function TextInput()
        {
            this.isQuickHitAreaEnabled = true;
            this.addEventListener(Event.ADDED_TO_STAGE, textInput_addedToStageHandler);
            this.addEventListener(Event.REMOVED_FROM_STAGE, textInput_removedFromStageHandler);
        }

        /**
         * The text editor sub-component.
         */
        protected var textEditor:ITextEditor;

        /**
         * The prompt text renderer sub-component.
         */
        protected var promptTextRenderer:ITextRenderer;

        /**
         * The currently selected background, based on state.
         */
        protected var currentBackground:DisplayObject;

        /**
         * @private
         */
        protected var _textEditorHasFocus:Boolean = false;

        /**
         * @private
         */
        protected var _ignoreTextChanges:Boolean = false;

        /**
         * @private
         */
        protected var _touchPointID:int = -1;

        /**
         * @private
         */
        protected var _text:String = "";
        
        /**
         * @private
         * Par of a Workaround fix that specially prevents editing when not in focus
         */
        private var _localIsEditable:Boolean = false;

        /**
         * The text displayed by the text input. The text input dispatches
         * `Event.CHANGE` when the value of the `text`
         * property changes for any reason.
         *
         * @see loom2d.events.Event#!CHANGE
         */
        public function get text():String
        {
            return this._text;
        }

        /**
         * @private
         */
        public function set text(value:String):void
        {
            if(!value)
            {
                //don't allow null or undefined
                value = "";
            }
            if(this._text == value)
            {
                return;
            }
            this._text = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
            this.dispatchEventWith(Event.CHANGE);
        }

        /**
         * @private
         */
        protected var _prompt:String;

        /**
         * The prompt, hint, or description text displayed by the input when the
         * value of its text is empty.
         */
        public function get prompt():String
        {
            return this._prompt;
        }

        /**
         * @private
         */
        public function set prompt(value:String):void
        {
            if(this._prompt == value)
            {
                return;
            }
            this._prompt = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _typicalText:String;

        /**
         * The text used to measure the input when the dimensions are not set
         * explicitly (in addition to using the background skin for measurement).
         */
        public function get typicalText():String
        {
            return this._typicalText;
        }

        /**
         * @private
         */
        public function set typicalText(value:String):void
        {
            if(this._typicalText == value)
            {
                return;
            }
            this._typicalText = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _maxChars:int = 0;

        /**
         * The maximum number of characters that may be entered.
         */
        public function get maxChars():int
        {
            return this._maxChars;
        }

        /**
         * @private
         */
        public function set maxChars(value:int):void
        {
            if(this._maxChars == value)
            {
                return;
            }
            this._maxChars = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _restrict:String;

        /**
         * Limits the set of characters that may be entered.
         */
        public function get restrict():String
        {
            return this._restrict;
        }

        /**
         * @private
         */
        public function set restrict(value:String):void
        {
            if(this._restrict == value)
            {
                return;
            }
            this._restrict = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _displayAsPassword:Boolean = false;

        /**
         * Determines if the entered text will be masked so that it cannot be
         * seen, such as for a password input.
         */
        public function get displayAsPassword():Boolean
        {
            return this._displayAsPassword;
        }

        /**
         * @private
         */
        public function set displayAsPassword(value:Boolean):void
        {
            if(this._displayAsPassword == value)
            {
                return;
            }
            this._displayAsPassword = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _isEditable:Boolean = true;

        /**
         * Determines if the text input is editable. If the text input is not
         * editable, it will still appear enabled.
         */
        public function get isEditable():Boolean
        {
            return this._isEditable;
        }

        /**
         * @private
         */
        public function set isEditable(value:Boolean):void
        {
            if(this._isEditable == value)
            {
                return;
            }
            this._isEditable = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _keyboardType:LoomKeyboardType = 0;

        /**
         * Determines the type of keyboard to open when control gains focus.
         */
        public function get keyboardType():LoomKeyboardType
        {
            return this._keyboardType;
        }

        /**
         * @private
         */
        public function set keyboardType(value:LoomKeyboardType):void
        {
            if(this._keyboardType == value)
            {
                return;
            }
            this._keyboardType = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _textEditorFactory:Function;

        /**
         * A function used to instantiate the text editor. If null,
         * `FeathersControl.defaultTextEditorFactory` is used
         * instead. The text editor must be an instance of
         * `ITextEditor`. This factory can be used to change
         * properties on the text editor when it is first created. For instance,
         * if you are skinning Feathers components without a theme, you might
         * use this factory to set styles on the text editor.
         *
         * The factory should have the following function signature:
         * `function():ITextEditor`
         *
         * @see feathers.core.ITextEditor
         * @see feathers.core.FeathersControl#defaultTextEditorFactory
         */
        public function get textEditorFactory():Function
        {
            return this._textEditorFactory;
        }

        /**
         * @private
         */
        public function set textEditorFactory(value:Function):void
        {
            if(this._textEditorFactory == value)
            {
                return;
            }
            this._textEditorFactory = value;
            this.invalidate(INVALIDATION_FLAG_TEXT_EDITOR);
        }

        /**
         * @private
         */
        protected var _promptFactory:Function;

        /**
         * A function used to instantiate the prompt text renderer. If null,
         * `FeathersControl.defaultTextRendererFactory` is used
         * instead. The prompt text renderer must be an instance of
         * `ITextRenderer`. This factory can be used to change
         * properties on the prompt when it is first created. For instance, if
         * you are skinning Feathers components without a theme, you might use
         * this factory to set styles on the prompt.
         *
         * The factory should have the following function signature:
         * `function():ITextRenderer`
         *
         * @see feathers.core.ITextRenderer
         * @see feathers.core.FeathersControl#defaultTextRendererFactory
         * @see feathers.controls.text.BitmapFontTextRenderer
         * @see feathers.controls.text.TextFieldTextRenderer
         */
        public function get promptFactory():Function
        {
            return this._promptFactory;
        }

        /**
         * @private
         */
        public function set promptFactory(value:Function):void
        {
            if(this._promptFactory == value)
            {
                return;
            }
            this._promptFactory = value;
            this.invalidate(INVALIDATION_FLAG_PROMPT_FACTORY);
        }

        /**
         * @private
         */
        protected var _promptProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to the text input's prompt
         * text renderer. The prompt text renderer is an `ITextRenderer`
         * instance that is created by `promptFactory`. The available
         * properties depend on which `ITextRenderer` implementation
         * is returned by `promptFactory`. The most common
         * implementations are `BitmapFontTextRenderer` and
         * `TextFieldTextRenderer`.
         *
         * If the subcomponent has its own subcomponents, their properties
         * can be set too, using attribute `&#64;` notation. For example,
         * to set the skin on the thumb of a `SimpleScrollBar`
         * which is in a `Scroller` which is in a `List`,
         * you can use the following syntax:
         * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
         *
         * Setting properties in a `promptFactory` function
         * instead of using `promptProperties` will result in
         * better performance.
         *
         * @see #promptFactory
         * @see feathers.core.ITextRenderer
         * @see feathers.controls.text.BitmapFontTextRenderer
         * @see feathers.controls.text.TextFieldTextRenderer
         */
        public function get promptProperties():Dictionary.<String, Object>
        {
            if(!this._promptProperties)
            {
                this._promptProperties = new Dictionary.<String, Object>;
            }
            return this._promptProperties;
        }

        /**
         * @private
         */
        public function set promptProperties(value:Dictionary.<String, Object>):void
        {
            if(this._promptProperties == value)
            {
                return;
            }
            this._promptProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         * The width of the first skin that was displayed.
         */
        protected var _originalSkinWidth:Number = NaN;

        /**
         * @private
         * The height of the first skin that was displayed.
         */
        protected var _originalSkinHeight:Number = NaN;

        /**
         * @private
         */
        protected var _backgroundSkin:DisplayObject;

        /**
         * A display object displayed behind the header's content.
         */
        public function get backgroundSkin():DisplayObject
        {
            return this._backgroundSkin;
        }

        /**
         * @private
         */
        public function set backgroundSkin(value:DisplayObject):void
        {
            if(this._backgroundSkin == value)
            {
                return;
            }

            if(this._backgroundSkin && this._backgroundSkin != this._backgroundDisabledSkin &&
                this._backgroundSkin != this._backgroundFocusedSkin)
            {
                this.removeChild(this._backgroundSkin);
            }
            this._backgroundSkin = value;
            if(this._backgroundSkin && this._backgroundSkin.parent != this)
            {
                this._backgroundSkin.visible = false;
                this._backgroundSkin.touchable = false;
                this.addChildAt(this._backgroundSkin, 0);
            }
            this.invalidate(INVALIDATION_FLAG_SKIN);
        }

        /**
         * @private
         */
        protected var _backgroundFocusedSkin:DisplayObject;

        /**
         * A display object displayed behind the header's content when the
         * TextInput has focus.
         */
        public function get backgroundFocusedSkin():DisplayObject
        {
            return this._backgroundFocusedSkin;
        }

        /**
         * @private
         */
        public function set backgroundFocusedSkin(value:DisplayObject):void
        {
            if(this._backgroundFocusedSkin == value)
            {
                return;
            }

            if(this._backgroundFocusedSkin && this._backgroundFocusedSkin != this._backgroundSkin &&
                this._backgroundFocusedSkin != this._backgroundDisabledSkin)
            {
                this.removeChild(this._backgroundFocusedSkin);
            }
            this._backgroundFocusedSkin = value;
            if(this._backgroundFocusedSkin && this._backgroundFocusedSkin.parent != this)
            {
                this._backgroundFocusedSkin.visible = false;
                this._backgroundFocusedSkin.touchable = false;
                this.addChildAt(this._backgroundFocusedSkin, 0);
            }
            this.invalidate(INVALIDATION_FLAG_SKIN);
        }

        /**
         * @private
         */
        protected var _backgroundDisabledSkin:DisplayObject;

        /**
         * A background to display when the header is disabled.
         */
        public function get backgroundDisabledSkin():DisplayObject
        {
            return this._backgroundDisabledSkin;
        }

        /**
         * @private
         */
        public function set backgroundDisabledSkin(value:DisplayObject):void
        {
            if(this._backgroundDisabledSkin == value)
            {
                return;
            }

            if(this._backgroundDisabledSkin && this._backgroundDisabledSkin != this._backgroundSkin &&
                this._backgroundDisabledSkin != this._backgroundFocusedSkin)
            {
                this.removeChild(this._backgroundDisabledSkin);
            }
            this._backgroundDisabledSkin = value;
            if(this._backgroundDisabledSkin && this._backgroundDisabledSkin.parent != this)
            {
                this._backgroundDisabledSkin.visible = false;
                this._backgroundDisabledSkin.touchable = false;
                this.addChildAt(this._backgroundDisabledSkin, 0);
            }
            this.invalidate(INVALIDATION_FLAG_SKIN);
        }

        /**
         * Quickly sets all padding properties to the same value. The
         * `padding` getter always returns the value of
         * `paddingTop`, but the other padding values may be
         * different.
         */
        public function get padding():Number
        {
            return this._paddingTop;
        }

        /**
         * @private
         */
        public function set padding(value:Number):void
        {
            this.paddingTop = value;
            this.paddingRight = value;
            this.paddingBottom = value;
            this.paddingLeft = value;
        }

        /**
         * @private
         */
        protected var _paddingTop:Number = 0;

        /**
         * The minimum space, in pixels, between the input's top edge and the
         * input's content.
         */
        public function get paddingTop():Number
        {
            return this._paddingTop;
        }

        /**
         * @private
         */
        public function set paddingTop(value:Number):void
        {
            if(this._paddingTop == value)
            {
                return;
            }
            this._paddingTop = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _paddingRight:Number = 0;

        /**
         * The minimum space, in pixels, between the input's right edge and the
         * input's content.
         */
        public function get paddingRight():Number
        {
            return this._paddingRight;
        }

        /**
         * @private
         */
        public function set paddingRight(value:Number):void
        {
            if(this._paddingRight == value)
            {
                return;
            }
            this._paddingRight = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _paddingBottom:Number = 0;

        /**
         * The minimum space, in pixels, between the input's bottom edge and
         * the input's content.
         */
        public function get paddingBottom():Number
        {
            return this._paddingBottom;
        }

        /**
         * @private
         */
        public function set paddingBottom(value:Number):void
        {
            if(this._paddingBottom == value)
            {
                return;
            }
            this._paddingBottom = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _paddingLeft:Number = 0;

        /**
         * The minimum space, in pixels, between the input's left edge and the
         * input's content.
         */
        public function get paddingLeft():Number
        {
            return this._paddingLeft;
        }

        /**
         * @private
         */
        public function set paddingLeft(value:Number):void
        {
            if(this._paddingLeft == value)
            {
                return;
            }
            this._paddingLeft = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         * Flag indicating that the text editor should get focus after it is
         * created.
         */
        protected var _isWaitingToSetFocus:Boolean = false;

        /**
         * @private
         */
        protected var _pendingSelectionStartIndex:int = -1;

        /**
         * @private
         */
        protected var _pendingSelectionEndIndex:int = -1;

        /**
         * @private
         */
        protected var _oldMouseCursor:String = null;

        /**
         * @private
         */
        protected var _textEditorProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to the text input's
         * text editor. The text editor is an `ITextEditor` instance
         * that is created by `textEditorFactory`.
         *
         * If the subcomponent has its own subcomponents, their properties
         * can be set too, using attribute `&#64;` notation. For example,
         * to set the skin on the thumb of a `SimpleScrollBar`
         * which is in a `Scroller` which is in a `List`,
         * you can use the following syntax:
         * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
         *
         * Setting properties in a `textEditorFactory` function
         * instead of using `textEditorProperties` will result in
         * better performance.
         *
         * @see #textEditorFactory
         * @see feathers.core.ITextEditor
         */
        public function get textEditorProperties():Dictionary.<String, Object>
        {
            if(!this._textEditorProperties)
            {
                this._textEditorProperties = new Dictionary.<String, Object>;
            }
            return this._textEditorProperties;
        }

        /**
         * @private
         */
        public function set textEditorProperties(value:Dictionary.<String, Object>):void
        {
            if(this._textEditorProperties == value)
            {
                return;
            }
            this._textEditorProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @inheritDoc
         */
        override public function showFocus():void
        {
            this.selectRange(0, this._text.length);
            super.showFocus();
        }

        /**
         * Focuses the text input control so that it may be edited.
         */
        public function setFocus():void
        {
            if(this._textEditorHasFocus)
            {
                return;
            }
            if(this.textEditor)
            {
                this._isWaitingToSetFocus = false;
                this.textEditor.setFocus();
            }
            else
            {
                this._isWaitingToSetFocus = true;
                this.invalidate(INVALIDATION_FLAG_SELECTED);
            }
        }

        /**
         * Sets the range of selected characters. If both values are the same,
         * or the end index is `-1`, the text insertion position is
         * changed and nothing is selected.
         */
        public function selectRange(startIndex:int, endIndex:int = -1):void
        {
            if(endIndex < 0)
            {
                endIndex = startIndex;
            }
            if(startIndex < 0)
            {
                Debug.assert("Expected start index >= 0. Received " + startIndex + ".");
            }
            if(endIndex > this._text.length)
            {
                Debug.assert("Expected start index > " + this._text.length + ". Received " + endIndex + ".");
            }

            if(this.textEditor)
            {
                this._pendingSelectionStartIndex = -1;
                this._pendingSelectionEndIndex = -1;
                this.textEditor.selectRange(startIndex, endIndex);
            }
            else
            {
                this._pendingSelectionStartIndex = startIndex;
                this._pendingSelectionEndIndex = endIndex;
                this.invalidate(INVALIDATION_FLAG_SELECTED);
            }
        }

        /**
         * @private
         */
        override protected function draw():void
        {
            const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);
            const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
            const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
            const skinInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SKIN);
            var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);
            const textEditorInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_TEXT_EDITOR);
            const promptFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_PROMPT_FACTORY);
            const focusInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_FOCUS);

            if(textEditorInvalid)
            {
                this.createTextEditor();
            }

            if(promptFactoryInvalid)
            {
                this.createPrompt();
            }

            if(textEditorInvalid || stylesInvalid)
            {
                this.refreshTextEditorProperties();
            }

            if(promptFactoryInvalid || stylesInvalid)
            {
                this.refreshPromptProperties();
            }

            if(textEditorInvalid || dataInvalid)
            {
                const oldIgnoreTextChanges:Boolean = this._ignoreTextChanges;
                this._ignoreTextChanges = true;
                this.textEditor.text = this._text;
                this._ignoreTextChanges = oldIgnoreTextChanges;
            }

            if(promptFactoryInvalid || dataInvalid)
            {
                this.promptTextRenderer.visible = this._prompt && !this._text;
            }

            if(textEditorInvalid || stateInvalid)
            {
                this.textEditor.isEnabled = this._isEnabled;
                /*if(!this._isEnabled && Mouse.supportsNativeCursor && this._oldMouseCursor)
                {
                    Mouse.cursor = this._oldMouseCursor;
                    this._oldMouseCursor = null;
                }*/
            }

            if(textEditorInvalid || stateInvalid || skinInvalid)
            {
                this.refreshBackground();
            }

            sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

            if(textEditorInvalid || promptFactoryInvalid || sizeInvalid || stylesInvalid || skinInvalid || stateInvalid)
            {
                this.layout();
            }

            if(sizeInvalid || focusInvalid)
            {
                this.refreshFocusIndicator();
            }

            this.doPendingActions();

            if(text && text.length > 0 || _textEditorHasFocus)
            {
                if(promptTextRenderer) promptTextRenderer.visible = false;
                if(textEditor) textEditor.visible = true;
                layout();
            }
            else
            {
                if(promptTextRenderer) promptTextRenderer.visible = true;
                if(textEditor) textEditor.visible = false;
                layout();
            }
        }

        /**
         * @private
         */
        protected function autoSizeIfNeeded():Boolean
        {
            const needsWidth:Boolean = isNaN(this.explicitWidth);
            const needsHeight:Boolean = isNaN(this.explicitHeight);
            if(!needsWidth && !needsHeight)
            {
                return false;
            }

            var typicalTextWidth:Number = 0;
            var typicalTextHeight:Number = 0;
            if(this._typicalText)
            {
                const oldIgnoreTextChanges:Boolean = this._ignoreTextChanges;
                this._ignoreTextChanges = true;
                this.textEditor.setSize(NaN, NaN);
                this.textEditor.text = this._typicalText;
                HELPER_POINT = this.textEditor.measureText();
                this.textEditor.text = this._text;
                this._ignoreTextChanges = oldIgnoreTextChanges;
                typicalTextWidth = HELPER_POINT.x;
                typicalTextHeight = HELPER_POINT.y;
            }
            if(this._prompt)
            {
                this.promptTextRenderer.setSize(NaN, NaN);
                HELPER_POINT = this.promptTextRenderer.measureText();
                typicalTextWidth = Math.max(typicalTextWidth, HELPER_POINT.x);
                typicalTextHeight = Math.max(typicalTextHeight, HELPER_POINT.y);
            }

            var newWidth:Number = this.explicitWidth;
            var newHeight:Number = this.explicitHeight;
            if(needsWidth)
            {
                newWidth = Math.max(this._originalSkinWidth, typicalTextWidth + this._paddingLeft + this._paddingRight);
            }
            if(needsHeight)
            {
                newHeight = Math.max(this._originalSkinHeight, typicalTextHeight + this._paddingTop + this._paddingBottom);
            }

            if(this._typicalText)
            {
                this.textEditor.width = this.actualWidth - this._paddingLeft - this._paddingRight;
                this.textEditor.height = this.actualHeight - this._paddingTop - this._paddingBottom;
            }

            return this.setSizeInternal(newWidth, newHeight, false);
        }

        /**
         * @private
         */
        protected function createTextEditor():void
        {
            if(this.textEditor)
            {
                this.removeChild(DisplayObject(this.textEditor), true);
                this.textEditor.removeEventListener(Event.CHANGE, textEditor_changeHandler);
                this.textEditor.removeEventListener(FeathersEventType.ENTER, textEditor_enterHandler);
                this.textEditor.removeEventListener(FeathersEventType.FOCUS_IN, textEditor_focusInHandler);
                this.textEditor.removeEventListener(FeathersEventType.FOCUS_OUT, textEditor_focusOutHandler);
                this.textEditor = null;
            }

            const factory:Function = this._textEditorFactory != null ? this._textEditorFactory : FeathersControl.defaultTextEditorFactory;
            this.textEditor = ITextEditor(factory.call());
            this.textEditor.addEventListener(Event.CHANGE, textEditor_changeHandler);
            this.textEditor.addEventListener(FeathersEventType.ENTER, textEditor_enterHandler);
            this.textEditor.addEventListener(FeathersEventType.FOCUS_IN, textEditor_focusInHandler);
            this.textEditor.addEventListener(FeathersEventType.FOCUS_OUT, textEditor_focusOutHandler);
            this.addChild(DisplayObject(this.textEditor));
        }

        /**
         * @private
         */
        protected function createPrompt():void
        {
            if(this.promptTextRenderer)
            {
                this.removeChild(DisplayObject(this.promptTextRenderer), true);
                this.promptTextRenderer = null;
            }

            const factory:Function = this._promptFactory != null ? this._promptFactory : FeathersControl.defaultTextRendererFactory;
            this.promptTextRenderer = ITextRenderer(factory.call());
            this.addChild(DisplayObject(this.promptTextRenderer));
        }

        /**
         * @private
         */
        protected function doPendingActions():void
        {
            if(this._isWaitingToSetFocus)
            {
                this._isWaitingToSetFocus = false;
                if(!this._textEditorHasFocus)
                {
                    this.textEditor.setFocus();
                }
            }
            if(this._pendingSelectionStartIndex >= 0)
            {
                const startIndex:int = this._pendingSelectionStartIndex;
                const endIndex:int = this._pendingSelectionEndIndex;
                this._pendingSelectionStartIndex = -1;
                this._pendingSelectionEndIndex = -1;
                this.selectRange(startIndex, endIndex);
            }
        }

        /**
         * @private
         */
        protected function refreshTextEditorProperties():void
        {
            this.textEditor.displayAsPassword = this._displayAsPassword;
            this.textEditor.maxChars = this._maxChars;
            this.textEditor.restrict = this._restrict;
            this.textEditor.isEditable = (this._isEditable && this._localIsEditable);
            this.textEditor.keyboardType = this._keyboardType;
            
            const displayTextEditor:DisplayObject = DisplayObject(this.textEditor);
            Dictionary.mapToObject(this._textEditorProperties, displayTextEditor);
        }

        /**
         * @private
         */
        protected function refreshPromptProperties():void
        {
            this.promptTextRenderer.text = this._prompt;
            const displayPrompt:DisplayObject = DisplayObject(this.promptTextRenderer);
            Dictionary.mapToObject(this._promptProperties, displayPrompt);
        }

        /**
         * @private
         */
        protected function refreshBackground():void
        {
            const useDisabledBackground:Boolean = !this._isEnabled && this._backgroundDisabledSkin;
            const useFocusBackground:Boolean = this._textEditorHasFocus && this._backgroundFocusedSkin;
            this.currentBackground = this._backgroundSkin;
            if(useDisabledBackground)
            {
                this.currentBackground = this._backgroundDisabledSkin;
            }
            else if(useFocusBackground)
            {
                this.currentBackground = this._backgroundFocusedSkin;
            }
            else
            {
                if(this._backgroundFocusedSkin)
                {
                    this._backgroundFocusedSkin.visible = false;
                    this._backgroundFocusedSkin.touchable = false;
                }
                if(this._backgroundDisabledSkin)
                {
                    this._backgroundDisabledSkin.visible = false;
                    this._backgroundDisabledSkin.touchable = false;
                }
            }

            if(useDisabledBackground || useFocusBackground)
            {
                if(this._backgroundSkin)
                {
                    this._backgroundSkin.visible = false;
                    this._backgroundSkin.touchable = false;
                }
            }

            if(this.currentBackground)
            {
                if(isNaN(this._originalSkinWidth))
                {
                    this._originalSkinWidth = this.currentBackground.width;
                }
                if(isNaN(this._originalSkinHeight))
                {
                    this._originalSkinHeight = this.currentBackground.height;
                }
            }
        }

        /**
         * @private
         */
        protected function layout():void
        {
            if(this.currentBackground)
            {
                this.currentBackground.visible = true;
                this.currentBackground.touchable = true;
                this.currentBackground.width = this.actualWidth;
                this.currentBackground.height = this.actualHeight;
            }

            this.textEditor.x = this._paddingLeft;
            this.textEditor.y = this._paddingTop;
            this.textEditor.width = this.actualWidth - this._paddingLeft - this._paddingRight;
            this.textEditor.height = this.actualHeight - this._paddingTop - this._paddingBottom;

            this.promptTextRenderer.x = this._paddingLeft;
            this.promptTextRenderer.y = this._paddingTop;
            this.promptTextRenderer.width = this.actualWidth - this._paddingLeft - this._paddingRight;
            this.promptTextRenderer.height = this.actualHeight - this._paddingTop - this._paddingBottom;
        }

        /**
         * @private
         */
        protected function setFocusOnTextEditorWithTouch(touch:Touch):void
        {
            HELPER_POINT = touch.getLocation(this.stage);
            const isInBounds:Boolean = this.contains(this.stage.hitTest(HELPER_POINT, true));
            if(!this._textEditorHasFocus && isInBounds)
            {
                HELPER_POINT = this.globalToLocal(HELPER_POINT);
                HELPER_POINT.x -= this._paddingLeft;
                HELPER_POINT.y -= this._paddingTop;
                this._isWaitingToSetFocus = false;
                this.textEditor.setFocus();
            }
        }

        /**
         * @private
         */
        protected function textInput_addedToStageHandler(event:Event):void
        {
            // We need to validate when put on stage because touch events expect a validated control
            validate();
            stage.addEventListener(TouchEvent.TOUCH, textInput_touchHandler);
        }
        
        /**
         * @private
         */
        protected function textInput_removedFromStageHandler(event:Event):void
        {
            stage.removeEventListener(TouchEvent.TOUCH, textInput_touchHandler);
            
            this._textEditorHasFocus = false;
            this._isWaitingToSetFocus = false;
            this._touchPointID = -1;
            /*if(Mouse.supportsNativeCursor && this._oldMouseCursor)
            {
                Mouse.cursor = this._oldMouseCursor;
                this._oldMouseCursor = null;
            }*/
        }

        /**
         * @private
         */
        protected function textInput_touchHandler(event:TouchEvent):void
        {
            if(!this._isEnabled)
            {
                this._touchPointID = -1;
                return;
            }

            var touch:Touch = null;
            
            const touches:Vector.<Touch> = event.getTouches(stage, null, HELPER_TOUCHES_VECTOR);
            
            if (_textEditorHasFocus) {
                var clearFocus:Boolean = false;
                for each(touch in touches) {
                    if (!touch.isTouching(this) && touch.phase == TouchPhase.ENDED) {
                        clearFocus = true;
                        break;
                    }
                    
                    //end hover
                    /*if(Mouse.supportsNativeCursor && this._oldMouseCursor)
                    {
                        Mouse.cursor = this._oldMouseCursor;
                        this._oldMouseCursor = null;
                    }*/
                }
                
                if (clearFocus) {
                    this.textEditor.clearFocus();
                    return;
                }
            }

            if(this._touchPointID >= 0)
            {
                touch = null;
                for each(var currentTouch:Touch in touches)
                {
                    if (!currentTouch.isTouching(this)) continue;
                    if(currentTouch.id == this._touchPointID)
                    {
                        touch = currentTouch;
                        break;
                    }
                }
                if(!touch)
                {
                    HELPER_TOUCHES_VECTOR.length = 0;
                    return;
                }
                if(touch.phase == TouchPhase.ENDED)
                {
                    this._touchPointID = -1;
                    if(this.textEditor.setTouchFocusOnEndedPhase)
                    {
                        this.setFocusOnTextEditorWithTouch(touch);
                    }
                }
            }
            else
            {
                for each(touch in touches)
                {
                    if (!touch.isTouching(this)) continue;
                    if(touch.phase == TouchPhase.BEGAN)
                    {
                        this._touchPointID = touch.id;
                        if(!this.textEditor.setTouchFocusOnEndedPhase)
                        {
                            this.setFocusOnTextEditorWithTouch(touch);
                        }
                        break;
                    }
                    else if(touch.phase == TouchPhase.HOVER)
                    {
                        /*if(Mouse.supportsNativeCursor && !this._oldMouseCursor)
                        {
                            this._oldMouseCursor = Mouse.cursor;
                            Mouse.cursor = MouseCursor.IBEAM;
                        }*/
                        break;
                    }
                }
            }
            HELPER_TOUCHES_VECTOR.length = 0;
        }

        /**
         * @private
         */
        override protected function focusInHandler(event:Event):void
        {
            super.focusInHandler(event);
            this.setFocus();
        }

        /**
         * @private
         */
        override protected function focusOutHandler(event:Event):void
        {
            super.focusOutHandler(event);
            this.textEditor.clearFocus();
        }

        /**
         * @private
         */
        protected function textEditor_changeHandler(event:Event):void
        {
            if(this._ignoreTextChanges)
            {
                return;
            }
            this.text = this.textEditor.text;
        }

        /**
         * @private
         */
        protected function textEditor_enterHandler(event:Event):void
        {
            this.dispatchEventWith(FeathersEventType.ENTER);
        }

        /**
         * @private
         */
        protected function textEditor_focusInHandler(event:Event):void
        {
            this._textEditorHasFocus = true;
            this._localIsEditable = true; // Workaround Hack
            this.refreshTextEditorProperties(); // Workaround Hack
            this._touchPointID = -1;
            this.invalidate(INVALIDATION_FLAG_STATE);
            if(this._focusManager)
            {
                this._focusManager.focus = this;
            }
            else
            {
                this.dispatchEventWith(FeathersEventType.FOCUS_IN);
            }
        }

        /**
         * @private
         */
        protected function textEditor_focusOutHandler(event:Event):void
        {
            this._textEditorHasFocus = false;
            this._localIsEditable = false; // Workaround Hack
            this.refreshTextEditorProperties(); // Workaround Hack
            this.invalidate(INVALIDATION_FLAG_STATE);
            if(this._focusManager)
            {
                if(this._focusManager.focus == this)
                {
                    this._focusManager.focus = null;
                }
            }
            else
            {
                this.dispatchEventWith(FeathersEventType.FOCUS_OUT);
            }
        }
    }
}
