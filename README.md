# csveval.vim

This plugin implements :CsvEval which parses a string that consists of a
combination of functions and cells to perform simple mathematical operations
that may be useful for processing CSV files.

## Examples

`:CsvEval sum(A1, B1)`

Inserts the sum of A1 and B1 at the end of the current line.

`:CsvEval mean(A1:A3, D4)`

Inserts the mean of A1, A2, A3, D4 at the end of the current line.

`:%CsvEval multiply(divide(G#, C#) 5000)`

For each line in the buffer, divide the number in column G by the number in
column C, multiply by 5000, and append the result to the respective line.

`:'<,'>g/^/exec ":CsvEval sum(A#, B" . (line(".") - 1) . ")"`

Calculate the cumulative total over a range. (First line must be complete)

## Documentation

See `:help csveval`
