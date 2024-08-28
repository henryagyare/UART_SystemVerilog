`timescale 1ns / 1ps

package uart2_pkgs;
    typedef enum logic [1:0] 
    { 
        IDLE_STATE,
        START_STATE,
        MOVE_DATA_STATE,
        STOP_STATE        
    } state_encoding;
endpackage

package fsm_pkgs;
    typedef enum logic [1:0] 
    {  
        IDLE_STATE,
        COLLECT_STATE,
        OUTPUT_STATE
    } fsm_8to64_state_encoding;

    typedef enum logic [1:0] 
    {  
        IDLE,
        MOVE,
        DONE
    } fsm_64to8_state_encoding;

endpackage

