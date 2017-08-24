module dgt.io;
import core.stdc.stdio;

@nogc nothrow:

void print(in int value)
{
    printf("%d", value);
}

void print(in double value)
{
    printf("%f", value);
}

void print(T)(in T obj)
{
    obj.print();
}

void print(T)(in T[] items)
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

void print(T:char)(in T[] items)
{
    printf("%s", items.ptr);
}

void print(T, A...)(in T obj, in A a)
{
    print(obj);
    foreach(val; a)
        print(val);
}

void println(A...)(in A values)
{
    foreach(val; values)
    {
        print(val);
    }
    print("\n");
}
