// ______________________________________________________________________ 
//
// zx-Microdrive / DISCiPLE option.

// 7719h
// selected microdrive channel address
                Variable_Def CHNL,   "CHNL",   $5D2F

// mgt
// we use two bits of MGT as flags:
// 1 : for DISCiPLE, reset for Microdrive
// 2 : for real hardware and a single microdrive configuration swapping cartridge 
//     at startup
// 4 : for emulator i.e. to use more than one microdrive within an emulator.
                Variable_Def MGT,   "MGT",   4

// 7734h INKEY  <<<
//
// 7749h SELECT <<<
// 


// 775Eh
// OPEN - MDR
// it relies on a BASIC's OPEN#4 to Microdrive 
// and sets the variables used to access the "!Blocks" data-file
                Colon_Def MDR, "MDR", is_normal // : mdr  ( n -- )
                dw      TO_R                 // >r
                dw      R_OP, ZLESS          // r@ 0<
                dw      R_OP, LIT, 15        // r@ [ decimal 15 ] Literal > 
                dw      GREATER              
                dw      PLUS, LIT, 25        // + [ decimal 25 ] Literal ?error
                dw      QERROR
                dw      R_OP, R_OP, PLUS     // r@ r@ + [ hex 5C16 ] Literal // STRMS 
                dw      LIT,  STRMS          //
                dw      PLUS, FETCH          // + @  // offset to stream #n    
                dw      LIT, CHANS           // [ hex 5C4F ] Literal  // CHANS
                dw      FETCH, PLUS          // @ + // address of channel #n
                dw      ONE_SUBTRACT, TO_R   // 1- >r
                dw      R_OP, LIT, 4         // r@ [ decimal 4 ] Literal + c@ [ hex 4D ] Literal - 
                dw      PLUS, CFETCH
                dw      LIT, $4D, SUBTRACT
                dw      LIT, 25, QERROR      // [ decimal 25 ] Literal ?error
                dw      R_OP                 // r@ [ decimal 26 ] Literal + @
                dw      LIT, 26, PLUS
                dw      FETCH
                dw      MMAP, STORE          // mmap !
                dw      R_TO                 // r> chnl !   // normally 5D2F
                dw      CHNL, STORE
                dw      R_TO                 // r> strm  !   // normally 4
                dw      STRM, STORE
                dw      EXIT


// 77CDh
// SCTR
// it fills the microdrive map with FFs 
// gets the HDNUMB variable of the Microdrive Channel
// calculates the corrisponding bit (byte and bit)
// and fools the microdrive to believe there is only that one sector free.
                Colon_Def SCTR, "SCTR", is_normal // : sctr  ( -- )
                dw      MMAP, FETCH          // mmap @ 
                dw      LIT, 32, LIT, 255    // [ decimal 32 ] Literal [ decimal 255 ] Literal fill 
                dw      FILL
                dw      CHNL, FETCH, LIT, 41 // chnl @ [ decimal 41 ] Literal // HDNUMB of channel
                dw      PLUS, CFETCH         // + c@                    // sect
                dw      LIT, 8               // [ decimal 8 ] Literal   
                dw      DIVMOD               // /mod        // rem q
                dw      SWAP                 // swap        // q   rem
                dw      ONE, SWAP            // 1 swap      // q 1 rem 
                dw      LSHIFT               // lshift      // q bits
                dw      NEG_ONE              //    [ decimal -1 ] Literal
                dw      XOR_OP               // xor          // q negbits
                dw      MMAP, FETCH          // mmap @       // q negbits 5CF0
                dw      ROT, PLUS            // rot +       // negbits 5CF0+q
                dw      CSTORE               // c!
                dw      EXIT

    // was: 
    // >r    // saves the quotient i.e. the offset inside microdrive map
    // 1 swap -1 Do 2* Loop  2/ 
    // [ decimal 255 ] Literal swap - mmap @ 
    // r> + c!


// 7831h
// MDRGET
// low level "CHREC" read
// gets the current channel "M" pointer stored in CHANNEL 
// puts   3 to channel+12 (i.e. a value > 512 for CHBYTE)
// puts   0 to channel+67 (RECFLG) this is not EOF
// puts 254 to channel+24 (CHFLAG) to read/write flag
// then forces the read of the next character available
                Colon_Def MDRGET, "MDRGET", is_normal // : mdrget
                dw      CHNL, FETCH, TO_R        //chnl @ >r
                dw      R_OP, ZEQUAL             // r@ 0=  [ 5 ] Literal ?error
                dw      LIT, 5, QERROR       
                dw      THREE                    // 3 // [ 3 ] Literal 
                dw       R_OP, LIT, 12           //
                dw      PLUS, CSTORE             // r@  [ decimal  12 ] Literal + c! // CHBYTE of channel
                dw      ZERO                     // 0 
                dw      R_OP, LIT, 67            // r@  [ decimal  67 ] Literal + c! // RECFLG of channel
                dw      PLUS, CSTORE
                dw      LIT, 254                 //[ decimal 254 ] Literal 
                dw      R_TO, LIT, 24            // r> [ decimal  24 ] Literal + c! // CHFLAG of channel
                dw      PLUS, CSTORE
                dw      STRM, FETCH, SELECT      // strm @ select 
                dw      INKEY, DROP              // inkey drop
                dw      DEVICE, FETCH, SELECT    // device @ select
                dw      EXIT
    

