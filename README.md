# vforth
__v.Forth 1.5m__ 

__build 20200808 - Matteo Vitturi, 1990-2020__

This version is a back-porting to Microdrive and DiSCIPLE MSG from v.Forth 1.5 NEXTZXOS version.

MDR : ZX Microdrive version now uses all the eight (8) Microdrive-units chained together to offer 1778 blocks / screens (889 KBytes). I think nobody on Earth ever owned 8 Microdrive-units at the same time, so the only way to use this much storage is using an emulator.

MGT: DiSCIPLE version uses two disks as usual  (#1 for Forth, #2 for Blocks) that offer 1560 blocks / screens (780 KBytes). Again, better use an emulator.

In this version 1.5 there are a few deep modifications from previous version 1.413 that make it "deprecated".

The two versions are compiled from a single source file F15m.f , with the only difference in the content of MGT  variable  that contains  0 for  Microdrive and 1 for DISCiPLE-MGT, 



# vforth
__v.Forth 1.413e__ 

__build 20190311 - Matteo Vitturi, 1990-2019__

In spring of 1990 I had the chance to work for a couple of months on a Sinclair ZX Spectrum 48K equipped with a Microdrive. 
Among the other things, I succeeded to disassemble an reassemble the machine code of a Forth for Spectrum 
Oasis Software's __"White Lightning"__ (https://sites.google.com/view/vforth/wl-dis).

My purpose was to make effective the use of the Microdrive within the Forth environment. 

The result has been satisfying, but due to the fragility of the keyboard, I had to move to emulators that supported Microdrivers.

https://sites.google.com/view/vforth/vforth1-3

https://www.oocities.org/matteo_vitturi/english/index.htm

