//  ______________________________________________________________________ 
//
//  L3.asm
// 
//  Continuation of L2.asm
//  I/O Block definitions
//  ______________________________________________________________________ 


//  ______________________________________________________________________ 
//
// r/w          a n f --
// read/write block n depending on flag f, true-flag means read, false-flag means write.
                Colon_Def READ_WRITE, "R/W", is_normal
                dw      TO_R                    // >r    
                dw      ONE_SUBTRACT            // 1-
                dw      DUP, ZLESS              // dup 0<
                dw      OVER, NSEC              // over #sec
                dw      ONE_SUBTRACT, GREATER   // 1- >
                dw      OR_OP                   // or
                dw      LIT, 6, QERROR          // 6 ?error
                dw      R_TO                    // r>
                                                // if
                dw      ZBRANCH
                dw      Read_Write_Else - $           
                dw          MGT, FETCH
                dw          ONE, AND_OP
                dw          ZBRANCH
                dw          Read_Write_Else_1 - $           

                dw              MGTRD
                dw          BRANCH
                dw          Read_Write_Endif_1 - $
Read_Write_Else_1:                              //    else                                                     
                dw              MDRRD
Read_Write_Endif_1:                             //    endif

                dw      BRANCH
                dw      Read_Write_Endif - $
Read_Write_Else:                                // else                                                     
                dw          MGT, FETCH
                dw          ONE, AND_OP
                dw          ZBRANCH
                dw          Read_Write_Else_2 - $           

                dw              MGTWR
                dw          BRANCH
                dw          Read_Write_Endif_2 - $
Read_Write_Else_2:                              //    else                                                     
                dw              MDRWR
Read_Write_Endif_2:                             //    endif

Read_Write_Endif:                               // endif
                dw      EXIT                    // ;


//  ______________________________________________________________________ 
//
// +buf        a1 -- a2 f
// advences to next buffer, cyclically rotating along them
                Colon_Def PBUF, "+BUF", is_normal
                dw      LIT, 516, PLUS          // 516 +
                dw      DUP, LIMIT, FETCH       // dup limit @
                dw      EQUALS                  // =
                                                // if
                dw      ZBRANCH
                dw      PBuf_Endif - $
                dw          DROP                //      drop
                dw          FIRST, FETCH        //      first @    
PBuf_Endif:                                     // endif
                dw      DUP, PREV, FETCH        // dup prev @                    
                dw      SUBTRACT                // -
                dw      EXIT                    // ;

//  ______________________________________________________________________ 
//
// update       --
// mark the last used block to be written to disk
                Colon_Def UPDATE, "UPDATE", is_normal
                dw      PREV, FETCH, FETCH      // prev @ @
                dw      LIT, $8000, OR_OP       // $8000, or
                dw      PREV, FETCH, STORE      // prev @ !
                dw      EXIT                    // ;


//  ______________________________________________________________________ 
//
// empty-buffers --
                Colon_Def EMPTY_BUFFERS, "EMPTY-BUFFERS", is_normal
                dw      FIRST, FETCH            // first @
                dw      LIMIT, FETCH            // limit @
                dw      OVER, SUBTRACT, ERASE   // over - erase
                dw      EXIT                    // ;

//  ______________________________________________________________________ 
//
// buffer       n -- a
// read block n and gives the address to a buffer 
// any block previously inside the buffer, if modified, is rewritten to
// disk before reading the block n.

                Colon_Def BUFFER, "BUFFER", is_normal
                dw      USE, FETCH              // use @
                dw      DUP, TO_R               // dup >r
                                                // begin
Buffer_Begin:                                                
                dw          PBUF                //      +buf
                                                // until
                dw      ZBRANCH
                dw      Buffer_Begin - $
                dw      USE, STORE              // use !
                dw      R_OP, FETCH, ZLESS      // r @ 0<
                                                // if
                dw      ZBRANCH
                dw      Buffer_Endif - $
                dw          R_OP, CELL_PLUS     //      r cell+
                dw          R_OP, FETCH         //      r fetch
                dw          LIT, $7FFF          //      7FFF
                dw          AND_OP              //      and
                dw          ZERO, READ_WRITE    //      0 r/w
