// Created       : 2021-10-28
// ===================================================================
// 
// 
//====================================================================
//
//----------------------------------------------------------------
// Model of pixel array
// 
//----------------------------------------------------------------

module PIXEL_ARRAY
  (
   input logic VBN1,
   input logic RAMP,
   input logic RESET,
   input logic ERASE,
   input logic EXPOSE,
   input logic READ_1,
   input logic READ_2,
   inout logic[15:0] DATA_1,
   inout logic[15:0] DATA_2
   );

   
   PIXEL_SENSOR pixel_sensor1(
     .VBN1(VBN1),
     .RAMP(RAMP), 
     .RESET(RESET), 
     .ERASE(ERASE), 
     .EXPOSE(EXPOSE), 
     .READ(READ_1), 
     .DATA(DATA_1[0 +: 8])
     );

   PIXEL_SENSOR pixel_sensor2(
     .VBN1(VBN1), 
     .RAMP(RAMP), 
     .RESET(RESET), 
     .ERASE(ERASE), 
     .EXPOSE(EXPOSE), 
     .READ(READ_1), 
     .DATA(DATA_1[8 +: 8])
     );

   PIXEL_SENSOR pixel_sensor3(
     .VBN1(VBN1), 
     .RAMP(RAMP), 
     .RESET(RESET), 
     .ERASE(ERASE), 
     .EXPOSE(EXPOSE), 
     .READ(READ_2), 
     .DATA(DATA_2[7:0])
     );

   PIXEL_SENSOR pixel_sensor4(
     .VBN1(VBN1), 
     .RAMP(RAMP), 
     .RESET(RESET), 
     .ERASE(ERASE), 
     .EXPOSE(EXPOSE), 
     .READ(READ_2), 
     .DATA(DATA_2[15:8])
     );


endmodule 
