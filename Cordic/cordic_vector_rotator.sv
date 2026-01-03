module cordic_vector_rotator #(
    parameter int unsigned  XY_WIDTH = 16,
    parameter int unsigned  ANGLE_WIDTH = 12,
    parameter int unsigned  ITERATION = 0, // номер итерации алгоритма
    parameter int unsigned  USER_WIDTH = 32
) (
    input   logic                                   clk,
    input   logic                                   reset_n,

    input   logic signed    [ANGLE_WIDTH-1:0]       rot_angle, // угол, на величину которого поворачивает экземпляр данного модуля

    input   logic signed    [XY_WIDTH-1:0]          x_i,
    input   logic signed    [XY_WIDTH-1:0]          y_i,
    input   logic signed    [ANGLE_WIDTH-1:0]       angle_i, // текущее значение угла (старшие два бита используются только под знак)
    input   logic           [1:0]                   quarter_i,
    input   logic                                   valid_i, 
    input   logic                                   sat_flag_i,
    input   logic           [USER_WIDTH-1:0]        user_i, // пользовательские данные

    output  logic signed    [XY_WIDTH-1:0]          x_o,
    output  logic signed    [XY_WIDTH-1:0]          y_o,
    output  logic signed    [ANGLE_WIDTH-1:0]       angle_o,
    output  logic           [1:0]                   quarter_o,
    output  logic                                   valid_o,
    output  logic                                   sat_flag_o,
    output  logic           [USER_WIDTH-1:0]        user_o // пользовательские данные

);

/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
    logic signed [XY_WIDTH-1:0]     x_reg;
    logic signed [XY_WIDTH-1:0]     y_reg;
    logic signed [ANGLE_WIDTH-1:0]  angle_reg;
    logic [1:0]                     quarter_reg;
    logic                           valid_reg;
    logic                           sat_flag, sat_x, sat_y;
    logic [USER_WIDTH-1:0]          user;

    logic signed [XY_WIDTH:0]       x_next;
    logic signed [XY_WIDTH:0]       y_next;
    logic signed [ANGLE_WIDTH-1:0]  angle_next;
    logic [1:0]                     quarter_next;

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
        sat_flag    <= sat_flag_i;
        x_reg       <= x_i;
        y_reg       <= y_i;
        angle_reg   <= angle_i;
        quarter_reg <= quarter_i;
        user        <= user_i;
    end

    always_comb begin
        quarter_next = quarter_reg;

        if(angle_reg[ANGLE_WIDTH-1]) begin // если угол отрицательный
            x_next = $signed({x_reg[XY_WIDTH-1], x_reg}) + ($signed({y_reg[XY_WIDTH-1], y_reg}) >>> ITERATION);
            y_next = $signed({y_reg[XY_WIDTH-1], y_reg}) - ($signed({x_reg[XY_WIDTH-1], x_reg}) >>> ITERATION);
            angle_next = angle_reg + rot_angle;
        end else begin
            x_next = $signed({x_reg[XY_WIDTH-1], x_reg}) - ($signed({y_reg[XY_WIDTH-1], y_reg}) >>> ITERATION);
            y_next = $signed({y_reg[XY_WIDTH-1], y_reg}) + ($signed({x_reg[XY_WIDTH-1], x_reg}) >>> ITERATION);
            angle_next = angle_reg - rot_angle;
        end
    end

    // saturation
    always_comb begin
        if(!x_next[XY_WIDTH] & x_next[XY_WIDTH-1]) begin 
            x_o = {1'b0, {(XY_WIDTH-1){1'b1}}};
            sat_x = 1'b1;
            // $error("1. Saturation. Iteration = %0d", ITERATION);
        end else if(x_next[XY_WIDTH] & !x_next[XY_WIDTH-1]) begin
            x_o = {1'b1, {(XY_WIDTH-1){1'b0}}};
            sat_x = 1'b1;
            // $error("2. Saturation. Iteration = %0d", ITERATION);
        end else begin
            x_o = x_next[XY_WIDTH-1:0];
            sat_x = 1'b0;
        end

        if(!y_next[XY_WIDTH] & y_next[XY_WIDTH-1]) begin 
            y_o = {1'b0, {(XY_WIDTH-1){1'b1}}};
            sat_y = 1'b1;
            // $error("3. Saturation. Iteration = %0d", ITERATION);
        end else if(y_next[XY_WIDTH] & !y_next[XY_WIDTH-1]) begin
            y_o = {1'b1, {(XY_WIDTH-1){1'b0}}};
            sat_y = 1'b1;
            // $error("4. Saturation. Iteration = %0d", ITERATION);
        end else begin
            y_o = y_next[XY_WIDTH-1:0];
            sat_y = 1'b0;
        end
    end

    assign valid_o = valid_reg;
    assign angle_o = angle_next;
    assign quarter_o = quarter_next;
    assign sat_flag_o = sat_flag | sat_x | sat_y;
    assign user_o = user;

endmodule