Buffer_Endif:                                   // endif
                dw      R_OP, STORE             // r !
                dw      R_OP, PREV, STORE       // r prev !
                dw      R_TO, CELL_PLUS         // r> cell+
                dw      EXIT                    // ;

//  ______________________________________________________________________ 
//
// block        n -- a
// Leaves the buffer address that contains the block n. 
// If the block is not already present, it will be loaded from disk
// The block previously inside the buffer, if modified, is rewritten to
// disk before reading the block n.
// See also BUFFER, R/W, UPDATE, FLUSH.

                Colon_Def BLOCK, "BLOCK", is_normal
                dw      OFFSET, FETCH           // offset @
                dw      PLUS, TO_R              // + >r
                dw      PREV, FETCH             // prev @
                dw      DUP, FETCH              // dup @
                dw      R_OP, SUBTRACT          // r -
                dw      DUP, PLUS               // dup +  ( trick: check equality without most significant bit )
                                                // if
                dw        ZBRANCH
                dw        Block_Endif_1 - $
Block_Begin:                                    //      begin
                dw          PBUF, ZEQUAL        //          +buf 0
                                                //          if
                dw          ZBRANCH
                dw          Block_Endif_2 - $
                dw              DROP            //              drop
                dw              R_OP, BUFFER    //              r buffer
                dw              DUP             //              dup
                dw              R_OP, ONE       //              r 1
                dw              READ_WRITE      //              r/w
                dw              TWO_MINUS       //              2-
Block_Endif_2:                                  //          endif
                dw          DUP, FETCH, R_OP    //          dup @ r
                dw          SUBTRACT, DUP       //          - dup
                dw          PLUS, ZEQUAL        //          + 0=
                                                //      until
                dw        ZBRANCH
                dw        Block_Begin - $
                dw        DUP, PREV, STORE      //      dup prev !
Block_Endif_1:                                  // endif
                dw      R_TO, DROP, CELL_PLUS   // r> drop cell+
                dw      EXIT                    // ;
              
//  ______________________________________________________________________ 
//
// #buff        -- n
// number of buffers available. must be the difference between LIMIT and FIRST divided by 516
                Constant_Def NBUFF,   "#BUFF", (LIMIT_system-FIRST_system)/516

//  ______________________________________________________________________ 
//
// flush        --
                Colon_Def FLUSH, "FLUSH", is_normal
                dw      NBUFF, ONE_PLUS, ZERO   // #buff 1+ 0   
Flush_Do:                                       // do
                dw      C_DO
                dw      ZERO, BUFFER, DROP      //      0 buffer drop
                                                // loop
                dw      C_LOOP, Flush_Do - $
//              dw      BLK_FH, FETCH           // blk-fh @     ( ZX-Next dependance )    
//              dw      F_SYNC, DROP            // f_sync drop
                dw      EXIT                    // exit


//  ______________________________________________________________________ 
//
// load+        n --
                Colon_Def LOAD_P, "LOAD+", is_normal
                dw      BLK, FETCH, TO_R        // blk @ >r
                dw      TO_IN, FETCH, TO_R      // >in @ >r

                dw      ZERO, TO_IN, STORE      // 0 >in !
                dw      BSCR, MUL, BLK, STORE   // b/scr * blk !
                dw      INTERPRET               // interpret

                dw      R_TO, TO_IN, STORE      // r> >in !
                dw      R_TO, BLK, STORE        // r> blk !
                dw      EXIT                    // ;

//  ______________________________________________________________________ 
//
// -->          --
                Colon_Def LOAD_NEXT, "-->", is_immediate
                dw      QLOADING                // ?loading
                dw      ZERO, TO_IN, STORE      // 0 >in !
                dw      BSCR                    // b/scr
                dw      BLK, FETCH              // blk @
                dw      OVER                    // over
                dw      MOD                     // mod
                dw      SUBTRACT                // -
                dw      BLK, PLUSSTORE          // +!
                dw      EXIT                    // ;

//  ______________________________________________________________________ 
//
// '            -- xt
                Colon_Def TICK, "'", is_normal
                dw      LFIND                   // -find
                dw      ZEQUAL                  // 0=
                dw      ZERO, QERROR            // 0 ?error
                dw      DROP                    // drop
                dw      EXIT                    // ;

