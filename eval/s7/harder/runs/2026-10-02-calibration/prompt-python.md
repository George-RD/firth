For each task, write a Python 3 function named `main`. Use only the standard library.

Do not use any tool except reading this prompt file and writing your answer file, and do not use the internet. After you answer, you will be shown how each answer did on its task's example: the result, or the diagnostics if it failed. You may then fix your answers; there is at most 1 such round.

Answer every task in this exact format, one block per task, and nothing that could be mistaken for one:

### task: <task id>
```python
<source>
```

If you believe a task cannot be written with what is available, still give your best attempt, and add one line after the block starting `NOTE:`.

# Tasks

## bowling
rolls lists the pins knocked down by each roll of one complete, valid game of ten-pin bowling. A game has ten frames. In frames 1 to 9, a first roll of 10 is a strike and ends the frame; otherwise the frame has two rolls. A frame scores its pins plus a bonus: after a strike, the pins of the next two rolls; after a spare (two rolls in one frame totalling 10), the pins of the next roll. The tenth frame has a third roll only when its first two rolls make a strike or a spare; those extra rolls count once, as the tenth frame's bonus. Return the running total after each frame (ten numbers).
Arguments, in order: rolls: list[int].
Return: totals: list[int].
Example: main([10, 7, 3, 9, 0, 10, 0, 8, 8, 2, 0, 6, 10, 10, 10, 8, 1]) returns [20, 39, 48, 66, 74, 84, 90, 120, 148, 167].

## lru
A cache holds at most cap distinct keys (cap is at least 1). Process keys in order. If a key is in the cache, it is a hit and becomes the most recently used key. Otherwise it is a miss: if the cache already holds cap keys, the least recently used key is removed first, then the key is added as the most recently used. The cache starts empty. Return the number of misses and the keys left in the cache, from least to most recently used. keys has at most 60 elements.
Arguments, in order: cap: int, keys: list[int].
Return: misses: int, cache: list[int] (as a tuple, in this order).
Example: main(2, [1, 2, 1, 3, 2]) returns (4, [3, 2]).

## rpn
Evaluate a program for a stack calculator. Token i is kinds[i] and vals[i] (the two sequences have the same length). Kinds: 0 pushes vals[i]; 1 to 4 pop b (the top), then a, and push a + b, a - b, a * b, or a divided by b with the quotient rounded toward zero (-7 and 2 give -3); 5 pushes a copy of the top value. vals[i] is used only by kind 0. Stop at the first error. Return (result, status): status 1 when a token needs more values than the calculator's stack holds, 2 when a division has b = 0, and, after the last token, 3 when the stack does not hold exactly one value. With status 1, 2 or 3, result is 0. Otherwise status is 0 and result is the one value left.
Arguments, in order: kinds: list[int], vals: list[int].
Return: result: int, status: int (as a tuple, in this order).
Example: main([0, 0, 0, 3, 1], [2, 3, 4, 0, 0]) returns (14, 0).

## edit-cost
Return the least total cost of turning xs into ys with these edits: inserting one element costs insert, deleting one costs delete, and replacing one element with a different value costs replace. insert, delete and replace are each at least 1. Each sequence has at most 25 elements.
Arguments, in order: xs: list[int], ys: list[int], insert: int, delete: int, replace: int.
Return: cost: int.
Example: main([1, 2, 3], [1, 3, 4], 1, 1, 1) returns 2.

## shortest-hops
A directed graph has nodes 0 to n - 1 and edges froms[k] -> tos[k] of weight weights[k] (the three sequences have the same length; weights are 0 or more; there can be several edges between two nodes). For every node, find the least total weight of a path from source to it and, among the paths with that weight, the fewest edges. Return both as sequences of length n: dist[v] and hops[v], each -1 when v cannot be reached. The source has distance 0 and 0 hops. n is at most 12 and there are at most 40 edges.
Arguments, in order: n: int, froms: list[int], tos: list[int], weights: list[int], source: int.
Return: dist: list[int], hops: list[int] (as a tuple, in this order).
Example: main(4, [0, 0, 1, 2], [1, 2, 3, 3], [1, 4, 1, 1], 0) returns ([0, 1, 4, 2], [0, 1, 1, 2]).

## merge-ranges
Range k covers the whole numbers from starts[k] to ends[k], both included (the two sequences have the same length, and starts[k] <= ends[k]); the ranges are in no particular order. Merge ranges that overlap or are next to each other (as 1 to 3 and 4 to 6 are) until no two of them do. Return the merged ranges' starts and ends, ordered by start, and how many whole numbers they cover in all. There are at most 30 ranges.
Arguments, in order: starts: list[int], ends: list[int].
Return: merged-starts: list[int], merged-ends: list[int], covered: int (as a tuple, in this order).
Example: main([8, 1, 4, 15], [10, 3, 6, 15]) returns ([1, 8, 15], [6, 10, 15], 10).

## tiny-vm
Run a program for a machine with four registers r[0] to r[3], which start as regs. Instruction i is code[3i], code[3i+1], code[3i+2]: an operation op and two operands a and b (code's length is a multiple of 3; a register operand is always 0 to 3). Operations: 0 halts; 1 sets r[a] to b; 2 adds r[b] to r[a]; 3 subtracts r[b] from r[a]; 4 multiplies r[a] by r[b]; 5 copies r[b] into r[a]; 6 jumps to instruction b if r[a] is not 0; 7 jumps to instruction b if r[a] is less than 0. Execution starts at instruction 0 and otherwise goes to the next instruction. Before each instruction: if its number is not between 0 and the number of instructions minus 1, stop with status 1; otherwise, if limit instructions have already been executed, stop with status 2. Executing a halt stops with status 0. Return the registers, the number of instructions executed (a halt counts) and the status. limit is at most 300.
Arguments, in order: code: list[int], regs: list[int], limit: int.
Return: regs-out: list[int], executed: int, status: int (as a tuple, in this order).
Example: main([1, 0, 5, 1, 1, 1, 1, 2, 1, 4, 1, 0, 3, 0, 2, 6, 0, 3, 0, 0, 0], [0, 0, 0, 0], 100) returns ([0, 120, 1, 0], 19, 0).

## lis-smallest
Return a longest strictly increasing subsequence of xs (elements in their original order, not necessarily next to each other, each greater than the one before). When there are several, return the one whose values are smallest in dictionary order: the smallest first value, then among those the smallest second value, and so on. xs has at most 30 elements.
Arguments, in order: xs: list[int].
Return: lis: list[int].
Example: main([5, 1, 6, 2, 7, 3]) returns [1, 2, 3].
