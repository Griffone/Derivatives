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
        | {:const, number}
        | {:sum, expression, expression}
        | {:sub, expression, expression}
        | {:mul, expression, expression}
        | {:div, expression, expression}

    @doc """
    Attempt to evaluate an expression.
    Will perform any available functions.
    """
    @spec evaluate(expression) :: expression | :illegal_expression
    def evaluate({:sum, {:const, a}, {:const, b}}), do: {:const, a + b}
    def evaluate({:sum, a, {:const, 0}}), do: a
    def evaluate({:sum, {:const, 0}, b}), do: b
    def evaluate({:sub, {:const, a}, {:const, b}}), do: {:const, a - b}
    def evaluate({:sub, a, {:const, 0}}), do: a
    def evaluate({:mul, {:const, a}, {:const, b}}), do: {:const, a * b}
    def evaluate({:mul, _, {:const, 0}}), do: {:const, 0}
    def evaluate({:mul, {:const, 0}, _}), do: {:const, 0}
    def evaluate({:mul, a, {:const, 1}}), do: a
    def evaluate({:mul, {:const, 1}, b}), do: b
    def evaluate({:div, {:const, a}, {:const, b}}), do: {:const, a / b}
    def evaluate({:div, _, {:const, 0}}), do: :illegal_expression
    def evaluate({:div, 0, _}), do: {:const, 0}
    def evaluate({op, a, b}) do
        a = evaluate(a)
        b = evaluate(b)
        case a do
            {:const, _} ->
                evaluate({op, a, b})
            _ ->
                case b do
                    {:const, _} ->
                        evaluate({op, a, b})
                    _ ->
                        {op, a, b}
                end
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
    def parse(string), do: parse(string, nil)
    def parse(string, result), do: result
end