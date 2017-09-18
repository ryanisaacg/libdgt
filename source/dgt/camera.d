module dgt.camera;

import dgt.geom;

///A set of projections used to manage windows and views
struct Camera
{
    const Transform project, unproject, opengl;

    ////Create a camera with a given window size and view of the world
    pure @nogc nothrow this(in Rectangle windowSize, in Rectangle world)
    {
        project = Transform.translate(-windowSize.topLeft)
            * Transform.scale(Vector(windowSize.width / world.width, windowSize.height / world.height).inverse)
            * Transform.translate(world.topLeft);
        unproject = project.inverse;
        opengl = Transform.translate(-world.topLeft)
            * Transform.scale(world.size.inverse * 2)
            * Transform.translate(Vector(-1, -1))
            * Transform.scale(Vector(1, -1));
    }
}

unittest
{
    const cam = Camera(Rectangle(0, 0, 100, 100), Rectangle(0, 0, 50, 50));
    const screenBottom = Vector(0, 100);
    const worldBottom = Vector(0, 50);
    assert(cam.project * screenBottom == worldBottom);
    assert(cam.unproject * worldBottom == screenBottom);
    assert(cam.opengl * worldBottom == Vector(-1, -1));
}
unittest
{
    const cam = Camera(Rectangle(0, 0, 100, 100), Rectangle(50, 50, 50, 50));
    const worldTop = Vector(50, 50);
    assert(cam.opengl * worldTop == Vector(-1, 1));
}