// 7882h
// MDRR1
// verifies if the current microdrive buffer is the requested block
// otherwise, it forces channel+13 "CHREC" and calls MDRGET
                Colon_Def MDRR1, "MDRR1", is_normal // : mdrr1  ( n -- )
                dw      LIT, 4, MDR
                dw      CHNL, FETCH, TO_R            // [ 4 ] Literal mdr chnl @ >r
                dw      LIT, 254, DIVMOD             // [ decimal 254 ] Literal /mod   // find drive# and sector#
                dw      DUP, LIT, 48, PLUS           // dup    [ decimal  48 ] Literal +
                dw      R_OP, LIT, 53
                dw      PLUS, CSTORE                 // r@  [ decimal  53 ] Literal + c!   // Last byte of HDNAME
                dw      MGT, FETCH, TWO_DIV, PLUS    // MGT @ 2/ +                         // DR0 correction
//              dw      TWO_PLUS                     // 2+                                 // DR0 is drive #2
                dw      R_OP, LIT, 25
                dw      PLUS, CSTORE                 // r@  [ decimal  25 ] Literal + c!   // CHDRIV
                dw      ONE_SUBTRACT, R_TO           // 1-  r> [ decimal  13 ] Literal + c!   // CHREC of channel
                dw      LIT, 13, PLUS, CSTORE        
                dw      MDRGET                       // mdrget
                dw      EXIT


// 78c1h
// MDRRD
// read block n and store it to buffer at address a
                Colon_Def MDRRD, "MDRRD", is_normal // : mdrrd  ( a n -- ) 
                dw      MDRR1                    // mdrr1
                dw      CHNL, FETCH              // chnl @
                dw      LIT, 82, PLUS            // [ decimal 82 ] Literal + // first byte of channel's data-area 
                dw      SWAP, BBUF, CMOVE        // swap b/buf cmove
                dw      EXIT
    

// 78e0h
// MDRWR    
// write block n to microdrive taking it from buffer at address a
                Colon_Def MDRWR, "MDRWR", is_normal // : mdrwr  ( a n -- )
                dw      MDRR1                       // mdrr1
                dw      CHNL, FETCH, TO_R           // chnl @ >r
                dw      R_OP, LIT, 82, PLUS         // r@ [ decimal 82 ] Literal + 
                dw      BBUF, CMOVE                 // b/buf cmove
                dw      SCTR                        // sctr
                dw      LIT, 255, R_OP              // [ decimal 255 ] Literal r@
                dw      LIT, 24, PLUS, CSTORE       // [ decimal  24 ] Literal + c!    // CHFLAG of channel
                dw      LIT, 511, R_OP              // [ decimal 511 ] Literal r@ 
                dw      LIT, 11, PLUS, STORE        // [ decimal  11 ] Literal + !     // CHBYTE of channel
                dw      STRM, FETCH, SELECT         // strm @ select
                dw      R_OP                        // r [ decimal 593 ] Literal + c@  // latest byte of channel's data-area
                dw      LIT, 593, PLUS, CFETCH      //
                dw      EMITC                       // emitc
                dw      DEVICE, FETCH, SELECT       // device @ select
                // it puts 255 to CHREC to clear everything.
                dw      LIT, 255, R_TO              // [ decimal 255 ] Literal r>  
                dw      LIT, 13, PLUS, CSTORE       // [ decimal  13 ] Literal + c!    // CHREC of channel
                dw      EXIT
    ;
    
// ______________________________________________________________________ 

// MGT DISCiPLE option

//  ______________________________________________________________________ 
//

// .( RSAD )
// call DISCiPLE 44h hook code (RDAD)
// somehow, it needs a CAT 2 from Basic, first.
                New_Def RSAD, "RSAD", is_code, is_normal // CODE rsad ( a n -- )
                ld      a, 2                    // Drive number
                pop     hl                      // D=track E=sector
                ex      (sp), ix
                push    bc
                push    de
                ex      de, hl
                rst     08
                db      $44         // WSAD 
                pop     de
                pop     bc
                pop     ix
                next


// WSAD 
// call DISCiPLE 45h hook code (RDAD)
// somehow, it needs a CAT 2 from Basic, first.
                New_Def WSAD, "WSAD", is_code, is_normal // CODE wsad ( a n -- )
                ld      a, 2                    // Drive number
                pop     hl                      // D=track E=sector
                ex      (sp), ix
                push    bc
                push    de
                ex      de, hl
                rst     08
                db      $45     // WSAD 
                pop     de
                pop     bc
                pop     ix
                next


// MGTSTS )
// convert block number into side-track-sector.
                Colon_Def MGTSTS, "MGTSTS", is_normal // : mgtsts ( n -- side-track-sector )
                dw      LIT, 40, PLUS           // [ decimal 40 ] Literal      +
                dw      LIT, 10, DIVMOD         // [ decimal 10 ] Literal      /mod
                dw      DUP                     // dup
                dw      LIT, 80                 // [ decimal 80 ] Literal      < 0= 
                dw      LESS, ZEQUAL            
                dw      ZBRANCH
                dw      MGTSTS_Endif - $        // If 
                dw      LIT, 48, PLUS           // [ decimal 48 ] Literal  +
MGTSTS_Endif:                                   // Endif
                dw      LIT, 256                //[ decimal 256 ] Literal     * + 1+ 
                dw      MUL, PLUS, ONE_PLUS
                dw      EXIT
    ;


// MGTRD )
// MGT DISCiPLE read sector to address
                Colon_Def MGTRD, "MGTRD", is_normal  // : mgtrd ( a n -- )
                dw      MGTSTS, RSAD
                dw      EXIT
    
     
// MGTWR 
// MGT DISCiPLE write sector from address
                Colon_Def MGTWR, "MGTWR", is_normal  // : mgtwr ( a n -- )
                dw      MGTSTS, WSAD 
                dw      EXIT

// ______________________________________________________________________ 

// 7946h    
//  number of blocks available
                Constant_Def NSEC       ,   "#SEC"     ,   1778   // MDR
//              Constant_Def NSEC       ,   "#SEC"     ,   1560   // Disciple

// ______________________________________________________________________ 

