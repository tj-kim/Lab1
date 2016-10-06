// 1-bit Adder Circuit
module adder_1bit // add and "subtract"
(
    output sum,       // 1 bit sum of a and b and carryin
    output carryout,  // Carry out of the summation of a and b and carryin
    input a,          // 1 bit input a
    input b,          // 1 bit input b
    input carryin    // 1 bit input carryin
);

    wire not_b, Xor_AB, Nand_AB, And_AB, Nand_XorAB_C, And_XorAB_C, nco;

    xor_1bit xor_1(Xor_AB, a, b);
    xor_1bit xor_2(sum, Xor_AB, carryin);
    nand #20 nand_1 (Nand_AB, a, b);
    not  #10 not1 (And_AB, Nand_AB);
    nand #20 nand_2 (Nand_XorAB_C, carryin, Xor_AB);
    not  #10 not2 (And_XorAB_C, Nand_XorAB_C);
    nor  #20 nor_1 (nco, And_XorAB_C, And_AB);
    not  #10 not_3 (carryout, nco);
endmodule