defmodule Derivative do

    @moduledoc """
    Mathemtatical derivative.
    """

    @typedoc """
    An expression type alias
    """
    @type expression :: Expression.expression
    @type variableId :: Expression.variableId

    @doc """
    Find a derivative of given expression.
    """
    @spec derive(expression, variableId) :: expression
    @spec derive(variableId, expression) :: expression
    def derive(expression, var) when is_tuple(expression), do: Expression.evaluate(deriv(var, Expression.evaluate(expression)))
    def derive(var, expression) when is_tuple(expression), do: deriv(var, Expression.evaluate(expression))

    @spec deriv(variableId, expression) :: expression
    defp deriv(x, {:num, _}), do: {:num, 0}
    defp deriv(x, {:var, x}), do: {:num, 1}
    defp deriv(x, {:var, y}), do: {:var, 0}
    defp deriv(x, {:sum, a, b}), do: {:sum, deriv(x, a), deriv(x, b)}
    defp deriv(x, {:sub, a, b}), do: {:sub, deriv(x, a), deriv(x, b)}
    defp deriv(x, {:mul, {:var, x}, b}), do: b
    defp deriv(x, {:mul, a, {:var, x}}), do: a
    defp deriv(x, {:mul, a, b}), do: {:sum, {:mul, deriv(x, a), b}, {:mul, a, deriv(x, b)}}
    defp deriv(x, {:pow, {:var, x}, b}), do: {:mul, b, {:pow, {:var, x}, {:sub, b, {:num, 1}}}}
    defp deriv(x, {:ln, e}), do: {:mul, {:ln, e}, deriv(x, e)}
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
        | {:pow, expression, expression}
        | {:ln, expression}

    @doc """
    Attempt to evaluate an expression.
    Will perform any available functions on numbers or simplify some of the more basic simplification rules.
    """
    @spec evaluate(expression) :: expression | :illegal_expression
    def evaluate({op, a, b}) do
        expr = eval({op, a, b})
        if expr != {op, a, b} do
            evaluate(expr)
        else
            expr
        end
    end
    def evaluate(expr), do: expr

    @spec eval(expression) :: expression | :illegal_expression
    # Addition
    defp eval({:sum, e, {:num, b}}) when b < 0, do: {:sub, e, {:num, -b}}
    defp eval({:sum, {:num, a}, {:num, b}}), do: {:num, a + b}
    defp eval({:sum, e, {:num, 0}}), do: e
    defp eval({:sum, {:num, 0}, e}), do: e
    defp eval({:sum, {:var, v}, {:var, v}}), do: {:mul, {:num, 2}, {:var, v}}
    defp eval({:sum, {:num, a}, {:sum, e, {:num, b}}}), do: {:sum, {:num, a + b}, e}
    defp eval({:sum, {:num, a}, {:sum, {:num, b}, e}}), do: {:sum, {:num, a + b}, e}
    defp eval({:sum, {:sum, e, {:num, a}}, {:num, b}}), do: {:sum, {:num, a + b}, e}
    defp eval({:sum, {:sum, {:num, a}, e}, {:num, b}}), do: {:sum, {:num, a + b}, e}
    # Subtraction
    defp eval({:sub, {:num, a}, {:num, b}}), do: {:num, a - b}
    defp eval({:sub, e, {:num, 0}}), do: e
    defp eval({:sub, e, e}), do: {:num, 0}
    # Multiplication
    defp eval({:mul, {:num, a}, {:num, b}}), do: {:num, a * b}
    defp eval({:mul, _, {:num, 0}}), do: {:num, 0}
    defp eval({:mul, {:num, 0}, _}), do: {:num, 0}
    defp eval({:mul, e, {:num, 1}}), do: e
    defp eval({:mul, {:num, 1}, e}), do: e
    defp eval({:mul, {:var, v}, {:var, v}}), do: {:pow, {:var, v}, {:num, 2}}
    defp eval({:mul, {:var, v}, {:pow, {:var, v}, {:num, n}}}), do: {:pow, {:var, v}, {:num, n + 1}}
    defp eval({:mul, {:pow, {:var, v}, {:num, n}}, {:var, v}}), do: {:pow, {:var, v}, {:num, n + 1}}
    defp eval({:mul, {:num, a}, {:mul, e, {:num, b}}}), do: {:mul, e, {:num, a * b}}
    defp eval({:mul, {:num, a}, {:mul, {:num, b}, e}}), do: {:mul, e, {:num, a * b}}
    defp eval({:mul, {:mul, e, {:num, a}}, {:num, b}}), do: {:mul, e, {:num, a * b}}
    defp eval({:mul, {:mul, {:num, a}, e}, {:num, b}}), do: {:mul, e, {:num, a * b}}
    # Division
    defp eval({:div, {:num, a}, {:num, b}}), do: {:num, a / b}
    defp eval({:div, _, {:num, 0}}), do: :illegal_expression
    defp eval({:div, {:num, 0}, _}), do: {:num, 0}
    defp eval({:div, e, {:num, 1}}), do: e
    # Power
    defp eval({:pow, {:num, a}, {:num, b}}), do: :math.pow(a, b)
    defp eval({:pow, e, {:num, 1}}), do: e
    defp eval({:pow, {:num, 0}, {:num, 0}}), do: :illegal_expression
    defp eval({:pow, {:num, 0}, _}), do: {:num, 0}
    defp eval({:pow, _, {:num, 0}}), do: {:num, 1}
    # Natural logarithm
    defp eval({:ln, {:num, n}}), do: {:num, :math.log(n)}
    # General
    defp eval({op, a, b}) do
        ea = eval(a)
        eb = eval(b)
        if ea != a or eb != b do
            eval({op, ea, eb})
        else
            {op, a, b}
        end
    end
    defp eval(expression), do: expression

    def toString(expression), do: expr_to_str(expression)

    defp expr_to_str({:mul, {:num, n}, {:var, v}}), do: "#{n}#{v}"
    defp expr_to_str({:mul, {:var, v}, {:num, n}}), do: "#{n}#{v}"
    defp expr_to_str({op, {opA, aa, ab}, {opB, ba, bb}}), do: "(" <> expr_to_str({opA, aa, ab}) <> ")" <> op_to_str(op) <> "(" <> expr_to_str({opB, ba, bb}) <> ")"
    defp expr_to_str({op, {opA, aa, ab}, b}), do: "(" <> expr_to_str({opA, aa, ab}) <> ")" <> op_to_str(op) <> expr_to_str(b)
    defp expr_to_str({op, a, {opB, ba, bb}}), do: expr_to_str(a) <> op_to_str(op) <> "(" <> expr_to_str({opB, ba, bb}) <> ")"
    defp expr_to_str({op, a, b}), do: expr_to_str(a) <> op_to_str(op) <> expr_to_str(b)
    defp expr_to_str({:num, n}), do: "#{n}"
    defp expr_to_str({:var, v}), do: "#{v}"
    defp expr_to_str({op, e}), do: op_to_str(op) <> "(" <> expr_to_str(e) <> ")"

    defp op_to_str(:sum), do: " + "
    defp op_to_str(:sub), do: " - "
    defp op_to_str(:mul), do: " * "
    defp op_to_str(:div), do: " / "
    defp op_to_str(:pow), do: "^"
