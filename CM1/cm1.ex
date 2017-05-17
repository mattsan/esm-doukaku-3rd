defmodule CM1 do
  defmodule Coder do
    def decode(bits), do: decode(bits, <<>>)

    def encode(str), do: encode(str, <<>>)

    defp decode(<<>>, acc),                         do: acc
    defp decode(<<0b00::2,      rest::bits>>, acc), do: decode(rest, <<acc::binary, ?0>>)
    defp decode(<<0b01::2,      rest::bits>>, acc), do: decode(rest, <<acc::binary, ?1>>)
    defp decode(<<0b100::3,     rest::bits>>, acc), do: decode(rest, <<acc::binary, ?2>>)
    defp decode(<<0b1010::4,    rest::bits>>, acc), do: decode(rest, <<acc::binary, ?3>>)
    defp decode(<<0b1011::4,    rest::bits>>, acc), do: decode(rest, <<acc::binary, ?4>>)
    defp decode(<<0b1100::4,    rest::bits>>, acc), do: decode(rest, <<acc::binary, ?5>>)
    defp decode(<<0b11010::5,   rest::bits>>, acc), do: decode(rest, <<acc::binary, ?6>>)
    defp decode(<<0b11011::5,   rest::bits>>, acc), do: decode(rest, <<acc::binary, ?7>>)
    defp decode(<<0b111000::6,  rest::bits>>, acc), do: decode(rest, <<acc::binary, ?8>>)
    defp decode(<<0b111001::6,  rest::bits>>, acc), do: decode(rest, <<acc::binary, ?9>>)
    defp decode(<<0b1110100::7, rest::bits>>, acc), do: decode(rest, <<acc::binary, ?+>>)
    defp decode(<<0b1110101::7, rest::bits>>, acc), do: decode(rest, <<acc::binary, ?->>)
    defp decode(<<0b1110110::7, rest::bits>>, acc), do: decode(rest, <<acc::binary, ?*>>)
    defp decode(<<0b1110111::7, rest::bits>>, acc), do: decode(rest, <<acc::binary, ?/>>)

    defp encode(<<>>, acc),                 do: acc
    defp encode(<<?0, rest::binary>>, acc), do: encode(rest, <<acc::bits, 0b00::2>>)
    defp encode(<<?1, rest::binary>>, acc), do: encode(rest, <<acc::bits, 0b01::2>>)
    defp encode(<<?2, rest::binary>>, acc), do: encode(rest, <<acc::bits, 0b100::3>>)
    defp encode(<<?3, rest::binary>>, acc), do: encode(rest, <<acc::bits, 0b1010::4>>)
    defp encode(<<?4, rest::binary>>, acc), do: encode(rest, <<acc::bits, 0b1011::4>>)
    defp encode(<<?5, rest::binary>>, acc), do: encode(rest, <<acc::bits, 0b1100::4>>)
    defp encode(<<?6, rest::binary>>, acc), do: encode(rest, <<acc::bits, 0b11010::5>>)
    defp encode(<<?7, rest::binary>>, acc), do: encode(rest, <<acc::bits, 0b11011::5>>)
    defp encode(<<?8, rest::binary>>, acc), do: encode(rest, <<acc::bits, 0b111000::6>>)
    defp encode(<<?9, rest::binary>>, acc), do: encode(rest, <<acc::bits, 0b111001::6>>)
    defp encode(<<?+, rest::binary>>, acc), do: encode(rest, <<acc::bits, 0b1110100::7>>)
    defp encode(<<?-, rest::binary>>, acc), do: encode(rest, <<acc::bits, 0b1110101::7>>)
    defp encode(<<?*, rest::binary>>, acc), do: encode(rest, <<acc::bits, 0b1110110::7>>)
    defp encode(<<?/, rest::binary>>, acc), do: encode(rest, <<acc::bits, 0b1110111::7>>)
  end

  defmodule Calculator do
    def to_token(["+"]), do: :add
    def to_token(["-"]), do: :sub
    def to_token(["*"]), do: :tim
    def to_token(["/"]), do: :div
    def to_token(["**"]), do: :pow
    def to_token(["//"]), do: :rem
    def to_token([n]), do: String.to_integer n

    def to_rpn([value]), do: [value]
    def to_rpn([lhs, op, rhs|tokens]), do: to_rpn(tokens, [op, rhs, lhs])

    def eval_rpn([value]), do: value
    def eval_rpn(tokens), do: eval_rpn(tokens, [])

    def pow(lhs, rhs), do: List.duplicate(lhs, rhs) |> Enum.reduce(&*/2)

    defp to_rpn([], acc), do: Enum.reverse acc
    defp to_rpn(tokens = [:pow|_], acc = [:pow|_]), do: to_rpn_pow(tokens, acc)
    defp to_rpn(tokens = [op|_], acc = [prev_op|_]), do: to_rpn(tokens, order_of_operator(prev_op) < order_of_operator(op), acc)

    defp to_rpn([op, value|tokens], true, [prev_op|acc]), do: to_rpn(tokens, [prev_op, op, value|acc])
    defp to_rpn([op, value|tokens], false, acc), do: to_rpn(tokens, [op, value|acc])

    defp to_rpn_pow([op, value|tokens], acc) do
      {ops, rest_acc} = Enum.split_while(acc, &(&1 == op))
      to_rpn(tokens, ops ++ [op, value|rest_acc])
    end

    defp eval_rpn([], [value]), do: value
    defp eval_rpn([:add|tokens], [rhs, lhs|acc]), do: eval_rpn(tokens, [lhs + rhs|acc])
    defp eval_rpn([:sub|tokens], [rhs, lhs|acc]), do: eval_rpn(tokens, [lhs - rhs|acc])
    defp eval_rpn([:tim|tokens], [rhs, lhs|acc]), do: eval_rpn(tokens, [lhs * rhs|acc])
    defp eval_rpn([:div|tokens], [rhs, lhs|acc]), do: eval_rpn(tokens, [div(lhs, rhs)|acc])
    defp eval_rpn([:pow|tokens], [rhs, lhs|acc]), do: eval_rpn(tokens, [pow(lhs, rhs)|acc])
    defp eval_rpn([:rem|tokens], [rhs, lhs|acc]), do: eval_rpn(tokens, [rem(lhs, rhs)|acc])
    defp eval_rpn([value|tokens], acc), do: eval_rpn(tokens, [value|acc])

    defp order_of_operator(op) when op in [:pow], do: 3
    defp order_of_operator(op) when op in [:tim, :div, :rem], do: 2
    defp order_of_operator(op) when op in [:add, :sub], do: 1
    defp order_of_operator(_), do: 0
  end

  def decode(str) do
    [bit_length_s, bit_string] = String.split(str, ":")
    significant_length = String.to_integer(bit_length_s)
    bit_length = String.length(bit_string) * 4
    <<source_bits::size(significant_length), _::bits>> = <<String.to_integer(bit_string, 16)::size(bit_length)>>
    Coder.decode(<<source_bits::size(significant_length)>>)
  end

  def encode(input) do
    bits = Coder.encode("#{input}")
    bits_str = Enum.join for << x::4 <- <<bits::bits, 0::3>> >>, do: Integer.to_string(x, 16)
    "#{bit_size(bits)}:#{bits_str}"
  end

  def calculate(str) do
    Regex.scan(~r"\d+|\+|-|\*{1,2}|/{1,2}", str)
    |> Enum.map(&Calculator.to_token/1)
    |> Calculator.to_rpn
    |> Calculator.eval_rpn
  end

  defmodule Tester do
    def solve(input) do
      input
      |> CM1.decode
      |> CM1.calculate
      |> CM1.encode
    end

    def judge(expected, expected), do: "  PASS  "
    def judge(_, _),               do: "* FAILED"

    def test(input, expected) do
      actual = solve(input)
      IO.puts "#{judge(expected, actual)} input #{input}, expected #{expected}, actual #{actual}"
    end
  end
end
