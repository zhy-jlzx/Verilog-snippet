`timescale 1ns / 1ps
//===========================================================================
//  Copyright(c) 2022 Purple Mountain Obvservatory. All rights reserved
//  Department:         Key Laboratory of Dark Mater & Space Astronomy
//  Designer:           Zhang Yan
//---------------------------------------------------------------------------
//  Project:            *****************************************
//  Device:             *****************************************
//  Module Name:        CNT_ASCE
//  Description:        Counter with Asynchronous Reset, Synchronous Reset and Enable
//  Version:            1.0
//---------------------------------------------------------------------------
//  Parameters
//  Name                Range           Descriptioin
//  WIDTH               [2,32]          width of the shift register
//---------------------------------------------------------------------------
//  REUSE ISSUES
//  Reset Strategy:     Asynchronous, Active High Reset; Synchronous Active High Reset
//  Clock Domains:      Single Clock Positive Edge
//  Instantiations:     None
//  Synthesizable:      Yes
//---------------------------------------------------------------------------
//  REVISE HISTORY
//  2022-09-27          Zhang Yan       File Created
//  
//===========================================================================
module CNT_ASCE
    #(parameter         WIDTH = 4)
    (
    input               clk,            //module clock
    input               rst,            //module reset high active
    input               srst,           //module synchronous reset
    input               ena,            //counter enable high active
    output[WIDTH-1:0]   dout            //counter data
    );


    reg[WIDTH-1:0]      registers;
    assign              dout = registers;

    always @(posedge clk or posedge rst) begin
        if (rst == 1'b1) registers <= 0;
        else begin
            if (srst == 1'b1) registers <= 0;
            else begin
                if (ena==1'b1) registers <= registers + 1'b1;
                else registers <= registers;
            end
        end
    end

endmodule
