`timescale 1ns / 1ps

module stopwatch(
  input        clk100_i,
  input        rstn_i,
  input        start_stop_i,
  input        set_i,
  input        change_i,
  output [6:0] hex0_o,
  output [6:0] hex1_o,
  output [6:0] hex2_o,
  output [6:0] hex3_o
);
  localparam STATE_DEFAULT = 3'd0;
  localparam STATE_1       = 3'd1;
  localparam STATE_2       = 3'd2;
  localparam STATE_3       = 3'd3;
  localparam STATE_4       = 3'd4;
  localparam PULSE_MAX     = 18'd259999;
  localparam COUNTER_MAX   = 4'd9;
  reg [2:0] state = STATE_DEFAULT;
  reg [2:0] next_state;
  reg       device_running = 1'd0;
  wire      btn_change_was_pressed;
  wire      btn_set_was_pressed;
  wire      btn_start_stop_was_pressed;
button start_stop(
  .in                 ( start_stop_i ),
  .rstn               ( rstn_i ),
  .clk                ( clk100_i ),
  .button_was_pressed ( btn_start_stop_was_pressed )
);
button set(
  .in                 ( set_i ),
  .rstn               ( rstn_i ),
  .clk                ( clk100_i ),
  .button_was_pressed ( btn_set_was_pressed )
); 
button change(
  .in                 ( change_i ),
  .rstn               ( rstn_i ),
  .clk                ( clk100_i ),
  .button_was_pressed ( btn_change_was_pressed )
); 
always @( posedge clk100_i )
begin
  if ( btn_start_stop_was_pressed && state == STATE_DEFAULT ) 
    device_running <= ~device_running;
end
reg [17:0] pulse_counter = 18'd0;
wire       hundredth_of_second_passed = ( pulse_counter == PULSE_MAX );
always @( posedge clk100_i or negedge rstn_i ) begin
  if ( !rstn_i ) pulse_counter <= 0;
  else 
    if ( device_running | hundredth_of_second_passed )
      if ( hundredth_of_second_passed ) pulse_counter <= 0;
      else pulse_counter <= pulse_counter + 1;
end
reg [3:0] hundredths_counter     = 4'd0;
wire      tenth_of_second_passed = ( ( hundredths_counter == COUNTER_MAX ) & hundredth_of_second_passed );
always @( posedge clk100_i or negedge rstn_i ) begin
  if ( !rstn_i ) hundredths_counter <= 0;
  else if ( hundredth_of_second_passed )
         if ( tenth_of_second_passed ) hundredths_counter <= 0;
       else hundredths_counter <= hundredths_counter + 1;
end
reg [3:0] tenths_counter = 0;
wire      second_passed  = ( ( tenths_counter == COUNTER_MAX ) & tenth_of_second_passed );

always @( posedge clk100_i or negedge rstn_i ) begin
  if ( !rstn_i ) tenths_counter <= 0;
  else if ( tenth_of_second_passed )
         if ( second_passed ) tenths_counter <= 0;
       else tenths_counter <= tenths_counter + 1;
end

reg  [3:0] seconds_counter    = 4'd0;
wire       ten_seconds_passed = ( ( seconds_counter == COUNTER_MAX ) & second_passed );
always @( posedge clk100_i or negedge rstn_i ) begin
  if ( !rstn_i ) seconds_counter <= 0;
  else if ( second_passed )
         if ( ten_seconds_passed ) seconds_counter <= 0;
       else seconds_counter <= seconds_counter + 1;
end

reg [3:0] ten_seconds_counter = 4'd0;
always @( posedge clk100_i or negedge rstn_i ) begin
  if ( !rstn_i ) ten_seconds_counter <= 0;
  else if ( ten_seconds_passed )
          if ( ten_seconds_counter == COUNTER_MAX ) ten_seconds_counter <= 0;
       else ten_seconds_counter <= ten_seconds_counter + 1;
end
always @(*) 
   begin
     case ( state )
       STATE_DEFAULT : if ( ( !device_running ) & ( btn_set_was_pressed ) ) begin
                         next_state = STATE_1;
                       end
                       else begin
                         next_state = STATE_DEFAULT;
                       end

       STATE_1 :       if ( btn_set_was_pressed ) begin
                         next_state = STATE_2;
                       end
                       else 
                         if ( btn_change_was_pressed ) begin
                           if ( hundredths_counter == COUNTER_MAX ) begin
                             hundredths_counter = 0;
                           end
                           else begin
                            hundredths_counter  = hundredths_counter + 1;
                            next_state          = STATE_1;
                           end
                         end
                         else begin
                           next_state = STATE_1;
                         end

       STATE_2 :       if ( btn_set_was_pressed ) begin
                         next_state = STATE_3;
                       end
                       else 
                         if ( btn_change_was_pressed ) begin
                           if ( tenths_counter == COUNTER_MAX ) begin
                             tenths_counter = 0;
                           end
                           else begin
                            tenths_counter = tenths_counter + 1;
                            next_state     = STATE_2;
                           end
                         end
                         else begin
                           next_state = STATE_2;
                         end

       STATE_3 :       if ( btn_set_was_pressed ) begin
                         next_state = STATE_4;
                       end
                       else 
                         if ( btn_change_was_pressed ) begin
                           if ( seconds_counter == COUNTER_MAX ) begin
                             seconds_counter      = 0;
                           end
                           else begin
                             seconds_counter      = seconds_counter + 1;
                             next_state           = STATE_3;
                           end
                         end
                         else begin
                           next_state  = STATE_3;
                         end

       STATE_4 :       if ( btn_set_was_pressed ) begin
                         next_state = STATE_DEFAULT;
                       end
                       else 
                         if ( btn_change_was_pressed ) begin
                           if ( ten_seconds_counter == COUNTER_MAX ) begin
                             ten_seconds_counter  = 0;
                           end
                           else begin
                             ten_seconds_counter = seconds_counter + 1;
                             ten_seconds_counter = STATE_4;
                           end
                         end
                         else begin
                           next_state = STATE_4;
                         end 

       default : next_state = STATE_DEFAULT;
     endcase
   end 

always @( posedge clk100_i or negedge rstn_i )
  begin
   if ( !rstn_i )
     state <= STATE_DEFAULT;
   else
     state <= next_state;
end
hex dec0(
  .in  ( hundredths_counter ),
  .out ( hex0_o             ) 
);
hex dec1(
  .in  ( tenths_counter ),
  .out ( hex1_o         ) 
);
hex dec2(
  .in  ( seconds_counter ),
  .out ( hex2_o          ) 
);
hex dec3(
  .in  ( seconds_counter ),
  .out ( hex3_o          ) 
);
endmodule
