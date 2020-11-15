`include "Params.h"

module Synapse (
    input                   clk,    //Clock
    input                   rst,    //Reset (System)
    inout   [DataWidth-1:0] v_b_t,  //Bi-Directional Port: Top-Side
    inout   [DataWidth-1:0] v_b_b,  //Bi-Directional Port: Bottomn-Side
    inout   [DataWidth-1:0] h_b_l,  //Bi-Directional Port: Left-Side
    inout   [DataWidth-1:0] h_b_r,  //Bi-Directional Port: Right-Side
    input   [DataWidth-1:0] v_s_i,  //Vertical Input
    input   [DataWidth-1:0] h_s_i,  //Horizontal Input
    output  [DataWidth-1:0] v_s_o,  //Vertical Output
    output  [DataWidth-1:0] h_s_o,  //Horizontal Output
    input   [AddrDMEM-1:0]  r_addr, //Read Address: Data Memory
    input   [AddrDMEM-1:0]  w_addr  //Write Address: Data Memory
);

    /* Memory                       */
    // Data Memory
    mem [DataWidth-1:0]     DMEM [0:(2**AddrDMEM)-1];

    //Configuration Memory
    mem [ConfWidth-1:0]     CMEM [0:(2**AddrCMEM)-1];


    /* Reg                          */
    reg [DataWidth-1:0]     v_REG;  //Pipeline Register: Vertical
    reg [DataWidth-1:0]     h_REG;  //Pipeline Register: Horizontal
    reg [DataWidth-1:0]     v_REG_o;//Forward Register: Vertical
    reg [DataWidth-1:0]     h_REG_o;//Forward Register: Horizontal
    reg [DataWidth-1:0]     a_REG;  //Adder: Operand Register
    reg [DataWidth-1:0]     m_REG;  //Multiplier: Output Register


    /* Wire                         */
    wire [DataWidth-1:0]    v_mux;
    wire [DataWidth-1:0]    h_mux;
    wire [DataWidth-1:0]    mlt;    //Multiplication Result
    wire [DataWidth-1:0]    add;    //Addtion Result
    wire [DataWidth-1:0]    m_mux1; //Multiply Operand-1
    wire [DataWidth-1:0]    m_mux2; //Multiply Operand-2
    wire [DataWidth-1:0]    a_out1; //Add Fanout-1
    wire [DataWidth-1:0]    a_out2; //Add Fanout-2
    wire [DataWidth-1:0]    a_mux;  //Add Operand-2
    wire [DataWidth-1:0]    ram_i;  //Data Memory Input
    wire [DataWidth-1:0]    ram_o;  //Data Memory Output


    /* Multiplier                   */
    //Operand-1
    assign m_mux1   = (sel_m_mux1 == 2'b00) ? h_s_i : 
                      (sel_m_mux1 == 2'b01) ? h_s_o :
                      (sel_m_mux1 == 2'b10) ? v_s_o : v_b_io;

    //Operand-2
    assign m_mux2   = (sel_m_mux2 == 2'b01) ? v_s_i :
                      (sel_m_mux2 == 2'b10) ? h_s_i :
                      (sel_m_mux2 == 2'b10) ? ram_o : 0;

    //Multiply
    assign mlt      = m_mux1 * m_mux2;

    //Multiplication Store
    always @(posedge clk) begin
        if (rst) begin
            m_REG   <= 0;
        end
        else begin
            m_REG   <= mlt;
        end
    end


    /* Adder                        */
    //Operand-1
    assign a_mux1   = (sel_a_mux1) ? ram_o : m_REG;

    //Operand-2
    assign a_mux2   = (sel_a_mux2 == 2'b00) ? h_b_r :
                      (sel_a_mux2 == 2'b01) ? h_b_l :
                      (sel_a_mux2 == 2'b10) ? h_b_t : h_b_t;

    //Operand-2 Store
    always @(posedge clk) begin
        if (rst) begin
            a_REG   <= 0;
        end
        else begin
            a_REG   <= a_mux2;
        end
    end

    //Addition
    assign add      = a_mux1 + a_REG;

    //Fan-out of Adder
    assign a_out1   = (sel_a1) ? add : z;
    assign a_out2   = (sel_a2) ? add : z;


    /* Vertical Pipeline Register   */
    assign v_line   = (sel_v_line == 2'b01) ? v_b_t :
                      (sel_v_line == 2'b10) ? v_b_b :
                      (sel_v_line == 2'b11) ? a_out2 : z;

    always @(posedge clk) begin
        if (rst) begin
            v_REG   <= 0;
        end
        else begin
            v_REG   <= v_line;
        end
    end


    /* Horizontal Pipeline Register   */
    assign h_line   = (sel_h_line == 2'b01) ? h_b_r :
                      (sel_h_line == 2'b10) ? h_b_l :
                      (sel_h_line == 2'b11) ? a_out1 : z;
                      
    always @(posedge clk) begin
        if (rst) begin
            h_REG   <= 0;
        end
        else begin
            h_REG   <= h_line;
        end
    end


    /* Vertical-Output to Top       */
    always @(posedge clk) begin
        if (rst) begin
            v_REG_o <= 0;
        end
        else begin
            v_REG_o <= v_s_i;
        end
    end

    assign v_s_o    = v_REG_o;


    /* Horizontal-Output to Left    */
    always @(posedge clk) begin
        if (rst) begin
            h_REG_o <= 0;
        end
        else begin
            h_REG_o <= h_s_i;
        end
    end

    assign h_s_o    = h_REG_o;


    /* Local Memory                 */
    //Memory-Write Select
    assign ram_i    = (sel_ram_i == 2'b01) ? h_REG :
                      (sel_ram_i == 2'b10) ? v_REG : 
                      (sel_ram_i == 2'b10) ? a_out2 : 0;

    //Memory-Write
    always @(posedge clk) begin
        if (we_ram) begin
            DMEM[w_addr]    = ram_i;
        end
    end

    //Memory-Read
    assign ram_o    = DMEM[r_addr];

endmodule