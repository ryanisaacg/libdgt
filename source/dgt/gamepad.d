module au.gamepad;

import derelict.sdl2.sdl;

static immutable TRIGGER_MAX = 32767.0;

struct Gamepad 
{
    private SDL_GameController* controller;

    @nogc nothrow:

    package this(SDL_GameController* controller)
    {
        this.controller = controller;
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
    float leftX()
    {
        return getTrigger(SDL_CONTROLLER_AXIS_LEFTX);
    }

    float leftY()
    {
        return getTrigger(SDL_CONTROLLER_AXIS_LEFTY);
    }

    float rightX()
    {
        return getTrigger(SDL_CONTROLLER_AXIS_RIGHTX);
    }

    float rightY()
    {
        return getTrigger(SDL_CONTROLLER_AXIS_RIGHTY);
    }

    float triggerLeft()
    {
        return getTrigger(SDL_CONTROLLER_AXIS_TRIGGERLEFT);
    }

    float triggerRight()
    {
        return getTrigger(SDL_CONTROLLER_AXIS_TRIGGERRIGHT);
    }

    bool faceDown()
    {
        return getButton(SDL_CONTROLLER_BUTTON_A);
    }   

    bool faceRight()
    {
        return getButton(SDL_CONTROLLER_BUTTON_B);
    }

    bool faceLeft()
    {
        return getButton(SDL_CONTROLLER_BUTTON_X);
    }
        
    bool faceUp()
    {
        return getButton(SDL_CONTROLLER_BUTTON_Y);
    }
        
    bool select()
    {
        return getButton(SDL_CONTROLLER_BUTTON_BACK);
    }
        
    bool main()
    {
        return getButton(SDL_CONTROLLER_BUTTON_GUIDE);
    }
        
    bool start()
    {
        return getButton(SDL_CONTROLLER_BUTTON_START);
    }
        
    bool leftStick()
    {
        return getButton(SDL_CONTROLLER_BUTTON_LEFTSTICK);
    }
        
    bool rightStick()
    {
        return getButton(SDL_CONTROLLER_BUTTON_RIGHTSTICK);
    }
        
    bool leftShoulder()
    {
        return getButton(SDL_CONTROLLER_BUTTON_LEFTSHOULDER);
    }

    bool rightShoulder()
    {
        return getButton(SDL_CONTROLLER_BUTTON_RIGHTSHOULDER);
    }
        
    bool dpadUp()
    {
        return getButton(SDL_CONTROLLER_BUTTON_DPAD_UP);
    }

    bool dpadDown()
    {
        return getButton(SDL_CONTROLLER_BUTTON_DPAD_DOWN);
    }
    
    bool dpadLeft()
    {
        return getButton(SDL_CONTROLLER_BUTTON_DPAD_LEFT);
    }

    bool dpadRight()
    {
        return getButton(SDL_CONTROLLER_BUTTON_DPAD_RIGHT);
    }
}
