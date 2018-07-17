/**
Copyright: Copyright (c) 2018, Joakim Brännström. All rights reserved.
License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
Author: Joakim Brännström (joakim.brannstrom@gmx.com)
*/
import core.stdc.stdlib;
import std.algorithm;
import std.array;
import std.ascii;
import std.conv;
import std.file;
import std.path;
import std.process;
import std.range;
import std.stdio;
import std.string;

int main(string[] args) {
    auto conf = cliParser(args);
    if (!conf.valid)
        return 1;

    alias HandleFn = int function(const Config);
    HandleFn[Config.Format] handle;
    handle[Config.Format.commonmark] = &toMarkdown;

    if (auto v = conf.dstFmt in handle) {
        return (*v)(conf);
    }

    writefln("Destination '%s' not supported", conf.dstFmt);
    writefln("Supported are %s", handle.byKey);
    return 1;
}

int toMarkdown(const Config conf) {
    auto pass1 = execute(["pandoc", "-s", "-S", "-f" ~ conf.srcFmt.to!string,
            "-t" ~ conf.dstFmt.to!string, conf.src]);
    if (pass1.status != 0) {
        writeln(pass1.output);
        return pass1.status;
    }

    auto clean_output = filter(pass1.output);

    auto fout = File(conf.dst, "w");
    fout.writefln("[Original Source](%s)", conf.src);
    fout.write(clean_output);

    return 0;
}

char[] filter(const(char)[] input) {
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

struct Config {
    /// False if the config is invalid in some way. Do not use the data. Just exit.
    bool valid;

    enum Format {
        html,
        pdf,
        commonmark
    }

    /// Source format parameters to pandoc
    Format srcFmt = Format.html;
    string src;

    /// Destination format
    Format dstFmt = Format.commonmark;
    string dst;
}

Config cliParser(string[] args) {
    Config conf;

    static import std.getopt;

    std.getopt.GetoptResult help_info;
    try {
        // dfmt off
        help_info = std.getopt.getopt(args, std.getopt.config.passThrough,
            std.getopt.config.keepEndOfOptions,
            "f", format("format of the source (default: %s)", Config.init.srcFmt), &conf.srcFmt,
            "t", format("format of the destination (default: %s)", Config.init.dstFmt), &conf.dstFmt,
            );
        // dfmt on

        conf.valid = () {
            if (args.length == 3) {
                conf.src = args[1];
                conf.dst = args[2].absolutePath;
                return !help_info.helpWanted;
            } else if (args.length < 3)
                writeln("Missing arguments SOURCE and DESTINATION");
            else if (args.length > 3)
                writeln("Too many arguments");
            return false;
        }();
    } catch (std.getopt.GetOptException e) {
        // unknown option
        writeln(e.msg);
    } catch (Exception e) {
        writeln(e.msg);
    }

    void printHelp() {
        import std.getopt : defaultGetoptPrinter;
        import std.format : format;
        import std.path : baseName;

        defaultGetoptPrinter(format("usage: %s [options] SOURCE DESTINATION\n",
                args[0].baseName), help_info.options);
    }

    if (!conf.valid) {
        printHelp;
    }

    return conf;
}
