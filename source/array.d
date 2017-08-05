import core.stdc.stdlib : malloc, realloc, free;

struct Array(T)
{

	private void* backingBuffer = null;
	private static immutable initialSize = 16;

	@nogc nothrow:
	public void ensureCapacity(size_t newCapacity)
	{
		void* old = backingBuffer;
		backingBuffer = realloc(backingBuffer, size_t.sizeof * 2 + T.sizeof * newCapacity);
		*capacity = newCapacity;
		if (old == null) *count = 0;
	}

	public void add(T val)
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

	public void addAll(A...)(A a)
	{
		foreach(val; a)
		{
			add(val);
		}
	}

	public void destroy()
	{
		free(backingBuffer);
	}

	pure:
	public void remove(size_t index)
	{
		buffer[index] = buffer[*count];
		*count -= 1;
	}

	public ref T opIndex(size_t index)
	{
		assert(index < *count);
		return buffer[index];
	}

	public ref T opIndexAssign(T value, size_t index)
	{
		assert(index < *count);
		return buffer[index] = value;
	}

	public void clear()
	{
		*count = 0;
	}

	public size_t length() { return *count; }
	private size_t* count() { return cast(size_t*) backingBuffer; }
	private size_t* capacity() {	return count + 1; }
	private T* buffer() { return cast(T*)(capacity + 1); }
	public T* ptr() { return buffer; }
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