//  ______________________________________________________________________ 
//
// forget       -- cccc
                Colon_Def FORGET, "FORGET", is_normal
                dw      CURRENT, FETCH          // current @
                dw      CONTEXT, FETCH          // context @
                dw      SUBTRACT, LIT, 23, QERROR // - 23 ?error
                dw      TICK, TO_BODY           // ' >body
                dw      DUP, FENCE, FETCH       // dup fence @ 
                dw      ULESS, LIT, 21, QERROR  // u< 21 ?error
                dw      DUP, NFA, DP, STORE     // dup nfa dp !
                dw      LFA, FETCH              // lfa @
                dw      CONTEXT, FETCH, STORE   // context @ !
                dw      EXIT                    // ;

//  ______________________________________________________________________ 
//
// marker       -- cccc
                Colon_Def MARKER, "MARKER", is_immediate
                dw      CBUILDS
                dw      VOC_LINK, FETCH, COMMA
                dw      CURRENT, FETCH, COMMA
                dw      CONTEXT, FETCH, COMMA
                dw      LATEST, COMMA
                dw      LATEST, PFA, LFA, FETCH, COMMA
                dw      DOES_TO
                dw      DUP, FETCH, VOC_LINK, STORE, CELL_PLUS
                dw      DUP, FETCH, CURRENT, STORE, CELL_PLUS
                dw      DUP, FETCH, CONTEXT, STORE, CELL_PLUS
                dw      DUP, FETCH, DP, STORE, CELL_PLUS
                dw           FETCH, CURRENT, FETCH, STORE
                dw      EXIT

//  ______________________________________________________________________ 
//
// spaces       n --
                Colon_Def SPACES, "SPACES", is_normal
                dw      ZERO, MAX
                dw      ZERO, C_Q_DO
                dw      Spaces_Leave - $
Spaces_Loop:                
                dw          SPACE
                dw      C_LOOP
                dw      Spaces_Loop - $
Spaces_Leave:                
                dw      EXIT                    // ;

//  ______________________________________________________________________ 
//
// <#           --
                Colon_Def BEGIN_DASH, "<#", is_normal
                dw      PAD, HLD, STORE
                dw      EXIT

//  ______________________________________________________________________ 
//
// #>           --
                Colon_Def DASH_END, "#>", is_normal
                dw      TWO_DROP
                dw      HLD, FETCH, PAD, OVER, SUBTRACT
                dw      EXIT

//  ______________________________________________________________________ 
//
// sign         n d -- d
                Colon_Def SIGN, "SIGN", is_normal
                dw      ZLESS
                dw      ZBRANCH
                dw      Sign_Endif - $
                dw          LIT, 45, HOLD
Sign_Endif:     
                dw      EXIT

//  ______________________________________________________________________ 
//
// #           d1 -- d2
                Colon_Def DASH, "#", is_normal
                dw      BASE, FETCH

                dw      TO_R                    // >r           ( ud1 )
                dw      ZERO, R_OP, UMDIVMOD    // 0 r um/mod   ( l rem1 h/r )            
                dw      R_TO, SWAP, TO_R        // r> swap >r   ( l rem )
                dw      UMDIVMOD                // um/mod       ( rem2 l/r )
                dw      R_TO                    // r>           ( rem2 l/r h/r )

                dw      ROT
                dw      LIT, 9, OVER, LESS
                dw      ZBRANCH
                dw      Dash_Endif - $
                dw          LIT, 7, PLUS
Dash_Endif:     

                dw      LIT, 48, PLUS, HOLD
                dw      EXIT

//  ______________________________________________________________________ 
//
// #s           d1 -- d2
                Colon_Def DASHES, "#S", is_normal
Dashes_Begin:                   
                dw      DASH, TWO_DUP
                dw          OR_OP, ZEQUAL
                dw      ZBRANCH
                dw      Dashes_Begin - $
                dw      EXIT

//  ______________________________________________________________________ 
//
// d.r          d n --
                Colon_Def D_DOT_R, "D.R", is_normal
                dw      TO_R
                dw      TUCK, DABS
                dw      BEGIN_DASH, DASHES, ROT, SIGN, DASH_END
                dw      R_TO
                dw      OVER, SUBTRACT, SPACES, TYPE
                dw      EXIT

