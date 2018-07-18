/**
Copyright: Copyright (c) 2018, Joakim Brännström. All rights reserved.
License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
Author: Joakim Brännström (joakim.brannstrom@gmx.com)

This module contains functionality for retrieving content over HTTP(s) and
store it in an intermediate buffer. This is then intended to be passed on to
e.g. pandoc via stdin.
*/
module marktool.htmlbuf;

import std.process : Pipe;

import std.typecons : Nullable;

struct HtmlData {
    ubyte[] data;
    alias data this;

    /// Write the lines via the pipe.
    void send(ref Pipe p) {
        p.writeEnd.write(data);
    }
}

HtmlData getContent(string url) {
    import std.algorithm : splitter, map;
    import std.array : array;
    static import requests;

    auto data = requests.getContent(url).data;
    return HtmlData(data);
}
