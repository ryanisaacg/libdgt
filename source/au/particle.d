import array, geom, texture, util;

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
    Array!Texture regions;
	Vector!int top_left, bottom_right, velocity_min, velocity_max,
        acceleration_min, acceleration_max, scale_min, scale_max,
		scale_velocity_min, scale_velocity_max;
	float rotation_min = 0, rotation_max = 0, rotational_velocity_min = 0,
        rotational_velocity_max = 0;
	int lifetime_min, lifetime_max;
	int particle_min, particle_max;
	ParticleBehavior behavior = ParticleBehavior.Ignore;

    @nogc nothrow public:
    this(Array!Texture regions)
    {
        this.regions = regions;
    }

    Particle emit()
    {
        return Particle(regions[randi_range(0, cast(int)regions.length)],
			 randvectori_range(top_left, bottom_right),
			 randvectori_range(velocity_min, velocity_max),
			 randvectori_range(acceleration_min, acceleration_max),
			 randvectori_range(scale_min, scale_max),
			 randvectori_range(scale_velocity_min, scale_velocity_max),
			 randf_range(rotation_min, rotation_max),
			 randf_range(rotational_velocity_min, rotational_velocity_max),
			 randi_range(lifetime_min, lifetime_max),
			 behavior);
    }
}