//  ______________________________________________________________________ 
//
// .r           n1 n2 --
                Colon_Def DOT_R, ".R", is_normal
                dw      TO_R
                dw      S_TO_D, R_TO
                dw      D_DOT_R
                dw      EXIT

//  ______________________________________________________________________ 
//
// d.           d --
                Colon_Def D_DOT, "D.", is_normal
                dw      ZERO, D_DOT_R, SPACE
                dw      EXIT

//  ______________________________________________________________________ 
//
// .            n --
                Colon_Def DOT, ".", is_normal
                dw      S_TO_D, D_DOT
                dw      EXIT

//  ______________________________________________________________________ 
//
// ?            n --
                Colon_Def QUESTION, "?", is_normal
                dw      FETCH, DOT
                dw      EXIT

//  ______________________________________________________________________ 
//
// u.           u --
                Colon_Def U_DOT, "U.", is_normal
                dw      ZERO, D_DOT
                dw      EXIT

//  ______________________________________________________________________ 
//
// words        --
                Colon_Def WORDS, "WORDS", is_normal
                dw      LIT, 128, OUT, STORE
                dw      CONTEXT, FETCH, FETCH
Words_Begin:        
                dw          DUP, CFETCH, LIT, $1F, AND_OP
                dw          OUT, FETCH, PLUS
                dw          CL, LESS, ZEQUAL
                dw          ZBRANCH
                dw          Words_Endif - $
                dw              CR, ZERO, OUT, STORE
Words_Endif:    
                dw          DUP, ID_DOT
                dw          PFA, LFA, FETCH
                dw          DUP, ZEQUAL
                dw          QTERMINAL, OR_OP
                dw      ZBRANCH
                dw      Words_Begin - $
                dw      DROP
                dw      EXIT

//  ______________________________________________________________________ 
//
// list         n --
                Colon_Def LIST, "LIST", is_normal
                dw      DECIMAL, CR
                dw      DUP, SCR, STORE
                dw      C_DOT_QUOTE
                db      5, "Scr# "
                dw      DOT
                dw      LSCR, ZERO, C_DO
List_Loop:
                dw          CR
                dw          I, THREE
                dw          DOT_R, SPACE
                dw          I, SCR, FETCH, DOT_LINE
                dw          QTERMINAL
                dw          ZBRANCH
                dw          List_Endif - $
                dw              C_LEAVE
                dw              List_Leave - $
List_Endif:
                dw      C_LOOP
                dw      List_Loop - $     
List_Leave:
                dw      CR           
                dw      EXIT

//  ______________________________________________________________________ 
//
// index        n1 n2 --
                Colon_Def INDEX, "INDEX", is_normal
                dw      ONE_PLUS, SWAP, C_DO
Index_Loop:                
                dw          CR, I, THREE
                dw          DOT_R, SPACE
                dw          ZERO, I, DOT_LINE
                dw          QTERMINAL
                dw          ZBRANCH
                dw          Index_Endif - $
                dw              C_LEAVE
                dw              Index_Leave - $
Index_Endif:
                dw      C_LOOP
                dw      Index_Loop - $
Index_Leave:
                dw      CR
                dw      EXIT

//  ______________________________________________________________________ 
//
// cls          --
                New_Def CLS, "CLS", is_code, is_normal
                push    bc
                push    de
                push    ix
                call    $0DAF 
                pop     ix
                pop     de
                pop     bc
                next


//  ______________________________________________________________________ 
//
// splash       --
                Colon_Def SPLASH, "SPLASH", is_normal
                dw      CLS
                dw      C_DOT_QUOTE
                db      68
                db      "v-Forth 1.6 MDR/MGT version", 13
                db      "build 20240420", 13
                db      "1990-2024 Matteo Vitturi", 13
                dw      EXIT

//  ______________________________________________________________________ 
//
// video        --
                Colon_Def VIDEO, "VIDEO", is_normal
                dw      TWO, DUP, DEVICE, STORE
                dw      SELECT
                dw      EXIT

//  ______________________________________________________________________ 
//
// accept-      a n1 -- n2
                Colon_Def ACCEPT_N, "ACCEPT-", is_normal
                dw      TO_R
                dw      ZERO
                dw      SWAP
                dw      DUP
                dw      R_TO
                dw      PLUS
                dw      SWAP
                dw      C_DO
