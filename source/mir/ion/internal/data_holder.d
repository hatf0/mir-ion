module mir.ion.internal.data_holder;

private static immutable memoryOverflowMessage = "Can not allocate enough memory";

version(D_Exceptions)
{
    private static immutable memoryOverflowException = new Error(memoryOverflowMessage);
}

private static void* validatePtr()(return void* ptr)
    @safe pure @nogc
{
    import mir.utility: _expect;
    if (_expect(ptr is null, false))
    {
        version(D_Exceptions)
            throw memoryOverflowException;
        else
            assert(0, memoryOverflowMessage);
    }
    else
    {
        return ptr;
    }
}

/++
+/
struct IonTapeHolder(size_t stackAllocatedLength)
{
    private align(16) ubyte[stackAllocatedLength] stackData = void;
    ///
    ubyte[] data;

    ///
    size_t currentTapePosition;

    ///
    inout(ubyte)[] tapeData() inout @property
    {
        return data[0 .. currentTapePosition];
    }

    ///
    @disable this(this);
    ///
    @disable this();

    ///
    this(size_t initialSize)
        @trusted pure nothrow @nogc
    {
        if (initialSize > stackAllocatedLength)
        {
            import mir.internal.memory: malloc;
            auto ptr = malloc(initialSize).validatePtr;
            data = cast(ubyte[])ptr[0 .. initialSize];
        }
        else
        {
            data = stackData[];
        }
    }

    ///
    ~this()
        @trusted pure nothrow @nogc
    {
        import mir.internal.memory: free;
        if (data.ptr != stackData.ptr)
        {
            free(data.ptr);
        }
    }

    ///
    void extend(size_t newSize)
        @trusted pure nothrow @nogc
    {
        import mir.internal.memory: malloc, realloc;
        import core.stdc.string: memcpy;

        if (newSize > data.length)
        {
            if (data.ptr != stackData.ptr)
            {
                auto ptr = realloc(data.ptr, newSize).validatePtr;
                data = cast(ubyte[])ptr[0 .. newSize];
            }
            else
            {
                auto ptr = malloc(newSize).validatePtr;
                memcpy(ptr, stackData.ptr, stackData.length);
                data = cast(ubyte[])ptr[0 .. newSize];
            }
        }
    }

    ///
    void reserve(size_t size)
    {
        assert(currentTapePosition <= data.length);

        import mir.utility: max;

        import mir.internal.memory: malloc, realloc;
        import core.stdc.string: memcpy;

        if (currentTapePosition + size > data.length)
        {
            auto newSize = data.length + max(size, data.length);
            if (data.ptr != stackData.ptr)
            {
                auto ptr = realloc(data.ptr, newSize).validatePtr;
                data = cast(ubyte[])ptr[0 .. newSize];
            }
            else
            {
                auto ptr = malloc(newSize).validatePtr;
                memcpy(ptr, stackData.ptr, stackData.length);
                data = cast(ubyte[])ptr[0 .. newSize];
            }
        }
    }
}
