module dgt.particle;
import dgt.geom, dgt.texture, dgt.util;

/**
Controls the behavior of particles when they collide with a tilemap

Ignore means the particles will continue as normal, Die will mean the particle disappears, and Bounce will mean the particle rebounds from the wall
*/
enum ParticleBehavior
{
    Ignore, Die, Bounce
}

/**
An individual instance of a particle

If you want to spawn particles use Window.addParticleBurst
*/
struct Particle
{
    Texture region;
    Vector!int position, velocity, acceleration, scale, scale_velocity;
    float rotation = 0, rotational_velocity = 0;
    int lifetime = 0;
    ParticleBehavior behavior = ParticleBehavior.Ignore;

    ///Step a particle forward a frame
    @safe @nogc nothrow pure public void update()
    {
        velocity = velocity + acceleration;
        position = position + velocity;
        scale = scale + scale_velocity;
        rotation += rotational_velocity;
        lifetime--;
    }
}

/**
A structure that allows particle spawn settings to be tweaked
*/
struct ParticleEmitter
{
    const(Texture[]) regions;
    Vector!int top_left, bottom_right, velocity_min, velocity_max,
        acceleration_min, acceleration_max, scale_min, scale_max,
        scale_velocity_min, scale_velocity_max;
    float rotation_min = 0, rotation_max = 0, rotational_velocity_min = 0,
        rotational_velocity_max = 0;
    int lifetime_min, lifetime_max;
    int particle_min, particle_max;
    ParticleBehavior behavior = ParticleBehavior.Ignore;

    @disable this();

    @nogc nothrow public:
    /**
    A list of all possible texture regions that the particles can source from
    */
    this(in Texture[] regions)
    {
        this.regions = regions;
    }

    ///Create a single particle
    Particle emit() const
    {
        return Particle(regions[randomRange(0, cast(int)regions.length)],
             randomRange(top_left, bottom_right),
             randomRange(velocity_min, velocity_max),
             randomRange(acceleration_min, acceleration_max),
             randomRange(scale_min, scale_max),
             randomRange(scale_velocity_min, scale_velocity_max),
             randomRange(rotation_min, rotation_max),
             randomRange(rotational_velocity_min, rotational_velocity_max),
             randomRange(lifetime_min, lifetime_max),
             behavior);
    }
}