AcceptN_Loop:    
//              dw          MMU7_FETCH
                dw          INKEY
//              dw          SWAP, MMU7_STORE
                dw          DUP, ZEQUAL
                dw          ZBRANCH
                dw          AcceptN_Endif_1 - $
//              dw              VIDEO, QUIT
                dw                  C_LEAVE     //              leave       
                dw                  AcceptN_Leave - $

AcceptN_Endif_1:   
                dw          DUP, LIT, 13, EQUALS 
                dw          ZBRANCH
                dw          AcceptN_Endif_2 - $
                dw              DROP, ZERO
AcceptN_Endif_2:
                dw          DUP, LIT, 10, EQUALS 
                dw          ZBRANCH
                dw          AcceptN_Endif_3 - $
                dw              DROP, ZERO
AcceptN_Endif_3:
                dw          I, CSTORE, ONE_PLUS

                dw          I, CFETCH, ZEQUAL   //      i 0= if
                dw          ZBRANCH
                dw              AcceptN_Endif_4 - $ 
                dw                  C_LEAVE     //              leave       
                dw                  AcceptN_Leave - $
AcceptN_Endif_4:                                 //      endif

                dw      C_LOOP
                dw      AcceptN_Loop -$ 
AcceptN_Leave:
                dw      EXIT

//  ______________________________________________________________________ 
//
// load-        n --
// Provided that a stream n is OPEN# via the standart BASIC 
// it accepts text from stream #n to the normal INTERPRET 
// up to now, text-file must end with QUIT 
                Colon_Def LOAD_N, "LOAD-", is_normal
                dw      SOURCE_ID, STORE
Load_N_Begin:                
                dw          TIB, FETCH
                dw          DUP, LIT, 80
                dw          TWO_DUP, BLANK
                dw          SOURCE_ID, FETCH
                dw          ABS_OP, DUP, DEVICE, STORE
                dw          SELECT
                dw          ACCEPT_N
                dw          VIDEO
                dw          TWO_DROP
                dw          ZERO, BLK, STORE
                dw          ZERO, TO_IN, STORE
                dw          INTERPRET
                dw          QTERMINAL
                dw      ZBRANCH
                dw      Load_N_Begin - $
                dw      EXIT

//  ______________________________________________________________________ 
//
// load         n --
// if n is positive, it loads screen #n (as usual)
// if n is negative, it connects stream #n to the normal INTERPRET 
// this second way is useful if you want to load any kind of file
// provied that it is OPEN# the usual BASIC way.
                Colon_Def LOAD, "LOAD", is_normal
                dw      DUP, ZLESS
                dw      ZBRANCH
                dw      Load_Else - $
                dw          LOAD_N
                dw      BRANCH
                dw      Load_Endif - $
Load_Else:      
                dw          LOAD_P                
Load_Endif: 
                dw      EXIT


//  ______________________________________________________________________ 
//
// autoexec     --
// this word is called the first time the Forth system boot to
// load Screen# 1. Once called it patches itself to prevent furhter runs.
                Colon_Def AUTOEXEC, "AUTOEXEC", is_normal
                dw      LIT, 11
                dw      LIT, NOOP
                dw      LIT, Autoexec_Ptr
                dw      STORE
                dw      LOAD
                dw      QUIT
                dw      EXIT
                

//  ______________________________________________________________________ 
//
// bye     --
//
                Colon_Def BYE, "BYE", is_normal
                dw      FLUSH
                dw      EMPTY_BUFFERS
//              dw      BLK_FH, FETCH, F_CLOSE, DROP
                dw      ZERO, PLUS_ORIGIN
                dw      BASIC
                
//  ______________________________________________________________________ 
//
// invv     --
//
                Colon_Def INVV, "INVV", is_normal
                dw      LIT, 20, EMITC, ONE, EMITC
                dw      EXIT

//  ______________________________________________________________________ 
//
// truv     --
//
                Colon_Def TRUV, "TRUV", is_normal
                dw      LIT, 20, EMITC, ZERO, EMITC
                dw      EXIT

//  ______________________________________________________________________ 
//
// mark     --
//
//              Colon_Def MARK, "MARK", is_normal
//              dw      INVV, TYPE, TRUV
//              dw      EXIT

