`include "Params.h"

module Activation (
    input                       clk,    //Clock
    input                       rst,    //Reset (System)
    inout  [`DataWidth-1:0]     act1,   //Activation Port-1
    inout  [`DataWidth-1:0]     act2,   //Activation Port-2
    input                       rtm_en  //Retime Enable
    input   [3:0]               cfgdat  //Configuration Data
)；

    /* Reg                      */
    reg [`DataWidth-1:0]    PreAct; //Pre-Activation

    /* Wire                     */
    wire [`DataWidth-1:0]   act_i;  //Pre-Activation
    wire [`DataWidth-1:0]   PstAct; //Post-Activation

    //Configuration Data (4-bit)
    wire [1:0]              sel_i;  //Act-Func Source Selection
    wire                    sel_o1; //Output Enable-1
    wire                    sel_o2; //Output Enable-2


    /* Pre-Activation Select    */
    assign sel_i    = cfgdat[1:0];
    assign act_i    = (sel_i == 2'b00) ? 0 :
                      (sel_i == 2'b01) ? 0 :
                      (sel_i == 2'b10) ? act1 : act2;


    /* Retime Pre-Activation    */
    always @(posedge clk) begin
        if (rst) begin
            PreAct  <= 0;
        end
        else if (rtm_en) begin
            PreAct  <= act_i;
        end
    end


    /* Activation (ReLU)        */
    assign PstAct   = (PreAct[`DataWidth-1]) ? 0 : PreAct;


    /* Post-Activation Output   */
    assign sel_o1   = cfgdat[2];
    assign sel_o2   = cfgdat[3];
    assign act1     = (sel_o1) ? PstAct : z;
    assign act2     = (sel_o2) ? PstAct : z;

endmodule