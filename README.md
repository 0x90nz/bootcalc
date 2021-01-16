# bootcalc

Did you ever feel like your life was missing a fully bootable RPN calculator in
less than 512 bytes? No? Doesn't matter, I made it anyway.

This is a pretty simple implementation of a calculator, and doesn't use any
super fancy space-saving techniques but still manages to fit in under the
required 512 bytes to fit into a PC boot sector.

The only requirement in terms of software to compile it is a copy of `nasm`.
You can make the bootsector by running `make`. To run it you'll need `qemu`,
if you've got that you can run `make run` to run the program.
