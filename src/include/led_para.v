// led 相关参数
`define PWM_COUNT 499
`define PWM_LOW_COUNT 50
`define PWM_HIGH_COUNT 498
`define PWM_OFF 0

// 颜色选择相关参数
`define RED 2'b01
`define GREEN 2'b10
`define YELLOW 2'b11

// 颜色对应位置
`define RED_ROW 8'b1000_0000
`define GREEN_ROW 8'b1000_0000
`define YELLOW_ROW 8'b1000_0000

`define RED_COL 8'b0100_0000
`define GREEN_COL 8'b0001_0000
`define YELLOW_COL 8'b0000_0010

// 扫描相关参数
`define SCAN_TIME 500