
module cordic_vector_top_tb;

    // Parameters
    localparam int unsigned XY_WIDTH = 16;
    localparam int unsigned ANGLE_WIDTH = 12;
    localparam int unsigned STAGES = 8;
    localparam string ROUND_TYPE = "HALF_TO_EVEN";

    //Ports
    reg clk;
    reg reset_n;

    reg [XY_WIDTH-1:0] x_i;
    reg [XY_WIDTH-1:0] y_i;
    reg [ANGLE_WIDTH-1:0] angle_i;
    reg valid_i;

    wire [XY_WIDTH-1:0] x_o;
    wire [XY_WIDTH-1:0] y_o;
    wire valid_o;

    cordic_vector_top # (
        .XY_WIDTH   (XY_WIDTH),
        .ANGLE_WIDTH(ANGLE_WIDTH),
        .STAGES     (STAGES),
        .ROUND_TYPE (ROUND_TYPE)
    )
    cordic_vector_top_inst (
        .clk    ( clk       ),
        .reset_n( reset_n   ),
        
        .x_i    ( x_i       ),
        .y_i    ( y_i       ),
        .angle_i( angle_i   ),
        .valid_i( valid_i   ),
        
        .x_o    ( x_o       ),
        .y_o    ( y_o       ),
        .valid_o( valid_o   )
    );

    always begin
        #5;
        clk <= 1'b0;
        #5;
        clk <= 1'b1;
    end


    initial begin
        reset_n <= 1'b0;
        x_i     <= XY_WIDTH'('d100);
        y_i     <= XY_WIDTH'('d100);
        angle_i <= '0;
        valid_i <= '0;
        repeat(10) @(posedge clk);
        reset_n <= 1'b1;
        repeat(10) @(posedge clk);

        for(int i = 0; i < 100; i++) begin
            automatic logic [ANGLE_WIDTH-1:0] rot_angle = ANGLE_WIDTH'($rtoi($atan(2**(-$itor(i)))*2**(ANGLE_WIDTH-2)));
            $display("Iteration = %0d, angle = %0f", i, rot_angle);
            // $display("%0f", $atan(2**(-$itor(i))));

        end
        

        for(int i = 0; i < 2**ANGLE_WIDTH; i++) begin
            angle_i <= i[ANGLE_WIDTH-1:0];
            valid_i <= 1'b1;
            @(posedge clk);
        end
        angle_i <= '0;
        valid_i <= '0;

        repeat(1000) @(posedge clk);
        $stop();        
    end

endmodule