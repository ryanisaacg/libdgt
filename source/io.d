import core.stdc.stdio;

@nogc nothrow:

void print(int value)
{
    printf("%d", value);
}

void print(double value)
{
    printf("%f", value);
}

void print(string value)
{
    printf("%s", value.ptr);
}

void print(char* value)
{
    printf("%s", value);
}

void print(T)(T obj)
{
    obj.print();
}

void print(T)(T[] items)
{
    print(T.stringof, "[");
    for(size_t i = 0; i < items.length; i++)
    {
        print(item);
        if(i != items.length - 1)
            print(", ");
    }
    print("]");
}

void print(T, A...)(T obj, A a)
{
    print(obj);
    foreach(val; a)
        print(val);
}

void println(A...)(A values)
{
    foreach(val; values)
    {
        print(val);
    }
    print("\n");
}
