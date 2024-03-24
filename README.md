# vforth

This is a back-porting to ZX Microdrive and DISCiPLE MGT from v.Forth NEXTZXOS version ( https://github.com/mattsteeldue/vforth-next ).

Apart from some obvious hardware limitations, the v-Forth Next version documentation is valid for this backporting.

To run this Forth system within an emulator, you have to pick one that supports Microdrive and/or DISCiPLE disk drive, such as Fuse (https://fuse-emulator.sourceforge.net) that works well under Windows and Linux.


ZX Microdrive version  
---------------------
It uses all the 8 Microdrive units, somehow chained together, to offer 1778 blocks half-KB each (889 KBytes). 
Emulators provide such 8 Microdrive units: the first unit is used to keep the system loader while the other 7 units are used to store blocks.
This Forth system uses a low-level direct acces to sectors, so that the "!Blocks" text-file appears as a single file spread across 7 cartridges.
I think nobody on Earth ever owned 8 Microdrive-units at the same time, so the only way to use this much storage is using an emulator.

To run under Windows you can use  Fuse  and to spare some time at start-up, you can specify the switches to enable ZX Interface 1 and insert eight Microdrive cartridges.

start fuse.exe ^
    --interface1 ^
    --microdrive-file M1.MDR   ^
    --microdrive-2-file M2.MDR ^
    --microdrive-3-file M3.MDR ^
    --microdrive-4-file M4.MDR ^
    --microdrive-5-file M5.MDR ^
    --microdrive-6-file M6.MDR ^
    --microdrive-7-file M7.MDR ^
    --microdrive-8-file M8.MDR 

Once the Spectrum is shows the copyright message, you should give the classic  RUN  to load the "run" loader.


Running on real hardware
------------------------
This Forth system was born and run on my  48K  for years, but to effectively run under real hardware, using a single Microdrive Unit, you need to use "run_HW" Basic loader instead of the usual "run" loader. That loader prompts you to switch cartridges, removing the "Programs" cartridge and inserting the "Blocks" one, and awaits a keypress.
Conversely, the "Blocks" cartridge must be prepared beforehand using the Basic program "Tap2Mdr.bas" (available in M1.MDR cartridge-file) that reads from tape file !Blocks7.TAP  four string-array to be transferred to a single text file to fill all the cartridge. Usually such a transfer program breaks with "Microdrive full" message after 160/170 blocks, depending on the real capacity of a cartridge. At this point the real-hardware single-unit system is ready to run.
In particular, !Blocks7.TAP file content was produced by "Mdr2Tap.bas" Basic program that exploits -- in Basic -- the same tecnique to achieve a  "Random R/W Access" from/to a single text file  "!Blocks"  present in all seven cartridge-files  M2.MDR ... M8.MDR



DISCiPLE version 
----------------
It uses both disks: unit #1 for MGT system and Forth itself and unit #2 for data storage to offer 1560 Blocks / Screens (780 KBytes). 
Again, Fuse emulator works fine.

To spare some time you can specify the suitable switches

start fuse.exe ^
    --disciple ^
    --discipledisk Forth1.IMG 

To start v-Forth system, you have to load the "run" Basic loader, usually  LOAD P6  would be fine.
But, I'm not aware of a switch Fuse provides to insert the second floppy disk image at start-up, and you have to select Forth2.IMG via usual Menu bar.
If you don't insert the second disk image you'll get an error message "NO DISK in drive".



History
-------

__v-Forth 1.6__ 

__build 20240321 - Matteo Vitturi, 1990-2024__

Back-porting to 48/128 KB from v-Forth 1.6 - Sinclair ZX Spectrum Next Version.

__v-Forth 1.52m__ 

__build 20220730 - Matteo Vitturi, 1990-2022__

Back-porting to 48/128 KB from v-Forth 1.52 - Sinclair ZX Spectrum Next Version.



__v.Forth 1.5m__ 

__build 20210215 - Matteo Vitturi, 1990-2021__

Keeping these back-ported version aligned with the new Next version.
Introducing example game "Chomp" in blocks 600-670. It's a PacMan style.
Once AUTOEXEC completes its LOAD, give 600 LOAD, then GAME.
Cursor keys (or Cursor Joystick maybe)



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
Oasis Software's __"White Lightning"__ https://worldofspectrum.org/archive/software/utilities/white-lightning-oasis-software (my pencil work is here https://sites.google.com/view/vforth/wl-dis).

My purpose was to make effective the use of the Microdrive within the Forth environment. 

The result has been satisfying, but due to the fragility of the keyboard, I had to move to emulators that supported Microdrivers.

https://sites.google.com/view/vforth/vforth1-3

https://www.oocities.org/matteo_vitturi/english/index.htm

