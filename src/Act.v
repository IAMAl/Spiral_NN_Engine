`include "Params.h"

module Activation (
    input                   clk,    //Clock
    input                   rst,    //Reset (System)
    inout                   act1,   //Activation Port-1
    inout                   act2    //Activation Port-2
)

    /* Reg                      */
    reg     [DataWidth-1:0] PreAct; //Pre-Activation
    reg     [DataWidth-1:0] PstAct; //Post-Activation


    /* Wire                     */
    wire    [DataWidth-1:0] act_i;  //Pre-Activation


    /* Pre-Activation Select    */
    assign act_i    = (sel_i == 2'b00) ? 0 :
                      (sel_i == 2'b01) ? 0 :
                      (sel_i == 2'b10) ? act1 : act2;


    /* Retime Activation        */
    always @(posedge clk) begin
        if (rst) begin
            PreAct  <= 0;
        end
        else begin
            PreAct  <= act_i;
        end
    end


    /* Post-Activation Output   */
    assign act1     = (sel_o1) ? PreAct : 0;
    assign act2     = (sel_o2) ? PreAct : 0;

endmodule