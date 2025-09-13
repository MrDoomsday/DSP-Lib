
module cordic_vector_top_tb;

    // Parameters
    localparam int unsigned XY_WIDTH = 16;
    localparam int unsigned ANGLE_WIDTH = 16;
    localparam string ROUND_TYPE = "HALF_TO_EVEN";

    localparam int unsigned COEFF_DEF_WIDTH = 16;
    localparam logic [COEFF_DEF_WIDTH-1:0] COEFF_DEF = 0.6073*2**COEFF_DEF_WIDTH;
    localparam real PI = 3.141592653589793;


    //Ports
    reg clk;
    reg reset_n;

    reg [XY_WIDTH-1:0] x_i;
    reg [XY_WIDTH-1:0] y_i;
    reg [ANGLE_WIDTH-1:0] angle_i;
    reg valid_i;

    wire signed [XY_WIDTH-1:0] x_o;
    wire signed [XY_WIDTH-1:0] y_o;
    wire valid_o;

    // variables 
    typedef struct packed {
        logic signed [XY_WIDTH-1:0] x;
        logic signed [XY_WIDTH-1:0] y;
        logic [ANGLE_WIDTH-1:0] angle;
    } task_for_rotation_t;

    mailbox #(task_for_rotation_t) mbx_task_for_rotation;
    mailbox #(task_for_rotation_t) mbx_vector_from_rotation;

    real tol = 100; // tolerance
    int unsigned cnt_vectors = 0;
    int unsigned total_vectors = 1000000;
    

    // instance
    cordic_vector_top # (
        .XY_WIDTH   (XY_WIDTH),
        .ANGLE_WIDTH(ANGLE_WIDTH),
        .ROUND_TYPE (ROUND_TYPE)
    ) cordic_vector_top_inst (
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

    task gen_vector();
        forever begin
            automatic task_for_rotation_t task_for_rotation;
            if(!std::randomize(task_for_rotation) with {
                (2*XY_WIDTH+1)'((2*XY_WIDTH)'(task_for_rotation.x*task_for_rotation.x) + (2*XY_WIDTH)'(task_for_rotation.y*task_for_rotation.y)) < (2*XY_WIDTH+1 )'(2**(2*XY_WIDTH-2)-1);
                task_for_rotation.angle > 0;
            }) begin
                $display("Error randomization task for rotation!");
                $fatal();
            end

            mbx_task_for_rotation.put(task_for_rotation);

            x_i     <= task_for_rotation.x;
            y_i     <= task_for_rotation.y;
            angle_i <= task_for_rotation.angle;
            valid_i <= '1;
            @(posedge clk);
            x_i     <= '0;
            y_i     <= '0;
            angle_i <= '0;
            valid_i <= '0;
        end
    endtask
    
    function logic signed [XY_WIDTH-1:0] get_x_rot_vector(logic signed [XY_WIDTH-1:0] x, y, logic [ANGLE_WIDTH-1:0] angle);
        automatic real angle_radian = 2*PI*$itor(angle)/$itor(2**ANGLE_WIDTH);
        return $signed(XY_WIDTH'($rtoi(x*$cos(angle_radian) - y*$sin(angle_radian))));
    endfunction

    function logic signed [XY_WIDTH-1:0] get_y_rot_vector(logic signed [XY_WIDTH-1:0] x, y, logic [ANGLE_WIDTH-1:0] angle);
        automatic real angle_radian = 2*PI*$itor(angle)/$itor(2**ANGLE_WIDTH);
        return $signed(XY_WIDTH'($rtoi(y*$cos(angle_radian) + x*$sin(angle_radian))));
    endfunction

    task monitor_vector();
        forever begin
            @(posedge clk);
            if(valid_o) begin
                automatic task_for_rotation_t vector_from_rotation;
                vector_from_rotation.x = x_o;
                vector_from_rotation.y = y_o;
                vector_from_rotation.angle = '0;
                mbx_vector_from_rotation.put(vector_from_rotation);
            end
        end
    endtask

    task check_vector();
        forever begin
            automatic task_for_rotation_t task_for_rotation, vector_from_rotation;
            automatic logic signed [XY_WIDTH-1:0] x_etalon, y_etalon;

            mbx_vector_from_rotation.get(vector_from_rotation);

            mbx_task_for_rotation.get(task_for_rotation);
            x_etalon = get_x_rot_vector(task_for_rotation.x, task_for_rotation.y, task_for_rotation.angle);
            y_etalon = get_y_rot_vector(task_for_rotation.x, task_for_rotation.y, task_for_rotation.angle);
            
            // check x
            if(!((($itor(x_etalon) - tol) <= $itor(vector_from_rotation.x)) && ($itor(vector_from_rotation.x) <= ($itor(x_etalon) + tol)))) begin
                $display("--------------------------------------------------------------------------------------------------");
                $display("x_0 = %0d, y_0 = %0d, angle = %0d (%0f grad)", task_for_rotation.x, task_for_rotation.y, task_for_rotation.angle, $itor(task_for_rotation.angle)*360/2**ANGLE_WIDTH);
                $error("The accepted value does not match the one calculated using the direct formula; x_a = %0d, x_c = %0d", vector_from_rotation.x, x_etalon);
            end else begin
                cnt_vectors++;
            end
            
            // check y
            if(!((($itor(y_etalon) - tol) <= $itor(vector_from_rotation.y)) && ($itor(vector_from_rotation.y) <= ($itor(y_etalon) + tol)))) begin
                $display("--------------------------------------------------------------------------------------------------");
                $display("x_0 = %0d, y_0 = %0d, angle = %0d (%0f grad)", task_for_rotation.x, task_for_rotation.y, task_for_rotation.angle, $itor(task_for_rotation.angle)*360/2**ANGLE_WIDTH);
                $error("The accepted value does not match the one calculated using the direct formula; y_a = %0d, y_c = %0d", vector_from_rotation.y, y_etalon);
            end else begin
                cnt_vectors++;
            end
        end
    endtask


    initial begin
        mbx_task_for_rotation = new();
        mbx_vector_from_rotation = new();

        reset_n <= 1'b0;
        x_i     <= '0;
        y_i     <= '0;
        angle_i <= '0;
        valid_i <= '0;
        repeat(10) @(posedge clk);
        reset_n <= 1'b1;
        repeat(10) @(posedge clk);        

        for(int i = 0; i < XY_WIDTH; i++) begin
            automatic logic [ANGLE_WIDTH-1:0] rot_angle = $signed(ANGLE_WIDTH'($rtoi(($atan(2**(-$itor(i)))/(2*PI))*2**ANGLE_WIDTH)));
            automatic real rot_angle_real = $atan(2**(-$itor(i)));
            $display("Iteration = %0d, angle = %0d, angle_real = %0f", i, $signed(rot_angle), rot_angle_real);
        end

        fork
            gen_vector();
            monitor_vector();
            check_vector();
        join_none

        wait(cnt_vectors >= 2*total_vectors);
        $display("**** Test completed ****");

        //repeat(100000) @(posedge clk);
        $stop();        
    end

endmodule