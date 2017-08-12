module au.array;
import core.stdc.stdlib : malloc, realloc, free;
import au.io;

struct Array(T)
{

	private void* backingBuffer = null;
	private static immutable initialSize = 16;

	@nogc nothrow public:
	void ensureCapacity(size_t newCapacity)
	{
		void* old = backingBuffer;
		backingBuffer = realloc(backingBuffer, size_t.sizeof * 2 + T.sizeof * newCapacity);
		*capacity = newCapacity;
		if (old == null) *count = 0;
	}

	void add(T val)
	{
		if (backingBuffer == null)
		{
			ensureCapacity(16);
			*count = 0;
		}
		if (*count >= *capacity)
			ensureCapacity(*capacity * 2);
		buffer[*count] = val;
		*count += 1;
	}

	void addAll(A...)(A a)
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

	int opApply(int delegate(T) @nogc nothrow dg) {
		for(size_t i = 0; i < length; i++) {
			dg(buffer[i]);
		}
        return 0;
    }

	void print()
	{
		au.io.print("Array!", T.stringof, "[");
		for(size_t i = 0; i < length; i++)
		{
			au.io.print(this[i]);
			if(i != length - 1)
			{
				au.io.print(", ");
			}
		}
		au.io.print("]");
	}

	pure:
	void remove(size_t index)
	{
		buffer[index] = buffer[*count];
		*count -= 1;
	}

	ref T opIndex(size_t index)
	{
		assert(index < *count);
		return buffer[index];
	}

	ref T opIndexAssign(T value, size_t index)
	{
		assert(index < *count);
		return buffer[index] = value;
	}

	ref Array!T opAssign(size_t N)(T[N] data)
	{
		ensureCapacity(N);
		clear();
		for(size_t i = 0; i < N; i++)
		{
			this[i] = data[i];
		}
		return this;
	}

	void clear()
	{
		*count = 0;
	}

	T* ptr() { return buffer; }
	size_t length() { return *count; }

	private:
	private size_t* count() { return cast(size_t*) backingBuffer; }
	private size_t* capacity() {	return count + 1; }
	private T* buffer() { return cast(T*)(capacity + 1); }
}

@nogc nothrow unittest
{
	Array!int x;
	for(int i = 0; i < 17; i++)
	{
		x.add(i);
	}
	assert(x[0] == 0);
	assert(x[16] == 16);
	x.destroy();
}
