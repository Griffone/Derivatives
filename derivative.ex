defmodule Derivative do

    @moduledoc """
    Mathemtatical derivative.
    """

    @typedoc """
    An expression type alias
    """
    @type expression :: Exprssion.expression

    @doc """
    Find a derivative of given expression.
    """
    @spec derivative(expression) :: expression
    def derivative(expr), do: expr
end


defmodule Expression do

    @moduledoc """
    An Expression module is essentially an expression object definition.
    """
    
    @typedoc """
    A variable identifier.
    """
    @type variableId :: String.t()

    @typedoc """
    An exprssion is a mathematical exprssion.
    """
    @type expression :: {:var, variableId}
        | {:num, number}
        | {:sum, expression, expression}
        | {:sub, expression, expression}
        | {:mul, expression, expression}
        | {:div, expression, expression}

    @doc """
    Attempt to evaluate an expression.
    Will perform any available functions.
    """
    @spec evaluate(expression) :: expression | :illegal_expression
    def evaluate({:sum, {:num, a}, {:num, b}}), do: {:num, a + b}
    def evaluate({:sum, a, {:num, 0}}), do: a
    def evaluate({:sum, {:num, 0}, b}), do: b
    def evaluate({:sub, {:num, a}, {:num, b}}), do: {:num, a - b}
    def evaluate({:sub, a, {:num, 0}}), do: a
    def evaluate({:mul, {:num, a}, {:num, b}}), do: {:num, a * b}
    def evaluate({:mul, _, {:num, 0}}), do: {:num, 0}
    def evaluate({:mul, {:num, 0}, _}), do: {:num, 0}
    def evaluate({:mul, a, {:num, 1}}), do: a
    def evaluate({:mul, {:num, 1}, b}), do: b
    def evaluate({:div, {:num, a}, {:num, b}}), do: {:num, a / b}
    def evaluate({:div, _, {:num, 0}}), do: :illegal_expression
    def evaluate({:div, 0, _}), do: {:num, 0}
    def evaluate({op, a, b}) do
        ea = evaluate(a)
        eb = evaluate(b)
        if ea != a or eb != b do
            evaluate({op, ea, eb})
        else
            {op, ea, eb}
        end
    end
    def evaluate(expression), do: expression
end

defmodule Parser do

    @moduledoc """
    String parser module.

    Used to parse expressions, used by Derivative module.
    Returns resulting expression.
    """
    @strings_ops    ["+", "-", "*", "/"]
    @ops_list        [{:sum, "+"}, {:sub, "-"}, {:mul, "*"}, {:div, "/"}]
    @regex_num      ~r{\d}
    @regex_var      ~r{[[:alpha:]]}

    @doc """
    Attempt to parse a string.
    """
    #@spec parse(String.t()) :: Expression.expression | :error
    def parse(string) do
        prefix = to_prefix(string)
        {expression, remainder} = to_expression(prefix)
        unless remainder != [] do
            expression
        else
            :error
        end
    end

    @doc """
    Transforms a prefix list to an expression.
    Last step of parsing an infix expression.
    """
    def to_expression([op | rest]) when is_atom(op) do
        {a, rest} = to_expression(rest)
        {b, rest} = to_expression(rest)
        {{op, b, a}, rest}
    end
    def to_expression([{varType, var} | rest]) when is_atom(varType) do
        {{varType, var}, rest}
    end

    @doc """
    Transform a string to prefix operation list.
    A middle step of parsing an infix expression.
    """
    def to_prefix("", [], [], result), do: result
    def to_prefix("", [], [op | opStack], result), do: to_prefix("", [], opStack, [op | result])
    def to_prefix("", [var | []], [op | opStack], result), do: to_prefix("", [], opStack, [ op, var | result])
    def to_prefix("", [a, b | varStack], [op | opStack], result), do: to_prefix("", varStack, opStack, [ op, a, b | result])
    def to_prefix("", [_ | _], [], _), do: :error
    def to_prefix(string, varStack \\ [], opStack \\ [], result \\ []) do
        {char, rest} = String.next_grapheme(string)
        cond do
            String.starts_with?(string, @strings_ops) ->
                {op, rest} = parse_operation(string)
                # TODO: pop higher precedence operators
                to_prefix(rest, varStack, [op | opStack], result)

            char =~ @regex_num ->
                {number, rest} = parse_number(string)
                to_prefix(rest, [{:num, number} | varStack], opStack, result)

            char =~ @regex_var ->
                to_prefix(rest, [{:var, char} | varStack], opStack, result)

            true ->
                to_prefix(rest, varStack, opStack, result)
        end
    end

    @doc """
    A help parse funtion.
    Attempts to parse a number from given string. Returns the rest of the string and the number is successful.
    """
    @spec parse_number(String.t()) :: {number, String.t()} | :error
    @spec parse_number(String.t(), number) :: {number, String.t()} | :error
    def parse_number(string, charId \\ 1) do
        curChar = String.at(string, charId)
        cond do
            curChar == nil ->
                Integer.parse(string)
            curChar == "." ->
                Float.parse(string)
            curChar =~ @regex_num ->
                parse_number(string, charId + 1)
            true ->
                Integer.parse(string)
        end
    end

    @doc """
    A help parse function.
    Parses a function operator. More for future proofing, once we get stuff like log and stuff.
    """
    @spec parse_operation(String.t()) :: {atom, String.t()} | :error
    @spec parse_operation(String.t(), list({atom, String.t()})) :: {atom, String.t()} | :error
    def parse_operation(string), do: parse_operation(string, @map_ops)
    def parse_operation(string, [{op, opName} | restOps]) do
        if String.starts_with?(string, opName) do
            {op, String.slice(string, String.length(opName)..-1)}
        else
            parse_operation(string, restOps)
        end
    end
    def parse_operation(string, []), do: :error
end