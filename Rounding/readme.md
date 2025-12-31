# Rounding

Реализованы основные методы округления с поддержкой насыщения. Считается, что in[IWIDTH-1] - знаковый бит, in[IWIDTH-2:IWIDTH-OWIDTH] - целая часть числа,
in[IWIDTH-OWIDTH-1:0] - дробная часть числа.
Для выходного вектора out[OWIDTH-1] - знаковый бит, out[OWIDTH-2:0] - целая часть числа, дробная часть отсутствует.

## Round down

![Round down](/Rounding/draw/round_down.png)

## Round up

![Round up](/Rounding/draw/roun_up.png)

## Half down

![Half down](/Rounding/draw/half_down.png)

## Half up

![Half up](/Rounding/draw/half_up.png)

## Half to zero

![Half to zero](/Rounding/draw/half_to_zero.png)

## Half from zero

![Half from zero](/Rounding/draw/half_from_zero.png)

## Half to even

![Half to even](/Rounding/draw/half_to_even.png)

## Half to odd

![Half to odd](/Rounding/draw/half_to_odd.png)
