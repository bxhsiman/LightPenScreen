// st_state.v
// 状态定义：待机、点亮、划亮、写字、擦除、取色、关机
`ifndef ST_STATE_V
`define ST_STATE_V

// 表层状态机
`define SLEEP 4'd0 //待机模式
`define LIGHT 4'd1 //点亮模式
`define DRAW 4'd2  //划亮模式 //需要特殊开发 一同点亮！
`define WRITE 4'd3 //写字模式
`define REVERSE 4'd4 //反色模式

`define ERASE 4'd5 //擦除模式
`define COLOR 4'd6 //取色模式

`define RST 4'd7
`define STOP 4'd8

// 深层状态机
`define STATE_0 3'd0 //red
`define STATE_1 3'd1 //green
`define STATE_2 3'd2 //red
`define STATE_3 3'd3 //green
`define STATE_4 3'd4 //next state


`define STATE_MAX `STATE_4

`endif
