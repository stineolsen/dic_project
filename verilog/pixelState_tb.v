//====================================================================
//        Copyright (c) 2021 Carsten Wulff Software, Norway
// ===================================================================
// Created       : wulff at 2021-7-21
// ===================================================================
//  The MIT License (MIT)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
//====================================================================


`timescale 1 ns / 1 ps

//====================================================================
// Testbench for pixelSensor
// - clock
// - instanciate pixel
// - State Machine for controlling pixel sensor
// - Model the ADC and ADC
// - Readout of the databus
// - Stuff neded for testbench. Store the output file etc.
//====================================================================
module pixelState_tb;

   //------------------------------------------------------------
   // Testbench clock
   //------------------------------------------------------------
   logic clk =0;
   logic reset =0;
   parameter integer clk_period = 500;
   parameter integer sim_end = clk_period*2400;
   always #clk_period clk=~clk;

   //------------------------------------------------------------
   // Pixel
   //------------------------------------------------------------
   parameter real    dv_pixel = 0.5;  //Set the expected photodiode current (0-1)

   //Analog signals
   logic              anaBias1;
   logic              anaRamp;
   logic              anaReset;

   //Tie off the unused lines
   assign anaReset = 1;

   //Digital
   wire              erase;
   wire              expose;
   wire             read_1;
   wire             read_2;
   wire             convert;

   tri [15:0]   pixdata1;
   tri [15:0]   pixdata2; 


   //Instanciate the pixel
   PIXEL_ARRAY   pa1(.VBN1(anaBias1), .RAMP(anaRamp), .RESET(anaReset), .ERASE(erase),.EXPOSE(expose),
    .READ_1(read_1), .READ_2(read_2), .DATA_1(pixdata1), .DATA_2(pixdata2));

   pixelState #(.c_erase(5),.c_expose(255),.c_convert(255),.c_read(5))
   fsm1(.clk(clk),.reset(reset),.erase(erase),.expose(expose),.read_1(read_1), .read_2(read_2), .convert(convert));


   //------------------------------------------------------------
   // DAC and ADC model
   //------------------------------------------------------------
   logic [15:0] data_1;
   logic [15:0] data_2;

   // If we are to convert, then provide a clock via anaRamp
   // This does not model the real world behavior, as anaRamp would be a voltage from the ADC
   // however, we cheat
   assign anaRamp = convert ? clk : 0;

   // During expoure, provide a clock via anaBias1.
   // Again, no resemblence to real world, but we cheat.
   assign anaBias1 = expose ? clk : 0;

   // If we're not reading the pixData, then we should drive the bus
   assign pixdata1 = read_1 ? 16'bz: data_1;
   assign pixdata2 = read_2 ? 16'bz: data_2;
 
   // When convert, then run a analog ramp (via anaRamp clock) and digtal ramp via
   // data bus.
   always_ff @(posedge clk or posedge reset) begin
      if(reset) begin
         data_1 =0;
         data_2 =0;

      end
      if(convert) begin
         data_1 +=  257;
         data_2 += 257;

      end
      else begin
         data_1 = 0;
         data_2 = 0;

      end
   end // always @ (posedge clk or reset)

   //------------------------------------------------------------
   // Readout from databus
   //------------------------------------------------------------
   logic [31:0] pixelDataOut;
   always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
         pixelDataOut = 0;
      end
    else begin
        if(read_1)
           pixelDataOut[15:0] <= pixdata1;
    else begin
        if(read_2)
            pixelDataOut[31:16] <= pixdata2;
        end
      end
   end

   //------------------------------------------------------------
   // Testbench stuff
   //------------------------------------------------------------
   initial
     begin
        reset = 1;

        #clk_period  reset=0;

        $dumpfile("pixelState_tb.vcd");
        $dumpvars(0,pixelState_tb);

        #sim_end
          $stop;

     end

endmodule // test
