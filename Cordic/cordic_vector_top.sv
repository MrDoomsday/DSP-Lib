/*
    Углы нарезаются на кусочки по (2*pi/2^ANGLE_WIDTH). Старшие два бита определяют квадрант
    > 00 - I   <
    > 01 - II  <
    > 10 - III <
    > 11 - IV  <
*/
module cordic_vector_top #(
    parameter int unsigned  XY_WIDTH = 16,
    parameter int unsigned  ANGLE_WIDTH = 12, // разрядность угла
    parameter string        ROUND_TYPE = "TRUNCATION" // тип округления чисел после блока умножения на масштабирующую константу
) (
    input   logic                               clk,
    input   logic                               reset_n,

    input   logic signed    [XY_WIDTH-1:0]      x_i,
    input   logic signed    [XY_WIDTH-1:0]      y_i,
    input   logic           [ANGLE_WIDTH-1:0]   angle_i,
    input   logic                               valid_i,

    output  logic signed    [XY_WIDTH-1:0]      x_o,
    output  logic signed    [XY_WIDTH-1:0]      y_o,
    output  logic                               valid_o
);


/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
    localparam int unsigned STAGES = XY_WIDTH; // количество итераций алгоритма

    // generate cordic iteration
    logic signed    [STAGES-1:0][XY_WIDTH:0]        rot_x_i, rot_x_o;
    logic signed    [STAGES-1:0][XY_WIDTH:0]        rot_y_i, rot_y_o;
    logic signed    [STAGES-1:0][ANGLE_WIDTH-1:0]   rot_angle_i, rot_angle_o;
    logic           [STAGES-1:0][1:0]               rot_quarter_i, rot_quarter_o;
    logic           [STAGES-1:0]                    rot_valid_i, rot_valid_o;


    // mult coefficient deformation
    localparam int unsigned COEFF_DEF_WIDTH = 16;
    localparam logic [COEFF_DEF_WIDTH-1:0] COEFF_DEF = 0.6073*2**COEFF_DEF_WIDTH;

    logic signed    [XY_WIDTH+COEFF_DEF_WIDTH:0]    mult_x, mult_y;
    logic signed    [XY_WIDTH-1:0]                  mult_x_round, mult_x_round_next, 
                                                    mult_y_round, mult_y_round_next;
    logic                                           mult_valid, mult_valid_round;
    logic           [1:0]                           mult_quarter, mult_quarter_round;


    // select quarter
    logic signed    [XY_WIDTH-1:0]      q_x, q_y;
    logic                               q_valid;
    
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
                assign rot_angle_i[i]   = $signed({2'b00, angle_i[ANGLE_WIDTH-3:0]});
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
    // coefficient deformation
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            mult_valid <= 'b0;
        end else begin
            mult_valid <= rot_valid_o[STAGES-1];
        end
    end

    always_ff @(posedge clk) begin
        mult_quarter <= rot_quarter_o[STAGES-1];
        mult_x <= $signed({1'b0, COEFF_DEF})*$signed(rot_x_o[STAGES-1][XY_WIDTH-1:0]);
        mult_y <= $signed({1'b0, COEFF_DEF})*$signed(rot_y_o[STAGES-1][XY_WIDTH-1:0]);
    end

    // round
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            mult_valid_round <= 'b0;
        end else begin
            mult_valid_round <= mult_valid;
        end
    end

    dsp_rounding #(XY_WIDTH+COEFF_DEF_WIDTH+1, XY_WIDTH, ROUND_TYPE) x_dsp_round ($signed(mult_x <<< 1), mult_x_round_next);
    dsp_rounding #(XY_WIDTH+COEFF_DEF_WIDTH+1, XY_WIDTH, ROUND_TYPE) y_dsp_round ($signed(mult_y <<< 1), mult_y_round_next);

    always_ff @(posedge clk) begin
        mult_quarter_round <= mult_quarter;
        mult_x_round <= mult_x_round_next;
        mult_y_round <= mult_y_round_next;
    end


    // select quarter
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            q_valid <= 'b0;
        end else begin
            q_valid <= mult_valid_round;
        end
    end

    always_ff @(posedge clk) begin
        case(mult_quarter_round)
            2'b00: begin
                q_x <= mult_x_round;
                q_y <= mult_y_round;
            end
            2'b01: begin
                q_x <= mult_x_round;
                q_y <= mult_y_round;
            end
            2'b10: begin
                q_x <= mult_x_round;
                q_y <= mult_y_round;
            end
            2'b11: begin
                q_x <= mult_x_round;
                q_y <= mult_y_round;
            end
        endcase
    end

    assign x_o      = q_x;
    assign y_o      = q_y;
    assign valid_o  = q_valid;


endmodule