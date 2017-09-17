module dgt.camera;

import dgt.geom;

///A set of projections used to manage windows and views
struct Camera
{
    const Transform project, unproject, opengl;

    ////Create a camera with a given window size and view of the world
    pure @nogc nothrow this(in Rectangle windowSize, in Rectangle world)
    {
        const normalizeWindow = Transform.normalize(windowSize);
        const normalizeWorld = Transform.normalize(world);
        project = normalizeWindow * normalizeWorld.inverse;
        unproject = normalizeWorld * normalizeWindow.inverse;
        opengl = normalizeWorld;
    }
}
