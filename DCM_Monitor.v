`timescale 1ns / 1ps
//===========================================================================
//  Copyright(c) 2022 Purple Mountain Obvservatory. All rights reserved
//  Department:         Key Laboratory of Dark Mater & Space Astronomy
//  Designer:           Zhang Yan
//---------------------------------------------------------------------------
//  Project:            *****************************************
//  Device:             *****************************************
//  Module Name:        DCM_Monitor
//  Description:        Monitor the DCM status and send reset signal
//  Version:            1.0
//---------------------------------------------------------------------------
//  Parameters
//---------------------------------------------------------------------------
//  REUSE ISSUES
//  Reset Strategy:     Asynchronous, Active High Reset
//  Clock Domains:      Single Clock Positive Edge from External Oscillator
//  Instantiations:     None
//  Synthesizable:      Yes
//---------------------------------------------------------------------------
//  REVISE HISTORY
//  2022-09-26          Zhang Yan       File Created
//  
//===========================================================================
module DCM_Monitor(
    input               clk,            //original clock from external oscillator
    input               dcm_lock,       //active high signal from DCM lock
    input               dcm_sta2,       //active high signal from DCM FX output stop
    output              dcm_rst         //active high output for DCM reset
    );

    //module reset
    //when dcm_lock == 1 and dcm_sta2 == 0 module stop
    wire                rst;
    assign              rst = dcm_lock & ~dcm_sta2;
    
    //counter for 40us delay
    //counter 01 7bit generate 2us pulse from 50Mhz clk
    //counter 02 5bit generate 40us pulse from counter 01 pulse
    wire                cnt01_srst, cnt02_srst;
    wire[4:0]           cnt02_val;
    wire[6:0]           cnt01_val;
    assign              cnt01_srst = (cnt01_val == 7'd99) ? 1'b1 : 1'b0;
    assign              cnt02_srst = (cnt02_val == 5'd20) ? 1'b1 : 1'b0;
    
    //shift register for dcm reset generate
    //register pulse is 00111111, reset length is 6
    reg[7:0]            sft_reg;
    assign              dcm_rst = sft_reg[7];


    always @(posedge clk or posedge rst) begin
        if(rst) sft_reg <= 8'h3f;
        else begin
            if(cnt02_srst) sft_reg <= 8'h3f;
            else sft_reg <= {sft_reg[6:0], 1'b0};
        end
    end


    CNT_ASCE #(.WIDTH(7))
    CNT_01(
        .clk(clk),
        .rst(rst),
        .srst(cnt01_srst),
        .ena(1'b1),
        .dout(cnt01_val)
    );


    CNT_ASCE #(.WIDTH(5))
    CNT_02(
        .clk(clk),
        .rst(rst),
        .srst(cnt02_srst),
        .ena(cnt01_srst),
        .dout(cnt02_val)
    );

endmodule
