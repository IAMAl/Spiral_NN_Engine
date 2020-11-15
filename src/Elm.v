`include "Params.h"

module Elm (
    inout   [DataWidth-1:0] v_b_t,
    inout   [DataWidth-1:0] v_b_b,
    inout   [DataWidth-1:0] h_b_l,
    inout   [DataWidth-1:0] h_b_r,
    input   [DataWidth-1:0] v_s_i,
    input   [DataWidth-1:0] h_s_i,
    output  [DataWidth-1:0] v_s_o,
    output  [DataWidth-1:0] h_s_o,
    input   [0:AddrRAM-1]   Addr
);

    //Memory
    mem [DataWidth-1:0] RAM [0:AddrRAM-1];


    //Register
    reg [DataWidth-1:0]     v_REG; 
    reg [DataWidth-1:0]     h_REG; 
    reg [DataWidth-1:0]     v_REG_o; 
    reg [DataWidth-1:0]     h_REG_o; 
    reg [DataWidth-1:0]     a_REG; 
    reg [DataWidth-1:0]     m_REG; 


    //Wire
    wire [DataWidth-1:0]    v_mux;
    wire [DataWidth-1:0]    h_mux;
    wire [DataWidth-1:0]    add;
    wire [DataWidth-1:0]    mlt;
    wire [DataWidth-1:0]    a_out1;
    wire [DataWidth-1:0]    a_out2;
    wire [DataWidth-1:0]    a_mux;
    wire [DataWidth-1:0]    m_mux1;
    wire [DataWidth-1:0]    m_mux2;
    wire [DataWidth-1:0]    ram_in;
    wire [DataWidth-1:0]    ram_out;


    /* Multiplier Input Select      */
    //Operand-1
    assign m_mux1   = (sel_m_mux1 == 2'b00) ? h_s_i : 
                      (sel_m_mux1 == 2'b01) ? h_s_o :
                      (sel_m_mux1 == 2'b10) ? v_s_o : v_b_io;

    //Operand-2
    assign m_mux2   = (sel_m_mux2 == 2'b01) ? v_s_i :
                      (sel_m_mux2 == 2'b10) ? h_s_i :
                      (sel_m_mux2 == 2'b10) ? ram_out : 0;

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


    /* Adder Input Select           */
    //Operand-1
    assign a_mux1   = (sel_a_mux1) ? ram_out : m_REG;

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


    /* Local Memory                 */
    //Memory In
    assign ram_in   = (sel_ram_i == 2'b01) ? h_REG :
                      (sel_ram_i == 2'b10) ? v_REG : 
                      (sel_ram_i == 2'b10) ? a_out2 : 0;

    //Memory-Write
    always @(posedge clk) begin
        if (we_ram) begin
            RAM[w_addr] = v_s_i;
        end
    end

    //Memory-Read
    assign ram_out  = RAM[r_addr]

endmodule