end

defmodule Parser do

    @moduledoc """
    String parser module.

    Used to parse expressions, used by Derivative module.

    Known limitation: doesn't use proper parsing technique, so requires strict mathematical notation (2x is illegal for example)
    """
    @strings_ops    ["+", "-", "*", "/", "^"]
    # An operator is {operator, symbol, priority}
    @ops_list       [{:sum, "+", 1}, {:sub, "-", 1}, {:mul, "*", 2}, {:div, "/", 2}, {:pow, "^", 3}, {:ln, "ln", 4}]
    @regex_num      ~r{\d}
    @regex_var      ~r{[[:alpha:]]}

    @type prefix_item :: {:var, Expression.variableId}
        | {:num, number}
        | :sum
        | :sub
        | :mul
        | :div
        | :pow
        | :ln

    @doc """
    Attempt to parse a string.
    """
    @spec parse(String.t()) :: Expression.expression | :error
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
    Because of the querk of the stacking, it invers operands order in order to restore the original one.
    """
    @spec to_expression(list(prefix_item)) :: Expression
    defp to_expression([op | rest]) when is_atom(op) do
        {a, rest} = to_expression(rest)
        {b, rest} = to_expression(rest)
        {{op, b, a}, rest}
    end
    defp to_expression([{varType, var} | rest]) when is_atom(varType) do
        {{varType, var}, rest}
    end

    @doc """
    Transform a string to prefix operation list.
    A middle step of parsing an infix expression.
    A querk of optimization and elixir lists, it invers the order of operands, for which to_expression corrects.
    """
    @spec to_prefix(String.t(), list({atom, number}), list(prefix_item)) :: list(prefix_item)
    defp to_prefix("", [], result), do: result
    defp to_prefix("", [{op, opPriority} | opStack], result), do: to_prefix("", opStack, [op | result])
    defp to_prefix(string, opStack \\ [], result \\ []) do
        {char, rest} = String.next_grapheme(string)
        cond do
            # Check for operators first
            String.starts_with?(string, @strings_ops) ->
                {op, rest} = parse_operation(string)
                {opStack, result} = append_operator(op, opStack, result)
                to_prefix(rest, opStack, result)

            # Check for numbers
            char =~ @regex_num ->
                {number, rest} = parse_number(string)
                to_prefix(rest, opStack, [{:num, number} | result])

            # Check for variables
            char =~ @regex_var ->
                to_prefix(rest, opStack, [{:var, char} | result])

            # Ignore other symbols
            true ->
                to_prefix(rest, opStack, result)
        end
    end

    @doc """
    Smartly append operator to the stack.
    Meaning operators of higher precedence will be popped from the stack to correct for precedence.
    """
    @spec append_operator({atom, number}, list({atom, number}), list(prefix_item)) :: {list({atom, number}), list(prefix_item)}
    defp append_operator({op, opPriority}, opStack, result) do
        case opStack do
            [{otherOp, otherPriority} | rest] when otherPriority > opPriority ->
                append_operator({op, opPriority}, rest, [otherOp | result])
            
            _ ->
                {[{op, opPriority} | opStack], result}
        end
    end

    @doc """
    A help parse funtion.
    Attempts to parse a number from given string. Returns the rest of the string and the number is successful.
    """
    @spec parse_number(String.t()) :: {number, String.t()} | :error
    @spec parse_number(String.t(), number) :: {number, String.t()} | :error
    defp parse_number(string, charId \\ 1) do
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
    Parses a function operator. More for future proofing, once we get stuff like log.
    """
    @spec parse_operation(String.t()) :: {atom, String.t()} | :error
    @spec parse_operation(String.t(), list({atom, String.t(), number})) :: {{atom, number}, String.t()} | :error
    defp parse_operation(string), do: parse_operation(string, @ops_list)
    defp parse_operation(string, [{op, opSymbol, opPriority} | restOps]) do
        if String.starts_with?(string, opSymbol) do
            {{op, opPriority}, String.slice(string, String.length(opSymbol)..-1)}
        else
            parse_operation(string, restOps)
        end
    end
    defp parse_operation(string, []), do: :error
