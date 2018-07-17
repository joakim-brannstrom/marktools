/**
Copyright: Copyright (c) 2018, Joakim Brännström. All rights reserved.
License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
Author: Joakim Brännström (joakim.brannstrom@gmx.com)
*/
module app;

int main(string[] args) {
    import std.stdio : writefln;
    import markdown;
    import pdf;

    auto conf = cliParser(args);
    if (!conf.valid)
        return 1;

    alias HandleFn = int function(const Config);

    HandleFn[Config.Format] handle;

    handle[Config.Format.commonmark] = &toMarkdown;
    handle[Config.Format.pdf] = &toPdf;

    if (auto v = conf.dstFmt in handle) {
        writefln("Converting '%s' (%s) to '%s' (%s)", conf.src, conf.srcFmt,
                conf.dst, conf.dstFmt);
        return (*v)(conf);
    }

    writefln("Destination '%s' not supported", conf.dstFmt);
    writefln("Supported are %s", handle.byKey);
    return 1;
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
    string[] src;

    /// Destination format
    Format dstFmt = Format.commonmark;
    string dst;
}

private:

Config cliParser(string[] args) {
    import std.format : format;
    import std.path : absolutePath;
    import std.stdio : writeln, writefln;
    import std.traits : EnumMembers;

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
            if (args.length >= 3) {
                conf.src = args[1 .. $ - 1];
                conf.dst = args[$ - 1].absolutePath;
                return !help_info.helpWanted;
            } else if (args.length < 3)
                writeln("Missing arguments [SOURCE] and DESTINATION");
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

        defaultGetoptPrinter(format("usage: %s [options] [SOURCE] DESTINATION\n",
                args[0].baseName), help_info.options);
        writefln("Supported formats %s", [EnumMembers!(Config.Format)]);
    }

    if (!conf.valid) {
        printHelp;
    }

    return conf;
}
