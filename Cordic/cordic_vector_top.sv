/*
    Модуль основан на материалах работы: DOI: 10.1145/275107.275139

    Углы нарезаются на кусочки по (2*pi/2^ANGLE_WIDTH). Старшие два бита определяют квадрант
    > 00 - I   <
    > 01 - II  <
    > 10 - III <
    > 11 - IV  <
*/
module cordic_vector_top #(
    parameter int unsigned  XY_WIDTH = 16,
    parameter int unsigned  ANGLE_WIDTH = 12, // разрядность угла
    parameter string        ROUND_TYPE = "HALF_TO_EVEN", // тип округления чисел после блока умножения на масштабирующую константу
    parameter int unsigned  USER_WIDTH = 32 // ширина интерфейса для передачи пользовательских данных
) (
    input   logic                               clk,
    input   logic                               reset_n,

    input   logic signed    [XY_WIDTH-1:0]      x_i,
    input   logic signed    [XY_WIDTH-1:0]      y_i,
    input   logic           [ANGLE_WIDTH-1:0]   angle_i,
    input   logic                               valid_i,
    input   logic           [USER_WIDTH-1:0]    user_i,

    output  logic signed    [XY_WIDTH-1:0]      x_o,
    output  logic signed    [XY_WIDTH-1:0]      y_o,
    output  logic                               valid_o,
    output  logic                               sat_flag_o, // saturation
    output  logic           [USER_WIDTH-1:0]    user_o

);


/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
    localparam int unsigned STAGES = XY_WIDTH; // количество итераций алгоритма

    /*-------------- generate cordic iteration --------------*/    
    logic signed    [STAGES-1:0][XY_WIDTH-1:0]      x;
    logic signed    [STAGES-1:0][XY_WIDTH-1:0]      y;
    logic signed    [STAGES-1:0][ANGLE_WIDTH-1:0]   angle;
    logic           [STAGES-1:0][1:0]               quarter;
    logic           [STAGES-1:0]                    valid;
    logic           [STAGES-1:0]                    sat_flag;
    logic           [STAGES-1:0][USER_WIDTH-1:0]    user;

    /*-------------- mult coefficient deformation --------------*/
    localparam int unsigned COEFF_DEF_WIDTH = 16;
    localparam logic [COEFF_DEF_WIDTH-1:0] COEFF_DEF = 0.6073*(2**COEFF_DEF_WIDTH);
    localparam real PI = 3.141592653589793;

    logic signed    [XY_WIDTH+COEFF_DEF_WIDTH-1:0]  mult_x, mult_y;
    logic signed    [XY_WIDTH-1:0]                  mult_x_round, mult_x_round_next, 
                                                    mult_y_round, mult_y_round_next;
    logic                                           mult_valid, mult_valid_round;
    logic           [1:0]                           mult_quarter, mult_quarter_round;
    logic           [USER_WIDTH-1:0]                mult_user, mult_user_round;
    logic                                           mult_sat_flag, mult_sat_flag_round;

    
/***********************************************************************************************************************/
/*******************************************            INSTANCE         ***********************************************/
/***********************************************************************************************************************/
    generate
        assign valid[0] = valid_i;
        assign x[0] = x_i;
        assign y[0] = y_i;
        assign angle[0] = $signed({2'b00, angle_i[ANGLE_WIDTH-3:0]});
        assign quarter[0] = angle_i[ANGLE_WIDTH-1:ANGLE_WIDTH-2];
        assign sat_flag[0] = 1'b0;
        assign user[0] = user_i;

        for(genvar i = 0; i < STAGES - 1; i++) begin: cordic_iteration
            logic signed [ANGLE_WIDTH-1:0] rot_angle = $signed(ANGLE_WIDTH'($rtoi(($atan(2**(-$itor(i)))/(2*PI))*2**ANGLE_WIDTH)));

            cordic_vector_rotator # (
                .XY_WIDTH       ( XY_WIDTH    ),
                .ANGLE_WIDTH    ( ANGLE_WIDTH ),
                .ITERATION      ( i           )
            ) vector_rotator (
                .clk        ( clk           ),
                .reset_n    ( reset_n       ),

                .rot_angle  ( rot_angle     ),

                .x_i        ( x[i]          ),
                .y_i        ( y[i]          ),
                .angle_i    ( angle[i]      ),
                .quarter_i  ( quarter[i]    ),
                .valid_i    ( valid[i]      ),
                .sat_flag_i ( sat_flag[i]   ),
                .user_i     ( user[i]       ),

                .x_o        ( x[i+1]        ),
                .y_o        ( y[i+1]        ),
                .angle_o    ( angle[i+1]    ),
                .quarter_o  ( quarter[i+1]  ),
                .valid_o    ( valid[i+1]    ),
                .sat_flag_o ( sat_flag[i+1] ),
                .user_o     ( user[i+1]     )
            );            
        end
    endgenerate

/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
    /*-------------- coefficient deformation --------------*/
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            mult_valid <= 'b0;
        end else begin
            mult_valid <= valid[STAGES-1];
        end
    end

    always_ff @(posedge clk) begin
        mult_user <= user[STAGES-1];
        mult_sat_flag <= sat_flag[STAGES-1];
        mult_quarter <= quarter[STAGES-1];
        mult_x <= $signed({1'b0, COEFF_DEF})*$signed(x[STAGES-1]);
        mult_y <= $signed({1'b0, COEFF_DEF})*$signed(y[STAGES-1]);
    end

    /*-------------- round --------------*/
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            mult_valid_round <= 'b0;
        end else begin
            mult_valid_round <= mult_valid;
        end
    end

    dsp_rounding #(XY_WIDTH+COEFF_DEF_WIDTH, XY_WIDTH, ROUND_TYPE) x_dsp_round (mult_x, mult_x_round_next);
    dsp_rounding #(XY_WIDTH+COEFF_DEF_WIDTH, XY_WIDTH, ROUND_TYPE) y_dsp_round (mult_y, mult_y_round_next);

    always_ff @(posedge clk) begin
        mult_user_round <= mult_user;
        mult_sat_flag_round <= mult_sat_flag;
        mult_quarter_round <= mult_quarter;
        mult_x_round <= mult_x_round_next;
        mult_y_round <= mult_y_round_next;
    end

    /*-------------- select quarter --------------*/
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            valid_o <= 'b0;
        end else begin
            valid_o <= mult_valid_round;
        end
    end

    always_ff @(posedge clk) begin
        user_o <= mult_user_round;
        sat_flag_o <= mult_sat_flag_round;
        case(mult_quarter_round)
            2'b00: begin
                x_o <= mult_x_round;
                y_o <= mult_y_round;
            end
            2'b01: begin
                x_o <= -mult_y_round;
                y_o <= mult_x_round;
            end
            2'b10: begin
                x_o <= -mult_x_round;
                y_o <= -mult_y_round;
            end
            2'b11: begin
                x_o <= mult_y_round;
                y_o <= -mult_x_round;
            end
        endcase
    end

endmodule