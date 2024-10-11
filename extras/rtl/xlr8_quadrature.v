/////////////////////////////////
// Filename    : xlr8_quadrature.v
// Author      : 
// Description : A collection of quadrature channels (up to 32) and the
//                AVR IO registers needed to access them.
//                Each QE Separately enabled/disabled).
//                3 Registers
//                  ControlRegister : 
//                        [7]   = enable channel (write, read returns enable with/of selected channel)
//                        [6]   = disable channel (strobe, always read as zero)
//                        [5]   = update channel zero count and rate (always read as zero). or x4 bit
//                        [4]   = sample rate. or x2 bit
//                        [3:0] = quadrature channel to enable/disable/update
//                  AngleLL :  [7:0]= lower        8 bits of quadrature count
//                  AngleML :  [7:0]= low middle   8 bits of quadrature count
//                  AngleMH :  [7:0]= upper middle 8 bits of quadrature count
//                  AngleHH :  [7:0]= upper        8 bits of quadrature count
//                  RateLL  :  [7:0]= lower        8 bits of quadrature rate
//                  RateML  :  [7:0]= low middle   8 bits of quadrature rate
//                  RateMH  :  [7:0]= upper middle 8 bits of quadrature rate
//                  RateHH  :  [7:0]= upper        8 bits of quadrature rate
//
//                   To start a channel typically the channel is reset
//                    first, then the control register with the desired channel indicated and
//                    both the enable and update bits set
//
// Copyright 2017, Superion Technology Group. All Rights Reserved
/////////////////////////////////