//  ______________________________________________________________________ 
//
// back     --
//
                Colon_Def BACK, "BACK", is_normal
                dw      HERE, SUBTRACT, COMMA
                dw      EXIT

//  ______________________________________________________________________ 
//
// if          ( -- a 2 ) \ compile-time 
// IF ... THEN 
// IF ... ELSE ... THEN 
                Colon_Def IF, "IF", is_immediate
                dw      COMPILE, ZBRANCH
                dw      HERE, ZERO, COMMA
                dw      TWO
                dw      EXIT

//  ______________________________________________________________________ 
//
// then        ( a 2 -- ) \ compile-time
//
                Colon_Def THEN, "THEN", is_immediate
                dw      QCOMP
                dw      TWO, QPAIRS
                dw      HERE, OVER, SUBTRACT, SWAP, STORE
                dw      EXIT

//  ______________________________________________________________________ 
//
// endif        ( a 2 -- ) \ compile-time
//
                Colon_Def ENDIF, "ENDIF", is_immediate
                dw      THEN
                dw      EXIT

//  ______________________________________________________________________ 
//
// else        ( a1 2 -- a2 2 ) \ compile-time 
//
                Colon_Def ELSE, "ELSE", is_immediate
                dw      QCOMP
                dw      TWO, QPAIRS
                dw      COMPILE, BRANCH
                dw      HERE, ZERO, COMMA
                dw      SWAP, TWO, THEN
                dw      TWO
                dw      EXIT

//  ______________________________________________________________________ 
//
// begin        ( -- a 1 ) \ compile-time
// BEGIN ... AGAIN
// BEGIN ... f UNTIL
// BEGIN ... f WHILE ... REPEAT
                Colon_Def BEGIN, "BEGIN", is_immediate
                dw      QCOMP
                dw      HERE
                dw      ONE
                dw      EXIT

//  ______________________________________________________________________ 
//
// again        ( a 1 -- ) \ compile-time
                Colon_Def AGAIN, "AGAIN", is_immediate
                dw      QCOMP
                dw      ONE, QPAIRS
                dw      COMPILE, BRANCH
                dw      BACK
                dw      EXIT

//  ______________________________________________________________________ 
//
// until        ( a 1 -- ) \ compile-time
                Colon_Def UNTIL, "UNTIL", is_immediate
                dw      QCOMP
                dw      ONE, QPAIRS
                dw      COMPILE, ZBRANCH
                dw      BACK
                dw      EXIT

//  ______________________________________________________________________ 
//
// end          ( a 1 -- ) \ compile-time
                Colon_Def END, "END", is_immediate
                dw      UNTIL
                dw      EXIT

//  ______________________________________________________________________ 
//
// while        ( a1 1 -- a1 1 a2 4 ) \ compile-time
                Colon_Def WHILE, "WHILE", is_immediate
                dw      IF
                dw      TWO_PLUS // ( that is 4 )
                dw      EXIT

//  ______________________________________________________________________ 
//
// repeat       ( a1 1 a2 4 -- ) \ compile-time
                Colon_Def REPEAT, "REPEAT", is_immediate
                dw      TWO_SWAP
                dw      AGAIN
                dw      TWO, SUBTRACT
                dw      THEN
                dw      EXIT

//  ______________________________________________________________________ 
//
// ?do-
// special version of "BACK" used by ?DO and LOOP
                Colon_Def C_DO_BACK, "?DO-", is_normal
                dw      BACK
CDoBack_Begin:                
                dw      SPFETCH, CSP, FETCH
                dw      SUBTRACT
                dw      ZBRANCH
                dw      CDoBack_While - $
                dw          TWO_PLUS, THEN
                dw      BRANCH
                dw      CDoBack_Begin - $
CDoBack_While:  
                dw      QCSP, CSP, STORE
                dw      EXIT

//  ______________________________________________________________________ 
//
// do
// DO  ... LOOP
// DO  ... n +LOOP
// ?DO ... LOOP
// ?DO ... n +LOOP
                Colon_Def DO, "DO", is_immediate
                dw      COMPILE, C_DO
                dw      CSP, FETCH, STORE_CSP
                dw      HERE, THREE
                dw      EXIT