end

defmodule Test do
    @moduledoc """
    Helper functions to test the whole calculator process.

    Includes simple single-element tests and whole pipeline tests and example functional data.
    """

    @spec sample_input() :: String.t()
    def sample_input(), do: "2 *x * 12 + 4 * 2 * 5 / 5 + 11 * x * x * x * x"
    @spec sample_expression() :: Expression.t()
    def sample_expression(), do: {:pow, {:var, "x"}, {:sum, {:num, 12}, {:mul, {:var, "x"}, {:num, 8.2}}}}
    @spec sample_evaluation() :: Expression.t()
    def sample_evaluation(), do: {:sum, {:num, 2}, {:num, 2}}

    @spec test_parse() :: Expression.expression
    def test_parse() do
        sample = sample_input()
        IO.puts("Parsing \"#{sample}\"")
        result = Parser.parse(sample_input())
        IO.puts("Parsed result: \"#{Expression.toString(result)}\"")
        result
    end
    @spec test_pipeline() :: Expression.expression
    def test_pipeline() do
        sample = test_parse()
        result = Expression.evaluate(sample)
        IO.puts("Simplified: \"#{Expression.toString(result)}\"")
        result = Derivative.derive(result, "x")
        IO.puts("Derivative result: \"#{Expression.toString(result)}\"")
        result
    end


end