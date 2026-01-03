module dsp_rounding #(
    parameter int unsigned  IWIDTH = 32,
    parameter int unsigned  OWIDTH = 32,
    parameter string        ROUND_TYPE = "HALF_TO_EVEN" // ROUND_DOWN, ROUND_UP, HALF_UP, HALF_DOWN, HALF_TO_ZERO, HALF_FROM_ZERO, HALF_TO_EVEN, HALF_TO_ODD
) (
    input   logic signed [IWIDTH-1:0] in,
    output  logic signed [OWIDTH-1:0] out
);

/*
    https://en.wikipedia.org/wiki/Rounding
    ----------------------- Directed rounding to an integer ------------------------
    ROUND_DOWN (TRUNCATION, floor) - for example, 23.7 gets rounded to 23, and −23.7 gets rounded to −24.
    ROUND_UP (ceil) - for example, 23.2 gets rounded to 24, and −23.7 gets rounded to −23. 
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

    function logic signed [OWIDTH-1:0] sat(logic [IWIDTH:0] in);
        logic [OWIDTH-1:0] out;
        if(!in[IWIDTH] & in[IWIDTH-1]) begin 
            out = {1'b0, {(OWIDTH-1){1'b1}}};
        end else if(in[IWIDTH] & !in[IWIDTH-1]) begin
            out = {1'b1, {(OWIDTH-1){1'b0}}};
        end else begin
            out = in[IWIDTH-1-:OWIDTH];
        end
        return out;
    endfunction

    generate
        if(ROUND_TYPE == "ROUND_DOWN") begin: truncation
            assign out = $signed(in[IWIDTH-1:IWIDTH-OWIDTH]);
        end else if(ROUND_TYPE == "ROUND_UP") begin: round_up
            wire [IWIDTH:0] ru = {in[IWIDTH-1], in[IWIDTH-1:0]} + {1'b0, {(OWIDTH-1){1'b0}}, |in[IWIDTH-OWIDTH-1:0], {(IWIDTH-OWIDTH){1'b0}}};
            assign out = sat(ru);
        end else if(ROUND_TYPE == "HALF_UP") begin: half_up
            wire [IWIDTH:0] hu = {in[IWIDTH-1], in[IWIDTH-1:0]} + {1'b0, {(OWIDTH){1'b0}}, 1'b1, {(IWIDTH-OWIDTH-1){1'b0}}};
            assign out = sat(hu);
        end else if(ROUND_TYPE == "HALF_DOWN") begin: half_down
            wire if_neg_half = in[IWIDTH-OWIDTH-1] & |in[IWIDTH-OWIDTH-2:0];// если дробная часть отрицательного числа меньше 0.5 (по модулю)
            wire [IWIDTH:0] hd = {in[IWIDTH-1], in[IWIDTH-1:0]} + (in[IWIDTH-1] ? {1'b0, {(OWIDTH){1'b0}}, 1'b0, {(IWIDTH-OWIDTH-1){if_neg_half}}} :
                                                                                  {1'b0, {(OWIDTH){1'b0}}, 1'b0, {(IWIDTH-OWIDTH-1){1'b1}}});
            assign out = sat(hd);
        end else if(ROUND_TYPE == "HALF_TO_ZERO") begin: half_to_zero
            wire [IWIDTH:0] htz = {in[IWIDTH-1], in[IWIDTH-1:0]} + {1'b0, {(OWIDTH){1'b0}}, in[IWIDTH-1], {(IWIDTH-OWIDTH-1){~in[IWIDTH-1]}}};
            assign out = sat(htz);
        end else if(ROUND_TYPE == "HALF_FROM_ZERO") begin: half_from_zero
            wire [IWIDTH:0] hfz = {in[IWIDTH-1], in[IWIDTH-1:0]} + {1'b0, {(OWIDTH){1'b0}}, ~in[IWIDTH-1], {(IWIDTH-OWIDTH-1){in[IWIDTH-1]}}};
            assign out = sat(hfz);
        end else if(ROUND_TYPE == "HALF_TO_EVEN") begin: half_to_even // convergent
            wire [IWIDTH:0] hte = {in[IWIDTH-1], in[IWIDTH-1:0]} + {1'b0, {(OWIDTH){1'b0}}, in[IWIDTH-OWIDTH], {(IWIDTH-OWIDTH-1){~in[IWIDTH-OWIDTH]}}};
            assign out = sat(hte);
        end else if(ROUND_TYPE == "HALF_TO_ODD") begin: half_to_odd
            wire [IWIDTH:0] hto = {in[IWIDTH-1], in[IWIDTH-1:0]} + {1'b0, {(OWIDTH){1'b0}}, ~in[IWIDTH-OWIDTH], {(IWIDTH-OWIDTH-1){in[IWIDTH-OWIDTH]}}};
            assign out = sat(hto);
        end else begin: round_default
            assign out = '0;
            $fatal("The rounding type is specified incorrectly");
        end
    endgenerate

endmodule