package com.taomee.mole;
 class HttpCache$2 implements java.util.Comparator {
    final synthetic com.taomee.mole.HttpCache this$0;

    HttpCache$2(com.taomee.mole.HttpCache p1)
    {
        this.this$0 = p1;
        return;
    }

    public int compare(java.io.File p3, java.io.File p4)
    {
        return Long.compare(p3.lastModified(), p4.lastModified());
    }

    public bridge synthetic int compare(Object p1, Object p2)
    {
        return this.compare(((java.io.File) p1), ((java.io.File) p2));
    }
}