module xlr8_quadrature
 #(parameter NUM_QUADRATURES = 4,
   parameter QECR_ADDR  = 6'h0,  // quadrature control register
   parameter QECNT2_ADDR = 6'h0, // quadrature count mid high
   parameter QECNT1_ADDR = 6'h0, // quadrature count mid low
   parameter QECNT0_ADDR = 6'h0, // quadrature count low
   parameter QERAT1_ADDR = 6'h0, // quadrature rate high
   parameter QERAT0_ADDR = 6'h0) // quadrature rate low
  (input logic clk,
  input logic                   en1mhz, // clock enable at 1MHz rate
  input logic                   rstn,
  // Register access for registers in first 64
  input [5:0]                   adr,
  input [7:0]                   dbus_in,
  output [7:0]                  dbus_out,
  input                         iore,
  input                         iowe,
  output wire                   io_out_en,
  // Register access for registers not in first 64
  input wire [7:0]              ramadr,
  input wire                    ramre,
  input wire                    ramwe,
  input wire                    dm_sel,
  // External inputs/outputs
  output logic [NUM_QUADRATURES-1:0]  quadratures_en,
  input logic [NUM_QUADRATURES-1:0] quad_in_a,
  input logic [NUM_QUADRATURES-1:0] quad_in_b
  );

  /////////////////////////////////
  // Local Parameters
  /////////////////////////////////
  localparam NUM_TIMERS = (NUM_QUADRATURES <= 16) ? NUM_QUADRATURES : 16;
  // Registers in I/O address range x0-x3F (memory addresses -x20-0x5F)
  //  use the adr/iore/iowe inputs. Registers in the extended address
  //  range (memory address 0x60 and above) use ramadr/ramre/ramwe
  localparam  QECR_DM_LOC     = (QECR_ADDR >= 16'h60) ? 1 : 0;
  localparam  QECNT2_DM_LOC   = (QECNT2_ADDR >= 16'h60) ? 1 : 0;
  localparam  QECNT1_DM_LOC   = (QECNT1_ADDR >= 16'h60) ? 1 : 0;
  localparam  QECNT0_DM_LOC   = (QECNT0_ADDR >= 16'h60) ? 1 : 0;
  localparam  QERAT1_DM_LOC   = (QERAT1_ADDR >= 16'h60) ? 1 : 0;
  localparam  QERAT0_DM_LOC   = (QERAT0_ADDR >= 16'h60) ? 1 : 0;

  localparam QEEN_BIT   = 7;
  localparam QEDIS_BIT  = 6;
  localparam QEUP_BIT   = 5;
  localparam QESAMPLE_BIT = 4;
  localparam QECHAN_LSB = 0;    

  /////////////////////////////////
  // Signals
  /////////////////////////////////
  /*AUTOREG*/
  /*AUTOWIRE*/ 
  logic qecr_sel;
  logic qecnt2_sel;
  logic qecnt1_sel;
  logic qecnt0_sel;
  logic qerat1_sel;
  logic qerat0_sel;
  logic qecr_we ;
  logic qecnt2_we ;
  logic qecnt1_we ;
  logic qecnt0_we ;
  logic qerat1_we ;
  logic qerat0_we ;
  logic qecr_re ;
  logic qecnt2_re ;
  logic qecnt1_re ;
  logic qecnt0_re ;
  logic qerat1_re ;
  logic qerat0_re ;
  logic [7:0] qecr_rdata;
  logic [7:0] qecnt2_rdata;
  logic [7:0] qecnt1_rdata;
  logic [7:0] qecnt0_rdata;
  logic [7:0] qerat1_rdata;
  logic [7:0] qerat0_rdata;
  logic       QEEN;
  logic [3:0] QECHAN;
  logic       QESAMPLE;
  logic [3:0] chan_in;
  logic [15:0] rat_count [NUM_QUADRATURES-1:0]; // Used to measure angular velocity. Ticks/Time
  logic [23:0] chan_cnt [NUM_QUADRATURES-1:0]; // quadrature count per channel
  logic [23:0] chan_cnt_r [NUM_QUADRATURES-1:0]; // quadrature count per channel shadow read register
  logic [15:0] chan_rat [NUM_QUADRATURES-1:0]; // quadrature rate per channel
  logic [NUM_QUADRATURES-1:0] sync_in_A;
  logic [NUM_QUADRATURES-1:0] sync_in_B;
  logic [NUM_QUADRATURES-1:0] sync_in_A_2;
  logic [NUM_QUADRATURES-1:0] sync_in_B_2;
  logic [NUM_QUADRATURES-1:0] load_en;
  logic [NUM_QUADRATURES-1:0] a_r;
  logic [NUM_QUADRATURES-1:0] a_f;
  logic [NUM_QUADRATURES-1:0] a_h;
  logic [NUM_QUADRATURES-1:0] a_l;
  logic [NUM_QUADRATURES-1:0] b_r;
  logic [NUM_QUADRATURES-1:0] b_f;
  logic [NUM_QUADRATURES-1:0] b_h;
  logic [NUM_QUADRATURES-1:0] b_l;
  reg [NUM_QUADRATURES-1:0] up;
  reg [NUM_QUADRATURES-1:0] dn;
  logic [NUM_QUADRATURES-1:0] x2;
  logic [NUM_QUADRATURES-1:0] x4;
  logic [14:0] timercnt_20; // 20ms  counter
  logic [4:0]  timercnt_200;// 200ms counter
  logic sample_20;          // 20ms  pulse
  logic sample_200;         // 200ms pulse
  logic [NUM_QUADRATURES-1:0]  sample_20_select; // select 20ms instead 200ms smpling rate
  logic [1:0] state;
  logic hold_rate;
  logic hold_count;
  logic read_rate;
  logic read_count;

  /////////////////////////////////
  // Functions and Tasks
  /////////////////////////////////

  /////////////////////////////////
  // Main Code
  /////////////////////////////////

  assign qecr_sel   = QECR_DM_LOC   ?  (dm_sel && ramadr == QECR_ADDR )   : (adr[5:0] == QECR_ADDR[5:0] ); 
  assign qecnt2_sel = QECNT2_DM_LOC ?  (dm_sel && ramadr == QECNT2_ADDR ) : (adr[5:0] == QECNT2_ADDR[5:0] );
  assign qecnt1_sel = QECNT1_DM_LOC ?  (dm_sel && ramadr == QECNT1_ADDR ) : (adr[5:0] == QECNT1_ADDR[5:0] );
  assign qecnt0_sel = QECNT0_DM_LOC ?  (dm_sel && ramadr == QECNT0_ADDR ) : (adr[5:0] == QECNT0_ADDR[5:0] );
  assign qerat1_sel = QERAT1_DM_LOC ?  (dm_sel && ramadr == QERAT1_ADDR ) : (adr[5:0] == QERAT1_ADDR[5:0] );
  assign qerat0_sel = QERAT0_DM_LOC ?  (dm_sel && ramadr == QERAT0_ADDR ) : (adr[5:0] == QERAT0_ADDR[5:0] );
  assign qecr_we    = qecr_sel   && (QECR_DM_LOC   ?  ramwe : iowe); 
  assign qecnt2_we  = qecnt2_sel && (QECNT2_DM_LOC ?  ramwe : iowe); 
  assign qecnt1_we  = qecnt1_sel && (QECNT1_DM_LOC ?  ramwe : iowe);
  assign qecnt0_we  = qecnt0_sel && (QECNT0_DM_LOC ?  ramwe : iowe); 
  assign qerat1_we  = qerat1_sel && (QERAT1_DM_LOC ?  ramwe : iowe);
  assign qerat0_we  = qerat0_sel && (QERAT0_DM_LOC ?  ramwe : iowe); 
  assign qecr_re    = qecr_sel   && (QECR_DM_LOC   ?  ramre : iore); 
  assign qecnt2_re  = qecnt2_sel && (QECNT2_DM_LOC ?  ramre : iore); 
  assign qecnt1_re  = qecnt1_sel && (QECNT1_DM_LOC ?  ramre : iore);
  assign qecnt0_re  = qecnt0_sel && (QECNT0_DM_LOC ?  ramre : iore); 
  assign qerat1_re  = qerat1_sel && (QERAT1_DM_LOC ?  ramre : iore);
  assign qerat0_re  = qerat0_sel && (QERAT0_DM_LOC ?  ramre : iore); 

  assign dbus_out =  ({8{qecr_sel}}   & qecr_rdata) |
                     ({8{qecnt2_sel}} & qecnt2_rdata) | 
                     ({8{qecnt1_sel}} & qecnt1_rdata) | 
                     ({8{qecnt0_sel}} & qecnt0_rdata) | 
                     ({8{qerat1_sel}} & qerat1_rdata) | 
                     ({8{qerat0_sel}} & qerat0_rdata); 
  assign io_out_en = qecr_re   || 
                     qecnt2_re || 
                     qecnt1_re ||
                     qecnt0_re || 
                     qerat1_re ||
                     qerat0_re; 

   // Control Register
  assign chan_in = dbus_in[QECHAN_LSB +: 4];
  always @(posedge clk or negedge rstn)
    begin
      if (!rstn)
        begin
          QEEN   <= 1'b0;
          QESAMPLE   <= 1'b0;
          QECHAN <= 4'h0;
          quadratures_en <= {NUM_QUADRATURES{1'b0}};
          sample_20_select <= {NUM_QUADRATURES{1'b0}};
          x2 <= {NUM_QUADRATURES{1'b0}};
          x4 <= {NUM_QUADRATURES{1'b0}};
        end
      else if (qecr_we)
        begin
          if (dbus_in[QEEN_BIT] && dbus_in[QEDIS_BIT])   // Overload function x2 x4 modes
            begin
              x2[chan_in] <= dbus_in[QESAMPLE_BIT];
              x4[chan_in] <= dbus_in[QEUP_BIT];
            end
          else
            begin
              // Or in the enable and sample bit from the host if the disable is not set
              QEEN     <= dbus_in[QEEN_BIT]       ||   (quadratures_en[chan_in]   && ~dbus_in[QEDIS_BIT]);
              QESAMPLE <= dbus_in[QESAMPLE_BIT]   ||   (sample_20_select[chan_in] && ~dbus_in[QEDIS_BIT]);
              // Select the QE to be enables or disabled
              QECHAN <= chan_in;
              quadratures_en[chan_in]   <= dbus_in[QEEN_BIT]      ||   (quadratures_en[chan_in]   && ~dbus_in[QEDIS_BIT]);
              sample_20_select[chan_in] <= dbus_in[QESAMPLE_BIT]  ||   (sample_20_select[chan_in] && ~dbus_in[QEDIS_BIT]);
            end
        end
      else
        begin
          QEEN <= quadratures_en[QECHAN];
          QESAMPLE <= sample_20_select[QECHAN];
        end
    end // always @ (posedge clk or negedge rstn)


  // Read control reg
  assign qecr_rdata = ({7'h0,QEEN}   << QEEN_BIT) |
                      ({7'h0,QESAMPLE} << QESAMPLE_BIT) |
                      ({4'h0,QECHAN} << QECHAN_LSB);

  assign qecnt2_rdata = chan_cnt_r[QECHAN][23:16];
  assign qecnt1_rdata = chan_cnt_r[QECHAN][15:8];
  assign qecnt0_rdata = chan_cnt_r[QECHAN][7:0];

  assign qerat1_rdata = chan_rat[QECHAN][15:8];
  assign qerat0_rdata = chan_rat[QECHAN][7:0];


  assign load_en = ((dbus_in[QEUP_BIT] && qecr_we) << chan_in);

  always @(posedge clk or negedge rstn)
    begin
      if (!rstn)
        begin
          /*AUTORESET*/
          // Beginning of autoreset for uninitialized flops
          timercnt_20 <= 15'd0;
          sample_20 <= 1'b0;
          // End of automatics
        end
      else if (en1mhz && |quadratures_en)
        begin
          // it takes 20000 cycles of 1MHz to get 20ms
          if (timercnt_20 == 15'd19999)
            begin
              timercnt_20 <= 15'd0;
              sample_20 <= 1'b1;
            end
          else
            begin
              timercnt_20 <= timercnt_20 + 15'd1;
            end
        end
      else
        begin
              sample_20 <= 1'b0;
        end
    end

  always @(posedge clk or negedge rstn)
    begin
      if (!rstn)
        begin
          /*AUTORESET*/
          // Beginning of autoreset for uninitialized flops
          timercnt_200 <= 4'd0;
          sample_200 <= 1'b0;
          // End of automatics
        end
      else if (sample_20 && |quadratures_en)
        begin
          // it takes 10 cycles of the 20ms time to get 200ms
          if (timercnt_200 == 4'd9)
            begin
              timercnt_200 <= 4'd0;
              sample_200 <= 1'b1;
            end
          else
            begin
              timercnt_200 <= timercnt_200 + 4'd1;
            end
        end
      else
        begin
              sample_200 <= 1'b0;
        end
    end


  // quadrature input synchronizers
  genvar ii;
  generate
    for (ii=0;ii<NUM_QUADRATURES;ii++) begin : gen_sync
      always @(posedge clk or negedge rstn) begin
        if (!rstn)
          begin
            sync_in_A[ii] <= 1'b0;
            sync_in_B[ii] <= 1'b0;
            sync_in_A_2[ii] <= 1'b0;
            sync_in_B_2[ii] <= 1'b0;
          end
        else
          begin
            sync_in_A[ii]   <= quad_in_a[ii];
            sync_in_B[ii]   <= quad_in_b[ii];
            sync_in_A_2[ii] <= sync_in_A[ii];
            sync_in_B_2[ii] <= sync_in_B[ii];
          end
      end // always @ (posedge clk or negedge rstn)
    end // for
  endgenerate // block: gen_sync

  // Edge detection
  generate
    for (ii=0;ii<NUM_QUADRATURES;ii++) begin : gen_edge
      assign a_r[ii] =  sync_in_A[ii] == 1'b1 && sync_in_A_2[ii] == 1'b0;
      assign a_f[ii] =  sync_in_A[ii] == 1'b0 && sync_in_A_2[ii] == 1'b1;
      assign b_r[ii] =  sync_in_B[ii] == 1'b1 && sync_in_B_2[ii] == 1'b0;
      assign b_f[ii] =  sync_in_B[ii] == 1'b0 && sync_in_B_2[ii] == 1'b1;
      assign a_h[ii] =  sync_in_A[ii] == 1'b1;
      assign a_l[ii] =  sync_in_A[ii] == 1'b0;
      assign b_h[ii] =  sync_in_B[ii] == 1'b1;
      assign b_l[ii] =  sync_in_B[ii] == 1'b0;
    end // for
  endgenerate // block: gen_edge

//    ----    ----    ----    ----    ----    ----
//    A   ----    ----    ----    ----    ----


//    B     ----    ----    ----    ----    ----
//      ----    ----    ----    ----    ----    ----

  generate
    for (ii=0;ii<NUM_QUADRATURES;ii++) begin : gen_count_mode
      always @(*)
        begin
          up[ii] = 1'b0;
          dn[ii] = 1'b0;
          if (a_r[ii] && b_h[ii])                       // a rising, b high   x1 x2 x4
            begin
              up[ii] = 1'b1;
            end
          if (b_f[ii] && a_h[ii] && x4[ii])             // b falling, a high        x4
            begin
              up[ii] = 1'b1;
            end
          if (a_f[ii] && b_l[ii] && (x2[ii] || x4[ii])) // a falling, b low      x2 x4
            begin
              up[ii] = 1'b1;
            end
          if (b_r[ii] && a_l[ii] && x4[ii])             // b rising, a low          x4
            begin
              up[ii] = 1'b1;
            end

          if (a_r[ii] && b_l[ii])                       // a rising, b low    x1 x2 x4
            begin
              dn[ii] = 1'b1;
            end
          if (b_f[ii] && a_l[ii] && x4[ii])             // b falling, a low         x4
            begin
              dn[ii] = 1'b1;
            end
          if (a_f[ii] && b_h[ii] && (x2[ii] || x4[ii])) // a falling, b high     x2 x4
            begin
              dn[ii] = 1'b1;
            end
          if (b_r[ii] && a_h[ii] && x4[ii])             // b rising, a high         x4
            begin
              dn[ii] = 1'b1;
            end
        end
    end
  endgenerate

  // Angular Speed
  generate
  for (ii=0;ii<NUM_QUADRATURES;ii++) begin : gen_tim
    always @(posedge clk or negedge rstn) begin
      if (!rstn)
        begin
          rat_count[ii] <= 16'h0;
          chan_rat[ii] <= 16'b0;
        end
      else if (load_en[ii])
        begin
          // chan_rat[ii] <= 16'b0;
          // rat_count[ii] <= 16'h0;
        end
      else if (quadratures_en[ii])
        begin
          if((sample_20 && sample_20_select[ii]) || (sample_200 && !sample_20_select[ii]))
            begin
              if (!hold_rate)
                chan_rat[ii] <= rat_count[ii];
              rat_count[ii] <= 16'h0;
            end
          else
            begin
              rat_count[ii] <= (rat_count[ii]);
              if (up[ii])
                begin
                  rat_count[ii] <= (rat_count[ii] + 16'd1);
                end
              if (dn[ii])
                begin
                  rat_count[ii] <= (rat_count[ii] - 16'd1);
                end
            end
        end
      else
        begin
          rat_count[ii] <= (rat_count[ii]);
          chan_rat[ii] <= chan_rat[ii];
        end
    end //always
  end // for
  endgenerate


  // POSITION Counting
  generate
    for (ii=0;ii<NUM_QUADRATURES;ii++) begin : gen_chan
      always @(posedge clk or negedge rstn) begin
        if (!rstn)
          begin
            chan_cnt[ii] <= 24'b0;
            chan_cnt_r[ii] <= 24'b0;
          end
        else
          begin
            if (!hold_count)
              chan_cnt_r[ii] <= chan_cnt[ii];
            if (load_en[ii])
              begin
                chan_cnt[ii] <= 24'b0;
                chan_cnt_r[ii] <= 24'b0;
              end
            else if (quadratures_en[ii])
              begin
                chan_cnt[ii] <= chan_cnt[ii];
                if (up[ii])
                  chan_cnt[ii] <= chan_cnt[ii] + 24'b1;
                if (dn[ii])
                  chan_cnt[ii] <= chan_cnt[ii] - 24'b1;
              end
            else
              chan_cnt[ii] <= chan_cnt[ii];
          end
      end // always @ (posedge clk or negedge rstn)
    end // for
  endgenerate // block: gen_chan



  // State machine to detect a 2 or 3 byte host read of rates or counts.
  assign read_count =  qecnt2_re || qecnt1_re || qecnt0_re;
  assign read_rate  =  qerat1_re || qerat0_re;

  localparam IDLE     = 2'b00;
  localparam ONE_READ = 2'b01;
  localparam TWO_READ = 2'b10;
  always @(posedge clk or negedge rstn)
    begin
      if (!rstn)
        begin
          state <= IDLE;
          hold_rate <= 1'b0;
          hold_count <= 1'b0;
        end
      else
        begin
          state <= state;
          hold_rate <= hold_rate;
          hold_count <= hold_count;
          case (state)
            IDLE:
              begin
                if (read_rate || read_count)
                  begin
                    state <= ONE_READ;
                    if (read_rate)
                      hold_rate <= 1'b1;
                    else
                      hold_count <= 1'b1;
                  end
                else
                  begin
                    state <= IDLE;
                    hold_rate <= 1'b0;
                    hold_count <= 1'b0;
                  end
              end
            ONE_READ:
              begin
                if (qecr_we)
                  begin
                    state <= IDLE;
                    hold_rate <= 1'b0;
                    hold_count <= 1'b0;
                  end
                else if (hold_rate && read_rate)
                  begin
                    state <= IDLE;
                    hold_rate <= 1'b0;
                    hold_count <= 1'b0;
                  end
                else if (hold_count && read_count)
                  begin
                    state <= TWO_READ;
                    hold_count <= 1'b1;
                    hold_rate <= 1'b0;
                  end
                else
                  begin
                    state <= ONE_READ;
                  end
              end
            TWO_READ:
              begin
                if (qecr_we)
                  begin
                    state <= IDLE;
                    hold_rate <= 1'b0;
                    hold_count <= 1'b0;
                  end
                else if (hold_count && read_count)
                  begin
                    state <= IDLE;
                    hold_count <= 1'b0;
                    hold_rate <= 1'b0;
                  end
                else
                  begin
                    state <= TWO_READ;
                  end
              end
          endcase
        end
    end

  
   /////////////////////////////////
   // Assertions
   /////////////////////////////////


   /////////////////////////////////
   // Cover Points
   /////////////////////////////////

`ifdef SUP_COVER_ON
`endif

endmodule

