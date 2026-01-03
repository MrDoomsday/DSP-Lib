onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cordic_vector_top_tb/DUT/clk
add wave -noupdate /cordic_vector_top_tb/DUT/reset_n
add wave -noupdate -expand -group input /cordic_vector_top_tb/DUT/x_i
add wave -noupdate -expand -group input /cordic_vector_top_tb/DUT/y_i
add wave -noupdate -expand -group input /cordic_vector_top_tb/DUT/angle_i
add wave -noupdate -expand -group input /cordic_vector_top_tb/DUT/valid_i
add wave -noupdate -expand -group input /cordic_vector_top_tb/DUT/user_i
add wave -noupdate -expand -group output /cordic_vector_top_tb/DUT/x_o
add wave -noupdate -expand -group output /cordic_vector_top_tb/DUT/y_o
add wave -noupdate -expand -group output /cordic_vector_top_tb/DUT/valid_o
add wave -noupdate -expand -group output /cordic_vector_top_tb/DUT/sat_flag_o
add wave -noupdate -expand -group output /cordic_vector_top_tb/DUT/user_o
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/angle
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/quarter
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/valid
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/sat_flag
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/user
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/mult_x
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/mult_y
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/mult_x_round
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/mult_x_round_next
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/mult_y_round
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/mult_y_round_next
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/mult_valid
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/mult_valid_round
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/mult_quarter
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/mult_quarter_round
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/mult_user
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/mult_user_round
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/mult_sat_flag
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/mult_sat_flag_round
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/x
add wave -noupdate -expand -group debug /cordic_vector_top_tb/DUT/y
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 3} {380 ns} 0} {{Cursor 4} {370 ns} 1}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {142 ns} {940 ns}
