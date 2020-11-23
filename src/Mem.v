`include "Params.h"

module DMem (
    input                       clk,    //Clock
    input                       rst,    //Reset (System)
    input   [`DataWidth-1:0]    v_s_i,  //Vertical Input
    input   [`DataWidth-1:0]    h_s_i,  //Horizontal Input
    output  [`DataWidth-1:0]    v_s_o,  //Vertical Output
    output  [`DataWidth-1:0]    h_s_o,  //Horizontal Output
    input   [AddrDMEM-1:0]      r_addr, //Read Address: Memory
    input   [AddrDMEM-1:0]      w_addr  //Write Address: Memory
);

    /* Memory                       */
    // Data Memory
    mem [`DataWidth-1:0]    DMEM [0:(2**AddrMEM)-1];


    /* Wire                         */
    wire [`DataWidth-1:0]   ram_i;      //Data Memory Input
    wire [`DataWidth-1:0]   ram_o;      //Data Memory Output

    //Configuration Data (4-bit)
    wire [1:0]              sel_ram_i;  //RAM Input Select
    wire [1:0]              sel_ram_0;  //RAM Output Select
    

    /* Datum Memory                 */
    //Write Datum Select
    assign ram_i    = (sel_ram_i == 2'b00) ? 0 :
                      (sel_ram_i == 2'b01) ? 0 :
                      (sel_ram_i == 2'b10) ? v_s_i : h_s_i;
    
    //Vertical Output
    assign v_s_o    = (sel_ram_o == 2'b00) ? 0 :
                      (sel_ram_o == 2'b01) ? 0 :
                      (sel_ram_o == 2'b10) ? ram_o : 0;

    //Horizontal Output
    assign h_s_o    = (sel_ram_o == 2'b00) ? 0 :
                      (sel_ram_o == 2'b01) ? 0 :
                      (sel_ram_o == 2'b10) ? 0 : ram_o;

    //Memory-Write
    always @(posedge clk) begin
        if (we_ram) begin
            DMEM[w_addr]    = ram_i;
        end
    end

    //Memory-Read
    assign ram_o    = DMEM[r_addr];

endmodule