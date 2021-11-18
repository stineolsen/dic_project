// ===================================================================
//
//====================================================================


`timescale 1 ns / 1 ps

//====================================================================
// Testbench for pixelArray
// - clock
// - instanciate pixel
// - State Machine for controlling pixel sensor
// - Model the ADC and ADC
// - Readout of the databus
// - Stuff neded for testbench. Store the output file etc.
//====================================================================

module pixelArray_tb;

   //------------------------------------------------------------
   // Testbench clock
   //------------------------------------------------------------
   logic clk =0;
   logic reset =0;
   parameter integer clk_period = 500;
   parameter integer sim_end = clk_period*2400;
   always #clk_period clk=~clk;

   //------------------------------------------------------------
   // PixelArray
   //------------------------------------------------------------
   parameter real    dv_pixel = 0.5;  //Set the expected photodiode current (0-1)

   //Analog signals
   logic              anaBias1;  //VBN1 i pixelArray
   logic              anaRamp;   //RAMP i pixelArray
   logic              anaReset;  //RESET i pixelArray

   //Tie off the unused lines
   assign anaReset = 1;

   //Digital
   wire              erase;
   wire              expose;
   wire              read_1;
   wire              read_2;
   wire              convert;  

   tri[15:0]         array_data1; //  We need this to be a wire, because we're tristating it?? Må vi det på denne også?
   tri[15:0]         array_data2; //  We need this to be a wire, because we're tristating it


   //Instanciate the pixel
   PIXEL_ARRAY  #(.dv_pixel(dv_pixel))  pixel_array1(.VBN1(anaBias1), .RAMP(anaRamp), .RESET(anaReset), .ERASE(erase), .EXPOSE(expose), .READ_1(read_1), .READ_2(read_2), .DATA_1(array_data1), .DATA_2(array_data2));
   // må vi ha med .dv_pixel hvis den kun brukes i pixelsensor?? 
   
   pixelArray #(.c_erase(5),.c_expose(255),.c_convert(255),.c_read(5))
   fa1(.clk(clk),.reset(reset),.erase(erase),.expose(expose),.read_1(read_1),, .read_2(read_2), .convert(convert));




   //------------------------------------------------------------
   // State Machine
   //------------------------------------------------------------
   parameter ERASE=0, EXPOSE=1, CONVERT=2, READ_1=3, READ_2=4, IDLE=5;

   logic               convert;
   logic               convert_stop;
   logic [2:0]         state,next_state;   //States
   integer           counter;            //Delay counter in state machine

   //State duration in clock cycles
   parameter integer c_erase = 5;
   parameter integer c_expose = 255;
   parameter integer c_convert = 255;
   parameter integer c_read = 5;


always_ff @(negedge clk ) begin
      case(state)
        ERASE: begin
           erase <= 1;
           read_1 <= 0;
           read_2 <= 0;
           expose <= 0;
           convert <= 0;
        end
        EXPOSE: begin
           erase <= 0;
           read_1 <= 0;
           read_2 <= 0;
           expose <= 1;
           convert <= 0;
        end
        CONVERT: begin
           erase <= 0;
           read_1 <= 0;
           read_2 <= 0;
           expose <= 0;
           convert = 1;
        end
        READ_1: begin
           erase <= 0;
           read_1 <= 1;
           read_2 <= 0;
           expose <= 0;
           convert <= 0;
        end
        READ_2: begin
           erase <= 0;
           read_1 <= 0;
           read_2 <= 1;
           expose <= 0;
           convert <= 0;
        end
        IDLE: begin
           erase <= 0;
           read_1 <= 0;
           read_2 <= 0;
           expose <= 0;
           convert <= 0;

        end
      endcase // case (state)
   end // always @ (state)
always_ff @(posedge clk or posedge reset) begin
      if(reset) begin
         state = IDLE;
         next_state = ERASE;
         counter  = 0;
         convert  = 0;
      end
      else begin
         case (state)
           ERASE: begin
              if(counter == c_erase) begin
                 next_state <= EXPOSE;
                 state <= IDLE;
              end
           end
           EXPOSE: begin
              if(counter == c_expose) begin
                 next_state <= CONVERT;
                 state <= IDLE;
              end
           end
           CONVERT: begin
              if(counter == c_convert) begin
                 next_state <= READ_1;
                 state <= IDLE;
              end
           end
           READ_1: begin
             if(counter == c_read) begin
                state <= IDLE;
                next_state <= READ_2;
             end
           end
            READ_2: begin
             if(counter == c_read) begin
                state <= IDLE;
                next_state <= ERASE;
             end
            end
           IDLE:
             state <= next_state;
         endcase // case (state)
         if(state == IDLE)
           counter = 0;
         else
           counter = counter + 1;
      end
   end // always @ (posedge clk or posedge reset)


   //------------------------------------------------------------
   // DAC and ADC model
   //------------------------------------------------------------
   logic[15:0] data_1;
   logic[15:0] data_2;

   // If we are to convert, then provide a clock via anaRamp
   // This does not model the real world behavior, as anaRamp would be a voltage from the ADC
   // however, we cheat
   assign anaRamp = convert ? clk : 0;

   // During expoure, provide a clock via anaBias1.
   // Again, no resemblence to real world, but we cheat.
   assign anaBias1 = expose ? clk : 0;

   // If we're not reading the pixData, then we should drive the bus
   assign array_data1 = read ? 16'bZ: data_1;
   assign array_data2 = read ? 16'bZ: data_2;


   // When convert, then run a analog ramp (via anaRamp clock) and digtal ramp via
   // data bus. Assert convert_stop to return control to main state machine.
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

        $dumpfile("pixelArray_tb.vcd");
        $dumpvars(0,pixelArray_tb);

        #sim_end
          $stop;


     end

endmodule // test
