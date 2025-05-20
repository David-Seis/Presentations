#Demo1 String Interpolation and Variable Assignment
    $characterName = "Frodo Baggins"
    $characterJob = "Ring-bearer"
    $Role = "Hobbit of the Shire"

    # Use variables in a string
    $message = "Greetings, I am $($characterName), a $characterJob and I am a $Role on a quest to destroy the One Ring."

    # Output the message
    Write-Output $message

#Demo2 Variable Reassignment and Arithmetic Operations
    # Demonstrating variable reassignment and arithmetic operations
    $number1 = 10
    $number2 = 20

    # Perform addition
    $sum = $number1 + $number2
    Write-Output "The sum of $number1 and $number2 is $sum."

    # Reassign variables
    $number1 = 15
    $number2 = 25

    # Perform multiplication
    $product = $number1 * $number2
    Write-Output "The product of $number1 and $number2 is `$$product."

