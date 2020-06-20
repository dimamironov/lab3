`timescale 1ns / 1ps

module button(
  input in,
  input clk,
  input rstn,
  output button_was_pressed
);
  reg [1:0] button_syncroniser;
  always @( posedge clk or negedge rstn ) begin
    if ( !rstn )
      button_syncroniser    <= 0;
    else begin
      button_syncroniser[0] <= ~in;
      button_syncroniser[1] <= button_syncroniser[0]; 
    end
  end
  assign button_was_pressed = ~button_syncroniser[1] & button_syncroniser[0];
endmodule
