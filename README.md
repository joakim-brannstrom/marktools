# marktool

**marktool** is a framework for writing plugins using libclang. The main focus
is tools for testing and analyze.

# Getting Started

marktool depends on the following software packages:

 * [D compiler](https://dlang.org/download.html) (dmd 2.079+, ldc 1.8.0+)
 * pandoc

For users running Ubuntu one of the dependencies can be installed with apt.
```sh
sudo apt install pandoc
```

Download the D compiler of your choice, extract it and add to your PATH shell
variable.
```sh
# example with an extracted DMD
export PATH=/path/to/dmd/linux/bin64/:$PATH
```

Once the dependencies are installed it is time to download the source code to install marktool.
```sh
git clone https://github.com/joakim-brannstrom/marktool.git
cd marktool
dub build -b release
```

Done! Have fun.
Don't be shy to report any issue that you find.
