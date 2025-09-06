module dsp_rounding #(
    parameter int unsigned  IWIDTH = 32,
    parameter int unsigned  OWIDTH = 32,
    parameter string        ROUND_TYPE = "HALF_TO_EVEN" // TRUNCATION, HALF_UP, HALF_DOWN, HALF_TO_ZERO, HALF_FROM_ZERO, HALF_TO_EVEN, HALF_TO_ODD
) (
    input   logic signed [IWIDTH-1:0] in,
    output  logic signed [OWIDTH-1:0] out
);

/*
    https://en.wikipedia.org/wiki/Rounding
    ----------------------- Directed rounding to an integer ------------------------
    TRUNCATION - for example, 23.7 gets rounded to 23, and −23.7 gets rounded to −23.
    ----------------------- Rounding to the nearest integer ------------------------
    HALF_UP - for example, 23.5 gets rounded to 24, and −23.5 gets rounded to −23.
    HALF_DOWN - for example, 23.5 gets rounded to 23, and −23.5 gets rounded to −24.
    HALF_TO_ZERO - for example, 23.5 gets rounded to 23, and −23.5 gets rounded to −23.
    HALF_FROM_ZERO - for example, 23.5 gets rounded to 24, and −23.5 gets rounded to −24.
    HALF_TO_EVEN - By this convention, if the fractional part of x is 0.5, then y is the even integer nearest to x. 
        Thus, for example, 23.5 becomes 24, as does 24.5; however, −23.5 becomes −24, as does −24.5
    HALF_TO_ODD - In this approach, if the fractional part of x is 0.5, then y is the odd integer nearest to x.
        Thus, for example, 23.5 becomes 23, as does 22.5; while −23.5 becomes −23, as does −22.5. 
*/

    generate
        if(ROUND_TYPE == "TRUNCATION") begin: truncation
            assign out = $signed(in[IWIDTH-1:IWIDTH-OWIDTH]);
        end else if(ROUND_TYPE == "HALF_UP") begin: half_up
            wire [IWIDTH-1:0] hu = in[IWIDTH-1:0] + {{(OWIDTH){1'b0}}, 1'b1, {(IWIDTH-OWIDTH-1){1'b0}}};
            assign out = $signed(hu[IWIDTH-1:IWIDTH-OWIDTH]);
        end else if(ROUND_TYPE == "HALF_DOWN") begin: half_down
            wire [IWIDTH-1:0] hd = in[IWIDTH-1:0] + {{(OWIDTH){1'b0}}, 1'b0, {(IWIDTH-OWIDTH-1){1'b1}}};
            assign out = $signed(hd[IWIDTH-1:IWIDTH-OWIDTH]);
        end else if(ROUND_TYPE == "HALF_TO_ZERO") begin: half_to_zero
            wire [IWIDTH-1:0] htz = in[IWIDTH-1:0] + {{(OWIDTH){1'b0}}, in[IWIDTH-1], {(IWIDTH-OWIDTH-1){~in[IWIDTH-1]}}};
            assign out = $signed(htz[IWIDTH-1:IWIDTH-OWIDTH]);
        end else if(ROUND_TYPE == "HALF_FROM_ZERO") begin: half_from_zero
            wire [IWIDTH-1:0] hfz = in[IWIDTH-1:0] + {{(OWIDTH){1'b0}}, ~in[IWIDTH-1], {(IWIDTH-OWIDTH-1){in[IWIDTH-1]}}};
            assign out = $signed(hfz[IWIDTH-1:IWIDTH-OWIDTH]);
        end else if(ROUND_TYPE == "HALF_TO_EVEN") begin: half_to_even // convergent
            wire [IWIDTH-1:0] hte = in[IWIDTH-1:0] + {{(OWIDTH){1'b0}}, in[IWIDTH-OWIDTH], {(IWIDTH-OWIDTH-1){~in[IWIDTH-OWIDTH]}}};
            assign out = $signed(hte[IWIDTH-1:IWIDTH-OWIDTH]);
        end else if(ROUND_TYPE == "HALF_TO_ODD") begin: half_to_odd
            wire [IWIDTH-1:0] hto = in[IWIDTH-1:0] + {{(OWIDTH){1'b0}}, ~in[IWIDTH-OWIDTH], {(IWIDTH-OWIDTH-1){in[IWIDTH-OWIDTH]}}};
            assign out = $signed(hto[IWIDTH-1:IWIDTH-OWIDTH]);
        end else begin: round_default
            assign out = '0;
            $fatal("The rounding type is specified incorrectly");
        end
    endgenerate
    
endmodule