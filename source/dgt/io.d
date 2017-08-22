module dgt.io;
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

void print(T)(const(T) obj)
{
    obj.print();
}

void print(T)(const(T[]) items)
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

void print(T:char)(const(T[]) items)
{
    printf("%s", items.ptr);
}

void print(T, A...)(const(T) obj, const(A) a)
{
    print(obj);
    foreach(val; a)
        print(val);
}

void println(A...)(const(A) values)
{
    foreach(val; values)
    {
        print(val);
    }
    print("\n");
}
