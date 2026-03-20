"""Simple calculator module.

This module provides basic arithmetic operations: addition, subtraction,
multiplication, and division.
"""


def add(a: float, b: float) -> float:
    """Add two numbers."""
    return a + b


def subtract(a: float, b: float) -> float:
    """Subtract the second number from the first."""
    return a - b


def multiply(a: float, b: float) -> float:
    """Multiply two numbers."""
    return a * b


def divide(a: float, b: float) -> float:
    """Divide two numbers and handle division by zero."""
    if b == 0:
        raise ValueError("Cannot divide by zero.")
    return a / b
