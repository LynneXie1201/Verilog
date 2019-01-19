// Part 2 skeleton

module part2
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	wire ld_x, sig_fill;
    wire [3:0] counter;
	
	
	
	
	
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
    // Instansiate datapath
	// datapath d0(...);

    // Instansiate FSM control
    // control c0(...);
    control C0(CLOCK_50, resetn, ~KEY[3], ~KEY[1], ld_x, sig_fill, counter);
    datapath D0(CLOCK_50, resetn, SW[6:0], SW[9:7], ld_x, sig_fill, counter, x, y, colour, writeEn);
    
endmodule

module control(
    input clk,
    input resetn,
    input load_x, // ~KEY[3]
    input fill_sqr, // ~KEY[1]

    output reg  ld_x, sig_fill,
    output reg [3:0] counter 
    );
    reg enable;
    reg [4:0] current_state, next_state; 

    localparam  S_LOAD_X        = 5'd0,
                S_LOAD_X_WAIT   = 5'd1,
                S_LOAD_Y        = 5'd2,
                S_LOAD_Y_WAIT   = 5'd3,
                S_CYCLE_1       = 5'd4,
             
                
    
     // counter
    always @ (posedge clk) 
    begin
        if (!resetn) begin
            counter <= 0;
        end
         if (load_x) begin
            counter <= 0;
            enable <= 0;
        end
        else if (sig_fill == 1'b1)
        	begin
        		
        	  if (counter == 4'b1111)
        	  		counter <= 0;
        	 		enable <= 1'b1;
        	  else 
        	 	counter <= counter + 1'b1;
        	 
        	end
           
        
    end            

    always@(*)
    begin: state_table 
            case (current_state)
                S_LOAD_X: next_state = load_x ? S_LOAD_X_WAIT : S_LOAD_X; // Loop in current state until value is input
                S_LOAD_X_WAIT: next_state = fill_sqr ? S_CYCLE_1 : S_LOAD_X_WAIT; // Loop in current state until go 
                S_CYCLE_1: next_state = enable ? S_CYCLE_2 : S_CYCLE_1; // Loop in current state until value is 
              
            
                S_CYCLE_2: next_state = S_LOAD_X;
                 
            default:     next_state = S_LOAD_X;
        endcase
    end // state_table

    always @(*)
    begin: enable_signals
        ld_x = 1'b0;
        sig_fill = 1'b0;
      //	cycle_0 = 0'b0;

        case (current_state)
            S_LOAD_X: begin
                ld_x = 1'b1;
                end
            // S_LOAD_X_WAIT: begin 
              //  cycle_0 = 1'b1;
                
          
          //  end
          
            S_CYCLE_1: begin 
                sig_fill = 1'b1;
                
          
            end
        
        endcase
    end // enable_signals

    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD_X;
        else
            current_state <= next_state;
    end // state_FFS

endmodule



module datapath (
    input clk,
    input resetn, 
    input [6:0] xy_input, 
    input [2:0] color, 
    input ld_x, 
    input sig_fill,
    input reg [3:0] counter,
    output reg [7:0] x_ret, 
    output reg [6:0] y_ret,
    output reg [2:0] color_ret,
    output reg writeEn
    );

    // input registers
    reg [7:0] x_reg;


    always @ (posedge clk) begin
        if (!resetn) begin
            x_reg <= 8'd0;
        end
        else begin
            if (ld_x)
                x_reg[6:0] <= xy_input;
                x_reg[7] <= 1'b0;
        end
    end

    // Output result
    always @ (posedge clk) begin
        if (!resetn) begin
            y_ret[6:0] <= 7'd0;
            x_ret[7:0] <= 8'd0; 
            color_ret[2:0] <= 2'd0;
            writeEn <= 1'd0;
        end
        
        // else if (cycle_0 == 1'b1)
        //	begin
        	  
        	
        	 //	x_ret[7:0] <= x_reg[7:0];
             //   y_ret[6:0] <= xy_input[6:0];
             //   color_ret[2:0] <= color[2:0];
             //   writeEn <= 1'b1;
        //	end
         else if (sig_fill == 1'b1)
        	begin
        	  
        	
        	 	x_ret[7:0] <= (x_reg[7:0] + counter[1:0]); 
                y_ret[6:0] <= (xy_input[6:0] + counter[3:2]);
                color_ret[2:0] <= color[2:0];
                writeEn <= 1'b1;
        	end
       
    end
    
   
    

endmodule

	



