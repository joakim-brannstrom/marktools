/**
Copyright: Copyright (c) 2018, Joakim Brännström. All rights reserved.
License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
Author: Joakim Brännström (joakim.brannstrom@gmx.com)
*/
module app;

import std.exception : collectException;

int main(string[] args) {
    auto conf = cliParser(args);
    if (!conf.valid)
        return 1;

    alias Fn = int function(const Config);
    Fn[Config.Command] cmds;

    cmds[Config.Command.standard] = &commandStandard;
    cmds[Config.Command.install] = &commandInstall;

    if (auto v = conf.cmd in cmds) {
        return (*v)(conf);
    }

    return 1;
}

int commandStandard(const Config conf) {
    import std.stdio : writefln;
    import marktool.markdown;
    import marktool.pdf;

    alias HandleFn = int function(const Config);

    HandleFn[Config.Format] handle;

    handle[Config.Format.commonmark] = &toMarkdown;
    handle[Config.Format.pdf] = &toPdf;

    if (auto v = conf.dstFmt in handle) {
        writefln("Converting %s (%s) to '%s' (%s)", conf.src, conf.srcFmt, conf.dst, conf.dstFmt);
        return (*v)(conf);
    }

    writefln("Destination '%s' not supported", conf.dstFmt);
    writefln("Supported are %s", handle.byKey);
    return 1;
}

int commandInstall(const Config conf) {
    import std.algorithm : map;
    import std.conv : text;
    import std.file : thisExePath, symlink, exists, remove;
    import std.path : dirName, buildPath;
    import std.stdio : writeln, writefln;
    import std.traits : EnumMembers;

    const string this_ = thisExePath;
    const string base = this_.dirName;

    foreach (def_; [EnumMembers!PreConfigDefault].map!text) {
        const target = buildPath(base, def_);

        try {
            if (exists(target))
                remove(target);
            symlink(this_, target);
            writefln("Created symlink '%s' -> '%s'", this_, target);
        } catch (Exception e) {
            writeln(e.msg).collectException;
            writefln("Unable to create symlink '%s' -> '%s'", this_, target).collectException;
        }
    }

    return 0;
}

struct Config {
    /// False if the config is invalid in some way. Do not use the data. Just exit.
    bool valid;

    enum Format {
        html,
        pdf,
        commonmark
    }

    enum Command {
        standard,
        install,
    }

    Command cmd;

    /// Source format parameters to pandoc
    Format srcFmt = Format.html;
    string[] src;

    /// Destination format
    Format dstFmt = Format.commonmark;
    string dst;
}

private:

/// Pre-configured defaults that make it convenient for the user.
enum PreConfigDefault {
    html2markdown,
    markdown2pdf,
}

Config cliParser(string[] args) {
    import std.conv : to;
    import std.file : thisExePath, exists;
    import std.format : format;
    import std.path : absolutePath, baseName, buildNormalizedPath, buildPath, dirName;
    import std.stdio : writeln, writefln;
    import std.traits : EnumMembers;

    static void genericParser(string[] args, ref Config conf) {
        static import std.getopt;

        std.getopt.GetoptResult help_info;
        try {
            bool install;
            // dfmt off
            help_info = std.getopt.getopt(args, std.getopt.config.passThrough,
                std.getopt.config.keepEndOfOptions,
                "f", format("format of the source (default: %s)", Config.init.srcFmt), &conf.srcFmt,
                "t", format("format of the destination (default: %s)", Config.init.dstFmt), &conf.dstFmt,
                "install", "create symlinks for convenient defaults", &install,
                );
            // dfmt on

            conf.valid = () {
                if (install) {
                    conf.cmd = Config.Command.install;
                    return true;
                } else if (args.length >= 3) {
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
    }

    static void html2Markdown(string[] args, ref Config conf) {
        conf.srcFmt = Config.Format.html;
        conf.dstFmt = Config.Format.commonmark;

        conf.valid = () {
            if (args.length == 3) {
                conf.src = [args[1]];
                conf.dst = args[2].absolutePath;
                return true;
            }
            return false;
        }();
    }

    static void markdown2Pdf(string[] args, ref Config conf) {
        conf.srcFmt = Config.Format.commonmark;
        conf.dstFmt = Config.Format.pdf;
        conf.valid = () {
            if (args.length >= 3) {
                conf.src = args[1 .. $ - 1];
                conf.dst = args[$ - 1].absolutePath;
                return true;
            }
            return false;
        }();
    }

    Config conf;

    alias Fn = void function(string[] args, ref Config);
    Fn[PreConfigDefault] cmds;
    cmds[PreConfigDefault.html2markdown] = &html2Markdown;
    cmds[PreConfigDefault.markdown2pdf] = &markdown2Pdf;

    const thisExe = () {
        try {
            auto tmp = buildPath(thisExePath.dirName, args[0].baseName).absolutePath.buildNormalizedPath;
            if (exists(tmp))
                return tmp;
        }
        catch(Exception e) {
        }
        return thisExePath;
    }();

    try {
        if (auto v = thisExe.baseName.to!(PreConfigDefault) in cmds)
            (*v)(args, conf);
        else
            genericParser(args, conf);
    } catch (Exception e) {
        writeln("Generic");
        genericParser(args, conf);
    }

    return conf;
}
