/*
    Углы нарезаются на кусочки по (2*pi/2^ANGLE_WIDTH). Старшие два бита определяют квадрант
    > 00 - I   <
    > 01 - II  <
    > 10 - III <
    > 11 - IV  <
*/
module cordic_vector_top #(
    parameter int unsigned  XY_WIDTH = 16,
    parameter int unsigned  ANGLE_WIDTH = 12, // разрядность угла. 
    parameter int unsigned  STAGES = 0, // количество итераций алгоритма
    parameter string        ROUND_TYPE = "TRUNCATION" // тип округления чисел после сумматоров в модулях поворота
) (
    input   logic                   clk,
    input   logic                   reset_n,

    input   logic signed    [XY_WIDTH-1:0]     x_i,
    input   logic signed    [XY_WIDTH-1:0]     y_i,
    input   logic           [ANGLE_WIDTH-1:0]  angle_i,
    input   logic           valid_i,

    output  logic signed [XY_WIDTH-1:0]     x_o,
    output  logic signed [XY_WIDTH-1:0]     y_o,
    output  logic                           valid_o
);


/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
    logic signed    [STAGES-1:0][XY_WIDTH:0]        rot_x_i, rot_x_o;
    logic signed    [STAGES-1:0][XY_WIDTH:0]        rot_y_i, rot_y_o;
    logic signed    [STAGES-1:0][ANGLE_WIDTH-1:0]   rot_angle_i, rot_angle_o;
    logic           [STAGES-1:0][1:0]               rot_quarter_i, rot_quarter_o;
    logic           [STAGES-1:0]                    rot_valid_i, rot_valid_o;
    
/***********************************************************************************************************************/
/*******************************************            INSTANCE         ***********************************************/
/***********************************************************************************************************************/
    generate
        for(genvar i = 0; i < STAGES; i++) begin: cordic_iteration
            cordic_vector_rotator # (
                .XY_WIDTH       ( XY_WIDTH + 1),
                .ANGLE_WIDTH    ( ANGLE_WIDTH ),
                .ITERATION      ( i           )
            ) vector_rotator (
                .clk        ( clk               ),
                .reset_n    ( reset_n           ),

                .x_i        ( rot_x_i[i]        ),
                .y_i        ( rot_y_i[i]        ),
                .angle_i    ( rot_angle_i[i]    ),
                .quarter_i  ( rot_quarter_i[i]  ),
                .valid_i    ( rot_valid_i[i]    ),

                .x_o        ( rot_x_o[i]        ),
                .y_o        ( rot_y_o[i]        ),
                .angle_o    ( rot_angle_o[i]    ),
                .quarter_o  ( rot_quarter_o[i]  ),
                .valid_o    ( rot_valid_o[i]    )
            );
            
            if(i == 0) begin
                assign rot_valid_i[i]   = valid_i;
                assign rot_x_i[i]       = $signed({x_i[XY_WIDTH-1], x_i});
                assign rot_y_i[i]       = $signed({y_i[XY_WIDTH-1], y_i});
                assign rot_angle_i[i]   = $signed({{2{angle_i[ANGLE_WIDTH-3]}}, angle_i[ANGLE_WIDTH-3:0]});
                assign rot_quarter_i[i] = angle_i[ANGLE_WIDTH-1:ANGLE_WIDTH-2];
            end else begin
                assign rot_valid_i[i]   = rot_valid_o[i-1];
                assign rot_x_i[i]       = rot_x_o[i-1];
                assign rot_y_i[i]       = rot_y_o[i-1];
                assign rot_angle_i[i]   = rot_angle_o[i-1];
                assign rot_quarter_i[i] = rot_quarter_o[i-1];
            end
        end
    endgenerate

/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
    assign x_o      = rot_x_o[STAGES-1][XY_WIDTH-1:0];
    assign y_o      = rot_y_o[STAGES-1][XY_WIDTH-1:0];
    assign valid_o  = rot_valid_o[STAGES-1];


endmodule