//  ______________________________________________________________________ 
//
// loop
                Colon_Def LOOP, "LOOP", is_immediate
                dw      THREE, QPAIRS
                dw      COMPILE, C_LOOP
                dw      C_DO_BACK
                dw      EXIT

//  ______________________________________________________________________ 
//
// +loop
                Colon_Def PLOOP, "+LOOP", is_immediate
                dw      THREE, QPAIRS
                dw      COMPILE, C_PLOOP
                dw      C_DO_BACK
                dw      EXIT

//  ______________________________________________________________________ 
//
// ?do
                Colon_Def QDO, "?DO", is_immediate
                dw      COMPILE, C_Q_DO
                dw      CSP, FETCH, STORE_CSP
                dw      HERE, ZERO, COMMA, ZERO
                dw      HERE, THREE
                dw      EXIT


//  ______________________________________________________________________ 
//
// RENAME 
// special utility to rename a word to another name but same length
                Colon_Def RENAME, "RENAME", is_normal  // : rename  ( -- "ccc" "ddd" )
                dw TICK, TO_BODY, NFA           // ' >body nfa
                dw DUP, CFETCH
                dw LIT, $1F, AND_OP             // dup c@  [ hex 1F ] Literal  and
                dw TWO_DUP, PLUS                // 2dup + 
                dw TO_R                         // >r
                //      bl word here  [ hex 20 ] Literal  allot
                dw BL, WORD                     // bl word 
                dw LIT, 32, ALLOT               //  [ hex 20 ] Literal  allot
                dw COUNT, LIT, $1F              // count  [ hex 1F ] Literal 
                dw AND_OP, ROT, MIN             // and rot min
                dw TO_R                         // >r 
                dw SWAP, ONE_PLUS               // swap 1+
                dw R_TO                         // r>
                dw CMOVE                        // cmove
                dw R_OP, CFETCH                 // r  c@  
                dw LIT, 128, OR_OP              // [ hex 80 ] Literal  or
                dw R_TO                         // r>      
                dw CSTORE                       // c!
                dw LIT, -32, ALLOT              // [ hex -20 ] Literal allot
                dw EXIT


//  ______________________________________________________________________ 
//
//  VALUE 
                Colon_Def VALUE, "VALUE", is_immediate  // : value ( n ccc --   ) (       -- n )
                dw CONSTANT                 // [compile] constant
                dw EXIT
                // ;
                // immediate 


//  ______________________________________________________________________ 
//
//  (TO)
                Colon_Def CTO, "(TO)", is_normal  
                dw TICK, TO_BODY            // ' >body
                dw STATE, FETCH             // state @
                dw ZBRANCH                  // If
                dw          To_1 - $
                dw      COMPILE, LIT        // compile lit 
                dw      COMMA               // , 
                dw      COMMA               // , 

                dw              BRANCH      // Else
                dw         To_2 - $
To_1:
                dw      SWAP, EXECUTE       //  swap execute
To_2:
                                            // Endif
                dw EXIT
//  ______________________________________________________________________ 
//
//  TO )
                Colon_Def TO, "TO", is_immediate  // : to ( n -- cccc )
                dw LIT, STORE
                dw CTO 
                dw EXIT


Latest_Definition:
//  ______________________________________________________________________ 
//
// \
                Colon_Def BACKSLASH, "\\", is_immediate  // this is a single back-slash
                dw      BLK, FETCH
                dw      ZBRANCH
                dw      Backslash_Else_1 - $
//              dw          BLK, FETCH, ONE, GREATER  // BLOCK 1 is used as temp-line in INCLUDE file
//              dw          ZBRANCH
//              dw          Backslash_Else_2 - $
                dw              TO_IN, FETCH, CL, MOD, CL
                dw              SWAP, SUBTRACT, TO_IN, PLUSSTORE
//              dw          BRANCH
//              dw          Backslash_Endif_2 - $
// Backslash_Else_2:
//              dw              BBUF, CELL_MINUS, TO_IN, STORE
// Backslash_Endif_2:
                dw      BRANCH
                dw      Backslash_Endif_1 - $
Backslash_Else_1:
                dw          ZERO
                dw          TIB, FETCH
                dw          TO_IN, FETCH
                dw          PLUS, STORE
Backslash_Endif_1:
                dw      EXIT
Fence_Word:

//  ______________________________________________________________________ 
//

Here_Dictionary db      0

