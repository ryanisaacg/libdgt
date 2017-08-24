module dgt.particle;
import dgt.array, dgt.geom, dgt.texture, dgt.util;

enum ParticleBehavior
{
    Ignore, Die, Bounce
}

struct Particle
{
    Texture region;
    Vector!int position, velocity, acceleration, scale, scale_velocity;
    float rotation = 0, rotational_velocity = 0;
    int lifetime = 0;
    ParticleBehavior behavior = ParticleBehavior.Ignore;

    @nogc nothrow pure public void update()
    {
        velocity = velocity + acceleration;
        position = position + velocity;
        scale = scale + scale_velocity;
        rotation += rotational_velocity;
        lifetime--;
    }
}

struct ParticleEmitter
{
    const(Array!Texture) regions;
    Vector!int top_left, bottom_right, velocity_min, velocity_max,
        acceleration_min, acceleration_max, scale_min, scale_max,
        scale_velocity_min, scale_velocity_max;
    float rotation_min = 0, rotation_max = 0, rotational_velocity_min = 0,
        rotational_velocity_max = 0;
    int lifetime_min, lifetime_max;
    int particle_min, particle_max;
    ParticleBehavior behavior = ParticleBehavior.Ignore;

    @nogc nothrow public:
    this(in Array!Texture regions)
    {
        this.regions = regions;
    }

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
