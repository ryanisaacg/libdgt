struct Vector(T, size_t N)
{
    static assert(N > 0);
    private T[N] data;

    @nogc nothrow pure public:
    @property T x() { return data[0]; }
    @property T x(T val) { return data[0] = val; }

    static if(N > 1)
    {
        @property T y() { return data[1]; }
        @property T y(T val) { return data[1] = val; }
    }

    static if(N > 2)
    {
        @property T z() { return data[2]; }
        @property T z(T val) { return data[2] = val; }
    }

}

struct Matrix(T, size_t M, size_t N)
{
    static assert(M > 0 && N > 0);
    private T[M * N] data;

    @nogc nothrow pure:

	public T* dataPointer() 
	{
		return data.ptr;
	}

    public void setToIdentity() 
	{
        static assert(M == N);
        for(size_t i = 0; i < M; i++)
            for(size_t j = 0; j < N; j++)
                this[i, j] = 0;
        for(size_t i = 0; i < M; i++)
            this[i, i] = 1;
    }

    public Matrix!(T, m, N) opBinary(string op, size_t m)(Matrix!(T, m, N) other)
    {
        static assert(op == "*");
        Matrix!(T, m, N) ret;
        for (size_t i = 0; i < m; i++) {
    		for (size_t j = 0; j < N; j++) {
    			for (size_t k = 0; k < M; k++) {
    				ret[i, j] = ret[i, j] + this[k, j] * other[i, k];
    			}
    		}
    	}
        return ret;
    }

    public Vector!(T, N) opBinary(string op)(Vector!(T, N) other)
    {
        static assert(op == "*");
        Vector!(T, N) ret;
		for (size_t i = 0; i < N; i++) {
			for (size_t j = 0; j < M; j++) {
				ret.data[i] += this[j, i] * other.data[j];
			}
		}
        return ret;
    }

    public T opIndex(size_t i, size_t j)
    {
        return data[i * N + j];
    }

    public T opIndexAssign(T val, size_t i, size_t j)
    {
        return data[i * N + j] = val;
    }
}

unittest
{
    Matrix!(int, 2, 2) m, n;
    m.setToIdentity();
    n[0, 0] = 5;
    assert((m * n)[0, 0] == 5);
    m[0, 0] = 2;
    assert((m * n)[0, 0] = 10);

    Matrix!(int, 3, 3) scale;
    scale.setToIdentity();
    scale[0, 0] = 2;
    scale[1, 1] = 2;
    Vector!(int, 3) vector;
    vector.x = 2;
    vector.y = 5;
    auto scaled = scale * vector;
    assert(scaled.x == 4 && scaled.y == 10);
}
