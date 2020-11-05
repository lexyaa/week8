//practice

//hms_cnt
module hms_cnt(
               o_hms_cnt,
               o_max_hit,
               i_max_cnt,
               clk,
               rst_n          );

output [5:0]   o_hms_cnt       ;
output         o_max_hit       ;

input  [5:0]   i_max_cnt       ;
input          clk             ;
input          rst_n           ;

reg    [5:0]   o_hms_cnt       ;
reg            o_max_hit       ;

always @(posedge clk or negedge rst_n) begin
       if(rst_n == 1'b0) begin
                o_hms_cnt <= 6'd0;
                o_max_hit <= 1'b0;
       end else begin
                if(o_hms_cnt >= i_max_cnt) begin
                          o_hms_cnt <= 6'd0;
                          o_max_hit <= 1'b1;
                end else begin
                          o_hms_cnt <= o_hms_cnt + 1'b1;
                          o_max_hit <= 1'b0;
                end
       end
end
endmodule

//minsec
module minsec( o_sec,
               o_min,
               o_max_hit_sec,
               o_max_hit_min,
               o_alarm,
               i_sec_clk,
               i_min_clk,
               i_alarm_en,
               i_alarm_sec_clk,
               i_alarm_min_clk,
               i_position,
               i_mode,
               clk,
               rst_n          );

output [5:0]   o_sec           ;
output [5:0]   o_min           ;
output         o_max_hit_sec   ;
output         o_max_hit_min   ;
output         o_alarm         ;

input          i_sec_clk       ;
input          i_min_clk       ;
input          i_alarm_en      ;
input          i_alarm_sec_clk ;
input          i_alarm_min_clk ;
input          i_position      ;
input  [1:0]   i_mode          ;

input          clk             ;
input          rst_n           ;

parameter      MODE_CLOCK = 2'b00 ;
parameter      MODE_SETUP = 2'b01 ;
parameter      MODE_ALARM = 2'b10 ;
parameter      POS_SEC    = 1'b0  ;
parameter      POS_MIN    = 1'b1  ;

 //MODE_CLOCK
wire   [5:0]   sec             ;
hms_cnt        u_hms_cnt_sec(
               .o_hms_cnt    ( sec             ),
               .o_max_hit    ( o_max_hit_sec   ),
               .i_max_cnt    ( 6'd59           ),
               .clk          ( i_sec_clk       ),
               .rst_n        ( rst_n           ));

wire   [5:0]   min             ;
hms_cnt        u_hms_cnt_min(
               .o_hms_cnt    ( min             ),
               .o_max_hit    ( o_max_hit_min   ),
               .i_max_cnt    ( 6'd59           ),
               .clk          ( i_min_clk       ),
               .rst_n        ( rst_n           ));

 //MODE_ALARM
wire   [5:0]   alarm_sec       ;
hms_cnt        u_hms_cnt_alarm_sec(
               .o_hms_cnt    ( alarm_sec       ),
               .o_max_hit    (                 ),
               .i_max_cnt    ( 6'd59           ),
               .clk          ( i_alarm_sec_clk ),
               .rst_n        ( rst_n           ));

wire   [5:0]   alarm_min       ;
hms_cnt        u_hms_cnt_alarm_min(
               .o_hms_cnt    ( alarm_min       ),
               .o_max_hit    (                 ),
               .i_max_cnt    ( 6'd59           ),
               .clk          ( i_alarm_min_clk ),
               .rst_n        ( rst_n           ));
 //MUX
reg    [5:0]   o_sec        ;
reg    [5:0]   o_min        ;
always @(*) begin
   case(i_mode)
       MODE_CLOCK:     begin
           o_sec = sec;
           o_min = min;
       end
       MODE_SETUP:     begin
           o_sec = sec;
           o_min = min;
       end
       MODE_ALARM:     begin
           o_sec = alarm_sec;
           o_min = alarm_min;
       end
   endcase
end

 //Alarm
wire            clk_1hz   ;
nco             u1_nco(
                .clk_gen  ( clk_1hz      ),
                .num      ( 32'd50000000 ),
                .clk      ( clk          ),
                .rst_n    ( rst_n        ));

reg     [3:0]   alarm_cnt ;
always @(posedge clk_1hz or negedge rst_n) begin
    if(rst_n == 1'b0) begin
       alarm_cnt = 0;
    end else begin
       if(o_alarm == 1'b1) begin
          alarm_cnt = alarm_cnt + 1;
       end else begin
          alarm_cnt = 0;
       end
    end
end

reg             o_alarm   ;
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
       o_alarm <= 1'b0;
    end else begin
       if((sec == alarm_sec && min == alarm_min)) begin
          o_alarm <= 1'b1 & i_alarm_en;
       end else begin
          if(alarm_cnt >= 4'd10) begin
            o_alarm <= 1'b0;
          end else begin
            o_alarm <= o_alarm & i_alarm_en;
          end
       end
    end
end

endmodule

// Numerical Controlled Oscillator
module nco(     clk_gen,
                num,
                clk,
                rst_n    );

output          clk_gen   ;
input  [31:0]   num       ;
input           clk       ;
input           rst_n     ;

reg    [31:0]   cnt       ;
reg             clk_gen   ;
always @(posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
                 cnt      <= 32'd0;
                 clk_gen  <= 1'd0;
        end else begin
                 if(cnt >= num/2-1) begin
                           cnt      <= 32'd0;
                           clk_gen  <= ~clk_gen;
                 end else begin
                           cnt <= cnt + 1'b1;
                 end
        end
end

endmodule

// Counter
module cnt60(  out,
               clk,
               rst_n );

output [5:0]   out          ;
input          clk          ;
input          rst_n        ;

reg    [5:0]   out          ;
always @(posedge clk or negedge rst_n) begin
       if(rst_n == 1'b0) begin
                out <= 6'd0;
       end else begin
                if(out >= 6'd59) begin
                       out <= 6'd0;
                end else begin
                       out <= out + 1'b1;
                end
       end

end

endmodule

// NCO Counter
module top_cnt(  out,
                 num,
                 clk,
                 rst_n  );

output [5:0]     out     ;
input  [31:0]    num     ;
input            clk     ;
input            rst_n   ;

wire             clk_gen ;

nco     nco_u0(  .clk_gen  ( clk_gen ),
                 .num      ( num     ),
                 .clk      ( clk     ),
                 .rst_n    ( rst_n   ));

cnt60   cnt_u0(  .out      ( out     ),
                 .clk      ( clk_gen ),
                 .rst_n    ( rst_n   ));

endmodule

//Double figure separate
module double_fig_sep(
              o_left,
              o_right,
              i_double_fig);

output [3:0]  o_left       ;
output [3:0]  o_right      ;

input  [5:0]  i_double_fig ;

assign o_left   = i_double_fig / 10;
assign o_right  = i_double_fig % 10;

endmodule

//FND Decoder
module fnd_dec( o_seg,
                i_num );

output [6:0]    o_seg  ;
input  [3:0]    i_num  ;

reg    [6:0]    o_seg  ;
always @(*) begin
       case(i_num)
            4'd0  : o_seg = 7'b1111_110;
            4'd1  : o_seg = 7'b0110_000;
            4'd2  : o_seg = 7'b1101_101;
            4'd3  : o_seg = 7'b1111_001;
            4'd4  : o_seg = 7'b0110_011;
            4'd5  : o_seg = 7'b1011_011;
            4'd6  : o_seg = 7'b1011_111;
            4'd7  : o_seg = 7'b1110_000;
            4'd8  : o_seg = 7'b1111_111;
            4'd9  : o_seg = 7'b1110_011;
            4'd10 : o_seg = 7'b1110_111;
            4'd11 : o_seg = 7'b1111_111;
            4'd12 : o_seg = 7'b1001_110;
            4'd13 : o_seg = 7'b1111_110;
            4'd14 : o_seg = 7'b1001_111;
            4'd15 : o_seg = 7'b1000_111;
            default o_seg = 7'b0000_000;
        endcase
end

endmodule

// LED Display
module led_disp( o_seg,
                 o_seg_dp,
                 o_seg_enb,
                 i_six_digit_seg,
                 i_six_dp,
                 clk,
                 rst_n      );

output [5:0]     o_seg_enb           ;
output           o_seg_dp            ;
output [6:0]     o_seg               ;

input  [41:0]    i_six_digit_seg     ;
input  [5:0]     i_six_dp            ;
input            clk                 ;
input            rst_n               ;

wire             gen_clk             ;
nco              u_nco(
                 .clk_gen  ( gen_clk  ),
                 .num      ( 32'd5000 ),
                 .clk      ( clk      ),
                 .rst_n    ( rst_n    ));

reg    [3:0]     cnt_common_node     ;
always @(posedge gen_clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
                 cnt_common_node <= 4'd0;
        end else begin
                 if(cnt_common_node >= 4'd5) begin
                        cnt_common_node <= 4'd0;
                 end else begin
                        cnt_common_node <= cnt_common_node + 1'b1;
                 end
        end
end

reg     [5:0]    o_seg_enb           ;
always @(cnt_common_node) begin
         case(cnt_common_node)
                 4'd0 : o_seg_enb = 6'b111110;
                 4'd1 : o_seg_enb = 6'b111101;
                 4'd2 : o_seg_enb = 6'b111011;
                 4'd3 : o_seg_enb = 6'b110111;
                 4'd4 : o_seg_enb = 6'b101111;
                 4'd5 : o_seg_enb = 6'b011111;
         endcase
end

reg              o_seg_dp            ;
always @(cnt_common_node) begin
         case(cnt_common_node)
                 4'd0 : o_seg_dp = i_six_dp[0];
                 4'd1 : o_seg_dp = i_six_dp[1];
                 4'd2 : o_seg_dp = i_six_dp[2];
                 4'd3 : o_seg_dp = i_six_dp[3];
                 4'd4 : o_seg_dp = i_six_dp[4];
                 4'd5 : o_seg_dp = i_six_dp[5];
         endcase
end

reg      [6:0]   o_seg               ;
always @(cnt_common_node) begin
         case(cnt_common_node)
                 4'd0 : o_seg = i_six_digit_seg[6:0];
                 4'd1 : o_seg = i_six_digit_seg[13:7];
                 4'd2 : o_seg = i_six_digit_seg[20:14];
                 4'd3 : o_seg = i_six_digit_seg[27:21];
                 4'd4 : o_seg = i_six_digit_seg[34:28];
                 4'd5 : o_seg = i_six_digit_seg[41:35];
         endcase
end

endmodule

//Buzzer
module buzz(       o_buzz,
                   i_buzz_en,
                   clk,
                   rst_n           );

output             o_buzz           ;

input              i_buzz_en        ;
input              clk              ;
input              rst_n            ;

parameter          C = 191113       ;
parameter          D = 170262       ;
parameter          E = 151686       ;
parameter          F = 143173       ;
parameter          G = 63776        ;
parameter          A = 56818        ;
parameter          B = 50619        ;

wire               clk_bit          ;
nco   u_nco_bit(   .clk_gen         ( clk_bit  ),
                   .num             ( 25000000 ),
                   .clk             ( clk      ),
                   .rst_n           ( rst_n    ));

reg   [4:0]        cnt              ;
always @(posedge clk_bit or negedge rst_n) begin
       if(rst_n == 1'b0) begin
                cnt <= 5'd0;
       end else begin
                if(cnt >= 5'd19) begin
                       cnt <= 5'd0;
                end else begin
                       cnt <= cnt + 1'd1;
                end
       end
end

reg   [31:0]         nco_num        ;
always @(*) begin
            case(cnt)
                5'd00 : nco_num = C ;
                5'd01 : nco_num = E ;
                5'd02 : nco_num = G ;
                5'd03 : nco_num = C ;
                5'd04 : nco_num = E ;
                5'd05 : nco_num = G ;
                5'd06 : nco_num = A ;
                5'd07 : nco_num = A ;
                5'd08 : nco_num = A ;
                5'd09 : nco_num = G ;
                5'd10 : nco_num = F ;
                5'd11 : nco_num = F ;
                5'd12 : nco_num = F ;
                5'd13 : nco_num = E ;
                5'd14 : nco_num = E ;
                5'd15 : nco_num = E ;
                5'd16 : nco_num = D ;
                5'd17 : nco_num = D ;
                5'd18 : nco_num = D ;
                5'd19 : nco_num = C ;
            endcase
end

wire                 buzz           ;
nco   u_nco_buzz(    .clk_gen     ( buzz    ),
                     .num         ( nco_num ),
                     .clk         ( clk     ),
                     .rst_n       ( rst_n   ));

assign               o_buzz = buzz & i_buzz_en;

endmodule

//Debounce
module debounce(
               o_sw,
               i_sw,
               clk  );
output         o_sw           ;

input          i_sw           ;
input          clk            ;

reg            dly1_sw        ;
always @(posedge clk) begin
         dly1_sw <= i_sw;
end

reg            dly2_sw        ;
always @(posedge clk) begin
         dly2_sw <= dly1_sw;
end

assign           o_sw = dly1_sw | ~dly2_sw;

endmodule

//controller
module controller(
               o_mode,
               o_position,
               o_alarm_en,
               o_sec_clk,
               o_min_clk,
               o_alarm_sec_clk,
               o_alarm_min_clk,
               i_sw0,
               i_sw1,
               i_sw2,
               i_sw3,
               i_max_hit_sec,
               i_max_hit_min,
               clk,
               rst_n          );

output [1:0]   o_mode          ;
output         o_position      ;
output         o_alarm_en      ;
output         o_sec_clk       ;
output         o_min_clk       ;
output         o_alarm_sec_clk ;
output         o_alarm_min_clk ;

input          i_sw0           ;
input          i_sw1           ;
input          i_sw2           ;
input          i_sw3           ;

input          i_max_hit_sec   ;
input          i_max_hit_min   ;

input          clk             ;
input          rst_n           ;

parameter      MODE_CLOCK = 2'b00     ;
parameter      MODE_SETUP = 2'b01     ;
parameter      MODE_ALARM = 2'b10     ;

parameter      POS_SEC = 1'b0         ;
parameter      POS_MIN = 1'b1         ;

wire           clk_slow               ;
nco            u_ncl_db(
               .clk_gen      ( clk_slow   ),
               .num          ( 32'd500000 ),
               .clk          ( clk        ),
               .rst_n        ( rst_n      ));

wire           sw0     ;
wire           sw1     ;
wire           sw2     ;
wire           sw3     ;
debounce       u_debouce0(
               .o_sw   ( sw0      ),
               .i_sw   ( i_sw0    ),
               .clk    ( clk_slow ));

debounce       u_debouce1(
               .o_sw   ( sw1      ),
               .i_sw   ( i_sw1    ),
               .clk    ( clk_slow ));

debounce       u_debouce2(
               .o_sw   ( sw2      ),
               .i_sw   ( i_sw2    ),
               .clk    ( clk_slow ));

debounce       u_debouce3(
               .o_sw   ( sw3      ),
               .i_sw   ( i_sw3    ),
               .clk    ( clk_slow ));

reg   [1:0]    o_mode  ;
always @(posedge sw0 or negedge rst_n) begin
    if(rst_n == 1'b0) begin
         o_mode <= MODE_CLOCK;
    end else begin
         if(o_mode >= MODE_ALARM) begin
             o_mode <= MODE_CLOCK;
         end else begin
             o_mode <= o_mode + 1'b1;
         end
    end
end

reg            o_position   ;
always @(posedge sw1 or negedge rst_n) begin
    if(rst_n == 1'b0) begin
         o_position <= POS_SEC;
    end else begin
         if(o_position >= POS_MIN) begin
             o_position <= POS_SEC;
         end else begin
             o_position <= o_position + 1'b1;
         end
    end
end

reg      o_alarm_en   ;
always @(posedge sw3 or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        o_alarm_en <= 1'b0;
    end else begin
        o_alarm_en <= o_alarm_en + 1'b1;
    end
end

wire     clk_1hz      ;
nco      u_nco(
         .clk_gen  (  clk_1hz        ),
         .num      (  32'd50000000   ),
         .clk      (  clk            ),
         .rst_n    (  rst_n          ));

reg      o_sec_clk         ;
reg      o_min_clk         ;
reg      o_alarm_sec_clk   ;
reg      o_alarm_min_clk   ;
always @(*) begin
   case(o_mode)
      MODE_CLOCK : begin
          o_sec_clk = clk_1hz;
          o_min_clk = i_max_hit_sec;
          o_alarm_sec_clk = 1'b0;
          o_alarm_min_clk = 1'b0;
      end
      MODE_SETUP : begin
          case(o_position)
              POS_SEC : begin
                 o_sec_clk = ~sw2;
                 o_min_clk = 1'b0;
                 o_alarm_sec_clk = 1'b0;
                 o_alarm_min_clk = 1'b0;
              end
              POS_MIN : begin
                 o_sec_clk = 1'b0;
                 o_min_clk = ~sw2;
                 o_alarm_sec_clk = 1'b0;
                 o_alarm_min_clk = 1'b0;
              end
          endcase
      end
      MODE_ALARM : begin
          case(o_position)
              POS_SEC : begin
                 o_sec_clk = clk_1hz;
                 o_min_clk = i_max_hit_sec;
                 o_alarm_sec_clk = ~sw2;
                 o_alarm_min_clk = 1'b0;
              end
              POS_MIN : begin
                 o_sec_clk = clk_1hz;
                 o_min_clk = i_max_hit_sec;
                 o_alarm_sec_clk = 1'b0;
                 o_alarm_min_clk = ~sw2;

              end
          endcase
      end
   endcase
end

endmodule

//Top hms clock
module top_hms_clock(
             o_seg,
             o_seg_dp,
             o_seg_enb,
             o_alarm,
             clk,
             i_sw0,
             i_sw1,
             i_sw2,
             i_sw3,
             rst_n           );

output [6:0] o_seg           ;
output       o_seg_dp        ;
output [5:0] o_seg_enb       ;
output       o_alarm         ;

input        clk             ;
input        i_sw0           ;
input        i_sw1           ;
input        i_sw2           ;
input        i_sw3           ;
input        rst_n           ;

wire  [1:0]  mode            ;
wire         position        ;
wire         alarm_en        ;
wire         sec_clk         ;
wire         min_clk         ;
wire         alarm_sec_clk   ;
wire         alarm_min_clk   ;

wire         max_hit_sec     ;
wire         max_hit_min     ;

controller   u_ctrl(
             .o_mode         ( mode          ),
             .o_position     ( position      ),
             .o_alarm_en     ( alarm_en      ),
             .o_sec_clk      ( sec_clk       ),
             .o_min_clk      ( min_clk       ),
             .o_alarm_sec_clk( alarm_sec_clk ),
             .o_alarm_min_clk( alarm_min_clk ),
             .i_max_hit_min  ( max_hit_min   ),
             .i_max_hit_sec  ( max_hit_sec   ),
             .i_sw0          ( i_sw0         ),
             .i_sw1          ( i_sw1         ),
             .i_sw2          ( i_sw2         ),
             .i_sw3          ( i_sw3         ),
             .clk            ( clk           ),
             .rst_n          ( rst_n         ));

wire [5:0]   sec             ;
wire [5:0]   min             ;
wire         alarm           ;
minsec       u_minsec(
             .o_sec          ( sec           ),
             .o_min          ( min           ),
             .o_max_hit_sec  ( max_hit_sec   ),
             .o_max_hit_min  ( max_hit_min   ),
             .o_alarm        ( alarm         ),
             .i_sec_clk      ( sec_clk       ),
             .i_min_clk      ( min_clk       ),
             .i_alarm_en     ( alarm_en      ),
             .i_alarm_sec_clk( alarm_sec_clk ),
             .i_alarm_min_clk( alarm_min_clk ),
             .i_position     ( position      ),
             .i_mode         ( mode          ),
             .clk            ( clk           ),
             .rst_n          ( rst_n         ));

wire [3:0]   sec_left        ;
wire [3:0]   sec_right       ;
double_fig_sep u0_dfs(
             .o_left         ( sec_left      ),
             .o_right        ( sec_right     ),
             .i_double_fig   ( sec           ));

wire [3:0]   min_left        ;
wire [3:0]   min_right       ;
double_fig_sep u1_dfs(
             .o_left         ( min_left      ),
             .o_right        ( min_right     ),
             .i_double_fig   ( min           ));

wire [6:0]   sec_seg_l       ;
wire [6:0]   sec_seg_r       ;
fnd_dec      u0_fnd_dec(
             .o_seg          ( sec_seg_l     ),
             .i_num          ( sec_left      ));

fnd_dec      u1_fnd_dec(
             .o_seg          ( sec_seg_r     ),
             .i_num          ( sec_right     ));

wire [6:0]   min_seg_l       ;
wire [6:0]   min_seg_r       ;
fnd_dec      u2_fnd_dec(
             .o_seg          ( min_seg_l     ),
             .i_num          ( min_left      ));

fnd_dec      u3_fnd_dec(
             .o_seg          ( min_seg_r     ),
             .i_num          ( min_right     ));

wire [41:0]  i_six_digit_seg   ;
assign       i_six_digit_seg = { {2{7'd0}}, min_seg_l, min_seg_r, sec_seg_l, sec_seg_r };
led_disp     u_led_disp(
             .o_seg            ( o_seg           ),
             .o_seg_dp         ( o_seg_dp        ),
             .o_seg_enb        ( o_seg_enb       ),
             .i_six_digit_seg  ( i_six_digit_seg ),
             .i_six_dp         ( 6'd0            ),
             .clk              ( clk             ),
             .rst_n            ( rst_n           ));

buzz         u_buzz(
             .o_buzz           ( o_alarm         ),
             .i_buzz_en        ( alarm           ),
             .clk              ( clk             ),
             .rst_n            ( rst_n           ));

endmodule
