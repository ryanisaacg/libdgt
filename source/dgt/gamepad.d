module dgt.gamepad;

import derelict.sdl2.sdl;

static immutable TRIGGER_MAX = 32767.0;

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

    private float getTrigger(SDL_GameControllerAxis axis)
    {
        return SDL_GameControllerGetAxis(controller, axis) / TRIGGER_MAX;
    }

    private bool getButton(SDL_GameControllerButton button)
    {
        return SDL_GameControllerGetButton(controller, button) != 0;
    }

    public:
    @property float leftX()
    {
        return getTrigger(SDL_CONTROLLER_AXIS_LEFTX);
    }

    @property float leftY()
    {
        return getTrigger(SDL_CONTROLLER_AXIS_LEFTY);
    }

    @property float rightX()
    {
        return getTrigger(SDL_CONTROLLER_AXIS_RIGHTX);
    }

    @property float rightY()
    {
        return getTrigger(SDL_CONTROLLER_AXIS_RIGHTY);
    }

    @property float triggerLeft()
    {
        return getTrigger(SDL_CONTROLLER_AXIS_TRIGGERLEFT);
    }

    @property float triggerRight()
    {
        return getTrigger(SDL_CONTROLLER_AXIS_TRIGGERRIGHT);
    }

    @property bool faceDown()
    {
        return getButton(SDL_CONTROLLER_BUTTON_A);
    }

    @property bool faceRight()
    {
        return getButton(SDL_CONTROLLER_BUTTON_B);
    }

    @property bool faceLeft()
    {
        return getButton(SDL_CONTROLLER_BUTTON_X);
    }

    @property bool faceUp()
    {
        return getButton(SDL_CONTROLLER_BUTTON_Y);
    }

    @property bool select()
    {
        return getButton(SDL_CONTROLLER_BUTTON_BACK);
    }

    @property bool main()
    {
        return getButton(SDL_CONTROLLER_BUTTON_GUIDE);
    }

    @property bool start()
    {
        return getButton(SDL_CONTROLLER_BUTTON_START);
    }

    @property bool leftStick()
    {
        return getButton(SDL_CONTROLLER_BUTTON_LEFTSTICK);
    }

    @property bool rightStick()
    {
        return getButton(SDL_CONTROLLER_BUTTON_RIGHTSTICK);
    }

    @property bool leftShoulder()
    {
        return getButton(SDL_CONTROLLER_BUTTON_LEFTSHOULDER);
    }

    @property bool rightShoulder()
    {
        return getButton(SDL_CONTROLLER_BUTTON_RIGHTSHOULDER);
    }

    @property bool dpadUp()
    {
        return getButton(SDL_CONTROLLER_BUTTON_DPAD_UP);
    }

    @property bool dpadDown()
    {
        return getButton(SDL_CONTROLLER_BUTTON_DPAD_DOWN);
    }

    @property bool dpadLeft()
    {
        return getButton(SDL_CONTROLLER_BUTTON_DPAD_LEFT);
    }

    @property bool dpadRight()
    {
        return getButton(SDL_CONTROLLER_BUTTON_DPAD_RIGHT);
    }
}
