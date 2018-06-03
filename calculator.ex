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
    @spec derivative(expression, variableId) :: expression
    @spec derivative(variableId, expression) :: expression
    def derivative(expression, var) when is_tuple(expression), do: Expression.evaluate(deriv(var, Expression.evaluate(expression)))
    def derivative(var, expression) when is_tuple(expression), do: deriv(var, Expression.evaluate(expression))
    @spec deriv(variableId, expression) :: expression
    defp deriv(x, {:num, _}), do: {:num, 0}
    defp deriv(x, {:var, x}), do: {:num, 1}
    defp deriv(x, {:var, y}), do: {:var, y}
    defp deriv(x, {:sum, a, b}), do: {:sum, deriv(x, a), deriv(x, b)}
    defp deriv(x, {:sub, a, b}), do: {:sub, deriv(x, a), deriv(x, b)}
    defp deriv(x, {:mul, {:var, x}, b}), do: b
    defp deriv(x, {:mul, a, {:var, x}}), do: a
    defp deriv(x, {:mul, a, b}), do: {:sum, {:mul, deriv(x, a), b}, {:mul, a, deriv(x, b)}}
    defp deriv(x, {:pow, {:var, x}, b}), do: {:mul, b, {:pow, {:var, x}, {:sub, b, {:num, 1}}}}
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

    @doc """
    Attempt to evaluate an expression.
    Will perform any available functions.
    """
    @spec evaluate(expression) :: expression | :illegal_expression
    def evaluate({:sum, a, {:num, b}}) when b < 0, do: {:sub, a, {:num, -b}}
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
    def evaluate({:mul, {:var, v}, {:var, v}}), do: {:pow, {:var, v}, {:num, 2}}
    def evaluate({:div, {:num, a}, {:num, b}}), do: {:num, a / b}
    def evaluate({:div, _, {:num, 0}}), do: :illegal_expression
    def evaluate({:div, {:num, 0}, _}), do: {:num, 0}
    def evaluate({:div, a, {:num, 1}}), do: a
    def evaluate({:pow, a, {:num, 1}}), do: a
    def evaluate({:pow, {:num, 0}, {:num, 0}}), do: :illegal_expression
    def evaluate({:pow, {:num, 0}, a}), do: {:num, 0}
    def evaluate({:pow, a, {:num, 0}}), do: {:num, 1}
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

    def toString(expression), do: expr_to_str(expression)

    defp expr_to_str({:mul, {:num, n}, {:var, v}}), do: "#{n}#{v}"
    defp expr_to_str({:mul, {:var, v}, {:num, n}}), do: "#{n}#{v}"
    defp expr_to_str({op, {opA, aa, ab}, {opB, ba, bb}}), do: "(" <> expr_to_str({opA, aa, ab}) <> ")" <> op_to_str(op) <> "(" <> expr_to_str({opB, ba, bb}) <> ")"
    defp expr_to_str({op, {opA, aa, ab}, b}), do: "(" <> expr_to_str({opA, aa, ab}) <> ")" <> op_to_str(op) <> expr_to_str(b)
    defp expr_to_str({op, a, {opB, ba, bb}}), do: expr_to_str(a) <> op_to_str(op) <> "(" <> expr_to_str({opB, ba, bb}) <> ")"
    defp expr_to_str({op, a, b}), do: expr_to_str(a) <> op_to_str(op) <> expr_to_str(b)
    defp expr_to_str({:num, n}), do: "#{n}"
    defp expr_to_str({:var, v}), do: "#{v}"

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
    Returns resulting expression.
    """
    @strings_ops    ["+", "-", "*", "/", "^"]
    # An operator is {operator, symbol, priority}
    @ops_list       [{:sum, "+", 1}, {:sub, "-", 1}, {:mul, "*", 2}, {:div, "/", 2}, {:pow, "^", 3}]
    @regex_num      ~r{\d}
    @regex_var      ~r{[[:alpha:]]}

    @type prefix_item :: {:var, Expression.variableId}
        | {:num, number}
        | :sum
        | :sub
        | :mul
        | :div
        | :pow

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
    Parses a function operator. More for future proofing, once we get stuff like log and stuff.
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