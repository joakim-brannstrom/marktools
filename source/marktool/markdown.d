/**
Copyright: Copyright (c) 2018, Joakim Brännström. All rights reserved.
License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
Author: Joakim Brännström (joakim.brannstrom@gmx.com)
*/
module marktool.markdown;

import app : Config;

int toMarkdown(const Config conf) {
    import std.conv : to;
    import std.process : execute;
    import std.stdio : writeln, File;

    auto pass1 = execute(["pandoc", "-s", "-f" ~ conf.srcFmt.to!string,
            "-t" ~ conf.dstFmt.to!string] ~ conf.src);
    if (pass1.status != 0) {
        writeln(pass1.output);
        return pass1.status;
    }

    auto clean_output = pass1.output.markdownCleanup;

    auto fout = File(conf.dst, "w");
    foreach (s; conf.src)
        fout.writefln("[Original Source](%s)", s);
    fout.write(clean_output);

    return 0;
}

private:

char[] markdownCleanup(const(char)[] input) {
    char[] output;
    size_t j;

    int column;
    for (size_t i = 0; i < input.length; i++) {
        char c = input[i];

        switch (c) {
        case '\t':
            while ((column & 7) != 7) {
                output ~= ' ';
                j++;
                column++;
            }
            c = ' ';
            column++;
            break;

        case '\r':
        case '\n':
            while (j && output[j - 1] == ' ')
                j--;
            output = output[0 .. j];
            column = 0;
            break;

        default:
            column++;
            break;
        }
        output ~= c;
        j++;
    }
    while (j && output[j - 1] == ' ')
        j--;
    return output[0 .. j];
}
