' TEST for Boolean OR 16 bits

DIM a as UInteger
DIM b as UByte

b = a OR 0
b = a OR 1
b = 0 OR a
b = 1 OR a
b = a OR a
b = (a = a) OR (a = a)

