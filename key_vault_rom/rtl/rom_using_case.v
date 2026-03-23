module rom_using_case(
    address, // addr input
    data, 
    read_en,
    chip_en
);

    input [3:0] address;
    output reg [7:0] data;
    input read_en;
    input chip_en;
   
    always @* begin
        if (chip_en && read_en) begin
            case(address)
                0 : data = 10;
                1 : data = 55;
                2 : data = 244;
                3 : data = 0;
                4 : data = 1;
                5 : data = 8'hff;
                6 : data = 8'h11;
                7 : data = 8'h1;
                8 : data = 8'h10;
                9 : data = 8'h0;
                10 : data = 8'h10;
                11 : data = 8'h15;
                12 : data = 8'h60;
                13 : data = 8'h90;
                14 : data = 8'h70;
                15 : data = 8'h90;
            endcase
        end
        else begin
                data = 8'h00;
        end
    end
endmodule
