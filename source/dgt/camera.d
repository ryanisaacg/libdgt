module dgt.camera;

import dgt.geom;

///A set of projections used to manage windows and views
struct Camera
{
    const Transform project, unproject, opengl;

    ////Create a camera with a given window size and view of the world
    pure @nogc nothrow this(in Rectangle windowSize, in Rectangle world, in Transform cameraTransform = Transform())
    {
        unproject = cameraTransform
            * Transform.translate(-world.topLeft)
            * Transform.scale(Vector(world.width / windowSize.width, world.height / windowSize.height).inverse)
            * Transform.translate(windowSize.topLeft);
        project = unproject.inverse;
        opengl = cameraTransform
            * Transform.translate(-world.topLeft)
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
unittest
{
    const cam = Camera(Rectangle(0, 0, 10, 10), Rectangle(0, 0, 10, 10),
            Transform.rotate(-90));
    const projected = cam.project * Vector(5, 0);
    assert(projected == Vector(0, 5));
}
