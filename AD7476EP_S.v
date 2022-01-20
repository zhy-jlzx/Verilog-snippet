//===========================================================================
// Copyright(c) 2019 Purple Mountain Obvservatory. All rights reserved
// Department:      Key Laboratory of Dark Mater & Space Astronomy
// Designer:        Zhang Yan
//---------------------------------------------------------------------------
// Project:         Asteroids
// Device:          AD7476 (12-bit 1MHz SPS ADC from Analog Devices, Inc. )
// DataSheet:       https://www.analog.com/media/en/technical-documentation/data-sheets/AD7476_7477_7478.pdf
// Module Name:     AD7476EP_S
// Description:     This module generate control signal of ADC
// Version:         1.2
//---------------------------------------------------------------------------
// Parameters:
//---------------------------------------------------------------------------
// REUSE ISSUES
// Reset Strategy:  Asynchronous, Active High Reset
// Clock Domains:   Single Clock Positive Edge 25MHz
// Instantiations:
// Synthesizable:   Yes
//---------------------------------------------------------------------------
// REVISE HISTORY
// 2019-01-07       Zhang Yan       File Created
// 2019-08-11       Zhang Yan       Updata file for verification module
// 2020-10-10       Zhang Yan       Modify file for high clock frequency
//===========================================================================
module AD7476EP_S(
    input           clk,            //module clock at 25 MHz
    input           rst,            //module reset
    input           sda,            //adc serial input
    output reg      scs,            //adc chip select
    output reg      sck,            //adc serial clock at input clk / 4
    output[11:0]    dout,           //adc value
    output reg      fin             //module finish
);

    //FSM cstate parameter
    parameter[2:0]  IDLE = 3'd0,
                    ST01 = 3'd1,
                    ST02 = 3'd2,
                    ST03 = 3'd3,
                    ST04 = 3'd4,
                    ST05 = 3'd5,
                    ST06 = 3'd6,
                    ST07 = 3'd7;

    //FSM register current-state & next-state
    (* syn_encoding = "onehot,safe" *)reg[2:0]        cstate, nstate;

    //Registers for shift register & counter
    reg             sreg_ena_r, sreg_ena_c, cnt_ena_r, cnt_ena_c;

    //Registers for SPI output
    reg             scs_c, sck_c, fin_c;

    //wires for counter
    wire[3:0]       cnt_val;
    wire            cnt_wire;

    //shift register for adc value
    SREG_12BIT_ESP  SREG_1(
        .Clock(clk),
        .Aclr(rst),
        .Shiften(sreg_ena_r),
        .Shiftin(sda),
        .Q(dout)
    );

    //counter for bit number
    CNT_4BIT_ACE    CNT_1(
        .Clock(clk),
        .Aclr(rst),
        .Enable(cnt_ena_r),
        .Q(cnt_val)
    );

    //comparator for bit number
    CMP_4BIT_15     CMP1(
        .DataA(cnt_val),
        .AEB(cnt_wire)
    );

    //always block for update current state
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cstate <= IDLE;
            sreg_ena_r <= 1'b0;
            cnt_ena_r <= 1'b0;
            scs <= 1'b1;
            sck <= 1'b1;
            fin <= 1'b0;
        end
        else begin
            cstate <= nstate;
            sreg_ena_r <= sreg_ena_c;
            cnt_ena_r <= cnt_ena_c;
            scs <= scs_c;
            sck <= sck_c;
            fin <= fin_c;
        end
    end

    //always block for combination logic
    always @* begin
        case(cstate)
            //state IDLE set scs to 0 at ST01
            //unconditional convert to ST01
            IDLE: begin
                nstate = ST01;
                sreg_ena_c = 1'b0;
                cnt_ena_c = 1'b0;
                scs_c = 1'b0;
                sck_c = 1'b1;
                fin_c = 1'b0;
            end
            //state ST01 set sck to 0 at ST02
            //state ST01 set cnt_ena to 1 at ST02
            //unconditional convert to ST02
            ST01: begin
                nstate = ST02;
                sreg_ena_c = 1'b0;
                cnt_ena_c = 1'b1;
                scs_c = 1'b0;
                sck_c = 1'b0;
                fin_c = 1'b0;
            end
            //state ST02 set cnt_ena to 0 at ST03
            //unconditional convert to ST03
            ST02: begin
                nstate = ST03;
                sreg_ena_c = 1'b0;
                cnt_ena_c = 1'b0;
                scs_c = 1'b0;
                sck_c = 1'b0;
                fin_c = 1'b0;
            end
            //state ST03 set sreg_ena to 1 at ST04
            //state ST03 set sck to 1 at ST04
            //unconditional convert to ST04
            ST03: begin
                nstate = ST04;
                sreg_ena_c = 1'b1;
                cnt_ena_c = 1'b0;
                scs_c = 1'b0;
                sck_c = 1'b1;
                fin_c = 1'b0;
            end
            //state ST04 set sreg_ena to 0 at ST05
            //unconditional convert to ST05
            ST04: begin
                nstate = ST05;
                scs_c = 1'b0;
                sck_c = 1'b1;
                fin_c = 1'b0;
                sreg_ena_c = 1'b0;
                cnt_ena_c = 1'b0;
            end
            //state ST05 set cnt_ena to 1 at ST02
            //state ST05 set sck to 0 at ST02
            //if cnt_wire convert to ST06, else to ST02
            ST05: begin
                if(cnt_wire) nstate = ST06;
                else nstate = ST02;
                scs_c = 1'b0;
                sck_c = 1'b0;
                fin_c = 1'b0;
                sreg_ena_c = 1'b0;
                cnt_ena_c = 1'b1;
            end
            //state ST06 set scs and sck to 1 at ST07
            //if cnt_wire stay in ST06 else to ST07
            ST06: begin
                if(cnt_wire) begin
                    nstate = ST06;
                    scs_c = 1'b0;
                    sck_c = 1'b0;
                end
                else begin
                    nstate = ST07;
                    scs_c = 1'b1;
                    sck_c = 1'b1;
                end
                fin_c = 1'b0;
                sreg_ena_c = 1'b0;
                cnt_ena_c = 1'b0;
            end
            //state 07 set fin signal to 1;
            //stay ST07 until next reset
            ST07: begin
                nstate = ST07;
                sreg_ena_c = 1'b0;
                cnt_ena_c = 1'b0;
                scs_c = 1'b1;
                sck_c = 1'b1;
                fin_c = 1'b1;
            end
            //default state to avoid dead lock
            default: begin
                nstate = ST07;
                sreg_ena_c = 1'b0;
                cnt_ena_c = 1'b0;
                scs_c = 1'b1;
                sck_c = 1'b1;
                fin_c = 1'b0;
            end
        endcase
    end

endmodule