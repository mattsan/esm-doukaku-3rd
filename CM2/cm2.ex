defmodule CM2 do
  defmodule Coder do
    def decode(str) do
      [size_s, hexcode] = String.split(str, ":")
      size = String.to_integer(size_s)
      [1|bits] = Integer.digits(String.to_integer("1" <> hexcode, 16), 2)
      decode(Enum.take(bits, size), <<>>)
    end

    def encode(value) do
      bits = _encode("#{value}")
      bit_length = length(bits)
      padding = List.duplicate(0, rem(4 - rem(bit_length, 4), 4))
      code = Integer.to_string(Integer.undigits(bits ++ padding, 2), 16)
      "#{bit_length}:#{code}"
    end

    defp decode([], acc), do: acc
    defp decode([0, 0               |rest], acc), do: decode(rest, <<acc::binary, ?0>>)
    defp decode([0, 1               |rest], acc), do: decode(rest, <<acc::binary, ?1>>)
    defp decode([1, 0, 0            |rest], acc), do: decode(rest, <<acc::binary, ?2>>)
    defp decode([1, 0, 1, 0         |rest], acc), do: decode(rest, <<acc::binary, ?3>>)
    defp decode([1, 0, 1, 1         |rest], acc), do: decode(rest, <<acc::binary, ?4>>)
    defp decode([1, 1, 0, 0         |rest], acc), do: decode(rest, <<acc::binary, ?5>>)
    defp decode([1, 1, 0, 1, 0      |rest], acc), do: decode(rest, <<acc::binary, ?6>>)
    defp decode([1, 1, 0, 1, 1      |rest], acc), do: decode(rest, <<acc::binary, ?7>>)
    defp decode([1, 1, 1, 0, 0, 0   |rest], acc), do: decode(rest, <<acc::binary, ?8>>)
    defp decode([1, 1, 1, 0, 0, 1   |rest], acc), do: decode(rest, <<acc::binary, ?9>>)
    defp decode([1, 1, 1, 0, 1, 0, 0|rest], acc), do: decode(rest, <<acc::binary, ?+>>)
    defp decode([1, 1, 1, 0, 1, 0, 1|rest], acc), do: decode(rest, <<acc::binary, ?->>)
    defp decode([1, 1, 1, 0, 1, 1, 0|rest], acc), do: decode(rest, <<acc::binary, ?*>>)
    defp decode([1, 1, 1, 0, 1, 1, 1|rest], acc), do: decode(rest, <<acc::binary, ?/>>)

    defp _encode(<<>>), do: []
    defp _encode(<<?0, rest::binary>>), do: [0, 0               |_encode(rest)]
    defp _encode(<<?1, rest::binary>>), do: [0, 1               |_encode(rest)]
    defp _encode(<<?2, rest::binary>>), do: [1, 0, 0            |_encode(rest)]
    defp _encode(<<?3, rest::binary>>), do: [1, 0, 1, 0         |_encode(rest)]
    defp _encode(<<?4, rest::binary>>), do: [1, 0, 1, 1         |_encode(rest)]
    defp _encode(<<?5, rest::binary>>), do: [1, 1, 0, 0         |_encode(rest)]
    defp _encode(<<?6, rest::binary>>), do: [1, 1, 0, 1, 0      |_encode(rest)]
    defp _encode(<<?7, rest::binary>>), do: [1, 1, 0, 1, 1      |_encode(rest)]
    defp _encode(<<?8, rest::binary>>), do: [1, 1, 1, 0, 0, 0   |_encode(rest)]
    defp _encode(<<?9, rest::binary>>), do: [1, 1, 1, 0, 0, 1   |_encode(rest)]
    defp _encode(<<?+, rest::binary>>), do: [1, 1, 1, 0, 1, 0, 0|_encode(rest)]
    defp _encode(<<?-, rest::binary>>), do: [1, 1, 1, 0, 1, 0, 1|_encode(rest)]
    defp _encode(<<?*, rest::binary>>), do: [1, 1, 1, 0, 1, 1, 0|_encode(rest)]
    defp _encode(<<?/, rest::binary>>), do: [1, 1, 1, 0, 1, 1, 1|_encode(rest)]
  end

  defmodule Parser do
    def parse(str) do
      Regex.scan(~r"\d+|\+|-|\*{1,2}|/{1,2}", str)
      |> Enum.map(fn
        ["+"] -> :add
        ["-"] -> :sub
        ["*"] -> :tim
        ["/"] -> :div
        ["**"] -> :pow
        ["//"] -> :rem
        [n] -> String.to_integer n
      end)
      |> get_expression
    end

    def get_expression(tokens) do
      {term, rest} = get_term(tokens)
      get_expression(term, rest)
    end
    def get_expression(term, []), do: term
    def get_expression(term1, [op|tokens]) when op in [:add, :sub] do
      {term2, rest} = get_term(tokens)
      get_expression({op, term1, term2}, rest)
    end

    def get_term(tokens) do
      {factor, rest} = get_factor(tokens)
      get_term(factor, rest)
    end
    def get_term(factor, []), do: {factor, []}
    def get_term(factor1, [op|tokens]) when op in [:tim, :div, :rem] do
      {factor2, rest} = get_factor(tokens)
      get_term({op, factor1, factor2}, rest)
    end
    def get_term(factor, rest), do: {factor, rest}

    def get_factor([value1, :pow|tokens]) do
      {value2, rest} = get_factor(tokens)
      {{:pow, value1, value2}, rest}
    end
    def get_factor([value|rest]), do: {value, rest}
  end

  defmodule Calc do
    def eval({:add, lhs, rhs}), do: eval(lhs) + eval(rhs)
    def eval({:sub, lhs, rhs}), do: eval(lhs) - eval(rhs)
    def eval({:tim, lhs, rhs}), do: eval(lhs) * eval(rhs)
    def eval({:div, lhs, rhs}), do: div(eval(lhs), eval(rhs))
    def eval({:pow, lhs, rhs}), do: List.duplicate(eval(lhs), eval(rhs)) |> Enum.reduce(&*/2)
    def eval({:rem, lhs, rhs}), do: rem(eval(lhs), eval(rhs))
    def eval(value), do: value
  end

  defmodule Tester do
    def solve(input) do
      input
      |> Coder.decode
      |> Parser.parse
      |> Calc.eval
      |> Coder.encode
    end

    def judge(expected, expected), do: "  PASS  "
    def judge(_, _),               do: "* FAILED"

    def test(input, expected) do
      actual = solve(input)
      IO.puts "#{judge(expected, actual)} input #{input}, expected #{expected}, actual #{actual}"
    end
  end
end
