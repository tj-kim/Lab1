LAB 1 REPORT
============
TJ Kim, Paul Krusell, Jay Woo

# Introduction

To the project manager,

We have taken note of your need of an ALU design and we want you to consider our design for your CPU. Our ALU has a total of nine features, implemented through bit slicing. In this paper, we will present our overall ALU design,discuss the different iterations we went through, and analyze the overall efficiency of our ALU in terms of delay.

# Implementation

Below are the various circuits we have drawn for the ALU. We will explain the details of a specific circuit, black box it, and apply it in bigger circuits. All the components were made using only nand, nor, and not gates.

It would be useful to look through our verilog code while reading these explanations, as a lot of variable names on both the circuit diagram and explanations are derived from there.

### Xor
![Test Table](https://github.com/tj-kim/Lab1/blob/master/images/xorgate.png)

Above is a circuit for a XOR gate. We used this circuit not only as one of the ALU commands, but also in other circuits that required a XOR gate.

### 2:1 mux
![Test Table](https://github.com/tj-kim/Lab1/blob/master/images/2_1mux.png)

Above is a circuit for a 2:1 mux. 

### 5:1 mux
![Test Table](https://github.com/tj-kim/Lab1/blob/master/images/5_1Mux.png)

We utilize the 2:1 mux to build a 5:1 mux, which we will use for our “muxIndex”. The “muxIndex” is an abbreviated version of “command” (the indication of which operation the ALU will do). We abbreviate “command” as the commands AND and NAND can be done with a 1 bit NAND/AND component, and the commands OR and NOR can be done with a 1 bit NOR/OR component, and the same for Add/Subtract. We originally planned to have an 8:1 mux with 7 2:1 muxes inside, but we realized that we only need 5 inputs, and thus effectively removed 3 muxes to build our 5:1 mux.

### 1 bit NOR/OR
![Test Table](https://github.com/tj-kim/Lab1/blob/master/images/Nor_or.png)

The 1 bit NOR/OR component computes both NOR and OR of the inputs A and B, but we use a mux to select which one we want. The command for the mux is “otherinputcommand” which is outputted by the LUT that takes in the initial “command” from the user.

### 1 bit NAND/AND
![Test Table](https://github.com/tj-kim/Lab1/blob/master/images/nand_and.png)

The 1 bit NAND/AND component is very similar to the 1 bit NOR/OR component. We compute both NAND and AND and use a 2:1 mux to select which value we want.

### 1 bit Adder/Subtractor
![Test Table](https://github.com/tj-kim/Lab1/blob/master/images/add_subtract.png)

The 1 bit Adder/Subtractor takes in ‘a’, ‘b’, and ‘cin’ (carryin) and adds those all together. The outputs are ‘sum’ and ‘carryout’. This component can only add, but by manipulating ‘b’, and ‘cin’, the ALU can subtract using this component. 

### 1 bit ALU
![Test Table](https://github.com/tj-kim/Lab1/blob/master/images/1bitalu.png)

(The blue input on the very right that is cut off reads ‘InvB’)

The 1 bit ALU component brings together all the components mentioned above. We added a 2:1 mux before the 1 bit Adder/Subtractor because we will manipulate operandB and Cin to make the adder/subtractor component do either addition or subtraction. That method saves space and time compared to doing both operations with the adder/subtractor and choosing whether to output the sum or the difference with a mux.

Another important design decision we made was to link operation SLT to muxIndex  ‘100’. None of the other muxIndexes have ‘1’ as their leftmost bit, and this design decision will come to help us when we implement the full ALU.

For the SLT output, we also opted to have it a constant value 0. This is because we want the result string for the SLT to be ‘..0001’ when B is greater than A, and ‘..0000’ when B is not greater than A. Therefore, we will initially set the final ‘result’ of the big ALU to be 32 bits of zeros and and alter the value of the rightmost bit later on.

### Full ALU with LUT
![Test Table](https://github.com/tj-kim/Lab1/blob/master/images/final_alu.png)

With the Full ALU with LUT, the user initially inputs a 3 bit command to select which operation the ALU should run on inputs A and B. The LUT takes in the command and outputs ‘muxIndex’, ‘InvB’, and ‘othercommandsignal’.  ‘muxIndex’ addresses the 5 bit mux in the ALU that selects which operation to run. ‘InvB’ raises a ‘1’ if the required operation is related to subtraction and needs B to be inverted. ‘othercommandsignal’ raises a ‘1’ if we are ANDing A and B or ORing A and B. In other words, ‘othercommandsignal’ differentiates between NAND/AND and NOR/OR.

The outputs of the LUT and the ‘i’th bit of A and B (‘i’ goes from 0 to 31) are fed into the ‘i’th 1 bit ALU (total of 32 1 bit ALUs). Each 1 bit ALU computes the ‘i’th bit of the output result signal.

The carryin input for each 1 bit ALU is the carryout output for the previous 1 bit ALU. For the first 1 bit ALU, the carryin is equal to ‘InvB’. We made this design choice because for multibit addition we do A + B, and for subtraction we do A + ~B + 1. Carryin for the first 1 bit ALU is 0 for addition, and 1 for subtraction, which lines up perfectly with the instances of the variable ‘InvB’. 

Now we will explain how we derive the SLT output value when the user selects the SLT operation. There is a 1 bit adder present in the circuit above that takes A[31], ~B[31], and the carryout of the 30th 1 bit ALU. This adder will output the sum of A[31] and ~B[31] with carryin being “carryout 30th”. This will give us the leftmost bit of the result had the selected operation been subtraction of B from A, along with its carryout. Using the sum and carryout, we find overflow, and using the overflow and the sum, we are able to derive the SLT output value.

Using a 2:1 mux, only when the muxIndex is set to SLT, we pass the SLT output value as the rightmost bit of the final result. If the muxIndex is not set to SLT, we return to the rightmost bit of the final result as the output of the very first 1 bit ALU. It is important to note that the 2:1 mux used here takes in for select signal as the very right bit of the muxIndex. (muxIndex is 3 bit, but only when we command for SLT is the rightmost bit ‘1’). 

At the very end of the circuit, we take the final 32 bit result output, and put all the values through a NOR gate to check whether or not all the values in the result are zeros or not. If the values are all zero, the output (which we will name ‘zero’) will be ‘1’, and if not the output (‘zero’) will be ‘0’. The ‘zero’ flag will be raised when A and B are equal and a subtraction related operation occurrs. The ‘zero’ flag will also be raised when A and B are inverses and an addition related operation occurs.

The big ALU now takes in 32 bit A, 32 bit B, and a user command to output carryout, final result, overflow, and a ‘zero’ flag.


# Test Results
Before testing our 32-bit ALU, we constructed test cases for the smaller components: the 2:1 MUX, the 5:1 MUX, and the 1-bit Full Adder. We then built a 4-bit ALU, which we tested using a well-chosen set of 4-bit operands. After generating the correct outputs with the 4-bit ALU, we tested our 32-bit ALU.

The individual tests are detailed below.

A written description of what tests you chose, and why you chose them. This should be roughly a paragraph or two per operation.
Specific instances where your test bench caught a flaw in your design.
As your ALU design evolves, you may find that new test cases should be added to your test bench. This is a good thing. When this happens, record specifically why these tests were added.

## Intermediate Components
Though these are not one of the 8 ALU operations, we decided it was important to test them, before putting them into the larger structures.

### 2:1 MUX
When the select flag is 0, the MUX should select input 0. Otherwise, it selects input 1.

```verilog
I0 I1 | S0 | O | Expected Output
---------------------------------------
 1  x |  0 | 1 | Selects in0
 x  1 |  1 | 1 | Selects in1
---------------------------------------
 0  x |  0 | 0 | Selects in0
 x  0 |  1 | 0 | Selects in1
```

None of the unassigned bits were selected in our test, so this passed.

### 5:1 MUX
Any of the 5 inputs may be selected by using select values in the range 0b000 to 0b100.

```verilog
I0 I1 I2 I3 I4 | S0 S1 S2 | O | Expected Output
----------------------------------------------------
 1  x  x  x  x |  0  0  0 | 1 | Selects in0
 x  1  x  x  x |  1  0  0 | 1 | Selects in1
 x  x  1  x  x |  0  1  0 | 1 | Selects in2
 x  x  x  1  x |  1  1  0 | 1 | Selects in3
 x  x  x  x  1 |  0  0  1 | 1 | Selects in4
----------------------------------------------------
 0  x  x  x  x |  0  0  0 | 0 | Selects in0
 x  0  x  x  x |  1  0  0 | 0 | Selects in1
 x  x  0  x  x |  0  1  0 | 0 | Selects in2
 x  x  x  0  x |  1  1  0 | 0 | Selects in3
 x  x  x  x  0 |  0  0  1 | 0 | Selects in4
```

As with before, none of the unassigned bits were selected, so this also passed.

## 1-Bit Full Adder
We tested every combination of inputs in the full adder like we did it HW1. Because there are so few cases it makes sense to exhaustively test:

```verilog
A B Cin | Cout S  | Expected Output
0 0  0  |  0   0  |  0  0
0 0  1  |  0   1  |  0  1
0 1  0  |  0   1  |  0  1
0 1  1  |  1   0  |  1  0
1 0  0  |  0   1  |  0  1
1 0  1  |  1   0  |  1  0
1 1  0  |  1   0  |  1  0
1 1  1  |  1   1  |  1  1
```
As seen above, every test case passed, which is what we expected as we used the same adder module from previous homeworks and labs.

## Basic Gates (NAND, AND, NOR, OR, XOR)
Originally, we planned on calculating the 32-bit results for each operation, by passing all of the digits to gates via 32-bit buses. When we tried implementing such a design, however, we quickly realized that the gate delay for the entire ALU would be huge for the basic gates, which should normally be quick to compute. For instance, a 32-input AND gate would have a gate delay of 320 units, as opposed to a 2-input AND gate, which has a delay of 20. After this, we adopted a bit-slicing method, where each 1-bit ALU component performed the operation on each pair of digits.

Using our bit-slicing method, we tested the 5 gate operations on a 4-bit ALU. Since the gates are element-wise operations, we specifically chose operands A and B to exhaustively test all possible pairs of digits (1 op 1, 0 op 1, 1 op 0, 0 op 0).

```verilog
 Cm  |	 A 	   B  |  Out | Cout  OF | Case
----------------------------------------------------
 101 | 1010  1100 | 0111 |	1    1  | NAND
 100 | 1010  1100 | 1000 |	1    1  | AND
 110 | 1010  1100 | 0001 |	1    1  | NOR
 111 | 1010  1100 | 1110 |	1    1  | OR
 010 | 1010  1100 | 0110 |	1    1  | XOR
```

We did the same for the 32-bit ALU, by repeating the same sequence of 4 bits eight times for each operand. For operand A, we repeated the sequence 0b1010 (0xA), and for operand B, we repeated the sequence 0b1100 (0xC). In the test results below, the 32-bit inputs and outputs (A, B, Out) are hex numbers, for readability purposes.

```verilog
 Cm  |    	A     	B     |   Out    | Cout  OF | Case
----------------------------------------------------
 101 | aaaaaaaa  cccccccc | 77777777 |	1   1   | NAND (all cases)
 100 | aaaaaaaa  cccccccc | 88888888 |	1   1   | AND (all cases)
 110 | aaaaaaaa  cccccccc | 11111111 |	1   1   | NOR (all cases)
 111 | aaaaaaaa  cccccccc | eeeeeeee |	1   1   | OR (all cases)
 010 | aaaaaaaa  cccccccc | 66666666 |	1   1   | XOR (all cases)
```

These 32-bit outputs can be compared to the 4-bit outputs:
NAND - 0b0111 = 0x7
AND - 0b1000 = 0x8
NOR - 0b0001 = 0x1
OR - 0b1110 = 0xE
XOR - 0x0110 = 0x6

We encountered some bugs before getting to this point, as shown in the table below, but they were due to programming errors rather than the design of the circuit. Basically, when we instantiated our MUXes, we did not order the inputs and outputs correctly, causing the ALU to select the wrong operations (with the exception of XOR since the command value 0b010 is a palindrome).

```verilog
 Cm  |    A     B |  Out | Cout  OF | Case
----------------------------------------------------
 101 | 1010  1100 | 0000 |    x   x | NAND
 100 | 1010  1100 | 0000 |    x   x | AND
 110 | 1010  1100 | 0000 |    x   x | NOR
 111 | 1010  1100 | 0000 |    x   x | OR
 010 | 1010  1100 | 0110 |    x   x | XOR
```

## Adder
These test cases include different combinations of sign of A, sign of B, carryout, and overflow to test on our 4-bit ALU.

```verilog
 Cm  |	A 	   B  |  Out | Cout  OF | Case
----------------------------------------------------
 000 | 1111  1111 | 1110 |	1   0   | ADD
 000 | 1011  1011 | 0110 |	1   1   | ADD
 000 | 1110  1100 | 1010 |	1   0   | ADD
 000 | 1111  1000 | 0111 |	1   1   | ADD
 000 | 0011  0011 | 0110 |	0   0   | ADD
 000 | 0101  0101 | 1010 |	0   1   | ADD
 000 | 0001  0010 | 0011 |	0   0   | ADD
 000 | 0111  0010 | 1001 |	0   1   | ADD
 000 | 0001  1000 | 1001 |	0   0   | ADD
 000 | 0001  1111 | 0000 |	1   0   | ADD
 000 | 0111  1001 | 0000 |	1   0   | ADD
 000 | 0000  0000 | 0000 |	0   0   | ADD
 000 | 0000  1111 | 1111 |	0   0   | ADD
 000 | 0000  0111 | 0111 |	0   0   | ADD
 000 | 1111  0000 | 1111 |	0   0   | ADD
 000 | 0111  0000 | 0111 |	0   0   | ADD
 ```

We applied similar principles for our 32-bit ALU addition test. We took a 32-bit value with only its leftmost 4 bits with values and the rest with zeros. We basically took our 4 bit cases and padded to the right 28 times with zeros. Here, we test different cases regarding sign of A, sign of B, carryout, and overflow. The 32 bit test case is a lot shorter than the 4 bit one as we proved the functionality of our ALU extensively in the 4 bit version.
 
```verilog
 Cm  |    	A     	B     |   Out    | Cout  OF | Case
------------------------------------------------------
 000 | 10000000  20000000 | 30000000 |	0   0   | ADD ++, ~CO*~OF
 000 | e0000000  c0000000 | a0000000 |	1   0   | ADD --, CO*~OF,
 000 | 70000000  20000000 | 90000000 |	0   1   | ADD ++, CO*~OF
 000 | f0000000  80000000 | 70000000 |	1   1   | ADD --, CO*OF
 000 | 10000000  f0000000 | 00000000 |	1   0   | ADD +-, CO*~OF
```


## Subtractor
For the subtractor, we used roughly the same cases from addition, because of the similarity between the adder and subtractor. We inverted the B operands from the addition test bench to find the new B operands. This way we can reuse the same cases for the subtractor that we used for the adder. Doing this, we found that all of our test cases were successful and correct, indicating that the subtractor worked for the 4-bit case. 

```verilog
 Cm  |	A   	B |  Out | Cout  OF | Case
------------------------------------------------------------------------
 001 | 1111  0001 | 1110 |	1   0   | SUB
 001 | 1011  0101 | 0110 |	1   1   | SUB
 001 | 1110  0100 | 1010 |	1   0   | SUB
 001 | 1111  1000 | 0111 |	1   0   | SUB
 001 | 0011  1101 | 0110 |	0   0   | SUB
 001 | 0101  1011 | 1010 |	0   1   | SUB
 001 | 0001  1110 | 0011 |	0   0   | SUB
 001 | 0111  1110 | 1001 |	0   1   | SUB
 001 | 0001  1000 | 1001 |	0   1   | SUB
 001 | 0001  0001 | 0000 |	1   0   | SUB
 001 | 0111  0111 | 0000 |	1   0   | SUB
 001 | 0000  0000 | 0000 |	1   0   | SUB
 001 | 0000  0001 | 1111 |	0   0   | SUB
 001 | 0000  1001 | 0111 |	0   0   | SUB
 001 | 1111  0000 | 1111 |	1   0   | SUB
 001 | 0111  0000 | 0111 |	1   0   | SUB
 ```
 
We then took some of the same cases that we used for the 4-bit subtractor and padded them with zeros to create 32-bit numbers, which we were able to run through our system and they worked. The 32-bit subtraction process compared to the other processes had a lot of delay, so our test bench delay initially was not enough. Because of that we got weird values. We checked the test bench dump for subtraction on GTKwave, and then extended the delay time in the test bench to fix the problem.

```verilog
 Cm  |    	A     	B     |    Out   | Cout  OF | Case
------------------------------------------------------
 001 | 10000000  e0000000 | 30000000 |	0   0   | SUB +-, ~CO*~OF
 001 | e0000000  40000000 | a0000000 |	1   0   | SUB -+, CO*~OF
 001 | 70000000  e0000000 | 90000000 |	0   1   | SUB +-, ~CO*OF
 001 | f0000000  80000000 | 70000000 |	1   0   | SUB -+, CO*OF
 001 | 70000000  50000000 | 20000000 |	1   0   | SUB ++, CO*~OF
 001 | ffffffff  ffffffff | 00000000 |	1   0   | SUB --, CO*~OF
```


## SLT
We tested different combinations of carryout, overflow, and whether or not A was actually less than B. The output displayed correctly as all zeros except for the first bit, which can be set to one if SLT triggers true.
```verilog
 Cm  |	 A 	   B  |  Out | Cout  OF | Case
------------------------------------------------------------------------
 011 | 0001  0011 | 0001 |	0   0   | SLT
 011 | 1011  0010 | 0001 |	1   0   | SLT
 011 | 1100  1111 | 0001 |	0   0   | SLT
 011 | 0101  0011 | 0000 |	1   0   | SLT
 011 | 0010  1101 | 0000 |	0   0   | SLT
 011 | 1111  1010 | 0000 |	1   0   | SLT
 011 | 1100  0101 | 0001 |	1   1   | SLT
 011 | 0101  1100 | 0000 |	0   1   | SLT
 ```
 
For the 32-bit cases, we used different combinations of negative and positive operands, with different relative magnitudes.

```verilog
 Cm  |    	A     	B     |   Out    | Cout  OF | Case
------------------------------------------------------
 011 | 80000000  ffffffff | 00000001 |	0   0   | SLT --, A<B
 011 | ffffffff  80000000 | 00000000 |	1   0   | SLT --, A>B
 011 | 01111111  0fffffff | 00000001 |	0   0   | SLT ++, A<B
 011 | 0fffffff  01111111 | 00000000 |	1   0   | SLT ++, A>B
 011 | f0000000  0fffffff | 00000001 |	1   0   | SLT -+, A<B
 011 | 0fffffff  f0000000 | 00000000 |	0   0   | SLT +-, A>B
 ```

We had a lot of issues getting this component to work correctly. In order to determine the value of the SLT, we had to take the leftmost bit of the difference of A and B. Then we had to use that leftmost bit and overflow to determine if SLT is raised to ‘1’ or not. However, when we set up the bit-slicing, we made the 1-bit ALU return ‘0’ for every bit of the result when selected for SLT operation. This zero overrode the difference of A and B, which garbled our results in the next cycle when the new left-most bit was looped back into the SLT.

To fix this problem, we created a 1 bit adder in the final ALU, separate from the 32 1-bit ALUs. This ALU took in A[31], ~B[31], and the carryout of the 30th 1-bit ALU (2nd to last) and computed the leftmost bit of the difference of A and B for us.


## Zero
We tested the zero output by setting the 4-bit ALU to subtract B from A. Since we already tested the 4-bit subtraction cases, we only chose two situations: one where the difference is zero and one where the difference is non-zero.

```verilog
 Cm  |    A     B | A - B | Zero | Case
------------------------------------------------------
 001 | 1111  1111 |  0000 |    1 | A-B==0
 001 | 1111  0000 |  1111 |    0 | A-B!=0
```

We did the same for the 32-bit ALU and achieved similar results.

```verilog
 Cm  |        A         B |      Out | Zero | Case
------------------------------------------------------
 001 | 1234abcd  1234abcd | 00000000 |    1 | A-B==0
 001 | 1234abcd  abcd1234 | 66679999 |    0 | A-B!=0
```

However, as we added test cases to the 32-bit test bench, we saw that our method of calculating the 32-input NOR gate was not correctly coded in structural Verilog.

```verilog
 Cm  |        A         B |      Out | Zero | Case
------------------------------------------------------
 001 | 1234abcd  1234abcd | 00000000 |    1 | A-B==0
 001 | 1234abcd  abcd1234 | 66679999 |    0 | A-B!=0
 000 | 12340000  abcd0000 | be010000 |    1 | A-B!=0
 000 | 12340000  abcd0000 | be010000 |    1 | A-B!=0
```

We used the following line of code to calculate the zero:

```verilog
nor #320(zero, result)
```

The nor function only seemed to be looking at the first digits of the result variable, so we instead listed out all 32 values of the result in the input, as follows:

```verilog
// Calculates zero (32-input NOR)
nor #320 nor_zero(zero, result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7]
                      , result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
                      , result[16], result[17], result[18], result[19], result[20], result[21], result[22], result[23]
                      , result[24], result[25], result[26], result[27], result[28], result[29], result[30], result[31]);
```

This returned the following test bench values, after we added new tests:

```verilog
 Cm  |        A         B |      Out | Zero | Case
------------------------------------------------------
 001 | 1234abcd  1234abcd | 00000000 |    1 | A-B==0
 001 | 1234abcd  abcd1234 | 66679999 |    0 | A-B!=0
 000 | 11111111  11111111 | 22222222 |    0 | A-B!=0
 001 | 50000000  30000000 | 20000000 |    0 | A-B!=0
```

# Timing Analysis
For each operation, we inspected the waveforms to observe how long it takes for the inputs to propagate through the gates. The units of time are ns.

## Basic Gates
For each of the basic gates, the propagation delay is relatively short, since these operations can be applied to all pairs of digits at the same time. However, for the very first bit, there are extra gates to account for, partly due to a MUX that decides whether or not to set the first bit to the value of the SLT operation. Thus, for the following waveforms, the 32-bit ALU will first calculate bits 2-32, and after another delay, it will resolve bit 1.

### NAND
![NAND Delay](https://github.com/tj-kim/Lab1/blob/master/Waveforms/delayNAND.png)

According to our calculations (also values are in circuit diagram), a NAND operation has a 1-bit Nor/or gate that has a delay of 100, a 5:1 mux that has a delay of 210, and a 2:1 mux that has a delay of 70. The total time it takes is 380, which lines up closely with the GTKwave diagram, although it is overshot by a bit. The GTKwave returns a delay of 320.

### AND
![AND Delay](https://github.com/tj-kim/Lab1/blob/master/Waveforms/delayAND.png)

Similarly to a NAND gate, an AND operation has a total delay of 380, which also lines up closely with our GTKwave value of 330. 

### NOR
![NOR Delay](https://github.com/tj-kim/Lab1/blob/master/Waveforms/delayNOR.png)

Same delay calculation as NAND of 380. GTKwave value of 320.

### OR
![OR Delay](https://github.com/tj-kim/Lab1/blob/master/Waveforms/delayOR.png)

Same delay calculation as AND of 380. GTKwave value of 330.


### XOR
![XOR Delay](https://github.com/tj-kim/Lab1/blob/master/Waveforms/delayXOR.png)

The XOR operator has the following components: 1-bit Xor operator with a delay of 60, a 5:1 mux with delay of 210, and a 2:1 mux with a delay of 70. The 2:1 mux is used for bit zero only, as we select between the rightmost ALU output and the SLT output. The total calculated time is 340, while the GTKwave time is 290.

## ADD
![ADD Delay](https://github.com/tj-kim/Lab1/blob/master/Waveforms/delayADD2.png)

The Add operator has the following components: 2:1 mux with delay 70, and 1-bit adder/subtractor with delay 120. We have 32 add/subtract processes so we multiply the delay of the adder with 32, and add it to the mux. The total calculated delay is 3910. The delay shown on the GTKwave is 420.

## SUB
![SUB Delay](https://github.com/tj-kim/Lab1/blob/master/Waveforms/delaySUB2.png)

The subtract operator has the same delay as an adder when calculated, 3910. The GTKwave value is 2300.

## SLT
![SLT Delay](https://github.com/tj-kim/Lab1/blob/master/Waveforms/delaySLT.png)

The calculated delay of the SLT includes the delay of a 2:1 mux (70), 31 1-bit subtractors (120*32), 1 1-bit adder (120), 2 Xor gates (2*60), and 1 2:1 mux (70). The total calculated delay is 4100. GTKwave returns a delay of 2200.

# Work Plan Reflection

We were able to follow our work plan very well. Our first few days went as planned, but we had to take longer on Tuesday and Wednesday, as the added complexities led to more code bugs and unusual situations within the circuit. It took extra time that we didn’t put into the work plan to fix these. The creation of the SLT system took much longer than expected, probably 3 hours instead of the predicted 1.5. We would create an idea for the SLT system, dissect it, and then retest or implement the idea. Once we figured out the SLT and it passed our test bench, the report came together quickly. 
Overall, our team met every day since Saturday to work on this, and felt we put in a good effort. We felt the workload was distributed well amongst our teammates. 
