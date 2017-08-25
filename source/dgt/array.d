module dgt.array;
import core.stdc.stdlib : malloc, realloc, free;
import dgt.io;

struct Array(T)
{

	private void* backingBuffer = null;
	private static immutable initialSize = 16;

    @disable this();

	@nogc @trusted nothrow public:
    this(in size_t initialCapacity)
    {
        ensureCapacity(initialCapacity);
    }

    this(size_t N)(in T[N] array)
    {
        this = array;
    }

	void ensureCapacity(in size_t newCapacity)
	{
		void* old = backingBuffer;
		backingBuffer = realloc(backingBuffer, size_t.sizeof * 2 + T.sizeof * newCapacity);
		*capacity = newCapacity;
		if (old == null) *count = 0;
	}

	void add(scope T val)
	{
		if (*count >= *capacity)
			ensureCapacity(*capacity * 2);
		buffer[*count] = val;
		*count += 1;
	}

	void addAll(A...)(scope A a)
	{
		foreach(val; a)
		{
			add(val);
		}
	}

	void destroy()
	{
		free(backingBuffer);
	}

	int opApply(int delegate(T) @nogc nothrow dg) const
    {
		for(size_t i = 0; i < length; i++)
			dg(buffer[i]);
        return 0;
    }

	void print() const
	{
		dgt.io.print("Array!", T.stringof, "[");
		for(size_t i = 0; i < length; i++)
		{
			dgt.io.print(this[i]);
			if(i != length - 1)
			{
				dgt.io.print(", ");
			}
		}
		dgt.io.print("]");
	}

	ref Array!T opAssign(size_t N)(in T[N] data)
	{
		ensureCapacity(N);
		clear();
		*count = N;
		for(size_t i = 0; i < N; i++)
		{
			this[i] = data[i];
		}
		return this;
	}

	pure:
	void remove(in size_t index)
	{
		buffer[index] = buffer[*count];
		*count -= 1;
	}

	ref T opIndex(in size_t index) const
	{
		assert(index < *count);
		return buffer[index];
	}

	ref T opIndexAssign(scope T value, in size_t index)
	{
		assert(index < *count);
		return buffer[index] = value;
	}

	void clear()
	{
		*count = 0;
	}

	 @property T* ptr() const { return buffer; }
	 @property size_t length() const { return *count; }

	private:
	private @property size_t* count() const { return cast(size_t*) backingBuffer; }
	private @property size_t* capacity() const { return count + 1; }
	private @property T* buffer() const { return cast(T*)(capacity + 1); }
}

@nogc nothrow:
unittest
{
	auto x = Array!int(4);
	for(int i = 0; i < 17; i++)
	{
		x.add(i);
	}
	assert(x[0] == 0);
	assert(x[16] == 16);
    x.addAll(1, 2, 3, 4);
    assert(x[x.length - 1] == 4);
    assert(x.ptr[0] == 0);
    x[0] = 5;
    assert(x[0] == 5);
    size_t length = x.length;
    x.remove(0);
    assert(x.length == length - 1);
    int first = x[0];
    auto other = Array!int(1);
    foreach(val; x)
    {
        other.add(val);
    }
    assert(x.length == other.length);
    assert(other[5] == x[5]);
    println(x);
    x.clear();
    assert(x.length == 0);
	x.destroy();
}
