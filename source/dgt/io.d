///@nogc printing functions
module dgt.io;
import core.stdc.stdio;

@nogc nothrow @trusted:

///Print the integer to stdout
void print(in int value)
{
    printf("%d", value);
}

///Print the double to stdout
void print(in double value)
{
    printf("%f", value);
}

///Call the print function of the object
void print(T)(in T obj)
{
    obj.print();
}

///Print an array of items
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

///Print a string (special case of an array)
void print(T:char)(in T[] items)
{
    printf("%s", items.ptr);
}

////Print some number of objects
void print(T, A...)(in T obj, in A a)
{
    print(obj);
    foreach(val; a)
        print(val);
}

///Print some number of objects followed by a newline
void println(A...)(in A values)
{
    foreach(val; values)
    {
        print(val);
    }
    print("\n");
}
