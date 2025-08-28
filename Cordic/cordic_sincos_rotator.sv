module cordic_vector_rotator #(
    parameter int unsigned  XY_WIDTH = 16,
    parameter int unsigned  ANGLE_WIDTH = 12,
    parameter int unsigned  ITERATION = 0 // номер итерации алгоритма
) (
    input   logic                                   clk,
    input   logic                                   reset_n,

    input   logic signed    [XY_WIDTH-1:0]          x_i,
    input   logic signed    [XY_WIDTH-1:0]          y_i,
    input   logic signed    [ANGLE_WIDTH-1:0]       angle_i, // текущее значение угла (старшие два бита используются только под знак)
    input   logic           [1:0]                   quarter_i,
    input   logic                                   valid_i, 

    output  logic signed    [XY_WIDTH-1:0]          x_o,
    output  logic signed    [XY_WIDTH-1:0]          y_o,
    output  logic signed    [ANGLE_WIDTH-1:0]       angle_o,
    output  logic           [1:0]                   quarter_o,
    output  logic                                   valid_o
);

/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
    localparam logic [ANGLE_WIDTH-1:0] rot_angle = ANGLE_WIDTH'($rtoi($atan(2**(-$itor(ITERATION)))*2**(ANGLE_WIDTH-2)));

    logic signed [XY_WIDTH-1:0]     x_reg;
    logic signed [XY_WIDTH-1:0]     y_reg;
    logic signed [ANGLE_WIDTH-1:0]  angle_reg;
    logic [1:0]                     quarter_reg;
    logic                           valid_reg;

    logic signed [XY_WIDTH-1:0]     x_next;
    logic signed [XY_WIDTH-1:0]     y_next;
    logic signed [ANGLE_WIDTH-1:0]  angle_next;
    logic [1:0]                     quarter_next;

    // logic signed [XY_WIDTH-1:0]     x_round;
    // logic signed [XY_WIDTH-1:0]     y_round;

/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            valid_reg <= '0;
        end else begin
            valid_reg <= valid_i;
        end
    end
    

    always_ff @(posedge clk) begin
        x_reg       <= x_i;
        y_reg       <= y_i;
        angle_reg   <= angle_i;
        quarter_reg <= quarter_i;
    end

    always_comb begin
        quarter_next    = quarter_reg;

        if(angle_reg > 0) begin
            x_next = x_reg - $signed(y_reg >>> ITERATION);
            y_next = y_reg + $signed(x_reg >>> ITERATION);
            angle_next = angle_reg - rot_angle;
        end else begin
            x_next = x_reg + $signed(y_reg >>> ITERATION);
            y_next = y_reg - $signed(x_reg >>> ITERATION);
            angle_next = angle_reg + rot_angle;
        end
    end

    // rounding
    // dsp_rounding #(XY_WIDTH+1, XY_WIDTH, ROUND_TYPE) x_dsp_round (x_next, x_round);
    // dsp_rounding #(XY_WIDTH+1, XY_WIDTH, ROUND_TYPE) y_dsp_round (y_next, y_round);

/*    
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            valid_o <= '0;
        end else begin
            valid_o <= valid_reg;
        end
    end

    always_ff @(posedge clk) begin
        x_o         <= x_round;
        y_o         <= y_round;
        angle_o     <= angle_next;
        quarter_o   <= quarter_next;
    end
*/

    assign valid_o = valid_reg;
    assign x_o = x_next;
    assign y_o = y_next;
    assign angle_o = angle_next;
    assign quarter_o = quarter_next;

endmodule