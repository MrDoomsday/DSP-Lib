module dsp_rounding #(
    parameter int unsigned IWIDTH = 32,
    parameter int unsigned OWIDTH = 32,
    parameter string ROUND_TYPE = "CONVERGENT" // TRUNCATION, HALF_UP, HALF_DOWN, TO_ZERO, FROM_ZERO, CONVERGENT
) (
    input logic [IWIDTH-1:0] in,
    output logic [OWIDTH-1:0] out
);


    generate
        if(ROUND_TYPE == "TRUNCATION") begin: truncation
            assign out = in[IWIDTH-1:IWIDTH-OWIDTH];
        end else if(ROUND_TYPE == "HALF_UP") begin: half_up
            wire [IWIDTH-1:0] hu = in[IWIDTH-1:0] + {{(OWIDTH){1'b0}}, 1'b1, {(IWIDTH-OWIDTH-1){1'b0}}};
            assign out = hu[IWIDTH-1:IWIDTH-OWIDTH];
        end else if(ROUND_TYPE == "HALF_DOWN") begin: half_down
            wire [IWIDTH-1:0] hd = in[IWIDTH-1:0] + {{(OWIDTH){1'b0}}, 1'b0, {(IWIDTH-OWIDTH-1){1'b1}}};
            assign out = hd[IWIDTH-1:IWIDTH-OWIDTH];
        end else if(ROUND_TYPE == "TO_ZERO") begin: to_zero
            wire [IWIDTH-1:0] tz = in[IWIDTH-1:0] + {{(OWIDTH){1'b0}}, in[IWIDTH-1], {(IWIDTH-OWIDTH-1){~in[IWIDTH-1]}}};
            assign out = tz[IWIDTH-1:IWIDTH-OWIDTH];
        end else if(ROUND_TYPE == "FROM_ZERO") begin: from_zero
            wire [IWIDTH-1:0] fz = in[IWIDTH-1:0] + {{(OWIDTH){1'b0}}, ~in[IWIDTH-1], {(IWIDTH-OWIDTH-1){in[IWIDTH-1]}}};
            assign out = fz[IWIDTH-1:IWIDTH-OWIDTH];
        end else if(ROUND_TYPE == "CONVERGENT") begin: from_zero
            wire [IWIDTH-1:0] cr = in[IWIDTH-1:0] + {{(OWIDTH){1'b0}}, in[IWIDTH-OWIDTH], {(IWIDTH-OWIDTH-1){~in[IWIDTH-OWIDTH]}}};
            assign out = cr[IWIDTH-1:IWIDTH-OWIDTH];
        end else begin: round_default
            $fatal("The rounding type is specified incorrectly");
        end
    endgenerate
    
endmodule