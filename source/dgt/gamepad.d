module dgt.gamepad;

import derelict.sdl2.sdl;

//The maximum value SDL reports for a trigger
static immutable TRIGGER_MAX = 32767.0;

/**
An attached game controller with a traditional setup

Only the controllers SDL supports out of the box will work, and no plans exist to expand this capability
*/
struct Gamepad
{
    private SDL_GameController* controller;

    @nogc nothrow:
    @disable this();

    package this(SDL_GameController* controller)
    {
        this.controller = controller;
    }

    package void destroy()
    {
        SDL_GameControllerClose(controller);
    }

    private float getAxis(SDL_GameControllerAxis axis)
    {
        return SDL_GameControllerGetAxis(controller, axis) / TRIGGER_MAX;
    }

    private bool getButton(SDL_GameControllerButton button)
    {
        return SDL_GameControllerGetButton(controller, button) != 0;
    }

    public:
    ///The X value of the left stick
    @property float leftX()
    {
        return getAxis(SDL_CONTROLLER_AXIS_LEFTX);
    }

    //The Y value of the left stick
    @property float leftY()
    {
        return getAxis(SDL_CONTROLLER_AXIS_LEFTY);
    }

    ///The X value of the right stick
    @property float rightX()
    {
        return getAxis(SDL_CONTROLLER_AXIS_RIGHTX);
    }

    ///The Y value of the right stick
    @property float rightY()
    {
        return getAxis(SDL_CONTROLLER_AXIS_RIGHTY);
    }

    ///How much the left trigger is being pressed
    @property float triggerLeft()
    {
        return getAxis(SDL_CONTROLLER_AXIS_TRIGGERLEFT);
    }

    ///How much the right trigger is being pressed
    @property float triggerRight()
    {
        return getAxis(SDL_CONTROLLER_AXIS_TRIGGERRIGHT);
    }

    ///If the bottom face button is being pressed (A on an XBOX controller)
    @property bool faceDown()
    {
        return getButton(SDL_CONTROLLER_BUTTON_A);
    }

    ///If the right face button is being pressed (B on an XBOX controller)
    @property bool faceRight()
    {
        return getButton(SDL_CONTROLLER_BUTTON_B);
    }

    ///If the left face button is being pressed (X on an XBOX controller)
    @property bool faceLeft()
    {
        return getButton(SDL_CONTROLLER_BUTTON_X);
    }

    ///If the top face button is being pressed (Y on an XBOX controller)
    @property bool faceUp()
    {
        return getButton(SDL_CONTROLLER_BUTTON_Y);
    }

    ///If the select button is being pressed (back on an XBOX controller)
    @property bool select()
    {
        return getButton(SDL_CONTROLLER_BUTTON_BACK);
    }

    ///If the main button is being pressed (the center X on an XBOX controller)
    @property bool main()
    {
        return getButton(SDL_CONTROLLER_BUTTON_GUIDE);
    }

    ///If the start button is being pressed
    @property bool start()
    {
        return getButton(SDL_CONTROLLER_BUTTON_START);
    }

    ///If the left stick is being pressed in
    @property bool leftStick()
    {
        return getButton(SDL_CONTROLLER_BUTTON_LEFTSTICK);
    }

    ///If the right stick is being pressed in
    @property bool rightStick()
    {
        return getButton(SDL_CONTROLLER_BUTTON_RIGHTSTICK);
    }

    ///If the left shoulder button is being pressed in
    @property bool leftShoulder()
    {
        return getButton(SDL_CONTROLLER_BUTTON_LEFTSHOULDER);
    }

    ///If the right shoulder button is being pressed in
    @property bool rightShoulder()
    {
        return getButton(SDL_CONTROLLER_BUTTON_RIGHTSHOULDER);
    }

    ///If Up on the dpad is being pressed
    @property bool dpadUp()
    {
        return getButton(SDL_CONTROLLER_BUTTON_DPAD_UP);
    }

    ///If Down on the dpad is being pressed
    @property bool dpadDown()
    {
        return getButton(SDL_CONTROLLER_BUTTON_DPAD_DOWN);
    }

    ///If Left on the dpad is being pressed
    @property bool dpadLeft()
    {
        return getButton(SDL_CONTROLLER_BUTTON_DPAD_LEFT);
    }

    ///If Right on the dpad is being pressed
    @property bool dpadRight()
    {
        return getButton(SDL_CONTROLLER_BUTTON_DPAD_RIGHT);
    }
}
