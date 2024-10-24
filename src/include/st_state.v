// st_state.v
// 状态定义：待机、点亮、划亮、写字、擦除、取色、关机
`ifndef ST_STATE_V
`define ST_STATE_V

// 表层状态机
`define SLEEP 3'd0
`define LIGHT 3'd1
`define DRAW 3'd2
`define WRITE 3'd3
`define ERASE 3'd4
`define COLOR 3'd5

`define RST 3'd6
`define STOP 3'd7

// 深层状态机
`define STATE_0 3'd0 //red
`define STATE_1 3'd1 //green
`define STATE_2 3'd2 //red
`define STATE_3 3'd3 //green
`define STATE_4 3'd4 //next state


`define STATE_MAX `STATE_4

`endif
